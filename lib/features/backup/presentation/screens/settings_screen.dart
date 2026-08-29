import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/core/services/service_locator.dart';
import 'package:utanglista_mobileapp/core/shared/app_confirm_dialog.dart';
import 'package:utanglista_mobileapp/core/shared/app_snack_bar.dart';
import 'package:utanglista_mobileapp/core/shared/main_app_bar.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';
import 'package:utanglista_mobileapp/core/utils/app_date_format.dart';
import 'package:utanglista_mobileapp/features/backup/presentation/bloc/backup_cubit.dart';

/*
  ==================================================================
  APP SETTINGS — currently, backup and restore.
  ==================================================================

  The third bottom-bar destination. Store settings (interest, rename,
  delete) live on the store itself; this screen is for things that
  span every store, which today means the backup.

  ------------------------------------------------------------------
  This is the only screen that touches the outside world, and it
  still makes no network call.
  ------------------------------------------------------------------

  Export writes the file to the app's own cache directory and hands
  its path to the OPERATING SYSTEM's share sheet. Where it goes from
  there — Drive, Messenger, a USB cable — is the user's choice, made
  in an OS dialog this app cannot see the result of. Import is the
  same in reverse: the OS file picker returns a path, and this screen
  reads it.

  So UtangLista still opens no sockets and has no server. What it has
  is a door the user opens themselves.
*/
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<BackupCubit>(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  /*
    ------------------------------------------------------------------
    EXPORT: cache file, then the share sheet.
    ------------------------------------------------------------------

    The file goes to the cache directory rather than Documents on
    purpose. It is a handoff, not storage — once the share sheet has
    it, the copy that matters is wherever the user sent it, and a
    cache the OS is free to clear is the right home for a duplicate of
    data the app already holds.
  */
  Future<void> _share(BuildContext context, BackupExported state) async {
    final cubit = context.read<BackupCubit>();

    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/${state.suggestedFileName}');

      await file.writeAsString(state.json, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          fileNameOverrides: [state.suggestedFileName],
          subject: 'UtangLista backup',
        ),
      );
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.failure(
          context,
          AppFailure(
            code: 'SHARE_FAILED',
            message: 'Could not share the backup file.',
          ),
        );
      }
    } finally {
      // Back to idle either way: the share sheet gives no usable
      // answer about what the user did, so treating "sheet closed" as
      // either success or failure would be inventing information.
      cubit.reset();
    }
  }

  /*
    ------------------------------------------------------------------
    IMPORT: pick, read, describe — and only then ask.
    ------------------------------------------------------------------

    Nothing is written here. The file is read and handed to the cubit,
    which validates it and reports what is inside; the confirmation
    happens after that, so the user is approving a described backup
    rather than a filename.
  */
  Future<void> _pickBackup(BuildContext context) async {
    final cubit = context.read<BackupCubit>();

    try {
      final picked = await FilePicker.pickFile(
        dialogTitle: 'Choose a UtangLista backup',
        type: FileType.any,
      );

      // Cancelled. Not a failure, and not worth a snackbar.
      if (picked == null) return;

      /*
        Read through `xFile`, not `path`. On Android the picker returns
        a content:// URI whose `path` is null — reading by path would
        work in a simulator and fail on the phones this app is for.
      */
      final contents = await picked.xFile.readAsString(encoding: utf8);

      await cubit.prepareRestore(contents);
    } catch (e) {
      cubit.reset();

      if (context.mounted) {
        AppSnackBar.failure(
          context,
          AppFailure(
            code: 'FILE_READ_FAILED',
            message: 'Could not read that file.',
          ),
        );
      }
    }
  }

  /*
    The most consequential dialog in the app. It names what is in the
    file, when it was made, and says plainly that everything currently
    in the app goes — because "Restore?" alone gives someone no way to
    tell a good backup from a stale one.
  */
  Future<void> _confirmRestore(
    BuildContext context,
    BackupReadyToRestore state,
  ) async {
    final cubit = context.read<BackupCubit>();

    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Replace everything with this backup?',
      message:
          'From ${AppDateFormat.withTime(state.summary.exportedAt)}.\n\n'
          'It contains ${state.summary.describe()}.\n\n'
          'Everything currently in UtangLista on this phone will be '
          'removed and replaced. This cannot be undone.',
      confirmLabel: 'Replace my data',
      isDestructive: true,
    );

    if (!confirmed) {
      cubit.reset();
      return;
    }

    await cubit.confirmRestore(state.json);
  }

  void _onState(BuildContext context, BackupState state) {
    switch (state) {
      case BackupExported():
        _share(context, state);

      case BackupReadyToRestore():
        _confirmRestore(context, state);

      case BackupRestored(:final rowCount):
        AppSnackBar.success(context, 'Restored $rowCount records.');
        context.read<BackupCubit>().reset();

      case BackupFailed(:final error):
        AppSnackBar.failure(context, error);
        context.read<BackupCubit>().reset();

      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: const MainAppBar(),
      body: BlocConsumer<BackupCubit, BackupState>(
        listener: _onState,
        builder: (context, state) {
          final busy = state is BackupExporting ||
              state is BackupReadingFile ||
              state is BackupRestoring;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text(
                'Settings',
                style: AppTextStyles.subtitle1.copyWith(
                  color: AppPalette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'UtangLista keeps everything on this phone. A backup is '
                'the only copy that survives losing it.',
                style: AppTextStyles.body1.copyWith(
                  color: AppPalette.textSecondary,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              _BackupCard(
                busy: busy,
                busyLabel: state is BackupExporting
                    ? 'Preparing backup...'
                    : null,
                onExport: busy
                    ? null
                    : () => context.read<BackupCubit>().exportBackup(),
                onImport: busy ? null : () => _pickBackup(context),
                restoring: state is BackupRestoring,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BackupCard extends StatelessWidget {
  final bool busy;
  final bool restoring;
  final String? busyLabel;
  final VoidCallback? onExport;
  final VoidCallback? onImport;

  const _BackupCard({
    required this.busy,
    required this.restoring,
    required this.busyLabel,
    required this.onExport,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppPalette.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.backup_outlined,
                  size: 18,
                  color: AppPalette.primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Backup & restore',
                style: AppTextStyles.body1.copyWith(
                  color: AppPalette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            'Save a copy of every store, customer, product, utang, '
            'payment and interest charge as a single file. Send it to '
            'yourself somewhere safe.',
            style: AppTextStyles.caption1.copyWith(
              color: AppPalette.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: onExport,
              icon: const Icon(Icons.ios_share_rounded, size: 20),
              label: Text(busyLabel ?? 'Save a backup'),
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.primaryDark,
                foregroundColor: AppPalette.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onImport,
              icon: restoring
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppPalette.primaryDark,
                      ),
                    )
                  : const Icon(Icons.settings_backup_restore_rounded, size: 20),
              label: Text(restoring ? 'Restoring...' : 'Restore a backup'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppPalette.primaryDark,
                side: const BorderSide(color: AppPalette.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          /*
            Said before the button is pressed, not only in the
            confirmation dialog. Someone deciding whether to tap
            "Restore" deserves to know it is a replacement rather than
            a merge while they are still deciding.
          */
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: AppPalette.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Restoring REPLACES everything on this phone with the '
                  'contents of the file. It does not merge.',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppPalette.textMuted,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
