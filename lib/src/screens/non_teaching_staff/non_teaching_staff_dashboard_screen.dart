import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/models/navigation_item_model.dart';
import 'package:school_management_system/src/services/role_permission_service.dart';
import 'package:school_management_system/src/config/navigation_config.dart';
import 'package:school_management_system/src/screens/admin/super_admin_dashboard_screen.dart' show DynamicAppDrawer, DashboardCard;
import 'package:school_management_system/src/widgets/app_bar_notification_icon.dart'; // Import new widget

class NonTeachingStaffDashboardScreen extends StatelessWidget {
  const NonTeachingStaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserModel? currentUser = Provider.of<UserModel?>(context);
    final RolePermissionService rolePermissionService = Provider.of<RolePermissionService>(context, listen: false);

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("User not authenticated.")));
    }
    if (currentUser.role != UserRole.nonTeachingStaff || currentUser.institutionId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Access Denied / Error")),
        body: const Center(
          child: Text("User is not Non-Teaching Staff or institution information is missing."),
        ),
      );
    }

    String dashboardTitle = currentUser.department != null && currentUser.department!.isNotEmpty
        ? "${currentUser.department} Staff Dashboard"
        : "Staff Dashboard";

    List<Widget> departmentDashboardCards = _getDepartmentSpecificDashboardCards(currentUser, rolePermissionService, context);

    return Scaffold(
      appBar: AppBar(
        title: Text(dashboardTitle),
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
            title: 'My Tasks',
            icon: Icons.task_alt,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('My Tasks (Not Implemented)')));
            },
          ),
          DashboardCard(
            title: 'Institution Calendar',
            icon: Icons.calendar_today,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calendar (Not Implemented)')));
            },
          ),
          DashboardCard(
            title: 'Announcements',
            icon: Icons.campaign,
            onTap: () => Navigator.pushNamed(context, '/announcements'),
          ),

          if (departmentDashboardCards.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "${currentUser.department ?? 'Your Department'} Specific Tools",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ...departmentDashboardCards,
          ] else if (currentUser.department != null && currentUser.department!.isNotEmpty) ...[
             const SizedBox(height: 10),
             Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "No specific tools configured or accessible for the ${currentUser.department} department at the moment.",
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ]
        ],
      ),
    );
  }

  List<Widget> _getDepartmentSpecificDashboardCards(UserModel currentUser, RolePermissionService permissionService, BuildContext context) {
    List<Widget> cards = [];
    final String? currentDepartment = currentUser.department;

    if (currentDepartment == null || currentDepartment.isEmpty) {
      return cards;
    }

    List<NavigationItemModel> potentialDeptItems = NavigationConfig.allAppNavigationItems.where((item) {
      bool roleMatch = item.targetUserRoles?.contains(UserRole.nonTeachingStaff) ?? false;
      bool departmentMatch = item.targetDepartments?.map((d) => d.toLowerCase()).contains(currentDepartment.toLowerCase()) ?? false;
      return roleMatch && departmentMatch;
    }).toList();

    for (var navItem in potentialDeptItems) {
        bool hasPermission = true;
        if (navItem.requiredPermission != null && navItem.requiredPermission!.isNotEmpty) {
            hasPermission = permissionService.can(navItem.requiredPermission!);
        }

        if (hasPermission) {
            cards.add(
                DashboardCard(
                    title: navItem.title,
                    icon: navItem.icon,
                    onTap: () {
                        if (navItem.routeName != null) {
                            Navigator.pushNamed(context, navItem.routeName!);
                        } else if (navItem.onTapAction != null) {
                            navItem.onTapAction!();
                        } else {
                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${navItem.title} (Action N/A)')));
                        }
                    },
                )
            );
        }
    }
    return cards;
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
              currentUser.displayName ?? 'Staff Member',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("Login ID: ${currentUser.customLoginId ?? currentUser.email}"),
            if (currentUser.staffId != null) Text("Staff ID: ${currentUser.staffId}"),
            if (currentUser.department != null && currentUser.department!.isNotEmpty)
              Text("Department: ${currentUser.department}"),
          ],
        ),
      ),
    );
  }
}
