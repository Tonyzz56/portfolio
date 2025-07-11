import 'package:cloud_firestore/cloud_firestore.dart';

// Defines a single fee item or a collection of items that form a structure for a class/program.
// This can be flexible. For example, one document per fee type per class per term.
class FeeStructureModel {
  final String id; // Firestore document ID
  final String institutionId;
  final String name; // e.g., "Grade 1 - Term 1 Tuition", "Standard Transport Fee - Route A"
  final String? description;

  final String academicYearId; // Link to AcademicYearModel
  final String? termId;         // Optional: If fee structure is term-specific
  final String? classId;        // Optional: If fee structure is class-specific
  // If classId is null, it might be a general institutional fee (e.g. application fee) or a template.

  // This can be a list of fee items if a "structure" groups multiple items
  // Or, each FeeStructureModel can represent a single fee item.
  // Let's go with a single fee item per document for simplicity initially.
  final String feeItemName; // e.g., "Tuition", "Exam Fee", "Bus Fee"
  final double amount;
  final String currency; // e.g., "KES"
  final DateTime dueDate;

  bool isActive; // If this fee structure is currently applicable/active
  final DateTime createdAt;
  DateTime updatedAt;

  FeeStructureModel({
    required this.id,
    required this.institutionId,
    required this.name, // Overall name for this fee structure/item entry
    this.description,
    required this.academicYearId,
    this.termId,
    this.classId,
    required this.feeItemName,
    required this.amount,
    this.currency = "KES",
    required this.dueDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeeStructureModel.fromMap(Map<String, dynamic> data, String documentId) {
    return FeeStructureModel(
      id: documentId,
      institutionId: data['institutionId'] ?? '',
      name: data['name'] ?? 'Unnamed Fee Structure',
      description: data['description'] as String?,
      academicYearId: data['academicYearId'] ?? '',
      termId: data['termId'] as String?,
      classId: data['classId'] as String?,
      feeItemName: data['feeItemName'] ?? 'Unnamed Fee Item',
      amount: (data['amount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'KES',
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 30)),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'institutionId': institutionId,
      'name': name,
      'description': description,
      'academicYearId': academicYearId,
      'termId': termId,
      'classId': classId,
      'feeItemName': feeItemName,
      'amount': amount,
      'currency': currency,
      'dueDate': Timestamp.fromDate(dueDate),
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(), // Use server timestamp
      'updatedAt': FieldValue.serverTimestamp(), // Use server timestamp
    };
  }
}
