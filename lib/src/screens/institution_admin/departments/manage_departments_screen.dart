import 'package:flutter/material.dart';
import 'package:school_management_system/src/models/department_model.dart';
import 'package:school_management_system/src/services/department_service.dart';
import 'package:school_management_system/src/models/user_model.dart'; // For UserModel if needed for HOD display
// import 'package:provider/provider.dart'; // If needing UserModel for HOD display
import 'department_form_screen.dart';

class ManageDepartmentsScreen extends StatefulWidget {
  final String institutionId;

  const ManageDepartmentsScreen({super.key, required this.institutionId});

  @override
  State<ManageDepartmentsScreen> createState() => _ManageDepartmentsScreenState();
}

class _ManageDepartmentsScreenState extends State<ManageDepartmentsScreen> {
  final DepartmentService _departmentService = DepartmentService();

  void _navigateToForm({DepartmentModel? department}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DepartmentFormScreen(
          institutionId: widget.institutionId,
          department: department,
        ),
      ),
    ).then((_) => setState(() {})); // Refresh list on return
  }

  Future<void> _confirmDelete(DepartmentModel department) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to permanently delete department "${department.name}"? This action cannot be undone. Ensure no staff are currently assigned to this department.'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete Permanently'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        bool success = await _departmentService.deleteDepartment(department.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Department "${department.name}" permanently deleted.'), backgroundColor: Colors.green),
          );
          if (success) setState(() {});
        }
      } catch (e) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete "${department.name}": ${e.toString()}'), backgroundColor: Colors.red),
            );
         }
      }
    }
  }

  // Helper to potentially fetch HOD name - in a real app, you'd fetch this from users collection
  // For now, it's a placeholder.
  Widget _getHodDisplay(String? hodUid) {
    if (hodUid == null || hodUid.isEmpty) {
      return const Text('HOD: Not Assigned', style: TextStyle(fontStyle: FontStyle.italic));
    }
    // In a real app:
    // final userServiceProvider = Provider.of<UserService>(context, listen:false); // Assuming a UserService
    // return FutureBuilder<UserModel?>(
    //   future: userServiceProvider.getUserById(hodUid),
    //   builder: (context, snapshot) {
    //     if (snapshot.connectionState == ConnectionState.waiting) return Text('HOD: Loading...');
    //     if (snapshot.hasData && snapshot.data != null) return Text('HOD: ${snapshot.data!.displayName}');
    //     return Text('HOD UID: $hodUid (Name not found)', style: TextStyle(fontStyle: FontStyle.italic));
    //   }
    // );
    return Text('HOD UID: $hodUid (Display logic placeholder)', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Departments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add New Department',
            onPressed: () => _navigateToForm(),
          ),
        ],
      ),
      body: StreamBuilder<List<DepartmentModel>>(
        stream: _departmentService.getDepartmentsForInstitution(widget.institutionId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No departments found. Add one!'));
          }

          List<DepartmentModel> departments = snapshot.data!;

          return ListView.builder(
            itemCount: departments.length,
            itemBuilder: (context, index) {
              DepartmentModel dept = departments[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  title: Text(dept.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dept.description ?? 'No description.'),
                      _getHodDisplay(dept.headOfDepartmentUid),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _navigateToForm(department: dept);
                      } else if (value == 'delete') {
                        _confirmDelete(dept);
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(leading: Icon(Icons.edit), title: Text('Edit')),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(leading: Icon(Icons.delete_forever, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red))),
                      ),
                    ],
                  ),
                  onTap: () => _navigateToForm(department: dept),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
