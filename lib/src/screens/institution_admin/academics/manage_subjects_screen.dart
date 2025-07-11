import 'package:flutter/material.dart';
import 'package:school_management_system/src/models/subject_model.dart';
import 'package:school_management_system/src/services/academic_service.dart';
import 'subject_form_screen.dart';

class ManageSubjectsScreen extends StatefulWidget {
  final String institutionId;

  const ManageSubjectsScreen({super.key, required this.institutionId});

  @override
  State<ManageSubjectsScreen> createState() => _ManageSubjectsScreenState();
}

class _ManageSubjectsScreenState extends State<ManageSubjectsScreen> {
  final AcademicService _academicService = AcademicService();

  void _navigateToForm({SubjectModel? subject}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectFormScreen(
          institutionId: widget.institutionId,
          subject: subject,
        ),
      ),
    ).then((_) => setState(() {})); // Refresh list on return
  }

  Future<void> _confirmDelete(SubjectModel subject) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to permanently delete subject "${subject.name} (${subject.code})"? This may affect class schedules and teacher assignments. This action cannot be undone.'),
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
      bool success = await _academicService.deleteSubject(subject.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subject "${subject.name}" ${success ? "permanently deleted" : "deletion failed"}.'), backgroundColor: success ? Colors.green : Colors.red),
        );
        if (success) setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Subjects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add New Subject',
            onPressed: () => _navigateToForm(),
          ),
        ],
      ),
      body: StreamBuilder<List<SubjectModel>>(
        stream: _academicService.getSubjects(widget.institutionId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No subjects found. Add one!'));
          }

          List<SubjectModel> subjects = snapshot.data!;

          return ListView.builder(
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              SubjectModel subject = subjects[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  title: Text('${subject.name} (${subject.code})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(subject.description ?? 'No description.'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _navigateToForm(subject: subject);
                      } else if (value == 'delete') {
                         _confirmDelete(subject);
                      }
                      // else if (value == 'assign_teachers') { /* Navigate to assign teachers screen */ }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(leading: Icon(Icons.edit), title: Text('Edit Subject')),
                      ),
                      // const PopupMenuItem<String>(
                      //   value: 'assign_teachers',
                      //   child: ListTile(leading: Icon(Icons.person_add_alt_1), title: Text('Assign Teachers')),
                      // ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(leading: Icon(Icons.delete_forever, color: Colors.red), title: Text('Delete Subject', style: TextStyle(color: Colors.red))),
                      ),
                    ],
                  ),
                   onTap: () => _navigateToForm(subject: subject),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
