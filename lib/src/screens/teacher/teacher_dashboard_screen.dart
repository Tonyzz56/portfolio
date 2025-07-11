import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/screens/admin/super_admin_dashboard_screen.dart' show DynamicAppDrawer, DashboardCard;
import 'package:school_management_system/src/widgets/app_bar_notification_icon.dart'; // Import new widget


class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserModel? currentUser = Provider.of<UserModel?>(context);

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("User not authenticated.")));
    }
    if (currentUser.role != UserRole.teacher || currentUser.institutionId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Access Denied / Error")),
        body: const Center(
          child: Text("User is not a teacher or institution information is missing."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        actions: const [ // Add notification icon
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
            title: 'My Classes & Students',
            icon: Icons.group,
            onTap: () => Navigator.pushNamed(context, '/teacher/my-classes'),
          ),
          DashboardCard(
            title: 'Enter Grades/Marks',
            icon: Icons.assessment,
            onTap: () => Navigator.pushNamed(context, '/teacher/enter-grades'),
          ),
          DashboardCard(
            title: 'Mark Attendance',
            icon: Icons.check_circle_outline,
            onTap: () => Navigator.pushNamed(context, '/teacher/mark-attendance'),
          ),
          DashboardCard(
            title: 'My Timetable',
            icon: Icons.schedule_send_outlined,
            onTap: () => Navigator.pushNamed(context, '/teacher/my-timetable'),
          ),
          DashboardCard(
            title: 'Manage My Uploads',
            icon: Icons.upload_file,
            onTap: () => Navigator.pushNamed(context, '/teacher/my-uploads'),
          ),
           DashboardCard(
            title: 'View Announcements',
            icon: Icons.campaign,
            onTap: () => Navigator.pushNamed(context, '/announcements'),
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
              currentUser.displayName ?? 'Teacher',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("Login ID: ${currentUser.customLoginId ?? currentUser.email}"),
            if (currentUser.staffId != null) Text("Staff ID: ${currentUser.staffId}"),
          ],
        ),
      ),
    );
  }
}
