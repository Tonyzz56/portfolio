import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/models/navigation_item_model.dart';
import 'package:school_management_system/src/services/auth_service.dart';
import 'package:school_management_system/src/services/role_permission_service.dart';
import 'package:school_management_system/src/services/navigation_service.dart';
import 'package:school_management_system/src/config/permissions.dart';
import 'package:school_management_system/src/widgets/app_bar_notification_icon.dart'; // Import new widget


class SuperAdminDashboardScreen extends StatelessWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel?>(context);
    final rolePermissionService = Provider.of<RolePermissionService>(context, listen: false);

    if (userModel == null) {
      return const Scaffold(body: Center(child: Text("User data not available. Please re-login.")));
    }

    bool canManagePermissions = userModel.role == UserRole.superAdmin || rolePermissionService.can(AppPermissions.permissionsManage);
    bool canManageSubscriptions = userModel.role == UserRole.superAdmin;
    bool canViewSystemLogs = userModel.role == UserRole.superAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
        actions: const [ // Add notification icon to app bar
          AppBarNotificationIcon(),
          SizedBox(width: 10), // Optional spacing
        ],
      ),
      drawer: const DynamicAppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
           DashboardCard(
            title: 'Manage Institutions',
            icon: Icons.school,
            onTap: () => Navigator.pushNamed(context, '/manage-institutions'),
          ),
           DashboardCard(
            title: 'Manage Announcements',
            icon: Icons.campaign,
            onTap: () => Navigator.pushNamed(context, '/announcements'),
          ),
          if (canManagePermissions)
            DashboardCard(
              title: 'Manage Roles & Permissions',
              icon: Icons.admin_panel_settings,
              onTap: () => Navigator.pushNamed(context, '/manage-permissions'),
            ),
          if (canManageSubscriptions)
            DashboardCard(
              title: 'Manage Subscriptions',
              icon: Icons.subscriptions,
              onTap: () => Navigator.pushNamed(context, '/manage-subscriptions'),
            ),
           if (canManageSubscriptions) // Assuming same permission for now
            DashboardCard(
              title: 'Subscription Operations',
              icon: Icons.published_with_changes_outlined,
              onTap: () => Navigator.pushNamed(context, '/admin/subscription-operations'), // New route
            ),
          const DashboardCard(
            title: 'System Analytics',
            icon: Icons.analytics,
          ),
          const DashboardCard(
            title: 'Payment Methods Config',
            icon: Icons.payment,
          ),
           if(canViewSystemLogs)
            DashboardCard(
              title: 'View System Logs',
              icon: Icons.receipt_long,
              onTap: () => Navigator.pushNamed(context, '/system-logs'),
            ),
        ],
      ),
    );
  }
}

// DynamicAppDrawer Widget
class DynamicAppDrawer extends StatelessWidget {
  const DynamicAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserModel?>(context);
    final navigationService = Provider.of<NavigationService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    if (currentUser == null) {
      return const Drawer(child: Center(child: Text("Not logged in.")));
    }

    List<NavigationItemModel> navItems = navigationService.getAccessibleNavigationItems(currentUser);

    String displayName = currentUser.displayName ?? currentUser.role.toString().split('.').last;
    String email = currentUser.email;
    String avatarLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : "?";

    final List<Widget> drawerItems = navItems.map((item) {
      return ListTile(
        leading: Icon(item.icon),
        title: Text(item.title),
        onTap: () {
          Navigator.pop(context);
          if (item.onTapAction != null) {
            item.onTapAction!();
          } else if (item.routeName != null) {
            Navigator.pushNamed(context, item.routeName!);
          } else if (item.directWidget != null) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => item.directWidget!));
          }
        },
      );
    }).toList();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(displayName),
            accountEmail: Text(email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(avatarLetter, style: const TextStyle(fontSize: 40.0)),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),
          ...drawerItems,
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context);
              await authService.signOut();
            },
          ),
        ],
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? route;
  final String? routeName;
  final VoidCallback? onTap;

  const DashboardCard({
    super.key,
    required this.title,
    required this.icon,
    this.route,
    this.routeName,
    this.onTap,
  }) : assert(route == null || routeName == null, 'Cannot provide both route and routeName');


  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, size: 40, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontSize: 18)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap ?? () {
          if (routeName != null) {
            Navigator.pushNamed(context, routeName!);
          } else if (route != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => route!),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title tapped (No Action Defined)')),
            );
          }
        },
      ),
    );
  }
}
