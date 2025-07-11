import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/models/grade_entry_model.dart';
import 'package:school_management_system/src/models/assessment_model.dart';
import 'package:school_management_system/src/models/subject_model.dart';
import 'package:school_management_system/src/services/grading_service.dart';
import 'package:school_management_system/src/services/academic_service.dart';

class StudentMyGradesScreen extends StatefulWidget {
  final String? targetChildUidFromRoute;
  final String? childNameForParentView;

  const StudentMyGradesScreen({
    super.key,
    this.targetChildUidFromRoute,
    this.childNameForParentView
  });

  @override
  State<StudentMyGradesScreen> createState() => _StudentMyGradesScreenState();
}

class _StudentMyGradesScreenState extends State<StudentMyGradesScreen> {
  final GradingService _gradingService = GradingService();
  final AcademicService _academicService = AcademicService();

  List<GradeEntryModel> _gradeEntries = [];
  Map<String, AssessmentModel> _assessmentDetailsCache = {};
  Map<String, SubjectModel> _subjectDetailsCache = {};

  bool _isLoading = true;
  String? _error;
  String _screenTitle = "My Grades";

  UserModel? _currentUser;
  String? _effectiveStudentUid;

  Map<String, List<GradeEntryModel>> _groupedBySubject = {};


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentUser == null) {
      _currentUser = Provider.of<UserModel?>(context);
      _initializeTargetStudentAndFetch();
    }
  }

  void _initializeTargetStudentAndFetch() {
    if (_currentUser == null) {
      setState(() { _error = "User not authenticated."; _isLoading = false; });
      return;
    }

    if (widget.targetChildUidFromRoute != null && _currentUser!.role == UserRole.parent) {
      _effectiveStudentUid = widget.targetChildUidFromRoute;
      _screenTitle = "Grades: ${widget.childNameForParentView ?? 'Child'}";
    } else if (_currentUser!.role == UserRole.student) {
      _effectiveStudentUid = _currentUser!.uid;
      _screenTitle = "My Grades";
    } else {
      setState(() {
        _error = _currentUser!.role == UserRole.parent
            ? "Please select a child from 'My Children' to view their grades."
            : "Access Denied. This view is for students or parents viewing a child.";
        _isLoading = false;
      });
      return;
    }
    _fetchGradesAndDetails();
  }

  Future<void> _fetchGradesAndDetails() async {
    if (_currentUser == null || _currentUser!.institutionId == null || _effectiveStudentUid == null) {
      setState(() { _error = "User, institution, or target student data not available."; _isLoading = false; });
      return;
    }
    setState(() { _isLoading = true; _error = null; });

    try {
      // Fetch all grades for the student first
      List<GradeEntryModel> grades = await _gradingService.getGradesForStudent(
        studentUid: _effectiveStudentUid!,
        institutionId: _currentUser!.institutionId!,
        // TODO: Add filters for academicYearId, termId if UI elements for these are added
      ).first; // Use .first to get a Future<List> from the Stream once

      // Collect all unique assessment and subject IDs
      Set<String> assessmentIds = grades.map((g) => g.assessmentId).toSet();
      Set<String> subjectIds = grades.map((g) => g.subjectId).toSet();

      // Batch fetch assessment details (conceptual - needs GradingService.getAssessmentsByIds)
      // For now, fetching one by one (inefficient) or assuming names are denormalized/less critical for this view
      for (String id in assessmentIds) {
        if (!_assessmentDetailsCache.containsKey(id)) {
          // Placeholder: In a real app, you would fetch AssessmentModel by ID
          // AssessmentModel? assessment = await _gradingService.getAssessmentById(id);
          // if (assessment != null) _assessmentDetailsCache[id] = assessment;
          // For now, we'll rely on showing IDs if names aren't easily fetched.
        }
      }
      // Batch fetch subject details
      for (String id in subjectIds) {
         if (!_subjectDetailsCache.containsKey(id)) {
          // Placeholder: In a real app, you would fetch SubjectModel by ID
          // SubjectModel? subject = await _academicService.getSubjectById(id);
          // if (subject != null) _subjectDetailsCache[id] = subject;
         }
      }

      // Group grades by subject
      _groupedBySubject = {};
      for (var grade in grades) {
        _groupedBySubject.putIfAbsent(grade.subjectId, () => []).add(grade);
      }


      if (mounted) {
        setState(() {
          _gradeEntries = grades; // Keep the flat list too if needed for other summaries
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = "Error fetching grades: ${e.toString()}"; _isLoading = false; });
      }
    }
  }

  String _getAssessmentName(String assessmentId) {
    return _assessmentDetailsCache[assessmentId]?.name ?? "Assessment (ID: ${assessmentId.substring(0,5)}...)";
  }
  String _getSubjectName(String subjectId) {
    return _subjectDetailsCache[subjectId]?.name ?? "Subject (ID: ${subjectId.substring(0,5)}...)";
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_screenTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center)))
              : _groupedBySubject.isEmpty && _effectiveStudentUid != null
                  ? const Center(child: Text('No grades found or published yet.'))
                  : ListView(
                      children: _groupedBySubject.entries.map((subjectEntry) {
                        String subjectId = subjectEntry.key;
                        List<GradeEntryModel> gradesForSubject = subjectEntry.value;

                        // Sort grades within subject by date or assessment name
                        gradesForSubject.sort((a,b) => (_assessmentDetailsCache[a.assessmentId]?.name ?? a.assessmentId)
                                                    .compareTo(_assessmentDetailsCache[b.assessmentId]?.name ?? b.assessmentId));


                        return ExpansionTile(
                          title: Text(_getSubjectName(subjectId), style: Theme.of(context).textTheme.titleLarge),
                          initiallyExpanded: true,
                          children: gradesForSubject.map((grade) {
                            AssessmentModel? assessment = _assessmentDetailsCache[grade.assessmentId];
                            return ListTile(
                              title: Text(_getAssessmentName(grade.assessmentId)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Marks: ${grade.marksObtained.toStringAsFixed(1)} / ${assessment?.maxMarks.toStringAsFixed(0) ?? 'N/A'}"),
                                  if (grade.gradeAwarded != null) Text("Grade: ${grade.gradeAwarded!}"),
                                  if (grade.comments != null && grade.comments!.isNotEmpty) Text("Comments: ${grade.comments!}"),
                                  Text("Date: ${DateFormat.yMMMd().format(grade.dateGraded)}"),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ),
    );
  }
}
