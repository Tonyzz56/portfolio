import 'package:flutter/material.dart'; // For IconData

class NavigationItemModel {
  final String title;
  final IconData icon;
  final String? routeName; // For named routes
  final Widget? directWidget; // For direct widget navigation (use one or the other)
  final String? requiredPermission; // Permission key from AppPermissions
  final List<UserRole>? targetUserRoles; // Specific roles this item is for (optional)
  final List<String>? targetDepartments; // Specific departments this item is for (optional, for non-teaching)
  final VoidCallback? onTapAction; // For items that don't navigate but perform an action

  NavigationItemModel({
    required this.title,
    required this.icon,
    this.routeName,
    this.directWidget,
    this.requiredPermission,
    this.targetUserRoles,
    this.targetDepartments,
    this.onTapAction,
  }) : assert(routeName == null || directWidget == null, 'Cannot provide both routeName and directWidget'),
       assert(routeName != null || directWidget != null || onTapAction != null, 'Must provide either a route, a widget, or an onTapAction');
}

// We will need to import UserRole from user_model.dart if not already implicitly available
// For simplicity, assuming UserRole enum is accessible here or NavigationService will handle the mapping.
enum UserRole { // Duplicating for context, actual import from user_model.dart
  superAdmin,
  institutionAdmin,
  teacher,
  student,
  nonTeachingStaff,
  parent,
  vendor,
  unknown
}
