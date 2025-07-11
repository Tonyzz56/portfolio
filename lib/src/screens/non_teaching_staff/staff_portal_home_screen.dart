import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/screens/placeholders/placeholder_screen.dart';

class StaffPortalHomeScreen extends StatelessWidget {
  const StaffPortalHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserModel? currentUser = Provider.of<UserModel?>(context);

    if (currentUser == null || currentUser.role != UserRole.nonTeachingStaff) {
      return Scaffold(
        appBar: AppBar(title: const Text("Access Denied")),
        body: const Center(child: Text("You do not have permission to view this page.")),
      );
    }

    String departmentInfo = currentUser.department != null && currentUser.department!.isNotEmpty
        ? "You are currently assigned to the ${currentUser.department} department."
        : "You are not currently assigned to a specific department. Some features may be limited.";

    return PlaceholderScreen(
      title: 'Staff Portal Home',
      message: 'Welcome, ${currentUser.displayName ?? currentUser.customLoginId}!\n\n'
               '$departmentInfo\n\n'
               'This is your central portal. Your main dashboard will show tools and functions specific to your department and role.\n'
               'Use the sidebar to navigate to available features such as Announcements and your Profile.\n\n'
               'Department-specific modules (e.g., for Finance, IT, Admin, Procurement, Transport, Accommodation) will be implemented in later phases.',
    );
  }
}
