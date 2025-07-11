import 'package:cloud_firestore/cloud_firestore.dart';

enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday
}

class TimetableEntryModel {
  final String id; // Firestore document ID
  final String institutionId;
  final String classId; // Link to ClassModel
  final String academicYearId; // Link to AcademicYearModel (timetable is usually per AY)
  final String? termId; // Optional: if timetable varies by term

  final DayOfWeek dayOfWeek;
  // Storing TimeOfDay as string "HH:mm" or as total minutes from midnight for easier querying/sorting.
  // For simplicity with Firestore, storing as "HH:mm" string for now.
  final String startTime; // e.g., "09:00"
  final String endTime;   // e.g., "09:45"

  final String subjectId; // Link to SubjectModel
  final String teacherUid; // Link to UserModel (Teacher)
  String? roomId; // Optional: Link to a RoomModel or just room number string

  final DateTime createdAt;
  DateTime updatedAt;

  TimetableEntryModel({
    required this.id,
    required this.institutionId,
    required this.classId,
    required this.academicYearId,
    this.termId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.subjectId,
    required this.teacherUid,
    this.roomId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TimetableEntryModel.fromMap(Map<String, dynamic> data, String documentId) {
    return TimetableEntryModel(
      id: documentId,
      institutionId: data['institutionId'] ?? '',
      classId: data['classId'] ?? '',
      academicYearId: data['academicYearId'] ?? '',
      termId: data['termId'] as String?,
      dayOfWeek: dayOfWeekFromString(data['dayOfWeek'] as String?),
      startTime: data['startTime'] ?? '00:00',
      endTime: data['endTime'] ?? '00:00',
      subjectId: data['subjectId'] ?? '',
      teacherUid: data['teacherUid'] ?? '',
      roomId: data['roomId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'institutionId': institutionId,
      'classId': classId,
      'academicYearId': academicYearId,
      'termId': termId,
      'dayOfWeek': dayOfWeek.toString().split('.').last,
      'startTime': startTime,
      'endTime': endTime,
      'subjectId': subjectId,
      'teacherUid': teacherUid,
      'roomId': roomId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

DayOfWeek dayOfWeekFromString(String? dayString) {
  if (dayString == null) return DayOfWeek.monday; // Default or handle error
  switch (dayString.toLowerCase()) {
    case 'monday': return DayOfWeek.monday;
    case 'tuesday': return DayOfWeek.tuesday;
    case 'wednesday': return DayOfWeek.wednesday;
    case 'thursday': return DayOfWeek.thursday;
    case 'friday': return DayOfWeek.friday;
    case 'saturday': return DayOfWeek.saturday;
    case 'sunday': return DayOfWeek.sunday;
    default: return DayOfWeek.monday;
  }
}

String dayOfWeekToString(DayOfWeek day) {
  return day.toString().split('.').last;
}

// Helper to convert "HH:mm" to TimeOfDay if needed in UI (TimeOfDay is not directly Firestore compatible)
// TimeOfDay stringToTimeOfDay(String timeStr) {
//   final parts = timeStr.split(':');
//   return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
// }
// String timeOfDayToString(TimeOfDay time) {
//   return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
// }
