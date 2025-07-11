import 'package:flutter/material.dart';
import 'package:school_management_system/src/models/navigation_item_model.dart';
import 'package:school_management_system/src/models/user_model.dart' show UserRole;
import 'package:school_management_system/src/config/permissions.dart';

class NavigationConfig {
  static List<NavigationItemModel> get allAppNavigationItems {
    return [
      // == Universal ==
      NavigationItemModel(
        title: 'My Profile',
        icon: Icons.person_outline,
        routeName: '/profile',
        targetUserRoles: UserRole.values.where((role) => role != UserRole.unknown).toList(),
      ),
      NavigationItemModel(
        title: 'Announcements',
        icon: Icons.campaign,
        routeName: '/announcements',
        targetUserRoles: UserRole.values.where((role) => role != UserRole.unknown).toList(),
      ),
      NavigationItemModel( // New Universal Item
        title: 'Notifications',
        icon: Icons.notifications_none_outlined, // Or Icons.notifications
        routeName: '/notifications',
        targetUserRoles: UserRole.values.where((role) => role != UserRole.unknown).toList(),
      ),

      // == Super Admin Specific ==
      NavigationItemModel(title: 'Manage Institutions', icon: Icons.school, routeName: '/manage-institutions', targetUserRoles: [UserRole.superAdmin]),
      NavigationItemModel(title: 'Roles & Permissions', icon: Icons.admin_panel_settings, routeName: '/manage-permissions', targetUserRoles: [UserRole.superAdmin], requiredPermission: AppPermissions.permissionsManage),
      NavigationItemModel(title: 'Manage Subscriptions', icon: Icons.subscriptions, routeName: '/manage-subscriptions', targetUserRoles: [UserRole.superAdmin]),
      NavigationItemModel(title: 'System Logs', icon: Icons.receipt_long, routeName: '/system-logs', targetUserRoles: [UserRole.superAdmin]),

      // == Institution Admin Specific ==
      NavigationItemModel(title: 'Manage Users', icon: Icons.people_alt_outlined, routeName: '/institution/manage-users', targetUserRoles: [UserRole.institutionAdmin], requiredPermission: AppPermissions.usersRead),
      NavigationItemModel(title: 'Manage Departments', icon: Icons.business_center_outlined, routeName: '/institution/manage-departments', targetUserRoles: [UserRole.institutionAdmin]),
      NavigationItemModel(title: 'Academic Management Hub', icon: Icons.school_outlined, routeName: '/institution/academic-settings', targetUserRoles: [UserRole.institutionAdmin]),
      NavigationItemModel(title: 'Institution Settings', icon: Icons.settings_applications, routeName: '/institution/settings', targetUserRoles: [UserRole.institutionAdmin], requiredPermission: AppPermissions.institutionSettingsEdit),

      NavigationItemModel(title: 'Manage Academic Years', icon: Icons.calendar_view_month_outlined, routeName: '/institution/academic/years', targetUserRoles: [UserRole.institutionAdmin], requiredPermission: AppPermissions.academicClassesManage),
      NavigationItemModel(title: 'Manage Subjects', icon: Icons.subject_outlined, routeName: '/institution/academic/subjects', targetUserRoles: [UserRole.institutionAdmin], requiredPermission: AppPermissions.academicSubjectsManage),
      NavigationItemModel(title: 'Manage Timetables (Admin Hub)', icon: Icons.table_chart_sharp, routeName: '/institution/academic/timetables', targetUserRoles: [UserRole.institutionAdmin], requiredPermission: AppPermissions.academicTimetableManage),
      NavigationItemModel(title: 'Attendance Reports (Admin)', icon: Icons.fact_check_outlined, routeName: '/institution/academic/attendance-reports', targetUserRoles: [UserRole.institutionAdmin], requiredPermission: AppPermissions.attendanceViewReportInstitution),
      NavigationItemModel(title: 'Manage Assessments (Admin)', icon: Icons.assignment_turned_in_outlined, routeName: '/institution/academic/assessments', targetUserRoles: [UserRole.institutionAdmin], requiredPermission: AppPermissions.gradesEnter),
      NavigationItemModel(title: 'Grade Reports (Admin)', icon: Icons.assessment_work_outlined, routeName: '/institution/academic/grade-reports', targetUserRoles: [UserRole.institutionAdmin], requiredPermission: AppPermissions.gradesViewAllInInstitution),


      // == Teacher Specific ==
      NavigationItemModel(title: 'My Classes & Students', icon: Icons.group_outlined, routeName: '/teacher/my-classes', targetUserRoles: [UserRole.teacher]),
      NavigationItemModel(title: 'Enter Grades', icon: Icons.assessment_outlined, routeName: '/teacher/enter-grades', targetUserRoles: [UserRole.teacher], requiredPermission: AppPermissions.gradesEnter),
      NavigationItemModel(title: 'Mark Attendance', icon: Icons.check_circle_outline, routeName: '/teacher/mark-attendance', targetUserRoles: [UserRole.teacher], requiredPermission: AppPermissions.attendanceMark),
      NavigationItemModel(title: 'Manage My Uploads', icon: Icons.upload_file_outlined, routeName: '/teacher/my-uploads', targetUserRoles: [UserRole.teacher], requiredPermission: AppPermissions.filesUpload),
      NavigationItemModel(title: 'My Timetable (Teacher)', icon: Icons.schedule_send_outlined, routeName: '/teacher/my-timetable', targetUserRoles: [UserRole.teacher]),


      // == Student Specific ==
      NavigationItemModel(title: 'My Grades', icon: Icons.bar_chart_outlined, routeName: '/student/my-grades', targetUserRoles: [UserRole.student, UserRole.parent]),
      NavigationItemModel(title: 'My Attendance', icon: Icons.event_available, routeName: '/student/my-attendance', targetUserRoles: [UserRole.student, UserRole.parent]),
      NavigationItemModel(title: 'My Timetable', icon: Icons.schedule_outlined, routeName: '/student/my-timetable', targetUserRoles: [UserRole.student]),
      NavigationItemModel(title: 'My Submissions', icon: Icons.file_present_outlined, routeName: '/student/my-submissions', targetUserRoles: [UserRole.student], requiredPermission: AppPermissions.filesUpload),

      // == Non-Teaching Staff (General and Department Specific) ==
      NavigationItemModel(title: 'Staff Portal Home', icon: Icons.work_outline, routeName: '/staff/home', targetUserRoles: [UserRole.nonTeachingStaff]),
      NavigationItemModel(title: 'Fee Collection Records', icon: Icons.point_of_sale, routeName: '/staff/finance/fee-records', targetUserRoles: [UserRole.nonTeachingStaff], targetDepartments: ['Finance'], requiredPermission: AppPermissions.feesRecordPayment),
      NavigationItemModel(title: 'Financial Reports (Staff)', icon: Icons.insights, routeName: '/staff/finance/reports', targetUserRoles: [UserRole.nonTeachingStaff], targetDepartments: ['Finance'], requiredPermission: AppPermissions.feesViewReports),
      NavigationItemModel(title: 'IT Support Tickets', icon: Icons.support_agent, routeName: '/staff/it/support-tickets', targetUserRoles: [UserRole.nonTeachingStaff], targetDepartments: ['IT']),
      NavigationItemModel(title: 'Manage IT Assets', icon: Icons.computer, routeName: '/staff/it/assets', targetUserRoles: [UserRole.nonTeachingStaff], targetDepartments: ['IT']),
      NavigationItemModel(title: 'Manage Books (Library)', icon: Icons.menu_book, routeName: '/staff/library/manage-books', targetUserRoles: [UserRole.nonTeachingStaff], targetDepartments: ['Library']),
      NavigationItemModel(title: 'Issue/Return Books', icon: Icons.import_export, routeName: '/staff/library/issue-return', targetUserRoles: [UserRole.nonTeachingStaff], targetDepartments: ['Library']),
      NavigationItemModel(title: 'View Transport Routes', icon: Icons.directions_bus, routeName: '/staff/transport/routes', targetUserRoles: [UserRole.nonTeachingStaff], targetDepartments: ['Transport']),
      NavigationItemModel(title: 'Vehicle Maintenance Log', icon: Icons.build_circle_outlined, routeName: '/staff/transport/maintenance', targetUserRoles: [UserRole.nonTeachingStaff], targetDepartments: ['Transport']),
      NavigationItemModel(title: 'Room Allocations', icon: Icons.hotel, routeName: '/staff/accommodation/allocations', targetUserRoles: [UserRole.nonTeachingStaff], targetDepartments: ['Accommodation']),
      NavigationItemModel(title: 'Maintenance Requests (Accomm.)', icon: Icons.construction, routeName: '/staff/accommodation/maintenance', targetUserRoles: [UserRole.nonTeachingStaff], targetDepartments: ['Accommodation']),
      NavigationItemModel(title: 'Manage Purchase Orders', icon: Icons.receipt_long_outlined, routeName: '/staff/procurement/orders', targetUserRoles: [UserRole.nonTeachingStaff], targetDepartments: ['Procurement']),
      NavigationItemModel(title: 'Supplier Management', icon: Icons.group_work, routeName: '/staff/procurement/suppliers', targetUserRoles: [UserRole.nonTeachingStaff], targetDepartments: ['Procurement']),
      NavigationItemModel(title: 'General Office Tasks', icon: Icons.business, routeName: '/staff/admin/tasks', targetUserRoles: [UserRole.nonTeachingStaff], targetDepartments: ['Administration']),
      NavigationItemModel(title: 'Record Keeping', icon: Icons.archive_outlined, routeName: '/staff/admin/records', targetUserRoles: [UserRole.nonTeachingStaff], targetDepartments: ['Administration']),

      // == Parent Specific ==
      NavigationItemModel(title: 'My Children', icon: Icons.escalator_warning, routeName: '/parent/my-children', targetUserRoles: [UserRole.parent]),

      // == Vendor Specific ==
      NavigationItemModel(title: 'My Orders (Vendor)', icon: Icons.inventory_2_outlined, routeName: '/vendor/my-orders', targetUserRoles: [UserRole.vendor]),
    ];
  }
}
