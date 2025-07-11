import 'package:cloud_firestore/cloud_firestore.dart';

enum FeePaymentStatus {
  pending, // Fee assigned, no payment yet
  partiallyPaid,
  paid,
  overdue,
  waived,
  cancelled, // If a fee assignment was cancelled
}

// Represents an instance of a specific fee item assigned to a student.
class StudentFeeStatusModel {
  final String id; // Firestore document ID (could be auto-generated)
  final String institutionId;
  final String studentUid;
  final String feeStructureId; // Link to the specific FeeStructureModel item

  final String academicYearId; // Context for which AY this fee instance applies
  final String? termId;        // Context for which Term this fee instance applies (if applicable)
  final String? classId;       // Context: Student's class when this fee was assigned/due

  final String feeItemName; // Copied from FeeStructureModel for easier display
  final double amountDue;   // Copied from FeeStructureModel
  double amountPaid;
  double get balance => amountDue - amountPaid;

  final DateTime originalDueDate; // Copied from FeeStructureModel or set at assignment
  DateTime? actualPaymentDate; // Date of last/full payment for this specific item

  FeePaymentStatus paymentStatus;
  List<String> paymentTransactionIds; // Links to PaymentTransactionModel documents for this fee item

  final DateTime createdAt; // When this fee was assigned to the student
  DateTime updatedAt;   // Last update to this status (e.g., payment received)

  StudentFeeStatusModel({
    required this.id,
    required this.institutionId,
    required this.studentUid,
    required this.feeStructureId,
    required this.academicYearId,
    this.termId,
    this.classId,
    required this.feeItemName,
    required this.amountDue,
    this.amountPaid = 0.0,
    required this.originalDueDate,
    this.actualPaymentDate,
    this.paymentStatus = FeePaymentStatus.pending,
    this.paymentTransactionIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudentFeeStatusModel.fromMap(Map<String, dynamic> data, String documentId) {
    return StudentFeeStatusModel(
      id: documentId,
      institutionId: data['institutionId'] ?? '',
      studentUid: data['studentUid'] ?? '',
      feeStructureId: data['feeStructureId'] ?? '',
      academicYearId: data['academicYearId'] ?? '',
      termId: data['termId'] as String?,
      classId: data['classId'] as String?,
      feeItemName: data['feeItemName'] ?? 'N/A',
      amountDue: (data['amountDue'] ?? 0.0).toDouble(),
      amountPaid: (data['amountPaid'] ?? 0.0).toDouble(),
      originalDueDate: (data['originalDueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      actualPaymentDate: (data['actualPaymentDate'] as Timestamp?)?.toDate(),
      paymentStatus: feePaymentStatusFromString(data['paymentStatus'] as String?),
      paymentTransactionIds: List<String>.from(data['paymentTransactionIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'institutionId': institutionId,
      'studentUid': studentUid,
      'feeStructureId': feeStructureId,
      'academicYearId': academicYearId,
      'termId': termId,
      'classId': classId,
      'feeItemName': feeItemName,
      'amountDue': amountDue,
      'amountPaid': amountPaid,
      'balance': balance, // Calculated, but can be stored for querying/convenience
      'originalDueDate': Timestamp.fromDate(originalDueDate),
      'actualPaymentDate': actualPaymentDate != null ? Timestamp.fromDate(actualPaymentDate!) : null,
      'paymentStatus': paymentStatus.toString().split('.').last,
      'paymentTransactionIds': paymentTransactionIds,
      'createdAt': FieldValue.serverTimestamp(), // Use server timestamp on create
      'updatedAt': FieldValue.serverTimestamp(), // Use server timestamp on update
    };
  }
}

FeePaymentStatus feePaymentStatusFromString(String? statusString) {
  if (statusString == null) return FeePaymentStatus.pending;
  switch (statusString.toLowerCase()) {
    case 'pending': return FeePaymentStatus.pending;
    case 'partiallypaid': return FeePaymentStatus.partiallyPaid;
    case 'paid': return FeePaymentStatus.paid;
    case 'overdue': return FeePaymentStatus.overdue;
    case 'waived': return FeePaymentStatus.waived;
    case 'cancelled': return FeePaymentStatus.cancelled;
    default: return FeePaymentStatus.pending;
  }
}

String feePaymentStatusToString(FeePaymentStatus status) {
  return status.toString().split('.').last;
}
