import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management_system/src/models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'notifications';

  // Create a new notification for a specific user
  Future<NotificationModel?> createNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? relatedEntityId,
    String? relatedEntityType,
    String? routeName,
    Map<String, dynamic>? routeArguments,
  }) async {
    try {
      DocumentReference docRef = _firestore.collection(_collectionPath).doc();
      NotificationModel newNotification = NotificationModel(
        id: docRef.id,
        userId: userId,
        title: title,
        body: body,
        type: type,
        relatedEntityId: relatedEntityId,
        relatedEntityType: relatedEntityType,
        routeName: routeName,
        routeArguments: routeArguments,
        isRead: false,
        createdAt: DateTime.now(), // Will be replaced by server timestamp in toMap
      );
      // Use a modified toMap that sets server timestamp for createdAt
      Map<String, dynamic> dataToSet = newNotification.toMap();
      dataToSet['createdAt'] = FieldValue.serverTimestamp(); // Ensure server timestamp

      await docRef.set(dataToSet);
      // To return the model with the server-generated timestamp, we'd ideally fetch it back.
      // For now, returning the client-generated one, or could return void/bool.
      // DocumentSnapshot newDoc = await docRef.get();
      // return NotificationModel.fromMap(newDoc.data() as Map<String,dynamic>, newDoc.id);
      return newNotification; // Note: createdAt will be client-side initially
    } catch (e) {
      print("Error creating notification: $e");
      return null;
    }
  }

  // Get notifications for a specific user, ordered by most recent
  // Includes pagination support (basic limit, could be extended with startAfter)
  Stream<List<NotificationModel>> getNotificationsForUser(String userId, {int limit = 20}) {
    return _firestore
        .collection(_collectionPath)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get count of unread notifications for a user
  Stream<int> getUnreadNotificationCount(String userId) {
    return _firestore
        .collection(_collectionPath)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }


  // Mark a specific notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(_collectionPath).doc(notificationId).update({'isRead': true});
      return true;
    } catch (e) {
      print("Error marking notification $notificationId as read: $e");
      return false;
    }
  }

  // Mark all notifications for a user as read
  Future<bool> markAllAsRead(String userId) async {
    try {
      WriteBatch batch = _firestore.batch();
      QuerySnapshot unreadNotifications = await _firestore
          .collection(_collectionPath)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadNotifications.docs.isEmpty) return true; // No unread notifications

      for (DocumentSnapshot doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      return true;
    } catch (e) {
      print("Error marking all notifications as read for user $userId: $e");
      return false;
    }
  }

  // Delete a specific notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collectionPath).doc(notificationId).delete();
      return true;
    } catch (e) {
      print("Error deleting notification $notificationId: $e");
      return false;
    }
  }

  // Delete all notifications for a user (e.g., "Clear All")
  Future<bool> deleteAllNotificationsForUser(String userId) async {
     try {
      WriteBatch batch = _firestore.batch();
      QuerySnapshot userNotifications = await _firestore
          .collection(_collectionPath)
          .where('userId', isEqualTo: userId)
          .get();

      if (userNotifications.docs.isEmpty) return true;

      for (DocumentSnapshot doc in userNotifications.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      return true;
    } catch (e) {
      print("Error deleting all notifications for user $userId: $e");
      return false;
    }
  }

  // Example of how another service might trigger a notification:
  // This would typically be called from a Firebase Function or a backend after an event.
  // For client-side triggers (less common for some types like "gradeUpdate"),
  // the relevant service (e.g., GradingService) would call this.
  //
  // Future<void> sendNewAnnouncementNotification(AnnouncementModel announcement) async {
  //   // Logic to determine target userIds based on announcement scope and targetRoles
  //   List<String> targetUserIds = []; // ... determine recipients ...
  //
  //   for (String userId in targetUserIds) {
  //     await createNotification(
  //       userId: userId,
  //       title: "New Announcement: ${announcement.title}",
  //       body: announcement.content.length > 100 ? "${announcement.content.substring(0, 97)}..." : announcement.content,
  //       type: NotificationType.newAnnouncement,
  //       relatedEntityId: announcement.id,
  //       relatedEntityType: "announcement",
  //       routeName: "/announcements", // Or specific announcement view route
  //     );
  //   }
  // }
}
