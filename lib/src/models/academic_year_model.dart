import 'package:cloud_firestore/cloud_firestore.dart';

class AcademicYearModel {
  final String id; // Firestore document ID
  final String institutionId;
  final String name; // e.g., "2023-2024", "AY2024"
  final DateTime startDate;
  final DateTime endDate;
  bool isActive; // Is this the currently active academic year for the institution?
  // (Consider: only one academic year should be active at a time per institution)
  final DateTime createdAt;
  DateTime updatedAt;

  AcademicYearModel({
    required this.id,
    required this.institutionId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isActive = false,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(endDate.isAfter(startDate), "End date must be after start date");

  factory AcademicYearModel.fromMap(Map<String, dynamic> data, String documentId) {
    return AcademicYearModel(
      id: documentId,
      institutionId: data['institutionId'] ?? '',
      name: data['name'] ?? 'Unnamed Academic Year',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 365)),
      isActive: data['isActive'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'institutionId': institutionId,
      'name': name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
