import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/services/auth_service.dart';
import 'package:school_management_system/src/services/role_permission_service.dart';
import 'login_screen.dart';
import '../admin/super_admin_dashboard_screen.dart';
import '../institution_admin/institution_admin_dashboard_screen.dart';
import '../teacher/teacher_dashboard_screen.dart';
import '../student/student_dashboard_screen.dart';
import '../non_teaching_staff/non_teaching_staff_dashboard_screen.dart';
import '../parent/parent_dashboard_screen.dart'; // Import ParentDashboardScreen


class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Provider.of<AuthService>(context);
    final RolePermissionService rolePermissionService = Provider.of<RolePermissionService>(context);

    return StreamBuilder<UserModel?>(
      stream: authService.user,
      builder: (BuildContext context, AsyncSnapshot<UserModel?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          print("Error in AuthWrapper stream: ${snapshot.error} ${snapshot.stackTrace}");
          rolePermissionService.clearCurrentUserPermissions();
          return const Scaffold(
            body: Center(child: Text('An error occurred. Please restart the app.')),
          );
        }

        final UserModel? user = snapshot.data;

        if (user != null) {
          rolePermissionService.loadCurrentUserPermissions(userRoleToString(user.role));

          if (!user.isActive) {
             WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Your account has been deactivated. Please contact support.'),
                    backgroundColor: Colors.red,
                  ),
                );
             });
            authService.signOut();
            rolePermissionService.clearCurrentUserPermissions();
            return const LoginScreen();
          }

          // Check for institutionId for roles that require it
          final rolesRequiringInstitutionId = [
            UserRole.institutionAdmin,
            UserRole.teacher,
            UserRole.student,
            UserRole.nonTeachingStaff,
            UserRole.parent
          ];
          if (rolesRequiringInstitutionId.contains(user.role) && user.institutionId == null) {
            print("Error: User ${user.uid} (Role: ${user.role}) is missing institutionId. Defaulting to LoginScreen.");
            authService.signOut();
            rolePermissionService.clearCurrentUserPermissions();
            return const LoginScreen();
          }

          switch (user.role) {
            case UserRole.superAdmin:
              return const SuperAdminDashboardScreen();
            case UserRole.institutionAdmin:
              // InstitutionAdminDashboardScreen now gets currentUser via Provider if needed, just pass ID
              return InstitutionAdminDashboardScreen(institutionId: user.institutionId!);
            case UserRole.teacher:
              // TeacherDashboardScreen also gets currentUser via Provider
              return const TeacherDashboardScreen();
            case UserRole.student:
              // StudentDashboardScreen also gets currentUser via Provider
              return const StudentDashboardScreen();
            case UserRole.nonTeachingStaff:
              // NonTeachingStaffDashboardScreen also gets currentUser via Provider
              return const NonTeachingStaffDashboardScreen();
            case UserRole.parent: // Added case for Parent
              return const ParentDashboardScreen();
            // TODO: Add case for UserRole.vendor to navigate to VendorDashboardScreen
            // case UserRole.vendor:
            //   return VendorDashboardScreen();

            default:
              print("Unknown or unsupported user role for UID: ${user.uid}, Role: ${user.role}. Defaulting to LoginScreen.");
              authService.signOut();
              rolePermissionService.clearCurrentUserPermissions();
              return const LoginScreen();
          }
        } else {
          rolePermissionService.clearCurrentUserPermissions();
          return const LoginScreen();
        }
      },
    );
  }
}
