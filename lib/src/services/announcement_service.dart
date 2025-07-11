import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management_system/src/models/announcement_model.dart';
import 'package:school_management_system/src/models/user_model.dart'; // For UserRole access if needed for filtering

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'announcements';

  // Create a new announcement
  Future<Announcement?> createAnnouncement({
    required String title,
    required String content,
    required String createdByUid,
    required String createdByName,
    required AnnouncementScope scope,
    String? institutionId, // Required if scope is 'institution'
    List<UserRole>? targetUserRoles, // Optional: Filter by specific roles
  }) async {
    if (scope == AnnouncementScope.institution && institutionId == null) {
      throw ArgumentError("Institution ID is required for institution-scoped announcements.");
    }

    try {
      DateTime now = DateTime.now();
      DocumentReference docRef = _firestore.collection(_collectionPath).doc();

      List<String>? targetRolesStrings;
      if (targetUserRoles != null && targetUserRoles.isNotEmpty) {
          targetRolesStrings = targetUserRoles.map((role) => userRoleToString(role)).toList();
      }

      Announcement newAnnouncement = Announcement(
        id: docRef.id,
        title: title,
        content: content,
        createdAt: now,
        createdByUid: createdByUid,
        createdByName: createdByName,
        scope: scope,
        institutionId: institutionId,
        targetRoles: targetRolesStrings,
        isPublished: true, // Default to published immediately
        publishDate: now,  // Default to now
      );

      await docRef.set(newAnnouncement.toMap());
      return newAnnouncement;
    } catch (e) {
      print('Error creating announcement: $e');
      return null;
    }
  }

  // Get announcements relevant to a user
  // This is a simplified version. A more robust version would consider:
  // - User's role for role-specific announcements.
  // - User's institutionId.
  // - Pagination for large numbers of announcements.
  Stream<List<Announcement>> getAnnouncementsForUser({
    required String? userInstitutionId, // Null if user is SuperAdmin or not tied to one institution
    required UserRole userRole,
  }) {
    // Base query for published announcements, ordered by creation date
    Query query = _firestore
        .collection(_collectionPath)
        .where('isPublished', isEqualTo: true)
        .where('publishDate', isLessThanOrEqualTo: Timestamp.now()) // Only show if publishDate is past or now
        .orderBy('publishDate', descending: true) // Show newest first
        .orderBy('createdAt', descending: true);


    // This logic can get complex quickly.
    // Firestore does not support OR queries on different fields directly.
    // So, fetching system-wide AND institution-specific (if applicable) AND role-specific might require multiple queries and merging client-side,
    // or careful data structuring/denormalization if performance is critical.

    // Simplified approach for now:
    // 1. Fetch System-wide announcements.
    // 2. If user has an institutionId, fetch announcements for that institution.
    // Then merge and filter by role client-side. This is not ideal for large datasets.
    // A better approach for scaling might involve Firebase Functions to populate a user-specific feed or using more targeted queries.

    return query.snapshots().map((snapshot) {
      List<Announcement> announcements = snapshot.docs
          .map((doc) => Announcement.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Client-side filtering (adjust as needed for performance and complexity)
      return announcements.where((ann) {
        bool scopeMatch = false;
        if (ann.scope == AnnouncementScope.system) {
          scopeMatch = true; // System announcements are for everyone (matching targetRoles)
        } else if (ann.scope == AnnouncementScope.institution && ann.institutionId == userInstitutionId) {
          scopeMatch = true; // Institution announcements for user's institution
        }

        if (!scopeMatch) return false;

        // Role filtering
        if (ann.targetRoles == null || ann.targetRoles!.isEmpty) {
          return true; // No specific role targeting, so it's for everyone within the scope
        }
        if (ann.targetRoles!.contains(userRoleToString(userRole))) {
          return true; // User's role is in the target list
        }

        return false; // Does not match scope or role
      }).toList();
    });
  }

  // Get announcements for Super Admin (can see all, or manage specific ones)
  Stream<List<Announcement>> getAllAnnouncementsForSuperAdmin() {
    return _firestore
        .collection(_collectionPath)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Announcement.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  // Update an announcement (e.g., by SuperAdmin or creator)
  Future<bool> updateAnnouncement(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collectionPath).doc(id).update(data);
      return true;
    } catch (e) {
      print('Error updating announcement $id: $e');
      return false;
    }
  }

  // Delete an announcement
  Future<bool> deleteAnnouncement(String id) async {
    try {
      await _firestore.collection(_collectionPath).doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting announcement $id: $e');
      return false;
    }
  }
}
