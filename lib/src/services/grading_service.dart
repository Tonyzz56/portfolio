import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management_system/src/models/assessment_model.dart';
import 'package:school_management_system/src/models/grade_entry_model.dart';

class GradingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _assessmentsCollection = 'assessments';
  final String _gradeEntriesCollection = 'grade_entries';

  // --- Assessment Methods ---

  Future<AssessmentModel?> createAssessment(AssessmentModel assessment, String createdByUid) async {
    try {
      DocumentReference docRef = _firestore.collection(_assessmentsCollection).doc();
      AssessmentModel newAssessment = AssessmentModel(
        id: docRef.id,
        institutionId: assessment.institutionId,
        name: assessment.name,
        description: assessment.description,
        academicYearId: assessment.academicYearId,
        termId: assessment.termId,
        classId: assessment.classId,
        subjectId: assessment.subjectId,
        maxMarks: assessment.maxMarks,
        weightage: assessment.weightage,
        assessmentDate: assessment.assessmentDate,
        createdByUid: createdByUid, // Ensure this is set
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await docRef.set(newAssessment.toMap());
      return newAssessment;
    } catch (e) {
      print("Error creating assessment: $e");
      return null;
    }
  }

  Stream<List<AssessmentModel>> getAssessments({
    required String institutionId,
    String? academicYearId,
    String? termId,
    String? classId,
    String? subjectId,
  }) {
    Query query = _firestore.collection(_assessmentsCollection).where('institutionId', isEqualTo: institutionId);
    if (academicYearId != null) query = query.where('academicYearId', isEqualTo: academicYearId);
    if (termId != null) query = query.where('termId', isEqualTo: termId);
    if (classId != null) query = query.where('classId', isEqualTo: classId);
    if (subjectId != null) query = query.where('subjectId', isEqualTo: subjectId);

    return query.orderBy('assessmentDate', descending: true).snapshots().map((snapshot) => snapshot.docs
        .map((doc) => AssessmentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  Future<bool> updateAssessment(String assessmentId, Map<String, dynamic> data) async {
    try {
      Map<String, dynamic> updateData = Map.from(data);
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(_assessmentsCollection).doc(assessmentId).update(updateData);
      return true;
    } catch (e) {
      print("Error updating assessment $assessmentId: $e");
      return false;
    }
  }

  Future<bool> deleteAssessment(String assessmentId) async {
    try {
      // TODO: Check if grades exist for this assessment before deleting.
      // Query grade_entries where assessmentId == assessmentId. If count > 0, prevent deletion or warn.
      // final gradesExist = await _firestore.collection(_gradeEntriesCollection).where('assessmentId', isEqualTo: assessmentId).limit(1).get();
      // if (gradesExist.docs.isNotEmpty) {
      //   throw Exception("Cannot delete assessment: Grades have already been entered for it.");
      // }
      await _firestore.collection(_assessmentsCollection).doc(assessmentId).delete();
      return true;
    } catch (e) {
      print("Error deleting assessment $assessmentId: $e");
      if (e.toString().contains("Cannot delete assessment")) throw e;
      return false;
    }
  }

  // --- Grade Entry Methods ---

  Future<bool> saveGradeEntries(List<GradeEntryModel> gradeEntries, String gradedByUid) async {
    if (gradeEntries.isEmpty) return true;

    WriteBatch batch = _firestore.batch();
    DateTime now = DateTime.now();

    for (var entryInput in gradeEntries) {
      DocumentReference docRef;
      Map<String, dynamic> dataToSave;

      // If entryInput.id is empty or a placeholder, it's a new record.
      // Otherwise, it's an update to an existing record.
      bool isNewRecord = entryInput.id.isEmpty || entryInput.id == "TEMP_NEW_GRADE_ID_PLACEHOLDER";

      if (!isNewRecord) { // Update existing
        docRef = _firestore.collection(_gradeEntriesCollection).doc(entryInput.id);
        // Construct map for update, ensuring server timestamp for updatedAt
        dataToSave = {
          'marksObtained': entryInput.marksObtained,
          'gradeAwarded': entryInput.gradeAwarded,
          'comments': entryInput.comments,
          'gradedByUid': gradedByUid,
          'dateGraded': Timestamp.fromDate(entryInput.dateGraded), // Or now, depending on logic
          'updatedAt': FieldValue.serverTimestamp(),
          // Ensure other fields like studentUid, assessmentId etc., are not changed by mistake.
          // Only updateable fields should be in this map.
        };
        // If you need to ensure certain fields are NEVER updated, remove them from dataToSave here.
        // For example, you wouldn't typically change studentUid or assessmentId on an existing grade entry.
        batch.update(docRef, dataToSave);
      } else { // Create new
        docRef = _firestore.collection(_gradeEntriesCollection).doc(); // New ID
        GradeEntryModel newEntry = GradeEntryModel(
            id: docRef.id,
            institutionId: entryInput.institutionId,
            studentUid: entryInput.studentUid,
            classId: entryInput.classId,
            subjectId: entryInput.subjectId,
            assessmentId: entryInput.assessmentId,
            academicYearId: entryInput.academicYearId,
            termId: entryInput.termId,
            marksObtained: entryInput.marksObtained,
            gradeAwarded: entryInput.gradeAwarded,
            comments: entryInput.comments,
            gradedByUid: gradedByUid,
            dateGraded: entryInput.dateGraded, // This should be 'now' or date of grading action
            createdAt: now, // Placeholder, will be server timestamp
            updatedAt: now  // Placeholder, will be server timestamp
        );
        dataToSave = newEntry.toMap(); // This toMap uses FieldValue.serverTimestamp()
        batch.set(docRef, dataToSave);
      }
    }
    try {
      await batch.commit();
      return true;
    } catch (e) {
      print("Error saving grade entries: $e");
      return false;
    }
  }

  Stream<List<GradeEntryModel>> getGradesForStudent({
    required String studentUid,
    required String institutionId,
    String? academicYearId,
    String? termId,
    String? classId, // Usually student is in one class per term/year
    String? subjectId,
  }) {
    Query query = _firestore.collection(_gradeEntriesCollection)
        .where('institutionId', isEqualTo: institutionId)
        .where('studentUid', isEqualTo: studentUid);

    if (academicYearId != null) query = query.where('academicYearId', isEqualTo: academicYearId);
    if (termId != null) query = query.where('termId', isEqualTo: termId);
    if (classId != null) query = query.where('classId', isEqualTo: classId);
    if (subjectId != null) query = query.where('subjectId', isEqualTo: subjectId);

    return query.orderBy('dateGraded', descending: true).snapshots().map((snapshot) => snapshot.docs
        .map((doc) => GradeEntryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  Stream<List<GradeEntryModel>> getGradesForAssessment({
    required String assessmentId,
    required String institutionId,
    String? classId,
  }) {
     Query query = _firestore.collection(_gradeEntriesCollection)
        .where('institutionId', isEqualTo: institutionId)
        .where('assessmentId', isEqualTo: assessmentId);
    if (classId != null) query = query.where('classId', isEqualTo: classId);
    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => GradeEntryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  Future<bool> deleteGradeEntry(String gradeEntryId) async {
    try {
      await _firestore.collection(_gradeEntriesCollection).doc(gradeEntryId).delete();
      return true;
    } catch (e) {
      print("Error deleting grade entry $gradeEntryId: $e");
      return false;
    }
  }
}
