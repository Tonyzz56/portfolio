import 'package:cloud_firestore/cloud_firestore.dart';

class DepartmentModel {
  final String id; // Firestore document ID
  final String name; // e.g., "Finance", "IT Support", "Administration"
  final String institutionId; // ID of the institution this department belongs to
  String? description;
  String? headOfDepartmentUid; // Optional: UID of the user who is HOD
  DateTime createdAt;
  DateTime updatedAt;

  DepartmentModel({
    required this.id,
    required this.name,
    required this.institutionId,
    this.description,
    this.headOfDepartmentUid,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DepartmentModel.fromMap(Map<String, dynamic> data, String documentId) {
    return DepartmentModel(
      id: documentId,
      name: data['name'] ?? 'Unnamed Department',
      institutionId: data['institutionId'] ?? '', // Should always be present
      description: data['description'] as String?,
      headOfDepartmentUid: data['headOfDepartmentUid'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'institutionId': institutionId,
      'description': description,
      'headOfDepartmentUid': headOfDepartmentUid,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      // id is the document ID, not stored as a field
    };
  }
}
