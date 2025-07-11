import 'package:flutter/material.dart';
import 'package:school_management_system/src/models/role_permission_model.dart';
import 'package:school_management_system/src/models/user_model.dart'; // For UserRole enum and userRoleToString
import 'package:school_management_system/src/services/role_permission_service.dart';
import 'edit_role_permissions_screen.dart';

class ManageRolePermissionsScreen extends StatefulWidget {
  const ManageRolePermissionsScreen({super.key});

  @override
  State<ManageRolePermissionsScreen> createState() => _ManageRolePermissionsScreenState();
}

class _ManageRolePermissionsScreenState extends State<ManageRolePermissionsScreen> {
  final RolePermissionService _rolePermissionService = RolePermissionService();

  // For creating new custom roles (e.g. nonTeachingStaff_finance)
  final TextEditingController _newRoleController = TextEditingController();

  // Predefined system roles from UserRole enum (excluding superAdmin and unknown)
  // Custom roles will be loaded from Firestore.
  List<String> getSystemRoles() {
    return UserRole.values
        .where((role) => role != UserRole.superAdmin && role != UserRole.unknown)
        .map((role) => userRoleToString(role))
        .toList();
  }

  Future<void> _addNewRole() async {
    final String newRoleId = _newRoleController.text.trim();
    if (newRoleId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Role ID cannot be empty.")));
      return;
    }
    if (newRoleId.contains(' ')) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Role ID cannot contain spaces.")));
        return;
    }

    // Check if role already exists (either as system role or custom)
    // System roles are implicitly "created" when their permissions are set.
    // For custom roles, we check if a document already exists.
    bool isSystemRole = getSystemRoles().contains(newRoleId);
    if (isSystemRole) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("'$newRoleId' is a system-defined role. Edit its permissions directly.")));
         return;
    }

    RolePermission? existingCustomRole = await _rolePermissionService.getRolePermissions(newRoleId);
    // getRolePermissions returns a default if not found, so check if its permissions map is empty or all false
    // A better check would be if the document actually exists, but getRolePermissions abstracts that.
    // For simplicity, we'll assume if it's not a system role and getRolePermissions returns the default (all false), it's new.
    // A more robust check: query Firestore directly for the document.

    // Let's assume for now that if not a system role, we can proceed to create/edit its permissions.
    // The EditRolePermissionsScreen will handle creating the document if it doesn't exist.

    _newRoleController.clear();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditRolePermissionsScreen(roleId: newRoleId),
      ),
    );
  }

  Future<void> _initializeDefaults() async {
    bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            title: const Text('Initialize Default Permissions?'),
            content: const Text('This will set/reset permissions for standard roles (student, teacher, institutionAdmin) to system defaults. Custom roles will not be affected. This is useful for initial setup. Continue?'),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Initialize', style: TextStyle(color: Colors.orange))),
            ],
          );
        });

    if (confirm == true) {
      await _rolePermissionService.initializeDefaultPermissionsForAllRoles();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Default permissions initialization process completed.'), backgroundColor: Colors.green)
      );
      setState(() {}); // Refresh the list
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Roles & Permissions'),
        actions: [
            IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Initialize Default Permissions',
                onPressed: _initializeDefaults,
            )
        ],
      ),
      body: StreamBuilder<List<RolePermission>>(
        stream: _rolePermissionService.getAllRolePermissionsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Combine system roles with roles fetched from Firestore (custom roles)
          List<String> systemRoles = getSystemRoles();
          List<RolePermission> customRolesFromDb = snapshot.data ?? [];

          Set<String> allRoleIds = {...systemRoles};
          for (var rolePerm in customRolesFromDb) {
            allRoleIds.add(rolePerm.roleId);
          }
          List<String> sortedRoleIds = allRoleIds.toList()..sort();


          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newRoleController,
                        decoration: const InputDecoration(
                          labelText: 'New Custom Role ID',
                          hintText: 'e.g., nonTeachingStaff_finance',
                          border: OutlineInputBorder()
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _addNewRole,
                      child: const Text('Add/Edit Role'),
                    )
                  ],
                ),
              ),
              const Divider(),
              if (sortedRoleIds.isEmpty)
                const Expanded(child: Center(child: Text('No roles found or defined yet. Add a custom role or initialize defaults.'))),
              Expanded(
                child: ListView.builder(
                  itemCount: sortedRoleIds.length,
                  itemBuilder: (context, index) {
                    final roleId = sortedRoleIds[index];
                    bool isSystem = systemRoles.contains(roleId);
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text(roleId, style: TextStyle(fontWeight: isSystem ? FontWeight.bold : FontWeight.normal)),
                        subtitle: Text(isSystem ? 'System Role' : 'Custom Role'),
                        trailing: const Icon(Icons.edit_attributes),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditRolePermissionsScreen(roleId: roleId),
                            ),
                          ).then((_){setState(() {});}); // Refresh on pop
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
