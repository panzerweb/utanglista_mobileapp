import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utanglista_mobileapp/core/error/error_definition.dart';
import 'package:utanglista_mobileapp/core/money/money.dart';
import 'package:utanglista_mobileapp/features/customers/domain/entities/customer_balance.dart';
import 'package:utanglista_mobileapp/features/customers/domain/repositories/customer_balance_repository.dart';
import 'package:utanglista_mobileapp/features/payments/data/model/payment_model.dart';
import 'package:utanglista_mobileapp/features/payments/domain/entities/payment_entity.dart';
import 'package:utanglista_mobileapp/features/payments/domain/repositories/payment_repository.dart';

const Object _unset = Object();

/*
  ------------------------------------------------------------------
  Payment history — a store's, or one customer's.
  ------------------------------------------------------------------
*/
enum PaymentListStateStatus { initial, loading, success, failure }

class PaymentListState {
  final int storeId;
  final int? customerId;
  final List<PaymentEntity> payments;
  final PaymentListStateStatus status;
  final AppFailure? error;

  const PaymentListState({
    required this.storeId,
    this.customerId,
    this.payments = const [],
    this.status = PaymentListStateStatus.initial,
    this.error,
  });

  bool get isEmpty =>
      status == PaymentListStateStatus.success && payments.isEmpty;

  Money get totalReceived =>
      payments.map((payment) => payment.amount).sum();

  PaymentListState copyWith({
    List<PaymentEntity>? payments,
    PaymentListStateStatus? status,
    Object? error = _unset,
  }) {
    return PaymentListState(
      storeId: storeId,
      customerId: customerId,
      payments: payments ?? this.payments,
      status: status ?? this.status,
      error: identical(error, _unset) ? this.error : error as AppFailure?,
    );
  }
}

class PaymentListCubit extends Cubit<PaymentListState> {
  final PaymentRepository repository;

  PaymentListCubit(this.repository, {required int storeId, int? customerId})
    : super(PaymentListState(storeId: storeId, customerId: customerId));

  Future<void> loadPayments() async {
    emit(state.copyWith(error: null, status: PaymentListStateStatus.loading));

    try {
      final payments = await repository.fetchPayments(
        state.storeId,
        customerId: state.customerId,
      );

      emit(
        state.copyWith(
          payments: payments,
          status: PaymentListStateStatus.success,
          error: null,
        ),
      );
    } on AppFailure catch (e) {
      emit(state.copyWith(error: e, status: PaymentListStateStatus.failure));
    } catch (e) {
      emit(
        state.copyWith(
          error: AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
          status: PaymentListStateStatus.failure,
        ),
      );
    }
  }
}

/*
  ------------------------------------------------------------------
  Recording a payment.
  ------------------------------------------------------------------

  Loads the balance first so the form can show what is owed and cap
  the amount. That cap is a COURTESY — the authoritative §23 check
  runs inside the datasource's database transaction, because a balance
  read out here can be stale by the time the write lands.
*/
enum RecordPaymentStatus { loading, ready, submitting, submitted, failure }

class RecordPaymentState {
  final int storeId;
  final int customerId;
  final String customerName;
  final CustomerBalance balance;
  final RecordPaymentStatus status;
  final int? createdPaymentId;
  final AppFailure? error;

  /*
    Whether the balance was ever read successfully.

    Needed because `balance` is CustomerBalance.zero both before the
    first load AND for a customer who genuinely owes nothing — the
    screen has to tell "could not load" apart from "nothing to pay",
    and the value alone cannot.
  */
  final bool hasLoadedBalance;

  const RecordPaymentState({
    required this.storeId,
    required this.customerId,
    this.customerName = '',
    this.balance = CustomerBalance.zero,
    this.status = RecordPaymentStatus.loading,
    this.createdPaymentId,
    this.error,
    this.hasLoadedBalance = false,
  });

  bool get isSubmitting => status == RecordPaymentStatus.submitting;

  /// §23: the most this customer may pay right now.
  Money get maximumPayment => balance.maximumPayment;

  bool get hasOutstanding => balance.hasDebt;

  /// True only when the balance failed to load in the first place —
  /// a rejected payment is a different thing and stays on the form.
  bool get isLoadFailure =>
      status == RecordPaymentStatus.failure && !hasLoadedBalance;

  RecordPaymentState copyWith({
    String? customerName,
    CustomerBalance? balance,
    RecordPaymentStatus? status,
    Object? createdPaymentId = _unset,
    Object? error = _unset,
    bool? hasLoadedBalance,
  }) {
    return RecordPaymentState(
      storeId: storeId,
      customerId: customerId,
      customerName: customerName ?? this.customerName,
      balance: balance ?? this.balance,
      status: status ?? this.status,
      hasLoadedBalance: hasLoadedBalance ?? this.hasLoadedBalance,
      createdPaymentId: identical(createdPaymentId, _unset)
          ? this.createdPaymentId
          : createdPaymentId as int?,
      error: identical(error, _unset) ? this.error : error as AppFailure?,
    );
  }
}

class RecordPaymentCubit extends Cubit<RecordPaymentState> {
  final PaymentRepository repository;
  final CustomerBalanceRepository balanceRepository;

  RecordPaymentCubit(
    this.repository,
    this.balanceRepository, {
    required int storeId,
    required int customerId,
  }) : super(
         RecordPaymentState(storeId: storeId, customerId: customerId),
       );

  Future<void> loadBalance({String? customerName}) async {
    emit(
      state.copyWith(
        status: RecordPaymentStatus.loading,
        error: null,
        customerName: customerName,
      ),
    );

    try {
      final balance = await balanceRepository.fetchBalanceForCustomer(
        state.customerId,
      );

      emit(
        state.copyWith(
          balance: balance,
          status: RecordPaymentStatus.ready,
          error: null,
          hasLoadedBalance: true,
        ),
      );
    } on AppFailure catch (e) {
      emit(state.copyWith(error: e, status: RecordPaymentStatus.failure));
    } catch (e) {
      emit(
        state.copyWith(
          error: AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
          status: RecordPaymentStatus.failure,
        ),
      );
    }
  }

  /*
    Guarded against a double tap the same way the transaction builder
    is. Even if two calls got through, the datasource's transaction
    would reject the second as an overpayment — but not writing it in
    the first place is better than relying on that.
  */
  Future<void> submit(Money amount, {String? note}) async {
    if (state.isSubmitting) return;

    emit(
      state.copyWith(status: RecordPaymentStatus.submitting, error: null),
    );

    try {
      final paymentId = await repository.recordPayment(
        PaymentPayloadModel(
          storeId: state.storeId,
          customerId: state.customerId,
          amount: amount,
          note: note,
        ),
      );

      emit(
        state.copyWith(
          status: RecordPaymentStatus.submitted,
          createdPaymentId: paymentId,
          error: null,
        ),
      );
    } on AppFailure catch (e) {
      /*
        OVERPAYMENT carries the real outstanding figure, which means
        the balance this screen was showing is stale — something was
        recorded elsewhere while the seller was typing. Refresh so the
        cap and the "Pay full balance" shortcut are right on the retry.
      */
      emit(state.copyWith(status: RecordPaymentStatus.failure, error: e));

      if (e.code == 'OVERPAYMENT' || e.code == 'NO_OUTSTANDING_BALANCE') {
        await loadBalance();
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: RecordPaymentStatus.failure,
          error: AppFailure(
            code: 'UNKNOWN_ERROR',
            message: "Something unexpected happened!",
          ),
        ),
      );
    }
  }
}
