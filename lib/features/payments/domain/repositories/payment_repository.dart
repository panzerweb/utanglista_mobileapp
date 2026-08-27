import 'package:utanglista_mobileapp/core/helper/repository_guard.dart';
import 'package:utanglista_mobileapp/features/payments/data/datasource/payment_local_data_source.dart';
import 'package:utanglista_mobileapp/features/payments/data/model/payment_model.dart';
import 'package:utanglista_mobileapp/features/payments/domain/entities/payment_entity.dart';

/*
  ------------------------------------------------------------------
  Payments are recorded and read. Never edited, never deleted.
  ------------------------------------------------------------------

  §30: deleting a financial record changes accounting history, so V1
  does not offer it — there is no update or delete method here, and
  that absence is the feature. If corrections are ever supported they
  will be explicit reversal events (§25, §31), not mutations of this
  row.

  The §23 overpayment guard is NOT in this layer. It has to read the
  balance inside the same database transaction as the insert, so it
  lives in the datasource — see the note there.
*/
abstract class PaymentRepository {
  Future<int> recordPayment(PaymentPayloadModel payload);
  Future<PaymentEntity?> fetchPaymentById(int paymentId);
  Future<List<PaymentEntity>> fetchPayments(
    int storeId, {
    int? customerId,
    int? limit,
  });
}

class PaymentRepositoryImplementation implements PaymentRepository {
  final PaymentLocalDataSource localDataSource;

  PaymentRepositoryImplementation(this.localDataSource);

  // ========================================================
  // ** PAYMENT METHODS **
  // ========================================================
  @override
  Future<int> recordPayment(PaymentPayloadModel payload) {
    return repositoryGuard(
      () => localDataSource.recordPayment(payload),
      failureMessage: "Could not record this payment.",
    );
  }

  @override
  Future<PaymentEntity?> fetchPaymentById(int paymentId) {
    return repositoryGuard(() async {
      final model = await localDataSource.fetchPaymentById(paymentId);
      return model?.toEntity();
    }, failureMessage: "Could not load this payment.");
  }

  @override
  Future<List<PaymentEntity>> fetchPayments(
    int storeId, {
    int? customerId,
    int? limit,
  }) {
    return repositoryGuard(() async {
      final models = await localDataSource.fetchPayments(
        storeId,
        customerId: customerId,
        limit: limit,
      );

      return models.map((model) => model.toEntity()).toList();
    }, failureMessage: "Could not load payments.");
  }
}
