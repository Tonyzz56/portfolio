import 'package:flutter/material.dart';
import 'package:school_management_system/src/config/permissions.dart';
import 'package:school_management_system/src/models/role_permission_model.dart';
import 'package:school_management_system/src/services/role_permission_service.dart';

class EditRolePermissionsScreen extends StatefulWidget {
  final String roleId;

  const EditRolePermissionsScreen({super.key, required this.roleId});

  @override
  State<EditRolePermissionsScreen> createState() => _EditRolePermissionsScreenState();
}

class _EditRolePermissionsScreenState extends State<EditRolePermissionsScreen> {
  final RolePermissionService _rolePermissionService = RolePermissionService();
  Map<String, bool> _currentPermissions = {};
  bool _isLoading = true;
  String _searchTerm = "";

  // Group permissions for better UI
  Map<String, List<String>> _groupedPermissions = {};

  @override
  void initState() {
    super.initState();
    _loadPermissions();
    _groupPermissions();
  }

  void _groupPermissions() {
    _groupedPermissions = {};
    List<String> allPermissions = AppPermissions.getAllPermissions();
    allPermissions.sort();

    for (String perm in allPermissions) {
      String groupKey = "general"; // Default group
      if (perm.contains(':')) {
        groupKey = perm.split(':')[0]; // Group by module e.g. 'users', 'institutions'
      }
      _groupedPermissions.putIfAbsent(groupKey, () => []).add(perm);
    }
  }


  Future<void> _loadPermissions() async {
    setState(() => _isLoading = true);
    RolePermission? rolePerm = await _rolePermissionService.getRolePermissions(widget.roleId);
    if (mounted) {
      setState(() {
        // Ensure all defined permissions have an entry, defaulting to false if not present
        final allAppPermissions = AppPermissions.getAllPermissions();
        _currentPermissions = {
          for (var permKey in allAppPermissions)
            permKey: rolePerm?.permissions[permKey] ?? false
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _savePermissions() async {
    setState(() => _isLoading = true);
    bool success = await _rolePermissionService.setRolePermissions(widget.roleId, _currentPermissions);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Permissions updated successfully!' : 'Failed to update permissions.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      setState(() => _isLoading = false);
      if (success) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredGroupedPermissions = _groupedPermissions.map((key, value) {
        final filteredValues = value.where((perm) => perm.toLowerCase().contains(_searchTerm.toLowerCase())).toList();
        return MapEntry(key, filteredValues);
    })..removeWhere((key, value) => value.isEmpty);


    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Permissions: ${widget.roleId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _savePermissions,
            tooltip: 'Save Permissions',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search Permissions',
                      hintText: 'e.g., users:create or attendance',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchTerm = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredGroupedPermissions.keys.length,
                    itemBuilder: (context, groupIndex) {
                      String groupName = filteredGroupedPermissions.keys.elementAt(groupIndex);
                      List<String> permissionsInGroup = filteredGroupedPermissions[groupName]!;

                      return ExpansionTile(
                        title: Text(groupName.toUpperCase(), style: Theme.of(context).textTheme.titleMedium),
                        initiallyExpanded: _searchTerm.isNotEmpty || groupName == "general", // Expand if searching or it's general
                        children: permissionsInGroup.map((String permKey) {
                          return CheckboxListTile(
                            title: Text(permKey),
                            value: _currentPermissions[permKey] ?? false,
                            onChanged: (bool? value) {
                              if (value != null) {
                                setState(() {
                                  _currentPermissions[permKey] = value;
                                });
                              }
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
