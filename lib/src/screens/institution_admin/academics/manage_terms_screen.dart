import 'package:flutter/material.dart';
import 'package:school_management_system/src/models/academic_year_model.dart';
import 'package:school_management_system/src/models/term_model.dart';
import 'package:school_management_system/src/services/academic_service.dart';
import 'package:intl/intl.dart';
import 'term_form_screen.dart';
import 'manage_classes_screen.dart'; // For navigating to classes of a term

class ManageTermsScreen extends StatefulWidget {
  final String institutionId;
  final AcademicYearModel academicYear;

  const ManageTermsScreen({
    super.key,
    required this.institutionId,
    required this.academicYear,
  });

  @override
  State<ManageTermsScreen> createState() => _ManageTermsScreenState();
}

class _ManageTermsScreenState extends State<ManageTermsScreen> {
  final AcademicService _academicService = AcademicService();

  void _navigateToForm({TermModel? term}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TermFormScreen(
          institutionId: widget.institutionId,
          academicYearId: widget.academicYear.id,
          academicYearName: widget.academicYear.name,
          term: term,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _navigateToManageClasses(TermModel term) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageClassesScreen(
          institutionId: widget.institutionId,
          academicYear: widget.academicYear, // Pass the full AcademicYearModel
          term: term
        ),
      ),
    );
  }

  Future<void> _toggleCurrentTerm(TermModel term) async {
    bool success = await _academicService.updateTerm(
      term.id,
      {'isCurrentTerm': !term.isCurrentTerm},
      widget.institutionId,
      widget.academicYear.id
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Term "${term.name}" status updated to ${!term.isCurrentTerm ? "Current" : "Not Current"}.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) setState(() {});
    }
  }

  Future<void> _confirmDelete(TermModel term) async {
     bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to permanently delete term "${term.name}"? This may affect associated classes. This action cannot be undone.'),
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
      bool success = await _academicService.deleteTerm(term.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Term "${term.name}" ${success ? "permanently deleted" : "deletion failed"}.'), backgroundColor: success ? Colors.green : Colors.red),
        );
        if (success) setState(() {});
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Terms for ${widget.academicYear.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add New Term',
            onPressed: () => _navigateToForm(),
          ),
        ],
      ),
      body: StreamBuilder<List<TermModel>>(
        stream: _academicService.getTerms(widget.institutionId, widget.academicYear.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No terms found for ${widget.academicYear.name}. Add one!'));
          }

          List<TermModel> terms = snapshot.data!;

          return ListView.builder(
            itemCount: terms.length,
            itemBuilder: (context, index) {
              TermModel term = terms[index];
              String dateRange = "${DateFormat.yMMMd().format(term.startDate)} - ${DateFormat.yMMMd().format(term.endDate)}";
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  leading: Icon(term.isCurrentTerm ? Icons.play_circle_fill : Icons.pause_circle_outline, color: term.isCurrentTerm ? Colors.blueAccent : Colors.grey),
                  title: Text(term.name, style: TextStyle(fontWeight: term.isCurrentTerm ? FontWeight.bold : FontWeight.normal)),
                  subtitle: Text(dateRange),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _navigateToForm(term: term);
                      } else if (value == 'toggle_current') {
                        _toggleCurrentTerm(term);
                      } else if (value == 'delete') {
                        _confirmDelete(term);
                      }
                      else if (value == 'manage_classes') {
                        _navigateToManageClasses(term);
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(leading: Icon(Icons.edit), title: Text('Edit')),
                      ),
                      PopupMenuItem<String>(
                        value: 'manage_classes',
                        child: ListTile(leading: Icon(Icons.class_outlined), title: Text('Manage Classes')),
                      ),
                       PopupMenuItem<String>(
                        value: 'toggle_current',
                        child: ListTile(leading: Icon(term.isCurrentTerm ? Icons.pause_circle_outline : Icons.play_arrow_outlined), title: Text(term.isCurrentTerm ? 'Set Not Current' : 'Set as Current Term')),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(leading: Icon(Icons.delete_forever, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red))),
                      ),
                    ],
                  ),
                  onTap: () {
                      _navigateToManageClasses(term);
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
