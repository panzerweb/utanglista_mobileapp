import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:utanglista_mobileapp/core/services/service_locator.dart';
import 'package:utanglista_mobileapp/core/shared/app_snack_bar.dart';
import 'package:utanglista_mobileapp/core/shared/textfield/global_text_field.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_error_view.dart';
import 'package:utanglista_mobileapp/core/shared/views/app_loading_view.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';
import 'package:utanglista_mobileapp/features/customers/data/model/customer_payload_model.dart';
import 'package:utanglista_mobileapp/features/customers/domain/entities/customer_entity.dart';
import 'package:utanglista_mobileapp/features/customers/presentation/bloc/customer_cubit.dart';
import 'package:utanglista_mobileapp/features/customers/presentation/bloc/customer_state.dart';

/*
  Create and edit a customer, sharing one screen — the same reasoning
  as StoreFormScreen: two fields, two rules, one place to change them.
*/
class CustomerFormScreen extends StatelessWidget {
  final int storeId;

  /// null == create.
  final int? customerId;

  const CustomerFormScreen({
    super.key,
    required this.storeId,
    this.customerId,
  });

  bool get _isEditing => customerId != null;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => locator<CustomerFormCubit>()),
        BlocProvider(
          create: (_) {
            final cubit = locator<CustomerDetailCubit>();
            if (_isEditing) cubit.loadCustomer(customerId!);
            return cubit;
          },
        ),
      ],
      child: _isEditing
          ? _EditCustomerLoader(storeId: storeId, customerId: customerId!)
          : _CustomerFormView(storeId: storeId),
    );
  }
}

/// Waits for the existing customer so the controllers can be seeded
/// once, in initState.
class _EditCustomerLoader extends StatelessWidget {
  final int storeId;
  final int customerId;

  const _EditCustomerLoader({required this.storeId, required this.customerId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerDetailCubit, CustomerDetailState>(
      builder: (context, state) {
        if (state.status == CustomerDetailStateStatus.failure &&
            state.error != null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit customer')),
            body: AppErrorView(
              failure: state.error!,
              onRetry: () =>
                  context.read<CustomerDetailCubit>().loadCustomer(customerId),
            ),
          );
        }

        if (state.customer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit customer')),
            body: const AppLoadingView(message: 'Loading customer...'),
          );
        }

        return _CustomerFormView(storeId: storeId, existing: state.customer);
      },
    );
  }
}

class _CustomerFormView extends StatefulWidget {
  final int storeId;
  final CustomerEntity? existing;

  const _CustomerFormView({required this.storeId, this.existing});

  @override
  State<_CustomerFormView> createState() => _CustomerFormViewState();
}

class _CustomerFormViewState extends State<_CustomerFormView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _contactController;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _contactController = TextEditingController(
      text: widget.existing?.contactNumber ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  // ========================================================
  // ** VALIDATION **
  // Mirrors the cubit's rules so the user is told before submitting.
  // The cubit still checks: this is convenience, not the guarantee.
  // ========================================================

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.length < 2) return 'Name must be at least 2 characters';
    if (name.length > 60) return 'Name must be 60 characters or fewer';

    return null;
  }

  /*
    §4: contact is OPTIONAL, so blank passes. Only the length is
    checked — Philippine numbers get written every possible way, and
    rejecting a format the seller uses would just stop them recording
    it at all.
  */
  String? _validateContact(String? value) {
    final contact = value?.trim() ?? '';

    if (contact.length > 20) {
      return 'Contact number must be 20 characters or fewer';
    }

    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final cubit = context.read<CustomerFormCubit>();

    if (_isEditing) {
      cubit.editCustomer(
        UpdateCustomerPayloadModel(
          customerId: widget.existing!.id,
          name: _nameController.text.trim(),
          // '' is a deliberate clear, not "leave alone" — see
          // UpdateCustomerPayloadModel.
          contactNumber: _contactController.text.trim(),
        ),
      );
      return;
    }

    cubit.insertCustomer(
      CustomerPayloadModel(
        storeId: widget.storeId,
        name: _nameController.text.trim(),
        contactNumber: _contactController.text.trim(),
      ),
    );
  }

  void _onFormState(BuildContext context, CustomerFormState state) {
    switch (state) {
      case CustomerFormSuccess():
        AppSnackBar.success(context, 'Customer added.');
        context.pop();

      case CustomerFormUpdated():
        AppSnackBar.success(context, 'Changes saved.');
        context.pop();

      case CustomerFormFailure(:final error):
        AppSnackBar.failure(context, error);

      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomerFormCubit, CustomerFormState>(
      listener: _onFormState,
      builder: (context, state) {
        final isBusy =
            state is CustomerFormSubmitting || state is CustomerFormUpdating;

        return Scaffold(
          backgroundColor: AppPalette.background,
          appBar: AppBar(
            backgroundColor: AppPalette.primaryDark,
            foregroundColor: AppPalette.surface,
            title: Text(
              _isEditing ? 'Edit customer' : 'New customer',
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
                  GlobalTextField(
                    label: 'Full name',
                    fieldController: _nameController,
                    validator: _validateName,
                  ),

                  const SizedBox(height: 16),

                  GlobalTextField(
                    label: 'Contact number (optional)',
                    fieldController: _contactController,
                    validator: _validateContact,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Optional. Useful for following up on utang.',
                    style: AppTextStyles.caption1.copyWith(
                      color: AppPalette.textMuted,
                    ),
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
                            : (_isEditing ? 'Save changes' : 'Add customer'),
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
