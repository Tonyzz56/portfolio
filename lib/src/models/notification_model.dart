import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  newAnnouncement,
  gradeUpdate,
  feeReminder,
  eventReminder,
  newMessage, // Example for future chat/messaging
  systemAlert,
  custom // For general purpose notifications
}

class NotificationModel {
  final String id; // Firestore document ID
  final String userId; // UID of the recipient user
  final String title;
  final String body;
  final NotificationType type;
  final String? relatedEntityId;   // e.g., announcementId, studentId (if for parent about child), assessmentId
  final String? relatedEntityType; // e.g., "announcement", "student_grade", "fee_invoice"
  final String? routeName; // Optional: route to navigate to when notification is tapped
  final Map<String, dynamic>? routeArguments; // Optional: arguments for the route

  bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedEntityId,
    this.relatedEntityType,
    this.routeName,
    this.routeArguments,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> data, String documentId) {
    return NotificationModel(
      id: documentId,
      userId: data['userId'] ?? '',
      title: data['title'] ?? 'No Title',
      body: data['body'] ?? 'No Content',
      type: notificationTypeFromString(data['type'] as String?),
      relatedEntityId: data['relatedEntityId'] as String?,
      relatedEntityType: data['relatedEntityType'] as String?,
      routeName: data['routeName'] as String?,
      routeArguments: data['routeArguments'] != null ? Map<String, dynamic>.from(data['routeArguments']) : null,
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.toString().split('.').last,
      'relatedEntityId': relatedEntityId,
      'relatedEntityType': relatedEntityType,
      'routeName': routeName,
      'routeArguments': routeArguments,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt), // Or FieldValue.serverTimestamp() on create
    };
  }
}

NotificationType notificationTypeFromString(String? typeString) {
  if (typeString == null) return NotificationType.custom;
  switch (typeString.toLowerCase()) {
    case 'newannouncement': return NotificationType.newAnnouncement;
    case 'gradeupdate': return NotificationType.gradeUpdate;
    case 'feereminder': return NotificationType.feeReminder;
    case 'eventreminder': return NotificationType.eventReminder;
    case 'newmessage': return NotificationType.newMessage;
    case 'systemalert': return NotificationType.systemAlert;
    default: return NotificationType.custom;
  }
}

String notificationTypeToString(NotificationType type) {
  return type.toString().split('.').last;
}
