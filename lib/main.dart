import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/screens/auth/auth_wrapper.dart';
import 'package:school_management_system/src/services/auth_service.dart';
import 'package:school_management_system/src/services/role_permission_service.dart';
import 'package:school_management_system/src/services/navigation_service.dart';
import 'package:school_management_system/src/services/notification_service.dart'; // Import NotificationService
import 'firebase_options.dart';

// Import screens for routing
import 'package:school_management_system/src/screens/profile/user_profile_screen.dart';
import 'package:school_management_system/src/screens/announcements/view_announcements_screen.dart';
import 'package:school_management_system/src/screens/notifications/notifications_screen.dart'; // Import NotificationsScreen
import 'package:school_management_system/src/screens/admin/manage_institutions_screen.dart';
import 'package:school_management_system/src/screens/admin/permissions/manage_role_permissions_screen.dart';
import 'package:school_management_system/src/screens/admin/subscriptions/manage_subscription_packages_screen.dart';
import 'package:school_management_system/src/screens/admin/subscriptions/subscription_operations_screen.dart'; // Import new screen
import 'package:school_management_system/src/screens/admin/logs/system_logs_screen.dart';

import 'package:school_management_system/src/screens/institution_admin/manage_users_screen.dart';
import 'package:school_management_system/src/screens/institution_admin/departments/manage_departments_screen.dart';
import 'package:school_management_system/src/screens/institution_admin/academics/academic_settings_hub_screen.dart';
import 'package:school_management_system/src/screens/institution_admin/academics/manage_academic_years_screen.dart';
import 'package:school_management_system/src/screens/institution_admin/academics/manage_subjects_screen.dart';
import 'package:school_management_system/src/screens/institution_admin/academics/institution_manage_timetables_hub_screen.dart';
import 'package:school_management_system/src/screens/institution_admin/academics/institution_attendance_report_screen.dart';
import 'package:school_management_system/src/screens/institution_admin/academics/manage_assessments_screen.dart';
import 'package:school_management_system/src/screens/institution_admin/academics/institution_grade_report_screen.dart';

import 'package:school_management_system/src/screens/placeholders/placeholder_screen.dart';

// Teacher screen
import 'package:school_management_system/src/screens/teacher/teacher_my_classes_screen.dart';
import 'package:school_management_system/src/screens/teacher/teacher_enter_grades_screen.dart';
import 'package:school_management_system/src/screens/teacher/teacher_mark_attendance_screen.dart';
import 'package:school_management_system/src/screens/teacher/teacher_my_uploads_screen.dart';
import 'package:school_management_system/src/screens/teacher/teacher_my_timetable_screen.dart';

// Student screen
import 'package:school_management_system/src/screens/student/student_my_grades_screen.dart';
import 'package:school_management_system/src/screens/student/student_my_attendance_screen.dart';
import 'package:school_management_system/src/screens/student/student_my_timetable_screen.dart';
import 'package:school_management_system/src/screens/student/student_my_submissions_screen.dart';

// Non-Teaching Staff screen
import 'package:school_management_system/src/screens/non_teaching_staff/staff_portal_home_screen.dart';

// Parent screen
import 'package:school_management_system/src/screens/parent/parent_my_children_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
       options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final RolePermissionService rolePermissionService = RolePermissionService();
    final NavigationService navigationService = NavigationService(rolePermissionService);
    final NotificationService notificationService = NotificationService(); // Instantiate NotificationService

    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        Provider<RolePermissionService>.value(value: rolePermissionService),
        Provider<NavigationService>.value(value: navigationService),
        Provider<NotificationService>.value(value: notificationService), // Provide NotificationService
        StreamProvider<UserModel?>.value(
          value: authService.user,
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: 'School Management System',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            )
          )
        ),
        home: const AuthWrapper(),
        onGenerateRoute: (settings) {
          final currentUser = Provider.of<UserModel?>(context, listen: false);

          MaterialPageRoute buildRoute(Widget widget) {
            return MaterialPageRoute(builder: (_) => widget);
          }

          MaterialPageRoute placeholderRoute(String title, {String? message}) {
            return MaterialPageRoute(builder: (_) => PlaceholderScreen(title: title, message: message));
          }

          print("Navigating to route: ${settings.name} with arguments: ${settings.arguments}");

          Map<String, dynamic> routeArgs = {};
          if (settings.arguments is Map<String, dynamic>) {
            routeArgs = settings.arguments as Map<String, dynamic>;
          } else if (settings.arguments is Map) {
             routeArgs = Map<String, dynamic>.from(settings.arguments as Map);
          }


          // Universal Routes
          if (settings.name == '/profile') {
            if (currentUser != null) return buildRoute(UserProfileScreen(currentUser: currentUser));
          }
          if (settings.name == '/announcements') {
             if (currentUser != null) return buildRoute(ViewAnnouncementsScreen(currentUser: currentUser));
          }
          if (settings.name == '/notifications') { // New Route for Notifications
             // NotificationsScreen uses Provider to get currentUser, so no direct pass needed here
             return buildRoute(const NotificationsScreen());
          }


          // Super Admin Routes
          if (settings.name == '/manage-institutions') return buildRoute(const ManageInstitutionsScreen());
          if (settings.name == '/manage-permissions') return buildRoute(const ManageRolePermissionsScreen());
          if (settings.name == '/manage-subscriptions') return buildRoute(const ManageSubscriptionPackagesScreen());
          if (settings.name == '/admin/subscription-operations') return buildRoute(const SubscriptionOperationsScreen()); // New route
          if (settings.name == '/system-logs') return buildRoute(const SystemLogsScreen());

          // Institution Admin Routes
          if (settings.name == '/institution/manage-users') {
            if (currentUser?.institutionId != null && currentUser?.role == UserRole.institutionAdmin) {
              return buildRoute(ManageUsersScreen(institutionId: currentUser!.institutionId!, institutionType: InstitutionType.other /* Placeholder */));
            }
          }
          if (settings.name == '/institution/manage-departments') {
             if (currentUser?.institutionId != null) return buildRoute(ManageDepartmentsScreen(institutionId: currentUser!.institutionId!));
          }
          if (settings.name == '/institution/academic-settings') {
             if (currentUser?.institutionId != null) return buildRoute(const AcademicSettingsHubScreen());
          }
          if (settings.name == '/institution/academic/years') {
             if (currentUser?.institutionId != null) return buildRoute(ManageAcademicYearsScreen(institutionId: currentUser!.institutionId!));
          }
           if (settings.name == '/institution/academic/subjects') {
             if (currentUser?.institutionId != null) return buildRoute(ManageSubjectsScreen(institutionId: currentUser!.institutionId!));
          }
          if (settings.name == '/institution/academic/timetables') {
             if (currentUser?.institutionId != null) return buildRoute(const InstitutionManageTimetablesHubScreen());
          }
          if (settings.name == '/institution/academic/attendance-reports') {
             if (currentUser?.institutionId != null) return buildRoute(InstitutionAttendanceReportScreen(institutionId: currentUser!.institutionId!));
          }
           if (settings.name == '/institution/academic/assessments') {
             if (currentUser?.institutionId != null) {
                final String? academicYearId = routeArgs['academicYearId'] as String?;
                final String? termId = routeArgs['termId'] as String?;
                final String? classId = routeArgs['classId'] as String?;
                final String? subjectId = routeArgs['subjectId'] as String?;
                final String? contextTitle = routeArgs['contextTitle'] as String?;

                if (academicYearId != null && (subjectId != null || classId != null) ) {
                     return buildRoute(ManageAssessmentsScreen(
                        institutionId: currentUser!.institutionId!,
                        academicYearId: academicYearId,
                        termId: termId,
                        classId: classId,
                        subjectId: subjectId,
                        contextTitle: contextTitle,
                    ));
                } else {
                    return placeholderRoute("Manage Assessments", message: "Context (Academic Year and Subject/Class) required. Navigate from Academic Hub & drill down.");
                }
             }
          }
          if (settings.name == '/institution/academic/grade-reports') {
             if (currentUser?.institutionId != null) return buildRoute(const InstitutionGradeReportScreen());
          }
          if (settings.name == '/institution/settings') return placeholderRoute('Institution Settings');


          // Teacher Routes
          if (settings.name == '/teacher/my-classes') return buildRoute(const TeacherMyClassesScreen());
          if (settings.name == '/teacher/enter-grades') return buildRoute(const TeacherEnterGradesScreen());
          if (settings.name == '/teacher/mark-attendance') return buildRoute(const TeacherMarkAttendanceScreen());
          if (settings.name == '/teacher/my-uploads') return buildRoute(const TeacherMyUploadsScreen());
          if (settings.name == '/teacher/my-timetable') return buildRoute(const TeacherMyTimetableScreen());

          // Student Routes
          if (settings.name == '/student/my-grades') {
            return buildRoute(StudentMyGradesScreen(
              targetChildUidFromRoute: routeArgs['childUid'] as String?,
              childNameForParentView: routeArgs['childNameForParentView'] as String?
            ));
          }
          if (settings.name == '/student/my-attendance') {
            return buildRoute(StudentMyAttendanceScreen(
              targetChildUidFromRoute: routeArgs['childUid'] as String?,
              childNameForParentView: routeArgs['childNameForParentView'] as String?
            ));
          }
          if (settings.name == '/student/my-timetable') {
             return buildRoute(StudentMyTimetableScreen(
              targetChildUidFromRoute: routeArgs['childUid'] as String?,
              childNameForParentView: routeArgs['childNameForParentView'] as String?
            ));
          }
          if (settings.name == '/student/my-submissions') {
            return buildRoute(const StudentMySubmissionsScreen());
          }


          // Non-Teaching Staff Routes
          if (settings.name == '/staff/home') return buildRoute(const StaffPortalHomeScreen());

          // Parent Routes
          if (settings.name == '/parent/my-children') return buildRoute(const ParentMyChildrenScreen());

          // Vendor Routes
          if (settings.name == '/vendor/my-orders') return placeholderRoute('My Orders (Vendor)');

          print("Route ${settings.name} not found for user role: ${currentUser?.role}");
          return MaterialPageRoute(builder: (context) => Scaffold(appBar: AppBar(title: Text("Page Not Found")), body: Center(child: Text("No route defined for ${settings.name}"))));
        },
      ),
    );
  }
}
