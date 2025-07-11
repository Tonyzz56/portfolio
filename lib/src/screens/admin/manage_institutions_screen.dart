import 'package:flutter/material.dart';
import 'package:school_management_system/src/models/institution_model.dart';
import 'package:school_management_system/src/services/institution_service.dart';
import 'institution_form_screen.dart'; // For adding/editing

class ManageInstitutionsScreen extends StatefulWidget {
  const ManageInstitutionsScreen({super.key});

  @override
  State<ManageInstitutionsScreen> createState() => _ManageInstitutionsScreenState();
}

class _ManageInstitutionsScreenState extends State<ManageInstitutionsScreen> {
  final InstitutionService _institutionService = InstitutionService();

  void _navigateToForm({Institution? institution}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InstitutionFormScreen(institution: institution),
      ),
    ).then((_) {
      // Refresh list if needed after form closes
      setState(() {});
    });
  }

  Future<void> _toggleActiveStatus(Institution institution) async {
    bool success = await _institutionService.toggleInstitutionStatus(institution.id, !institution.isActive);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Institution ${institution.name} status updated.')),
      );
      setState(() {}); // Refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status for ${institution.name}.')),
      );
    }
  }

  Future<void> _confirmDelete(Institution institution) async {
    // Show confirmation dialog before hard deleting
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to permanently delete ${institution.name}? This action cannot be undone and might affect associated users and data.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      bool success = await _institutionService.deleteInstitutionHard(institution.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Institution ${institution.name} permanently deleted.')),
        );
        setState(() {}); // Refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete ${institution.name}.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Institutions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add New Institution',
            onPressed: () => _navigateToForm(),
          ),
        ],
      ),
      body: StreamBuilder<List<Institution>>(
        stream: _institutionService.getInstitutions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Error fetching institutions: ${snapshot.error}");
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No institutions found. Add one!'));
          }

          List<Institution> institutions = snapshot.data!;

          return ListView.builder(
            itemCount: institutions.length,
            itemBuilder: (context, index) {
              Institution institution = institutions[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  title: Text(institution.name, style: TextStyle(fontWeight: institution.isActive ? FontWeight.bold : FontWeight.normal)),
                  subtitle: Text('${institutionTypeToString(institution.type)} - Admin UID: ${institution.adminUserId.substring(0,6)}...'),
                  leading: Icon(institution.isActive ? Icons.check_circle : Icons.cancel, color: institution.isActive ? Colors.green : Colors.grey),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _navigateToForm(institution: institution);
                      } else if (value == 'toggle_status') {
                        _toggleActiveStatus(institution);
                      } else if (value == 'delete_hard') {
                        _confirmDelete(institution);
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(leading: Icon(Icons.edit), title: Text('Edit')),
                      ),
                      PopupMenuItem<String>(
                        value: 'toggle_status',
                        child: ListTile(leading: Icon(institution.isActive ? Icons.visibility_off : Icons.visibility), title: Text(institution.isActive ? 'Deactivate' : 'Activate')),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'delete_hard',
                        child: ListTile(leading: Icon(Icons.delete_forever, color: Colors.red), title: Text('Delete Permanently', style: TextStyle(color: Colors.red))),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Could navigate to a detailed view screen
                     _navigateToForm(institution: institution); // Or open edit form directly
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
