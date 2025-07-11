import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus {
  present,
  absent,
  late,
  excused,
  // Add other statuses as needed, e.g., online, partial
}

class AttendanceRecordModel {
  final String id; // Firestore document ID
  final String institutionId;
  final String academicYearId;
  final String? termId;
  final String classId;
  final String studentUid;

  final DateTime date; // The specific date of the attendance record
  final String? subjectId; // Optional: if attendance is taken per subject/period
  final String? periodSlot; // Optional: e.g., "Period 1", "09:00-09:45", "Morning Session"

  final AttendanceStatus status;
  final String markedByUid; // UID of the teacher/staff who marked attendance
  String? remarks;       // Optional remarks

  final DateTime createdAt; // When the record was created in Firestore
  DateTime updatedAt;   // When the record was last updated

  AttendanceRecordModel({
    required this.id,
    required this.institutionId,
    required this.academicYearId,
    this.termId,
    required this.classId,
    required this.studentUid,
    required this.date,
    this.subjectId,
    this.periodSlot,
    required this.status,
    required this.markedByUid,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceRecordModel.fromMap(Map<String, dynamic> data, String documentId) {
    return AttendanceRecordModel(
      id: documentId,
      institutionId: data['institutionId'] ?? '',
      academicYearId: data['academicYearId'] ?? '',
      termId: data['termId'] as String?,
      classId: data['classId'] ?? '',
      studentUid: data['studentUid'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      subjectId: data['subjectId'] as String?,
      periodSlot: data['periodSlot'] as String?,
      status: attendanceStatusFromString(data['status'] as String?),
      markedByUid: data['markedByUid'] ?? '',
      remarks: data['remarks'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'institutionId': institutionId,
      'academicYearId': academicYearId,
      'termId': termId,
      'classId': classId,
      'studentUid': studentUid,
      // Store date as Timestamp. For querying by date, ensure it's just the date part (midnight).
      // Or store as YYYY-MM-DD string if that simplifies queries for daily attendance.
      // For now, storing full timestamp, query logic will need to handle date ranges.
      'date': Timestamp.fromDate(date),
      'subjectId': subjectId,
      'periodSlot': periodSlot,
      'status': status.toString().split('.').last,
      'markedByUid': markedByUid,
      'remarks': remarks,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

AttendanceStatus attendanceStatusFromString(String? statusString) {
  if (statusString == null) return AttendanceStatus.absent; // Default or handle error
  switch (statusString.toLowerCase()) {
    case 'present': return AttendanceStatus.present;
    case 'absent': return AttendanceStatus.absent;
    case 'late': return AttendanceStatus.late;
    case 'excused': return AttendanceStatus.excused;
    default: return AttendanceStatus.absent;
  }
}

String attendanceStatusToString(AttendanceStatus status) {
  return status.toString().split('.').last;
}

List<String> getAllAttendanceStatusStrings() {
    return AttendanceStatus.values.map((s) => attendanceStatusToString(s)).toList();
}
