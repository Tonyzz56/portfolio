import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management_system/src/models/role_permission_model.dart';
import 'package:school_management_system/src/models/user_model.dart'; // For UserRole and userRoleToString
import 'package:school_management_system/src/config/permissions.dart'; // For AppPermissions.getAllPermissions()

class RolePermissionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'role_permissions';

  // Get permissions for a specific role
  Future<RolePermission?> getRolePermissions(String roleId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collectionPath).doc(roleId).get();
      if (doc.exists) {
        return RolePermission.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      // If no specific permissions are set for a role, return a default (e.g., all false)
      // This prevents errors if a role document doesn't exist yet.
      Map<String, bool> defaultPermissions = {
        for (var perm in AppPermissions.getAllPermissions()) perm: false,
      };
      return RolePermission(roleId: roleId, permissions: defaultPermissions);

    } catch (e) {
      print('Error getting role permissions for $roleId: $e');
      return null; // Or throw error
    }
  }

  // Stream permissions for a specific role (for real-time updates in UI if needed)
  Stream<RolePermission?> streamRolePermissions(String roleId) {
     return _firestore.collection(_collectionPath).doc(roleId).snapshots().map((doc) {
       if (doc.exists) {
         return RolePermission.fromMap(doc.data() as Map<String, dynamic>, doc.id);
       }
       Map<String, bool> defaultPermissions = {
         for (var perm in AppPermissions.getAllPermissions()) perm: false,
       };
       return RolePermission(roleId: roleId, permissions: defaultPermissions);
     });
  }


  // Get all roles and their permissions (for Super Admin UI)
  Stream<List<RolePermission>> getAllRolePermissionsStream() {
    return _firestore.collection(_collectionPath).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return RolePermission.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Update or Create permissions for a role
  Future<bool> setRolePermissions(String roleId, Map<String, bool> permissions) async {
    try {
      // Validate roleId - should ideally match UserRole enum string values or predefined custom role strings
      // For now, we assume roleId is valid.
      RolePermission rolePerm = RolePermission(roleId: roleId, permissions: permissions);
      await _firestore.collection(_collectionPath).doc(roleId).set(rolePerm.toMap());
      return true;
    } catch (e) {
      print('Error setting role permissions for $roleId: $e');
      return false;
    }
  }

  // Initialize default permissions for all UserRoles (callable by SuperAdmin once)
  Future<void> initializeDefaultPermissionsForAllRoles() async {
    // Example: Give students very few permissions, teachers more, etc.
    // This should be carefully planned.

    Map<String, bool> studentDefaultPermissions = {
      for (var perm in AppPermissions.getAllPermissions()) perm: false, // Start with all false
      AppPermissions.usersUpdateOwn: true,
      AppPermissions.attendanceViewOwn: true,
      AppPermissions.gradesViewOwn: true,
      AppPermissions.filesUpload: true, // e.g., for assignments
      AppPermissions.filesDeleteOwn: true,
    };

    Map<String, bool> teacherDefaultPermissions = {
      for (var perm in AppPermissions.getAllPermissions()) perm: false,
      AppPermissions.usersUpdateOwn: true,
      AppPermissions.attendanceMark: true,
      AppPermissions.attendanceViewOwn: true, // Teachers can view their own attendance if tracked
      AppPermissions.gradesEnter: true,
      AppPermissions.gradesViewOwn: true, // Teachers can view own grades if they are also students in a system? Unlikely.
      AppPermissions.filesUpload: true,
      AppPermissions.filesDeleteOwn: true,
      // ... add more teacher specific like viewing their class students etc.
    };

    Map<String, bool> institutionAdminDefaultPermissions = {
        for (var perm in AppPermissions.getAllPermissions()) perm: false,
        AppPermissions.usersRead: true,
        AppPermissions.usersCreate: true, // Create users in their institution
        AppPermissions.usersUpdate: true, // Update users in their institution
        AppPermissions.usersToggleActive: true,
        AppPermissions.usersManageRoles: true, // Assign roles within their institution (non-admin roles)
        AppPermissions.institutionSettingsEdit: true,
        AppPermissions.announcementsCreateInstitution: true,
        AppPermissions.announcementsUpdateOwnInstitution: true,
        AppPermissions.announcementsDeleteOwnInstitution: true,
        AppPermissions.filesUpload: true,
        AppPermissions.filesDeleteAnyInInstitution: true,
        AppPermissions.academicClassesManage: true,
        AppPermissions.academicSubjectsManage: true,
        AppPermissions.academicTimetableManage: true,
        AppPermissions.attendanceViewReportInstitution: true,
        AppPermissions.gradesViewAllInInstitution: true,
        AppPermissions.gradesPublishReports: true,
        AppPermissions.feesDefineStructures: true,
        AppPermissions.feesAssignToStudents: true,
        AppPermissions.feesViewReports: true,
         // ... many more
    };

    // SuperAdmin inherently has all permissions, so no specific doc might be needed,
    // or one with all true can be created for consistency in checks.
    // Firestore rules will grant SuperAdmin access regardless of this doc.
    // Map<String, bool> superAdminPermissions = {
    //   for (var perm in AppPermissions.getAllPermissions()) perm: true,
    // };
    // await setRolePermissions(userRoleToString(UserRole.superAdmin), superAdminPermissions);


    // Set for manageable roles.
    // Note: UserRole.parent and UserRole.vendor would also need defaults.
    await setRolePermissions(userRoleToString(UserRole.student), studentDefaultPermissions);
    await setRolePermissions(userRoleToString(UserRole.teacher), teacherDefaultPermissions);
    await setRolePermissions(userRoleToString(UserRole.institutionAdmin), institutionAdminDefaultPermissions);
    // Add defaults for nonTeachingStaff (perhaps by department), parent, vendor

    // Example for a specific non-teaching staff role (conceptual)
    // String financeStaffRoleId = "nonTeachingStaff_finance";
    // Map<String, bool> financeStaffDefaultPermissions = {
    //   for (var perm in AppPermissions.getAllPermissions()) perm: false,
    //   AppPermissions.usersUpdateOwn: true,
    //   AppPermissions.feesRecordPayment: true,
    //   AppPermissions.feesViewReports: true,
    // };
    // await setRolePermissions(financeStaffRoleId, financeStaffDefaultPermissions);

    print("Default permissions initialization attempted.");
  }

  // --- Client-Side Permission Checking ---
  // This would typically live in a service that's easily accessible via Provider.
  // It would load the current user's role's permissions upon login and cache them.

  // For now, this is a placeholder structure. The actual caching and state management
  // would be handled by a dedicated PermissionStateService or similar.

  Map<String, bool>? _currentUserPermissions; // Cached permissions for the logged-in user

  Future<void> loadCurrentUserPermissions(String roleId) async {
    RolePermission? rolePerm = await getRolePermissions(roleId);
    if (rolePerm != null) {
      _currentUserPermissions = rolePerm.permissions;
    } else {
      _currentUserPermissions = { for (var perm in AppPermissions.getAllPermissions()) perm: false }; // Default to all false if role not found
    }
     print("Loaded permissions for role $roleId: $_currentUserPermissions");
  }

  // Call this after user logs in or when their role might change.
  // Example: Provider.of<AuthService>(context, listen: false).user.first.then((user) {
  //   if (user != null) {
  //      Provider.of<RolePermissionService>(context, listen: false).loadCurrentUserPermissions(userRoleToString(user.role));
  //   }
  // });

  bool can(String permissionKey) {
    if (_currentUserPermissions == null) {
      print("Warning: Permissions not loaded yet for current user. Denying '$permissionKey'.");
      return false; // Permissions not loaded, deny by default
    }
    return _currentUserPermissions![permissionKey] ?? false; // Default to false if key doesn't exist
  }

  void clearCurrentUserPermissions() {
    _currentUserPermissions = null;
  }
}
