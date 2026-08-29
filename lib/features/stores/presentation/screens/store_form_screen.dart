import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:utanglista_mobileapp/core/constants/enum.dart';
import 'package:utanglista_mobileapp/core/money/interest_rate.dart';
import 'package:utanglista_mobileapp/core/services/service_locator.dart';
import 'package:utanglista_mobileapp/core/shared/app_snack_bar.dart';
import 'package:utanglista_mobileapp/core/shared/dropdown/global_generic_dropdown.dart';
import 'package:utanglista_mobileapp/core/shared/textfield/global_text_field.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_error_view.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_loading_view.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';
import 'package:utanglista_mobileapp/features/stores/data/model/store_payload_model.dart';
import 'package:utanglista_mobileapp/features/stores/domain/entities/store_entity.dart';
import 'package:utanglista_mobileapp/features/stores/presentation/bloc/store_cubit.dart';
import 'package:utanglista_mobileapp/features/stores/presentation/bloc/store_state.dart';

/*
  Create and edit share one screen, told apart by [storeId].

  They are the same six fields with the same rules; two screens would
  mean two places to change when a field is added, and they would drift.

  On edit the store is loaded first so the fields start populated —
  an edit form that opens blank invites the user to wipe a description
  they meant to keep.
*/
class StoreFormScreen extends StatelessWidget {
  /// null == create.
  final int? storeId;

  const StoreFormScreen({super.key, this.storeId});

  bool get _isEditing => storeId != null;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => locator<StoreFormCubit>()),
        BlocProvider(
          create: (_) {
            final cubit = locator<StoreDetailCubit>();
            if (_isEditing) cubit.loadStore(storeId!);
            return cubit;
          },
        ),
      ],
      child: _isEditing
          ? _EditStoreLoader(storeId: storeId!)
          : const _StoreFormView(),
    );
  }
}

/// Waits for the existing store before building the form, so the
/// controllers can be seeded exactly once in initState.
class _EditStoreLoader extends StatelessWidget {
  final int storeId;

  const _EditStoreLoader({required this.storeId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoreDetailCubit, StoreDetailState>(
      builder: (context, state) {
        if (state.status == StoreDetailStateStatus.failure &&
            state.error != null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit store')),
            body: AppErrorView(
              failure: state.error!,
              onRetry: () =>
                  context.read<StoreDetailCubit>().loadStore(storeId),
            ),
          );
        }

        if (state.store == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit store')),
            body: const AppLoadingView(message: 'Loading store...'),
          );
        }

        return _StoreFormView(existing: state.store);
      },
    );
  }
}

class _StoreFormView extends StatefulWidget {
  final StoreEntity? existing;

  const _StoreFormView({this.existing});

  @override
  State<_StoreFormView> createState() => _StoreFormViewState();
}

class _StoreFormViewState extends State<_StoreFormView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _rateController;

  StoreCategory? _category;
  bool _interestEnabled = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;

    _nameController = TextEditingController(text: existing?.name ?? '');
    _descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    _rateController = TextEditingController(
      text: existing?.monthlyInterestRate.toEditableString() ?? '',
    );

    _category = existing?.category;
    _interestEnabled = existing?.monthlyInterestEnabled ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  // ========================================================
  // ** VALIDATION **
  // Mirrors the cubit's rules so the user is told before submitting.
  // The cubit still checks: this is convenience, not the guarantee.
  // ========================================================

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.length < 2) return 'Store name must be at least 2 characters';
    if (name.length > 60) return 'Store name must be 60 characters or fewer';

    return null;
  }

  /// §19: 0%-5%, with InterestRate owning the range.
  String? _validateRate(String? value) {
    if (!_interestEnabled) return null;

    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return 'Enter a monthly interest rate';

    final rate = InterestRate.tryParsePercent(raw);
    if (rate == null) return 'Enter a number, for example 2 or 2.5';

    if (!rate.isValid) {
      return 'Rate must be between 0% and '
          '${InterestRate.maximum.formatPercent()}';
    }

    return null;
  }

  InterestRate get _enteredRate =>
      InterestRate.tryParsePercent(_rateController.text) ?? InterestRate.zero;

  // ========================================================
  // ** SUBMIT **
  // ========================================================

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final cubit = context.read<StoreFormCubit>();

    if (_isEditing) {
      cubit.editStoreDetail(
        UpdateStorePayloadModel(
          storeId: widget.existing!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _category,
          monthlyInterestEnabled: _interestEnabled,
          // Persist zero when interest is off, so switching it back on
          // does not resurrect a rate the user thought they removed.
          monthlyInterestRate: _interestEnabled
              ? _enteredRate
              : InterestRate.zero,
        ),
      );
      return;
    }

    cubit.insertStore(
      StorePayloadModel(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        monthlyInterestEnabled: _interestEnabled,
        monthlyInterestRate: _interestEnabled
            ? _enteredRate
            : InterestRate.zero,
      ),
    );
  }

  void _onFormState(BuildContext context, StoreFormState state) {
    switch (state) {
      case StoreFormSuccess():
        AppSnackBar.success(context, 'Store created.');
        context.pop();

      case StoreFormUpdated():
        AppSnackBar.success(context, 'Changes saved.');
        context.pop();

      case StoreFormFailure(:final error):
        AppSnackBar.failure(context, error);

      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StoreFormCubit, StoreFormState>(
      listener: _onFormState,
      builder: (context, state) {
        final isBusy =
            state is StoreFormSubmitting || state is StoreFormUpdating;

        return Scaffold(
          backgroundColor: AppPalette.background,
          appBar: AppBar(
            backgroundColor: AppPalette.primaryDark,
            foregroundColor: AppPalette.surface,
            title: Text(
              _isEditing ? 'Edit store' : 'New store',
              style: AppTextStyles.body1.copyWith(
                color: AppPalette.surface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [
                  _SectionLabel('Store details'),

                  GlobalTextField(
                    label: 'Store name',
                    fieldController: _nameController,
                    validator: _validateName,
                  ),

                  const SizedBox(height: 16),

                  GlobalTextField(
                    label: 'Description (optional)',
                    fieldController: _descriptionController,
                    minLines: 3,
                    maxLines: 5,
                  ),

                  const SizedBox(height: 16),

                  GlobalGenericDropdown<StoreCategory>(
                    labelOfDropdown: 'Category',
                    selectedValue: _category,
                    itemsList: StoreCategory.values,
                    itemLabel: (category) => category.label,
                    icon: Icons.storefront_outlined,
                    onChanged: (value) => setState(() => _category = value),
                  ),

                  if (_category != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _category!.description,
                      style: AppTextStyles.caption1.copyWith(
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  _SectionLabel('Monthly interest'),

                  _InterestSection(
                    enabled: _interestEnabled,
                    rateController: _rateController,
                    validator: _validateRate,
                    onToggled: (value) {
                      setState(() => _interestEnabled = value);
                      // Re-validate so the rate error clears the moment
                      // interest is switched off.
                      _formKey.currentState?.validate();
                    },
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: isBusy ? null : _submit,
                      icon: isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppPalette.surface,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                        isBusy
                            ? 'Saving...'
                            : (_isEditing ? 'Save changes' : 'Create store'),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppPalette.primaryDark,
                        foregroundColor: AppPalette.surface,
                        disabledBackgroundColor: AppPalette.textMuted,
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
          ),
        );
      },
    );
  }
}

// ============================================================
// INTEREST
// ============================================================
/*
  §19: interest is optional and capped at 5%.

  The rate field only appears once the switch is on. Showing a disabled
  field alongside an off switch says the same thing twice, and invites
  the user to type into something that will be ignored.
*/
class _InterestSection extends StatelessWidget {
  final bool enabled;
  final TextEditingController rateController;
  final FormFieldValidator<String> validator;
  final ValueChanged<bool> onToggled;

  const _InterestSection({
    required this.enabled,
    required this.rateController,
    required this.validator,
    required this.onToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Charge monthly interest',
                      style: AppTextStyles.body1.copyWith(
                        color: AppPalette.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Optional. Applied to what a customer still owes.',
                      style: AppTextStyles.caption1.copyWith(
                        color: AppPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              Switch(
                value: enabled,
                onChanged: onToggled,
                activeThumbColor: AppPalette.surface,
                activeTrackColor: AppPalette.primary,
              ),
            ],
          ),

          if (enabled) ...[
            const SizedBox(height: 16),

            TextFormField(
              controller: rateController,
              validator: validator,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: AppTextStyles.body1.copyWith(
                color: AppPalette.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'Monthly rate',
                hintText: '2',
                suffixText: '%',
                helperText:
                    'Between 0% and '
                    '${InterestRate.maximum.formatPercent()}',
                filled: true,
                fillColor: AppPalette.accentSoft,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                labelStyle: AppTextStyles.body1.copyWith(
                  color: AppPalette.textSecondary,
                ),
                helperStyle: AppTextStyles.caption1.copyWith(
                  color: AppPalette.textMuted,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppPalette.accentSoft,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppPalette.primary,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppPalette.danger,
                    width: 1,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppPalette.danger,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
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
      padding: const EdgeInsets.only(bottom: 12),
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
