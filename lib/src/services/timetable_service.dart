import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management_system/src/models/timetable_entry_model.dart';

class TimetableService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'timetable_entries';

  // Create a new timetable entry
  Future<TimetableEntryModel?> createTimetableEntry(TimetableEntryModel entry) async {
    // Basic validation for start/end time format (HH:mm)
    final timeRegex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
    if (!timeRegex.hasMatch(entry.startTime) || !timeRegex.hasMatch(entry.endTime)) {
      throw ArgumentError('Start and End times must be in HH:mm format.');
    }
    // Add more validation: endTime > startTime, check for overlaps (complex)

    try {
      DocumentReference docRef = _firestore.collection(_collectionPath).doc();
      TimetableEntryModel newEntry = TimetableEntryModel(
        id: docRef.id,
        institutionId: entry.institutionId,
        classId: entry.classId,
        academicYearId: entry.academicYearId,
        termId: entry.termId,
        dayOfWeek: entry.dayOfWeek,
        startTime: entry.startTime,
        endTime: entry.endTime,
        subjectId: entry.subjectId,
        teacherUid: entry.teacherUid,
        roomId: entry.roomId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await docRef.set(newEntry.toMap());
      return newEntry;
    } catch (e) {
      print("Error creating timetable entry: $e");
      return null;
    }
  }

  // Get timetable entries for a specific class, academic year, and optionally term
  Stream<List<TimetableEntryModel>> getTimetableForClass({
    required String institutionId,
    required String classId,
    required String academicYearId,
    String? termId,
  }) {
    Query query = _firestore
        .collection(_collectionPath)
        .where('institutionId', isEqualTo: institutionId)
        .where('classId', isEqualTo: classId)
        .where('academicYearId', isEqualTo: academicYearId);

    if (termId != null && termId.isNotEmpty) {
      query = query.where('termId', isEqualTo: termId);
    }
    // Ordering by day then by start time
    // Note: Firestore requires an index for composite queries with range/orderBy on different fields.
    // For simplicity, client-side sorting might be easier initially if complex indexes are an issue.
    // However, for proper display, ordering by day and then time is crucial.
    // This might require creating composite indexes in Firestore.
    // query = query.orderBy('dayOfWeek').orderBy('startTime'); // This specific order might need an index

    return query.snapshots().map((snapshot) {
      var entries = snapshot.docs
          .map((doc) => TimetableEntryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      // Client-side sort if Firestore ordering is problematic without specific indexes
      entries.sort((a, b) {
        int dayCompare = a.dayOfWeek.index.compareTo(b.dayOfWeek.index);
        if (dayCompare != 0) return dayCompare;
        return a.startTime.compareTo(b.startTime);
      });
      return entries;
    });
  }

  // Get timetable entries for a specific teacher
  Stream<List<TimetableEntryModel>> getTimetableForTeacher({
    required String institutionId,
    required String teacherUid,
    required String academicYearId, // Usually timetable is viewed in context of current AY
    String? termId,
  }) {
     Query query = _firestore
        .collection(_collectionPath)
        .where('institutionId', isEqualTo: institutionId)
        .where('teacherUid', isEqualTo: teacherUid)
        .where('academicYearId', isEqualTo: academicYearId);

    if (termId != null && termId.isNotEmpty) {
      query = query.where('termId', isEqualTo: termId);
    }
    // query = query.orderBy('dayOfWeek').orderBy('startTime'); // Requires index

    return query.snapshots().map((snapshot) {
       var entries = snapshot.docs
          .map((doc) => TimetableEntryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      entries.sort((a, b) {
        int dayCompare = a.dayOfWeek.index.compareTo(b.dayOfWeek.index);
        if (dayCompare != 0) return dayCompare;
        return a.startTime.compareTo(b.startTime);
      });
      return entries;
    });
  }

  // Update an existing timetable entry
  Future<bool> updateTimetableEntry(String entryId, Map<String, dynamic> data) async {
    try {
      Map<String, dynamic> updateData = Map<String, dynamic>.from(data);
      updateData['updatedAt'] = Timestamp.now();
      // Add validation for time format and logical consistency if times are updated
      if (updateData.containsKey('startTime') || updateData.containsKey('endTime')) {
          final timeRegex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
          if (updateData.containsKey('startTime') && !timeRegex.hasMatch(updateData['startTime'])) {
              throw ArgumentError('Start time must be in HH:mm format.');
          }
          if (updateData.containsKey('endTime') && !timeRegex.hasMatch(updateData['endTime'])) {
              throw ArgumentError('End time must be in HH:mm format.');
          }
          // Consider fetching the doc to compare startTime and endTime if both are present or one is updated
      }

      await _firestore.collection(_collectionPath).doc(entryId).update(updateData);
      return true;
    } catch (e) {
      print("Error updating timetable entry $entryId: $e");
      return false;
    }
  }

  // Delete a timetable entry
  Future<bool> deleteTimetableEntry(String entryId) async {
    try {
      await _firestore.collection(_collectionPath).doc(entryId).delete();
      return true;
    } catch (e) {
      print("Error deleting timetable entry $entryId: $e");
      return false;
    }
  }

  // TODO: Add conflict detection logic (e.g., when creating/updating an entry)
  // This would check if a teacher or room is already booked for the given time slot.
  // This is complex and typically involves querying existing entries.
  // Future<bool> hasConflict(TimetableEntryModel entry) async { ... }
}
