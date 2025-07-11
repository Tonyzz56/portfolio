import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/screens/admin/super_admin_dashboard_screen.dart' show DashboardCard;
// Routes will be handled by Navigator.pushNamed

class AcademicSettingsHubScreen extends StatelessWidget {
  const AcademicSettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserModel? currentUser = Provider.of<UserModel?>(context);

    if (currentUser == null || currentUser.institutionId == null || currentUser.role != UserRole.institutionAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text("Access Denied")),
        body: const Center(child: Text("User, institution data not available, or insufficient permissions.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Academic Management Hub"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          DashboardCard(
            title: "Manage Academic Years & Terms",
            icon: Icons.calendar_view_month,
            onTap: () => Navigator.pushNamed(context, '/institution/academic/years'),
          ),
          DashboardCard(
            title: "Manage Classes",
            icon: Icons.class__outlined,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Manage Classes by first selecting Academic Year & Term.')),
              );
              Navigator.pushNamed(context, '/institution/academic/years');
            },
          ),
           DashboardCard(
            title: "Manage Subjects",
            icon: Icons.library_books_outlined,
            onTap: () => Navigator.pushNamed(context, '/institution/academic/subjects'),
          ),
          DashboardCard(
            title: "Manage Timetables",
            icon: Icons.table_chart_sharp,
            onTap: () => Navigator.pushNamed(context, '/institution/academic/timetables'),
          ),
          DashboardCard(
            title: "Manage Assessments",
            icon: Icons.assignment_turned_in_outlined,
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigating to general Assessment Management. Select context there or via Year/Subject drilldown.')),
              );
              // For a general assessments management, academicYearId is crucial.
              // This should ideally navigate to a screen where AY can be selected first,
              // or pass a currently active/selected AY ID if available globally.
              // For now, navigating to academic years as a starting point to select context.
              Navigator.pushNamed(context, '/institution/academic/years',
                // arguments: {'navigateToAssessments': true} // Future: Pass arg to AY screen to then auto-nav or show assessments button
              );
            },
          ),
          DashboardCard(
            title: "Attendance Reports",
            icon: Icons.fact_check_outlined,
            onTap: () => Navigator.pushNamed(context, '/institution/academic/attendance-reports'),
          ),
          DashboardCard( // New Card for Grade Reports
            title: "Grade Reports & Analysis",
            icon: Icons.assessment_work_outlined, // Or Icons.bar_chart or similar
            onTap: () => Navigator.pushNamed(context, '/institution/academic/grade-reports'),
          ),
          DashboardCard(
            title: "Assign Subjects to Classes (Future)",
            icon: Icons.link,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Assign Subjects to Classes (Not Implemented Yet)')),
              );
            },
          ),
          DashboardCard(
            title: "Assign Teachers to Subjects/Classes (Future)",
            icon: Icons.person_add_alt_1_outlined,
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Assign Teachers (Not Implemented Yet)')),
              );
            },
          ),
        ],
      ),
    );
  }
}
