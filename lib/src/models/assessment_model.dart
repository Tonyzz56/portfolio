import 'package:cloud_firestore/cloud_firestore.dart';

class AssessmentModel {
  final String id; // Firestore document ID
  final String institutionId;
  final String name; // e.g., "Mid-Term Exam", "Quiz 1", "Homework Assignment"
  final String? description;

  final String academicYearId; // Which academic year this assessment belongs to
  final String? termId;         // Optional: if assessment is specific to a term
  final String? classId;        // Optional: if assessment is for a whole class (e.g. class test)
                                // If classId is null, it might be a subject-level assessment applicable to multiple classes taking the subject.
  final String subjectId;      // Assessment is usually for a specific subject.


  final double maxMarks;
  final double? weightage; // e.g., 0.20 for 20% towards final grade for the subject in a term/year
  final DateTime? assessmentDate; // Date of the assessment or due date

  final String createdByUid; // User who created/defined this assessment
  final DateTime createdAt;
  DateTime updatedAt;

  AssessmentModel({
    required this.id,
    required this.institutionId,
    required this.name,
    this.description,
    required this.academicYearId,
    this.termId,
    this.classId, // Can be null if it's a general subject assessment not tied to one class
    required this.subjectId,
    required this.maxMarks,
    this.weightage,
    this.assessmentDate,
    required this.createdByUid,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AssessmentModel.fromMap(Map<String, dynamic> data, String documentId) {
    return AssessmentModel(
      id: documentId,
      institutionId: data['institutionId'] ?? '',
      name: data['name'] ?? 'Unnamed Assessment',
      description: data['description'] as String?,
      academicYearId: data['academicYearId'] ?? '',
      termId: data['termId'] as String?,
      classId: data['classId'] as String?,
      subjectId: data['subjectId'] ?? '',
      maxMarks: (data['maxMarks'] ?? 0.0).toDouble(),
      weightage: (data['weightage'] as num?)?.toDouble(),
      assessmentDate: (data['assessmentDate'] as Timestamp?)?.toDate(),
      createdByUid: data['createdByUid'] ?? '',
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
      'subjectId': subjectId,
      'maxMarks': maxMarks,
      'weightage': weightage,
      'assessmentDate': assessmentDate != null ? Timestamp.fromDate(assessmentDate!) : null,
      'createdByUid': createdByUid,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
