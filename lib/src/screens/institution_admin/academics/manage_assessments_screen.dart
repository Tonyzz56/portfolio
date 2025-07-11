import 'package:flutter/material.dart';
import 'package:school_management_system/src/models/assessment_model.dart';
import 'package:school_management_system/src/services/grading_service.dart';
import 'package:school_management_system/src/models/user_model.dart'; // For createdByUid context
import 'package:provider/provider.dart'; // To get current user
import 'package:intl/intl.dart';
import 'assessment_form_screen.dart';
// Import TeacherEnterGradesScreen if navigating directly from here
// import 'package:school_management_system/src/screens/teacher/teacher_enter_grades_screen.dart';


class ManageAssessmentsScreen extends StatefulWidget {
  final String institutionId;
  final String academicYearId;
  final String? termId;
  final String? classId;
  final String? subjectId;
  final String? contextTitle; // e.g., "Assessments for Math Grade 5A"

  const ManageAssessmentsScreen({
    super.key,
    required this.institutionId,
    required this.academicYearId,
    this.termId,
    this.classId,
    this.subjectId,
    this.contextTitle,
  });

  @override
  State<ManageAssessmentsScreen> createState() => _ManageAssessmentsScreenState();
}

class _ManageAssessmentsScreenState extends State<ManageAssessmentsScreen> {
  final GradingService _gradingService = GradingService();
  UserModel? _currentUser;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentUser = Provider.of<UserModel?>(context);
  }

  void _navigateToForm({AssessmentModel? assessment}) {
    if (_currentUser == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User data not available."), backgroundColor: Colors.red));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssessmentFormScreen(
          institutionId: widget.institutionId,
          academicYearId: widget.academicYearId,
          termId: widget.termId,
          classId: widget.classId,
          subjectId: widget.subjectId,
          assessment: assessment,
          createdByUid: _currentUser!.uid,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  // void _navigateToEnterGrades(AssessmentModel assessment) {
  //   if (_currentUser == null || _currentUser!.role != UserRole.teacher && _currentUser!.role != UserRole.institutionAdmin) {
  //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Only teachers or admins can enter grades.")));
  //     return;
  //   }
  //   // TeacherEnterGradesScreen will need more context like selectedClass
  //   // This navigation might be better placed on a teacher-specific assessment view
  //   // For now, this is a conceptual link.
  //   // Navigator.push(
  //   //   context,
  //   //   MaterialPageRoute(
  //   //     builder: (context) => TeacherEnterGradesScreen(
  //   //         // Required params for TeacherEnterGradesScreen:
  //   //         // selectedClass: ...
  //   //         // selectedSubject: ... (can get from assessment.subjectId)
  //   //         // selectedAssessment: assessment,
  //   //     ),
  //   //   ),
  //   // );
  //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Navigate to Enter Grades for ${assessment.name} (Not fully implemented here)")));
  // }


  Future<void> _confirmDelete(AssessmentModel assessment) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete assessment "${assessment.name}"? This may affect entered grades. This action cannot be undone.'),
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
        bool success = await _gradingService.deleteAssessment(assessment.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Assessment "${assessment.name}" ${success ? "deleted" : "deletion failed"}.'), backgroundColor: success ? Colors.green : Colors.red),
          );
          if (success) setState(() {});
        }
      } catch (e) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete "${assessment.name}": ${e.toString()}'), backgroundColor: Colors.red),
            );
         }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String screenTitle = widget.contextTitle ?? "Manage Assessments";

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add New Assessment',
            onPressed: () => _navigateToForm(),
          ),
        ],
      ),
      body: StreamBuilder<List<AssessmentModel>>(
        stream: _gradingService.getAssessments(
          institutionId: widget.institutionId,
          academicYearId: widget.academicYearId,
          termId: widget.termId,
          classId: widget.classId,
          subjectId: widget.subjectId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No assessments found for this selection. Add one!'));
          }

          List<AssessmentModel> assessments = snapshot.data!;

          return ListView.builder(
            itemCount: assessments.length,
            itemBuilder: (context, index) {
              AssessmentModel assessment = assessments[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  title: Text(assessment.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(assessment.description ?? 'No description.'),
                      Text('Max Marks: ${assessment.maxMarks}, Weightage: ${assessment.weightage != null ? (assessment.weightage! * 100).toStringAsFixed(0) + '%' : 'N/A'}'),
                      if (assessment.assessmentDate != null)
                        Text('Date: ${DateFormat.yMMMd().format(assessment.assessmentDate!)}'),
                      // TODO: Display Class Name and Subject Name instead of IDs if available
                      if(assessment.classId != null) Text("Class ID: ${assessment.classId!.substring(0,5)}..."),
                      if(assessment.subjectId.isNotEmpty) Text("Subject ID: ${assessment.subjectId.substring(0,5)}..."),
                    ],
                  ),
                  isThreeLine: (assessment.description ?? '').isNotEmpty || assessment.assessmentDate != null,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _navigateToForm(assessment: assessment);
                      } else if (value == 'delete') {
                         _confirmDelete(assessment);
                      } else if (value == 'enter_grades') {
                        // _navigateToEnterGrades(assessment);
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Enter Grades for ${assessment.name} (Teacher UI)")));
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(leading: Icon(Icons.edit), title: Text('Edit Assessment')),
                      ),
                      const PopupMenuItem<String>(
                        value: 'enter_grades',
                        child: ListTile(leading: Icon(Icons.grading), title: Text('Enter/View Grades')),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(leading: Icon(Icons.delete_forever, color: Colors.red), title: Text('Delete Assessment', style: TextStyle(color: Colors.red))),
                      ),
                    ],
                  ),
                  onTap: () {
                     _navigateToForm(assessment: assessment);
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
