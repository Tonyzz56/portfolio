import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/screens/admin/super_admin_dashboard_screen.dart' show DynamicAppDrawer, DashboardCard;
import 'package:school_management_system/src/widgets/app_bar_notification_icon.dart'; // Import new widget


class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserModel? currentUser = Provider.of<UserModel?>(context);

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("User not authenticated.")));
    }
    if (currentUser.role != UserRole.parent) {
      return Scaffold(
        appBar: AppBar(title: const Text("Access Denied")),
        body: const Center(child: Text("This dashboard is for parents only.")),
      );
    }
    if (currentUser.institutionId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Institution information is missing. Please contact support.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
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
            title: 'My Children\'s Overview',
            icon: Icons.escalator_warning,
            onTap: () {
              Navigator.pushNamed(context, '/parent/my-children');
            },
          ),
          DashboardCard(
            title: 'School Announcements',
            icon: Icons.campaign,
            onTap: () => Navigator.pushNamed(context, '/announcements'),
          ),
          // Example for future:
          // DashboardCard(
          //   title: 'Upcoming Events',
          //   icon: Icons.event,
          //   onTap: () { /* Navigate to school event calendar */ },
          // ),
          // DashboardCard(
          //   title: 'Fee Payments',
          //   icon: Icons.payment,
          //   onTap: () { /* Navigate to fee payment section */ },
          // ),
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
              currentUser.displayName ?? 'Parent',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("Login ID: ${currentUser.customLoginId ?? currentUser.email}"),
            if (currentUser.childUids != null && currentUser.childUids!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text("Linked to ${currentUser.childUids!.length} child(ren). View details in 'My Children'."),
              )
            else
              const Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: Text("No children currently linked to this account."),
              ),
          ],
        ),
      ),
    );
  }
}
