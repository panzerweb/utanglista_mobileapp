import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utanglista_mobileapp/core/money/interest_rate.dart';
import 'package:utanglista_mobileapp/core/services/service_locator.dart';
import 'package:utanglista_mobileapp/core/shared/app_confirm_dialog.dart';
import 'package:utanglista_mobileapp/core/shared/app_snack_bar.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_error_view.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_loading_view.dart';
import 'package:utanglista_mobileapp/core/shared/views/empty_state_view.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';
import 'package:utanglista_mobileapp/core/utils/app_date_format.dart';
import 'package:utanglista_mobileapp/features/interest/domain/entities/interest_preview.dart';
import 'package:utanglista_mobileapp/features/interest/presentation/bloc/interest_cubit.dart';

/*
  ------------------------------------------------------------------
  Charging a month's interest.
  ------------------------------------------------------------------

  Manual, not automatic. §22 requires that interest is never applied
  twice for a period, and the unique (customerId, periodKey) index
  makes that a database guarantee — so an automatic trigger would be
  SAFE. It is manual anyway because §21 makes each charge permanent
  and V1 has no reversal: the seller should see who is affected and
  decide, not discover it later in a ledger.

  Once this path has been used in anger, an automatic on-open check
  becomes a small change — the guard it would need already exists.
*/
class ApplyInterestScreen extends StatelessWidget {
  final int storeId;
  final InterestRate rate;

  const ApplyInterestScreen({
    super.key,
    required this.storeId,
    required this.rate,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ApplyInterestCubit(
        locator(),
        storeId: storeId,
        rate: rate,
        // Defaults to this month; the seller can step back to one they
        // missed.
        periodKey: AppDateFormat.periodKey(DateTime.now()),
      )..loadPreview(),
      child: const _ApplyInterestView(),
    );
  }
}

class _ApplyInterestView extends StatelessWidget {
  const _ApplyInterestView();

  /*
    The confirmation states the figures rather than asking "are you
    sure?" — the seller is agreeing to a specific amount across a
    specific number of people, and V1 cannot undo it.
  */
  Future<void> _confirmAndApply(
    BuildContext context,
    ApplyInterestState state,
  ) async {
    final cubit = context.read<ApplyInterestCubit>();
    final preview = state.preview!;

    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Charge ${state.periodLabel} interest?',
      message:
          '${preview.chargeCount} '
          '${preview.chargeCount == 1 ? 'customer' : 'customers'} will be '
          'charged ${preview.totalInterest.format()} in total, at '
          '${state.rate.formatPercent()} of what they owed entering '
          '${state.periodLabel}.\n\n'
          'Anything they took during the month is charged next month '
          'instead. Interest charges cannot be undone.',
      confirmLabel: 'Charge interest',
    );

    if (!confirmed || !context.mounted) return;

    await cubit.apply();
  }

  void _onState(BuildContext context, ApplyInterestState state) {
    if (state.status == ApplyInterestStatus.applied && state.result != null) {
      final result = state.result!;

      if (result.hasFailures) {
        AppSnackBar.warning(
          context,
          'Charged ${result.appliedCount}, '
          '${result.failures.length} could not be charged.',
        );
        return;
      }

      AppSnackBar.success(
        context,
        'Charged ${result.totalCharged.format()} to '
        '${result.appliedCount} '
        '${result.appliedCount == 1 ? 'customer' : 'customers'}.',
      );
      return;
    }

    if (state.status == ApplyInterestStatus.failure && state.error != null) {
      AppSnackBar.failure(context, state.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ApplyInterestCubit, ApplyInterestState>(
      listener: _onState,
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppPalette.background,
          appBar: AppBar(
            backgroundColor: AppPalette.primaryDark,
            foregroundColor: AppPalette.surface,
            title: Text(
              'Monthly interest',
              style: AppTextStyles.body1.copyWith(
                color: AppPalette.surface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: _buildBody(context, state),
          bottomNavigationBar: state.canApply
              ? _ApplyBar(
                  state: state,
                  onApply: () => _confirmAndApply(context, state),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ApplyInterestState state) {
    final cubit = context.read<ApplyInterestCubit>();

    if (state.status == ApplyInterestStatus.loading && state.preview == null) {
      return const AppLoadingView(message: 'Working out interest...');
    }

    if (state.status == ApplyInterestStatus.failure &&
        state.preview == null &&
        state.error != null) {
      return AppErrorView(failure: state.error!, onRetry: cubit.loadPreview);
    }

    final preview = state.preview;
    if (preview == null) {
      return const AppLoadingView(message: 'Working out interest...');
    }

    return Column(
      children: [
        _PeriodSelector(state: state, onShift: cubit.shiftPeriod),

        Expanded(
          child: preview.lines.isEmpty
              ? const EmptyStateView(
                  icon: Icons.people_outline_rounded,
                  title: 'No customers yet',
                  message:
                      'Add customers to this store before charging '
                      'interest.',
                )
              : _PreviewList(state: state, preview: preview),
        ),
      ],
    );
  }
}

// ============================================================
// PERIOD
// ============================================================
class _PeriodSelector extends StatelessWidget {
  final ApplyInterestState state;
  final ValueChanged<int> onShift;

  const _PeriodSelector({required this.state, required this.onShift});

  @override
  Widget build(BuildContext context) {
    final thisMonth = AppDateFormat.periodKey(DateTime.now());
    // Charging a month that has not happened yet is almost always a
    // mis-tap, so forward stops at the current one.
    final canGoForward = state.periodKey.compareTo(thisMonth) < 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: const BoxDecoration(
        color: AppPalette.surface,
        border: Border(bottom: BorderSide(color: AppPalette.border)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous month',
            onPressed: state.isApplying ? null : () => onShift(-1),
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppPalette.primaryDark,
          ),

          Expanded(
            child: Column(
              children: [
                Text(
                  state.periodLabel,
                  style: AppTextStyles.subtitle1.copyWith(
                    color: AppPalette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${state.rate.formatPercent()} of what was owed entering '
                  'this month',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: canGoForward ? 'Next month' : 'This is the current month',
            onPressed: (state.isApplying || !canGoForward)
                ? null
                : () => onShift(1),
            icon: const Icon(Icons.chevron_right_rounded),
            color: AppPalette.primaryDark,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PREVIEW
// ============================================================
class _PreviewList extends StatelessWidget {
  final ApplyInterestState state;
  final InterestPreview preview;

  const _PreviewList({required this.state, required this.preview});

  @override
  Widget build(BuildContext context) {
    final toCharge = preview.toCharge;
    final skipped = preview.skipped;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _Summary(preview: preview),

        const SizedBox(height: 20),

        if (toCharge.isNotEmpty) ...[
          _SectionLabel('Will be charged (${toCharge.length})'),
          for (final line in toCharge)
            _PreviewCard(line: line, rate: state.rate),
          const SizedBox(height: 20),
        ],

        if (skipped.isNotEmpty) ...[
          _SectionLabel('Skipped (${skipped.length})'),
          for (final line in skipped) _PreviewCard(line: line, rate: state.rate),
        ],
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  final InterestPreview preview;

  const _Summary({required this.preview});

  @override
  Widget build(BuildContext context) {
    // Everything already charged reads differently from nothing to do.
    if (preview.isFullyApplied) {
      return _Banner(
        icon: Icons.check_circle_outline_rounded,
        color: AppPalette.success,
        title: 'Already charged',
        message:
            'Interest for this month has been applied. It cannot be '
            'charged twice.',
      );
    }

    if (!preview.hasAnythingToApply) {
      return const _Banner(
        icon: Icons.info_outline_rounded,
        color: AppPalette.textSecondary,
        title: 'Nothing to charge',
        message:
            'No customer owed anything entering this month. Debts taken '
            'during the month are charged next month instead.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.primaryDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interest to charge',
            style: AppTextStyles.caption1.copyWith(
              color: AppPalette.primarySoft,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            preview.totalInterest.format(),
            style: AppTextStyles.heading1.copyWith(
              color: AppPalette.surface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${preview.chargeCount} '
            '${preview.chargeCount == 1 ? 'customer' : 'customers'} • '
            '${preview.rate.formatPercent()} of '
            '${preview.totalBase.format()} carried into the month',
            style: AppTextStyles.caption1.copyWith(
              color: AppPalette.primarySoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final InterestPreviewLine line;
  final InterestRate rate;

  const _PreviewCard({required this.line, required this.rate});

  @override
  Widget build(BuildContext context) {
    final willCharge = line.willApply;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.border),
      ),
      child: Opacity(
        opacity: willCharge ? 1 : 0.65,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body1.copyWith(
                      color: AppPalette.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    willCharge
                        // §21's base, shown so the arithmetic is checkable.
                        ? 'Owed ${line.baseAmount.format()} entering '
                              'the month'
                        : line.skipReason!,
                    style: AppTextStyles.caption1.copyWith(
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            if (willCharge)
              Text(
                '+${line.interestAmount.format()}',
                style: AppTextStyles.body1.copyWith(
                  color: AppPalette.warning,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              const Icon(
                Icons.remove_rounded,
                size: 18,
                color: AppPalette.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
class _ApplyBar extends StatelessWidget {
  final ApplyInterestState state;
  final VoidCallback onApply;

  const _ApplyBar({required this.state, required this.onApply});

  @override
  Widget build(BuildContext context) {
    final preview = state.preview!;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: const BoxDecoration(
        color: AppPalette.surface,
        border: Border(top: BorderSide(color: AppPalette.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 14,
                  color: AppPalette.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Interest charges are permanent and cannot be undone.',
                    style: AppTextStyles.caption1.copyWith(
                      color: AppPalette.textMuted,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: state.isApplying ? null : onApply,
                icon: state.isApplying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppPalette.surface,
                        ),
                      )
                    : const Icon(Icons.percent_rounded),
                label: Text(
                  state.isApplying
                      ? 'Charging...'
                      : 'Charge ${preview.totalInterest.format()}',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.primaryDark,
                  foregroundColor: AppPalette.surface,
                  disabledBackgroundColor: AppPalette.textMuted,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _Banner({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body1.copyWith(
                    color: AppPalette.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTextStyles.caption1.copyWith(
                    color: AppPalette.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.caption1.copyWith(
          color: AppPalette.textMuted,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
