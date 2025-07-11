import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectModel {
  final String id; // Firestore document ID
  final String institutionId;
  final String name; // e.g., "Mathematics", "Physics", "History"
  final String code; // e.g., "MATH101", "PHY202" (optional, but good for uniqueness)
  String? description;
  // List<String> teacherUids; // Teachers qualified or assigned to teach this subject (could be managed in a linking collection too)
  // String? departmentId; // Optional: if subjects are tied to departments (e.g. Science Dept offers Physics)

  final DateTime createdAt;
  DateTime updatedAt;

  SubjectModel({
    required this.id,
    required this.institutionId,
    required this.name,
    required this.code,
    this.description,
    // this.teacherUids = const [],
    // this.departmentId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubjectModel.fromMap(Map<String, dynamic> data, String documentId) {
    return SubjectModel(
      id: documentId,
      institutionId: data['institutionId'] ?? '',
      name: data['name'] ?? 'Unnamed Subject',
      code: data['code'] ?? '',
      description: data['description'] as String?,
      // teacherUids: List<String>.from(data['teacherUids'] ?? []),
      // departmentId: data['departmentId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'institutionId': institutionId,
      'name': name,
      'code': code,
      'description': description,
      // 'teacherUids': teacherUids,
      // 'departmentId': departmentId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
