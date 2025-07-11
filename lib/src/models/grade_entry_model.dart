import 'package:cloud_firestore/cloud_firestore.dart';

class GradeEntryModel {
  final String id; // Firestore document ID
  final String institutionId;
  final String studentUid;
  final String classId; // Class student was in when assessment was taken
  final String subjectId;
  final String assessmentId; // Link to AssessmentModel
  final String academicYearId;
  final String? termId;

  double marksObtained;
  String? gradeAwarded; // e.g., "A+", "B", "Pass", "Merit" (derived based on grading scale)
  String? comments;     // Teacher's comments on this specific entry

  final String gradedByUid; // UID of the teacher who entered/graded this
  final DateTime dateGraded;  // When this entry was created/last updated
  final DateTime createdAt; // Firestore server timestamp ideally for creation
  DateTime updatedAt; // Firestore server timestamp for updates

  GradeEntryModel({
    required this.id,
    required this.institutionId,
    required this.studentUid,
    required this.classId,
    required this.subjectId,
    required this.assessmentId,
    required this.academicYearId,
    this.termId,
    required this.marksObtained,
    this.gradeAwarded,
    this.comments,
    required this.gradedByUid,
    required this.dateGraded, // This could be same as updatedAt or a specific "published" date for grades
    required this.createdAt,
    required this.updatedAt,
  });

  factory GradeEntryModel.fromMap(Map<String, dynamic> data, String documentId) {
    return GradeEntryModel(
      id: documentId,
      institutionId: data['institutionId'] ?? '',
      studentUid: data['studentUid'] ?? '',
      classId: data['classId'] ?? '',
      subjectId: data['subjectId'] ?? '',
      assessmentId: data['assessmentId'] ?? '',
      academicYearId: data['academicYearId'] ?? '',
      termId: data['termId'] as String?,
      marksObtained: (data['marksObtained'] ?? 0.0).toDouble(),
      gradeAwarded: data['gradeAwarded'] as String?,
      comments: data['comments'] as String?,
      gradedByUid: data['gradedByUid'] ?? '',
      dateGraded: (data['dateGraded'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'institutionId': institutionId,
      'studentUid': studentUid,
      'classId': classId,
      'subjectId': subjectId,
      'assessmentId': assessmentId,
      'academicYearId': academicYearId,
      'termId': termId,
      'marksObtained': marksObtained,
      'gradeAwarded': gradeAwarded,
      'comments': comments,
      'gradedByUid': gradedByUid,
      'dateGraded': Timestamp.fromDate(dateGraded),
      'createdAt': FieldValue.serverTimestamp(), // Use server timestamp on create
      'updatedAt': FieldValue.serverTimestamp(), // Use server timestamp on update
    };
  }
}
