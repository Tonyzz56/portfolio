import 'package:flutter/material.dart';
import 'package:school_management_system/src/models/academic_year_model.dart';
import 'package:school_management_system/src/services/academic_service.dart';
import 'package:intl/intl.dart';
import 'academic_year_form_screen.dart';
import 'manage_terms_screen.dart'; // For navigating to terms of an academic year

class ManageAcademicYearsScreen extends StatefulWidget {
  final String institutionId;

  const ManageAcademicYearsScreen({super.key, required this.institutionId});

  @override
  State<ManageAcademicYearsScreen> createState() => _ManageAcademicYearsScreenState();
}

class _ManageAcademicYearsScreenState extends State<ManageAcademicYearsScreen> {
  final AcademicService _academicService = AcademicService();

  void _navigateToForm({AcademicYearModel? academicYear}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AcademicYearFormScreen(
          institutionId: widget.institutionId,
          academicYear: academicYear,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _navigateToManageTerms(AcademicYearModel year) {
     Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageTermsScreen(
          institutionId: widget.institutionId,
          academicYear: year
        ),
      ),
    );
  }

  Future<void> _toggleActiveStatus(AcademicYearModel year) async {
    bool success = await _academicService.updateAcademicYear(year.id, {'isActive': !year.isActive}, widget.institutionId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Academic year "${year.name}" status updated to ${!year.isActive ? "Active" : "Inactive"}.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) setState(() {});
    }
  }

  Future<void> _confirmDelete(AcademicYearModel year) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to permanently delete academic year "${year.name}"? This may affect associated terms and classes. This action cannot be undone.'),
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
      bool success = await _academicService.deleteAcademicYear(year.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Academic year "${year.name}" ${success ? "permanently deleted" : "deletion failed"}.'), backgroundColor: success ? Colors.green : Colors.red),
        );
        if (success) setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Academic Years'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add New Academic Year',
            onPressed: () => _navigateToForm(),
          ),
        ],
      ),
      body: StreamBuilder<List<AcademicYearModel>>(
        stream: _academicService.getAcademicYears(widget.institutionId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No academic years found. Add one!'));
          }

          List<AcademicYearModel> academicYears = snapshot.data!;

          return ListView.builder(
            itemCount: academicYears.length,
            itemBuilder: (context, index) {
              AcademicYearModel year = academicYears[index];
              String dateRange = "${DateFormat.yMMMd().format(year.startDate)} - ${DateFormat.yMMMd().format(year.endDate)}";
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  leading: Icon(year.isActive ? Icons.check_circle : Icons.hourglass_empty, color: year.isActive ? Colors.green : Colors.orangeAccent),
                  title: Text(year.name, style: TextStyle(fontWeight: year.isActive ? FontWeight.bold : FontWeight.normal)),
                  subtitle: Text(dateRange),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _navigateToForm(academicYear: year);
                      } else if (value == 'toggle_active') {
                        _toggleActiveStatus(year);
                      } else if (value == 'delete') {
                         _confirmDelete(year);
                      }
                      else if (value == 'manage_terms') {
                        _navigateToManageTerms(year);
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(leading: Icon(Icons.edit), title: Text('Edit')),
                      ),
                      const PopupMenuItem<String>( // Manage Terms navigation
                        value: 'manage_terms',
                        child: ListTile(leading: Icon(Icons.list_alt), title: Text('Manage Terms')),
                      ),
                      PopupMenuItem<String>(
                        value: 'toggle_active',
                        child: ListTile(leading: Icon(year.isActive ? Icons.cancel_outlined : Icons.check_circle_outline), title: Text(year.isActive ? 'Set Inactive' : 'Set Active')),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(leading: Icon(Icons.delete_forever, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red))),
                      ),
                    ],
                  ),
                   onTap: () {
                      _navigateToManageTerms(year);
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
