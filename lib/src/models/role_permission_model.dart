import 'package:cloud_firestore/cloud_firestore.dart';

class RolePermission {
  final String roleId; // e.g., "teacher", "student", "nonTeachingStaff_finance"
                     // This should match the string representation of UserRole or a custom defined role string.
  Map<String, bool> permissions; // Key: permission string (e.g., AppPermissions.usersCreate), Value: true/false

  RolePermission({
    required this.roleId,
    required this.permissions,
  });

  factory RolePermission.fromMap(Map<String, dynamic> data, String documentId) {
    // Ensure permissions map is correctly typed from Firestore's dynamic map
    Map<String, bool> typedPermissions = {};
    if (data['permissions'] is Map) {
      (data['permissions'] as Map).forEach((key, value) {
        if (value is bool) {
          typedPermissions[key as String] = value;
        } else if (value is String && (value == 'true' || value == 'false')) {
            // Handling if stored as string 'true'/'false' by mistake, though bool is preferred
            typedPermissions[key as String] = value == 'true';
        }
      });
    }

    return RolePermission(
      roleId: documentId, // Firestore document ID is the roleId
      permissions: typedPermissions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // roleId is the document ID, not stored as a field
      'permissions': permissions,
    };
  }
}
