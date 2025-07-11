import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {
  final String id; // Firestore document ID
  final String institutionId;
  final String name; // e.g., "Grade 1A", "Form 2 Blue", "Computer Science Year 1"
  String? academicYearId; // Link to the current AcademicYearModel this class instance pertains to
                         // Or, classes might be defined more generically and then instanced per year/term.
                         // For now, linking directly to an academic year.
  String? termId; // Optional: if this class instance is specific to a term within the academic year
  String? classTeacherUid; // UID of the main class teacher/homeroom teacher
  String? roomNumber;
  int? capacity;
  List<String>? studentUids; // List of UIDs of students enrolled in this class

  final DateTime createdAt;
  DateTime updatedAt;

  ClassModel({
    required this.id,
    required this.institutionId,
    required this.name,
    this.academicYearId,
    this.termId,
    this.classTeacherUid,
    this.roomNumber,
    this.capacity,
    this.studentUids,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClassModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ClassModel(
      id: documentId,
      institutionId: data['institutionId'] ?? '',
      name: data['name'] ?? 'Unnamed Class',
      academicYearId: data['academicYearId'] as String?,
      termId: data['termId'] as String?,
      classTeacherUid: data['classTeacherUid'] as String?,
      roomNumber: data['roomNumber'] as String?,
      capacity: data['capacity'] as int?,
      studentUids: (data['studentUids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'institutionId': institutionId,
      'name': name,
      'academicYearId': academicYearId,
      'termId': termId,
      'classTeacherUid': classTeacherUid,
      'roomNumber': roomNumber,
      'capacity': capacity,
      'studentUids': studentUids,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
