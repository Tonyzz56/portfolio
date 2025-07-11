import 'package:flutter/material.dart';
import 'package:school_management_system/src/models/class_model.dart';
import 'package:school_management_system/src/models/term_model.dart'; // To show context
import 'package:school_management_system/src/models/academic_year_model.dart'; // To show context
import 'package:school_management_system/src/services/academic_service.dart';
import 'class_form_screen.dart';
// import 'manage_subjects_for_class_screen.dart'; // Future screen
// import 'manage_students_for_class_screen.dart'; // Future screen

class ManageClassesScreen extends StatefulWidget {
  final String institutionId;
  final AcademicYearModel academicYear; // Pass the full AcademicYearModel
  final TermModel? term; // Optional: if classes are term-specific, otherwise academicYear specific

  const ManageClassesScreen({
    super.key,
    required this.institutionId,
    required this.academicYear,
    this.term,
  });

  @override
  State<ManageClassesScreen> createState() => _ManageClassesScreenState();
}

class _ManageClassesScreenState extends State<ManageClassesScreen> {
  final AcademicService _academicService = AcademicService();

  void _navigateToForm({ClassModel? classModel}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassFormScreen(
          institutionId: widget.institutionId,
          academicYearId: widget.academicYear.id,
          termId: widget.term?.id, // Pass termId if available
          classModel: classModel,
        ),
      ),
    ).then((_) => setState(() {})); // Refresh list
  }

  Future<void> _confirmDelete(ClassModel classModel) async {
     bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to permanently delete class "${classModel.name}"? This may affect enrolled students and assigned subjects/teachers. This action cannot be undone.'),
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
      bool success = await _academicService.deleteClass(classModel.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Class "${classModel.name}" ${success ? "permanently deleted" : "deletion failed"}.'), backgroundColor: success ? Colors.green : Colors.red),
        );
        if (success) setState(() {});
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    String screenTitle = "Manage Classes for ${widget.academicYear.name}";
    if (widget.term != null) {
      screenTitle += " - ${widget.term!.name}";
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add New Class',
            onPressed: () => _navigateToForm(),
          ),
        ],
      ),
      body: StreamBuilder<List<ClassModel>>(
        stream: _academicService.getClasses(
          widget.institutionId,
          academicYearId: widget.academicYear.id,
          termId: widget.term?.id
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No classes found for this ${widget.term != null ? "term" : "academic year"}. Add one!'));
          }

          List<ClassModel> classes = snapshot.data!;

          return ListView.builder(
            itemCount: classes.length,
            itemBuilder: (context, index) {
              ClassModel classItem = classes[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  title: Text(classItem.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (classItem.classTeacherUid != null && classItem.classTeacherUid!.isNotEmpty)
                        Text('Teacher UID: ${classItem.classTeacherUid}'), // TODO: Display teacher name
                      else
                        const Text('Teacher: Not Assigned'),
                      Text('Room: ${classItem.roomNumber ?? "N/A"}, Capacity: ${classItem.capacity ?? "N/A"}'),
                      Text('Students Enrolled: ${classItem.studentUids?.length ?? 0}'),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _navigateToForm(classModel: classItem);
                      } else if (value == 'delete') {
                         _confirmDelete(classItem);
                      }
                      // else if (value == 'manage_students') { /* Navigate to manage students for this class */ }
                      // else if (value == 'assign_subjects') { /* Navigate to assign subjects to this class */ }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(leading: Icon(Icons.edit), title: Text('Edit Class Details')),
                      ),
                      // const PopupMenuItem<String>(
                      //   value: 'manage_students',
                      //   child: ListTile(leading: Icon(Icons.groups_outlined), title: Text('Manage Students')),
                      // ),
                      // const PopupMenuItem<String>(
                      //   value: 'assign_subjects',
                      //   child: ListTile(leading: Icon(Icons.library_books_outlined), title: Text('Assign Subjects')),
                      // ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(leading: Icon(Icons.delete_forever, color: Colors.red), title: Text('Delete Class', style: TextStyle(color: Colors.red))),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Could navigate to a detailed class view screen, or directly to edit.
                    _navigateToForm(classModel: classItem);
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
