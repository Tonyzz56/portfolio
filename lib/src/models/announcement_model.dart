import 'package:cloud_firestore/cloud_firestore.dart';

enum AnnouncementScope {
  system, // For Super Admin to all users
  institution, // For Institution Admin to users in their institution
  // Could add more granular scopes like 'class', 'course' later
}

class Announcement {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final String createdByUid; // UID of the user who created it
  final String createdByName; // Display name of creator
  final AnnouncementScope scope;
  final String? institutionId; // Required if scope is 'institution'
  final List<String>? targetRoles; // Optional: UserRole strings like ['student', 'teacher']
  bool isPublished;
  DateTime? publishDate;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.createdByUid,
    required this.createdByName,
    required this.scope,
    this.institutionId,
    this.targetRoles,
    this.isPublished = true,
    this.publishDate,
  });

  factory Announcement.fromMap(Map<String, dynamic> data, String documentId) {
    return Announcement(
      id: documentId,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdByUid: data['createdByUid'] ?? '',
      createdByName: data['createdByName'] ?? 'Unknown User',
      scope: announcementScopeFromString(data['scope'] as String?),
      institutionId: data['institutionId'] as String?,
      targetRoles: (data['targetRoles'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      isPublished: data['isPublished'] ?? true,
      publishDate: (data['publishDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdByUid': createdByUid,
      'createdByName': createdByName,
      'scope': scope.toString().split('.').last,
      'institutionId': institutionId,
      'targetRoles': targetRoles,
      'isPublished': isPublished,
      'publishDate': publishDate != null ? Timestamp.fromDate(publishDate!) : null,
    };
  }
}

AnnouncementScope announcementScopeFromString(String? scopeString) {
  if (scopeString == null) return AnnouncementScope.institution; // Default or handle error
  switch (scopeString) {
    case 'system':
      return AnnouncementScope.system;
    case 'institution':
      return AnnouncementScope.institution;
    default:
      return AnnouncementScope.institution;
  }
}
