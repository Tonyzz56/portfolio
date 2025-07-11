import 'package:cloud_firestore/cloud_firestore.dart';

class TermModel {
  final String id; // Firestore document ID
  final String institutionId;
  final String academicYearId; // Link to the AcademicYearModel
  final String name; // e.g., "Term 1", "Semester 1", "Spring 2024"
  final DateTime startDate;
  final DateTime endDate;
  bool isCurrentTerm; // Is this the currently active term within the academic year?
                      // (Consider: only one term should be current at a time per institution)
  final DateTime createdAt;
  DateTime updatedAt;

  TermModel({
    required this.id,
    required this.institutionId,
    required this.academicYearId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isCurrentTerm = false,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(endDate.isAfter(startDate), "End date must be after start date");

  factory TermModel.fromMap(Map<String, dynamic> data, String documentId) {
    return TermModel(
      id: documentId,
      institutionId: data['institutionId'] ?? '',
      academicYearId: data['academicYearId'] ?? '',
      name: data['name'] ?? 'Unnamed Term',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 90)),
      isCurrentTerm: data['isCurrentTerm'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'institutionId': institutionId,
      'academicYearId': academicYearId,
      'name': name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isCurrentTerm': isCurrentTerm,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
