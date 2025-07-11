// Defines all available permission keys in the system.
// This helps in maintaining consistency and avoids typos.

class AppPermissions {
  // User Management
  static const String usersRead = 'users:read';
  static const String usersCreate = 'users:create';
  static const String usersUpdate = 'users:update'; // General update
  static const String usersUpdateOwn = 'users:update_own_profile'; // Specific for own profile
  static const String usersDelete = 'users:delete';
  static const String usersManageRoles = 'users:manage_roles'; // Assign/change roles
  static const String usersToggleActive = 'users:toggle_active';

  // Institution Management (Primarily SuperAdmin)
  static const String institutionsCreate = 'institutions:create';
  static const String institutionsRead = 'institutions:read'; // Reading list or any institution
  static const String institutionsUpdate = 'institutions:update';
  static const String institutionsDelete = 'institutions:delete';

  // Institution Settings (InstitutionAdmin for their own)
  static const String institutionSettingsEdit = 'institution_settings:edit';

  // Announcements
  static const String announcementsCreateSystem = 'announcements:create_system';
  static const String announcementsCreateInstitution = 'announcements:create_institution';
  static const String announcementsUpdateAny = 'announcements:update_any'; // SuperAdmin
  static const String announcementsUpdateOwnInstitution = 'announcements:update_own_institution'; // InstAdmin for their inst.
  static const String announcementsDeleteAny = 'announcements:delete_any';
  static const String announcementsDeleteOwnInstitution = 'announcements:delete_own_institution';

  // File Assets
  static const String filesUpload = 'files:upload';
  static const String filesDeleteOwn = 'files:delete_own'; // User deleting their own uploads
  static const String filesDeleteAnyInInstitution = 'files:delete_any_in_institution'; // InstAdmin
  static const String filesDeleteAnySystem = 'files:delete_any_system'; // SuperAdmin

  // Academic Structure (examples)
  static const String academicClassesManage = 'academic:classes:manage';
  static const String academicSubjectsManage = 'academic:subjects:manage';
  static const String academicTimetableManage = 'academic:timetable:manage';

  // Attendance (examples)
  static const String attendanceMark = 'attendance:mark'; // Teacher
  static const String attendanceViewReportInstitution = 'attendance:view_report_institution'; // InstAdmin
  static const String attendanceViewOwn = 'attendance:view_own'; // Student, Parent

  // Grades (examples)
  static const String gradesEnter = 'grades:enter'; // Teacher
  static const String gradesViewAllInInstitution = 'grades:view_all_in_institution'; // InstAdmin
  static const String gradesViewOwn = 'grades:view_own'; // Student, Parent
  static const String gradesPublishReports = 'grades:publish_reports'; // InstAdmin or specific role

  // Fees & Payments (examples)
  static const String feesDefineStructures = 'fees:define_structures'; // InstAdmin
  static const String feesAssignToStudents = 'fees:assign_to_students'; // InstAdmin/Accounts
  static const String feesRecordPayment = 'fees:record_payment'; // Accounts
  static const String feesViewReports = 'fees:view_reports'; // InstAdmin/Accounts
  static const String feesPayOnline = 'fees:pay_online'; // Student/Parent (for their own fees)

  // Transport (examples)
  static const String transportManageRoutes = 'transport:manage_routes';
  static const String transportAssignStudents = 'transport:assign_students';

  // Vendors (examples)
  static const String vendorsManage = 'vendors:manage'; // SuperAdmin or specific procurement role

  // Role & Permission Management (SuperAdmin only)
  static const String permissionsManage = 'permissions:manage';


  // Method to get all defined permissions, useful for UI generation
  static List<String> getAllPermissions() {
    return [
      usersRead, usersCreate, usersUpdate, usersUpdateOwn, usersDelete, usersManageRoles, usersToggleActive,
      institutionsCreate, institutionsRead, institutionsUpdate, institutionsDelete,
      institutionSettingsEdit,
      announcementsCreateSystem, announcementsCreateInstitution, announcementsUpdateAny, announcementsUpdateOwnInstitution, announcementsDeleteAny, announcementsDeleteOwnInstitution,
      filesUpload, filesDeleteOwn, filesDeleteAnyInInstitution, filesDeleteAnySystem,
      academicClassesManage, academicSubjectsManage, academicTimetableManage,
      attendanceMark, attendanceViewReportInstitution, attendanceViewOwn,
      gradesEnter, gradesViewAllInInstitution, gradesViewOwn, gradesPublishReports,
      feesDefineStructures, feesAssignToStudents, feesRecordPayment, feesViewReports, feesPayOnline,
      transportManageRoutes, transportAssignStudents,
      vendorsManage,
      permissionsManage,
    ];
  }
}
