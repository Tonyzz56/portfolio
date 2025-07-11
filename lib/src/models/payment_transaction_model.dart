import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMethod {
  mpesa,
  cash,
  bankTransfer,
  card, // Credit/Debit Card
  scholarship,
  waiver,
  other,
}

enum PaymentStatus {
  pending,    // e.g., Mpesa STK push sent, awaiting confirmation
  successful, // Payment confirmed
  failed,     // Payment attempt failed
  refunded,   // Payment was refunded
  cancelled,
}

class PaymentTransactionModel {
  final String id; // Firestore document ID
  final String institutionId;
  final String studentUid;
  // final String feeStructureId; // Optional: Link to specific FeeStructure item being paid for
  final List<String>? feeStructureIds; // Optional: If payment covers multiple fee items
  final String? invoiceId; // Optional: Link to an invoice document if invoices are generated

  final double amountPaid;
  final String currency;
  final DateTime paymentDate; // When the payment was made/recorded
  final PaymentMethod paymentMethod;
  final PaymentStatus status;

  final String? transactionReference; // e.g., Mpesa transaction ID, bank slip number, card auth code
  final String? paymentGatewayCheckoutId; // e.g., Daraja CheckoutRequestID for Mpesa STK

  final String recordedByUid; // UID of staff who recorded manual payment, or system for online
  String? notes; // Any notes by admin/staff regarding this payment

  final DateTime createdAt;
  DateTime updatedAt;

  PaymentTransactionModel({
    required this.id,
    required this.institutionId,
    required this.studentUid,
    this.feeStructureIds,
    this.invoiceId,
    required this.amountPaid,
    this.currency = "KES",
    required this.paymentDate,
    required this.paymentMethod,
    required this.status,
    this.transactionReference,
    this.paymentGatewayCheckoutId,
    required this.recordedByUid,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentTransactionModel.fromMap(Map<String, dynamic> data, String documentId) {
    return PaymentTransactionModel(
      id: documentId,
      institutionId: data['institutionId'] ?? '',
      studentUid: data['studentUid'] ?? '',
      feeStructureIds: (data['feeStructureIds'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      invoiceId: data['invoiceId'] as String?,
      amountPaid: (data['amountPaid'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'KES',
      paymentDate: (data['paymentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentMethod: paymentMethodFromString(data['paymentMethod'] as String?),
      status: paymentStatusFromString(data['status'] as String?),
      transactionReference: data['transactionReference'] as String?,
      paymentGatewayCheckoutId: data['paymentGatewayCheckoutId'] as String?,
      recordedByUid: data['recordedByUid'] ?? '',
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'institutionId': institutionId,
      'studentUid': studentUid,
      'feeStructureIds': feeStructureIds,
      'invoiceId': invoiceId,
      'amountPaid': amountPaid,
      'currency': currency,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'paymentMethod': paymentMethod.toString().split('.').last,
      'status': status.toString().split('.').last,
      'transactionReference': transactionReference,
      'paymentGatewayCheckoutId': paymentGatewayCheckoutId,
      'recordedByUid': recordedByUid,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

PaymentMethod paymentMethodFromString(String? methodString) {
  if (methodString == null) return PaymentMethod.other;
  switch (methodString.toLowerCase()) {
    case 'mpesa': return PaymentMethod.mpesa;
    case 'cash': return PaymentMethod.cash;
    case 'banktransfer': return PaymentMethod.bankTransfer;
    case 'card': return PaymentMethod.card;
    case 'scholarship': return PaymentMethod.scholarship;
    case 'waiver': return PaymentMethod.waiver;
    default: return PaymentMethod.other;
  }
}

String paymentMethodToString(PaymentMethod method) {
  return method.toString().split('.').last;
}

PaymentStatus paymentStatusFromString(String? statusString) {
  if (statusString == null) return PaymentStatus.pending;
  switch (statusString.toLowerCase()) {
    case 'pending': return PaymentStatus.pending;
    case 'successful': return PaymentStatus.successful;
    case 'failed': return PaymentStatus.failed;
    case 'refunded': return PaymentStatus.refunded;
    case 'cancelled': return PaymentStatus.cancelled;
    default: return PaymentStatus.pending;
  }
}

String paymentStatusToString(PaymentStatus status) {
  return status.toString().split('.').last;
}
