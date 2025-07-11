import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management_system/src/models/attendance_record_model.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'attendance_records';

  // Mark attendance for multiple students for a specific slot (batch write)
  Future<bool> markBatchAttendance(List<AttendanceRecordModel> records) async {
    if (records.isEmpty) return true; // No records to save

    WriteBatch batch = _firestore.batch();
    DateTime now = DateTime.now();

    for (var record in records) {
      // Check if a record for this student, date, class, subject(optional), period(optional) already exists.
      // If so, update it. Otherwise, create new.
      // This query can be complex. A simpler approach for now is to assume new records for each marking session,
      // or that the UI handles fetching existing records for update.
      // For this version, we'll assume new records or that record.id is pre-set if updating.

      DocumentReference docRef;
      AttendanceRecordModel recordToSave;

      if (record.id.isNotEmpty) { // Indicates an existing record to update
        docRef = _firestore.collection(_collectionPath).doc(record.id);
        recordToSave = AttendanceRecordModel(
          id: record.id, // Keep existing ID
          institutionId: record.institutionId,
          academicYearId: record.academicYearId,
          termId: record.termId,
          classId: record.classId,
          studentUid: record.studentUid,
          date: record.date, // Keep original date
          subjectId: record.subjectId,
          periodSlot: record.periodSlot,
          status: record.status,
          markedByUid: record.markedByUid,
          remarks: record.remarks,
          createdAt: record.createdAt, // Preserve original creation time
          updatedAt: now, // Update time
        );
        batch.update(docRef, recordToSave.toMap());
      } else { // New record
        docRef = _firestore.collection(_collectionPath).doc(); // New ID
         recordToSave = AttendanceRecordModel(
          id: docRef.id, // Assign new ID
          institutionId: record.institutionId,
          academicYearId: record.academicYearId,
          termId: record.termId,
          classId: record.classId,
          studentUid: record.studentUid,
          date: record.date,
          subjectId: record.subjectId,
          periodSlot: record.periodSlot,
          status: record.status,
          markedByUid: record.markedByUid,
          remarks: record.remarks,
          createdAt: now, // Set creation time
          updatedAt: now,
        );
        batch.set(docRef, recordToSave.toMap());
      }
    }

    try {
      await batch.commit();
      return true;
    } catch (e) {
      print("Error marking batch attendance: $e");
      return false;
    }
  }

  // Get attendance for a specific student over a date range
  Stream<List<AttendanceRecordModel>> getAttendanceForStudent({
    required String studentUid,
    required String institutionId,
    required DateTime startDate,
    required DateTime endDate,
    String? classId, // Optional filter
    String? subjectId, // Optional filter
  }) {
    // Ensure endDate is at the end of the day for inclusive range
    DateTime effectiveEndDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    Query query = _firestore
        .collection(_collectionPath)
        .where('institutionId', isEqualTo: institutionId)
        .where('studentUid', isEqualTo: studentUid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(effectiveEndDate));

    if (classId != null && classId.isNotEmpty) query = query.where('classId', isEqualTo: classId);
    if (subjectId != null && subjectId.isNotEmpty) query = query.where('subjectId', isEqualTo: subjectId);

    return query.orderBy('date', descending: true).snapshots().map((snapshot) => snapshot.docs
        .map((doc) => AttendanceRecordModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // Get attendance for a specific class on a specific date (and optionally period/subject)
  Stream<List<AttendanceRecordModel>> getAttendanceForClassOnDate({
    required String classId,
    required String institutionId,
    required DateTime date,
    String? subjectId,
    String? periodSlot,
  }) {
    // Normalize date to start and end of day for querying
    DateTime dayStart = DateTime(date.year, date.month, date.day);
    DateTime dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    Query query = _firestore
        .collection(_collectionPath)
        .where('institutionId', isEqualTo: institutionId)
        .where('classId', isEqualTo: classId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(dayEnd));

    if (subjectId != null && subjectId.isNotEmpty) query = query.where('subjectId', isEqualTo: subjectId);
    if (periodSlot != null && periodSlot.isNotEmpty) query = query.where('periodSlot', isEqualTo: periodSlot);

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => AttendanceRecordModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // Update a single attendance record (e.g., change status or add remark)
  Future<bool> updateAttendanceRecord(String recordId, Map<String, dynamic> data) async {
    try {
      Map<String,dynamic> updateData = Map.from(data); // ensure mutable
      updateData['updatedAt'] = Timestamp.now();
      await _firestore.collection(_collectionPath).doc(recordId).update(updateData);
      return true;
    } catch (e) {
      print("Error updating attendance record $recordId: $e");
      return false;
    }
  }

  // Delete an attendance record (less common, usually update status)
  Future<bool> deleteAttendanceRecord(String recordId) async {
    try {
      await _firestore.collection(_collectionPath).doc(recordId).delete();
      return true;
    } catch (e) {
      print("Error deleting attendance record $recordId: $e");
      return false;
    }
  }

  // TODO: Add methods for generating attendance reports (e.g., summaries, percentages).
  // These might involve more complex queries or aggregation, potentially using Cloud Functions
  // for efficiency if dealing with large datasets.
  // Example: Future<Map<String, double>> getAttendanceSummaryForClass(String classId, String termId) async { ... }
}
