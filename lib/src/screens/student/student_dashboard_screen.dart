import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/screens/admin/super_admin_dashboard_screen.dart' show DynamicAppDrawer, DashboardCard;
import 'package:school_management_system/src/widgets/app_bar_notification_icon.dart'; // Import new widget

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserModel? currentUser = Provider.of<UserModel?>(context);

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("User not authenticated.")));
    }
    if (currentUser.role != UserRole.student || currentUser.institutionId == null) { // Students must have an institution
      return Scaffold(
        appBar: AppBar(title: const Text("Access Denied / Error")),
        body: const Center(
          child: Text("User is not a student or institution information is missing."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
         actions: const [
          AppBarNotificationIcon(),
          SizedBox(width: 10),
        ],
      ),
      drawer: const DynamicAppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          _buildHeader(context, currentUser),
          const SizedBox(height: 20),
          DashboardCard(
            title: 'My Grades & Results',
            icon: Icons.bar_chart,
            onTap: () => Navigator.pushNamed(context, '/student/my-grades'),
          ),
          DashboardCard(
            title: 'My Attendance',
            icon: Icons.check_circle_outline,
            onTap: () => Navigator.pushNamed(context, '/student/my-attendance'),
          ),
          DashboardCard(
            title: 'My Timetable',
            icon: Icons.schedule,
            onTap: () => Navigator.pushNamed(context, '/student/my-timetable'),
          ),
          DashboardCard(
            title: 'Learning Materials',
            icon: Icons.menu_book,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Learning Materials (Not Implemented - Use Named Route /student/learning-materials)')));
            },
          ),
          DashboardCard(
            title: 'Announcements',
            icon: Icons.campaign,
            onTap: () => Navigator.pushNamed(context, '/announcements'),
          ),
           DashboardCard(
            title: 'My Submissions',
            icon: Icons.file_present_outlined,
            onTap: () => Navigator.pushNamed(context, '/student/my-submissions'),
          ),
           DashboardCard(
            title: 'Download Results (PDF)',
            icon: Icons.download_for_offline,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download Results (Not Implemented)')));
            },
          ),
        ],
      ),
    );
  }

   Widget _buildHeader(BuildContext context, UserModel currentUser) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentUser.displayName ?? 'Student',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("Login ID: ${currentUser.customLoginId ?? currentUser.email}"),
            if (currentUser.admissionNumber != null) Text("Admission No: ${currentUser.admissionNumber}"),
            if (currentUser.currentClassId != null) Text("Class ID: ${currentUser.currentClassId}"),
          ],
        ),
      ),
    );
  }
}
