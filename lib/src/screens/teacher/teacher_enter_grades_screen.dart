import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/models/class_model.dart';
import 'package:school_management_system/src/models/subject_model.dart';
import 'package:school_management_system/src/models/assessment_model.dart';
import 'package:school_management_system/src/models/grade_entry_model.dart';
import 'package:school_management_system/src/services/academic_service.dart';
import 'package:school_management_system/src/services/grading_service.dart';
import 'package:school_management_system/src/services/auth_service.dart';

class TeacherEnterGradesScreen extends StatefulWidget {
  const TeacherEnterGradesScreen({super.key});

  @override
  State<TeacherEnterGradesScreen> createState() => _TeacherEnterGradesScreenState();
}

class _TeacherEnterGradesScreenState extends State<TeacherEnterGradesScreen> {
  final AcademicService _academicService = AcademicService();
  final GradingService _gradingService = GradingService();
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  AcademicYearModel? _activeAcademicYear;
  TermModel? _currentTerm;

  List<ClassModel> _teacherClasses = [];
  ClassModel? _selectedClass;

  List<SubjectModel> _classSubjects = [];
  SubjectModel? _selectedSubject;

  List<AssessmentModel> _subjectAssessments = [];
  AssessmentModel? _selectedAssessment;

  List<UserModel> _studentsInClass = [];
  Map<String, GradeEntryModel> _gradeEntriesMap = {};
  Map<String, TextEditingController> _marksControllers = {};
  Map<String, TextEditingController> _commentsControllers = {};


  bool _isLoadingInitialData = true;
  bool _isLoadingContext = false; // For subjects, assessments, students
  bool _isSavingGrades = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentUser == null) {
      _currentUser = Provider.of<UserModel?>(context);
      if (_currentUser != null && _currentUser!.role == UserRole.teacher) {
        _fetchInitialTeacherContext();
      }
    }
  }

  Future<void> _fetchInitialTeacherContext() async {
    if (_currentUser == null || _currentUser!.institutionId == null) return;
    setState(() => _isLoadingInitialData = true);
    try {
      List<AcademicYearModel> years = await _academicService.getAcademicYears(_currentUser!.institutionId!).first;
      _activeAcademicYear = years.firstWhere((y) => y.isActive, orElse: () => years.isNotEmpty ? years.first : null);

      if (_activeAcademicYear != null) {
         List<TermModel> terms = await _academicService.getTerms(_currentUser!.institutionId!, _activeAcademicYear!.id).first;
        _currentTerm = terms.firstWhere((t) => t.isCurrentTerm, orElse: () => terms.isNotEmpty ? terms.first : null);

        // Placeholder: Fetch all classes in the active AY/Term for the institution.
        // TODO: This needs to be refined to fetch ONLY classes assigned to this teacher.
        // This might require a new method in AcademicService: getClassesForTeacher(teacherUid, ayId, termId)
        // or a more complex query based on how teacher-class-subject assignments are stored.
        _teacherClasses = await _academicService.getClasses(
            _currentUser!.institutionId!,
            academicYearId: _activeAcademicYear!.id,
            termId: _currentTerm?.id
        ).first;
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching teacher context: $e"), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoadingInitialData = false);
    }
  }

  Future<void> _onClassSelected(ClassModel? classModel) async {
    if (classModel == null) {
      setState(() {
        _selectedClass = null; _selectedSubject = null; _selectedAssessment = null;
        _classSubjects = []; _subjectAssessments = []; _studentsInClass = []; _gradeEntriesMap = {};
      });
      return;
    }
    setState(() {
      _selectedClass = classModel; _selectedSubject = null; _selectedAssessment = null;
      _subjectAssessments = []; _studentsInClass = []; _gradeEntriesMap = {};
      _isLoadingContext = true;
    });

    try {
      // Placeholder: Fetch all subjects for the institution.
      // TODO: Refine to fetch subjects taught by THIS teacher IN THIS class.
      // This requires a data model for class-subject-teacher assignments.
      _classSubjects = await _academicService.getSubjects(_currentUser!.institutionId!).first;
    } catch (e) {
       if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching subjects: $e"), backgroundColor: Colors.red));
    } finally {
       if(mounted) setState(() => _isLoadingContext = false);
    }
  }

  Future<void> _onSubjectSelected(SubjectModel? subject) async {
    if (subject == null || _selectedClass == null || _activeAcademicYear == null) {
      setState(() { _selectedSubject = null; _selectedAssessment = null; _subjectAssessments = []; _studentsInClass = []; _gradeEntriesMap = {}; });
      return;
    }
    setState(() { _selectedSubject = subject; _selectedAssessment = null; _isLoadingContext = true; _studentsInClass = []; _gradeEntriesMap = {}; });
    try {
      _subjectAssessments = await _gradingService.getAssessments(
        institutionId: _currentUser!.institutionId!,
        academicYearId: _activeAcademicYear!.id,
        termId: _currentTerm?.id,
        classId: _selectedClass!.id,
        subjectId: subject.id,
      ).first;
    } catch (e) {
       if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching assessments: $e"), backgroundColor: Colors.red));
    } finally {
       if(mounted) setState(() => _isLoadingContext = false);
    }
  }

  Future<void> _onAssessmentSelected(AssessmentModel? assessment) async {
    if (assessment == null || _selectedClass == null) {
      setState(() { _selectedAssessment = null; _studentsInClass = []; _gradeEntriesMap = {}; });
      return;
    }
    setState(() { _selectedAssessment = assessment; _isLoadingContext = true; });
    _gradeEntriesMap = {};
    _marksControllers = {};
    _commentsControllers = {};

    try {
      if (_selectedClass!.studentUids != null && _selectedClass!.studentUids!.isNotEmpty) {
        List<UserModel> students = [];
        for (String uid in _selectedClass!.studentUids!) {
          // TODO: Replace with actual user fetching from a UserService or AuthService.getUserById(uid)
           students.add(UserModel(uid: uid, email: "$uid@e.com", displayName: "Student ${uid.substring(0,5)}", customLoginId: "S-$uid".substring(0,8), role: UserRole.student, createdAt: DateTime.now(), updatedAt: DateTime.now()));
        }
        _studentsInClass = students..sort((a,b) => (a.displayName ?? a.uid).compareTo(b.displayName ?? b.uid)); // Sort students
      } else {
        _studentsInClass = [];
      }

      if (_studentsInClass.isNotEmpty) {
        List<GradeEntryModel> existingGrades = await _gradingService.getGradesForAssessment(
          assessmentId: assessment.id,
          institutionId: _currentUser!.institutionId!,
          classId: _selectedClass!.id,
        ).first;

        for (var grade in existingGrades) {
          _gradeEntriesMap[grade.studentUid] = grade;
        }
      }
      for (var student in _studentsInClass) {
        _marksControllers[student.uid] = TextEditingController(text: _gradeEntriesMap[student.uid]?.marksObtained.toString() ?? '');
        _commentsControllers[student.uid] = TextEditingController(text: _gradeEntriesMap[student.uid]?.comments ?? '');
      }
    } catch (e) {
       if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching students/grades: $e"), backgroundColor: Colors.red));
    } finally {
       if(mounted) setState(() => _isLoadingContext = false);
    }
  }

  Future<void> _saveGrades() async {
    if (_currentUser == null || _selectedClass == null || _selectedSubject == null || _selectedAssessment == null || _activeAcademicYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selection incomplete."),backgroundColor: Colors.red));
      return;
    }
    // Trigger validation for all visible text form fields
    bool allValid = true;
    _marksControllers.forEach((studentUid, controller) {
        // This is a bit of a hack to trigger validation visually if needed.
        // Proper way is to use GlobalKeys for each TextFormField if fine-grained control is needed,
        // or rely on the overall Form's validation.
        // For now, just checking the values directly.
        final marksStr = controller.text.trim();
        if (marksStr.isNotEmpty) {
            final marks = double.tryParse(marksStr);
            if (marks == null || marks < 0 || marks > _selectedAssessment!.maxMarks) {
                allValid = false;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid marks for a student: $marksStr. Must be between 0 and ${_selectedAssessment!.maxMarks}."), backgroundColor: Colors.red, duration: Duration(seconds: 5),));
            }
        }
    });
    if(!allValid) return;


    setState(() => _isSavingGrades = true);

    List<GradeEntryModel> entriesToSave = [];
    for (var student in _studentsInClass) {
      final marksStr = _marksControllers[student.uid]?.text.trim();
      final commentsStr = _commentsControllers[student.uid]?.text.trim();
      final marks = double.tryParse(marksStr ?? "");

      if (marks != null) {
        GradeEntryModel? existingEntry = _gradeEntriesMap[student.uid];
        entriesToSave.add(GradeEntryModel(
          id: existingEntry?.id ?? "TEMP_NEW_GRADE_ID_PLACEHOLDER",
          institutionId: _currentUser!.institutionId!,
          studentUid: student.uid,
          classId: _selectedClass!.id,
          subjectId: _selectedSubject!.id,
          assessmentId: _selectedAssessment!.id,
          academicYearId: _activeAcademicYear!.id,
          termId: _currentTerm?.id,
          marksObtained: marks,
          comments: commentsStr,
          gradedByUid: _currentUser!.uid,
          dateGraded: DateTime.now(),
          createdAt: existingEntry?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      } else if (marksStr != null && marksStr.isNotEmpty && marks == null) {
          // If text was entered but couldn't be parsed as double, it's an error already caught by validator, but double check
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid mark format for ${student.displayName}. Please enter a number."), backgroundColor: Colors.red));
           setState(() => _isSavingGrades = false);
           return;
      }
    }

    if (entriesToSave.isEmpty && _studentsInClass.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No marks entered or changed to save."), backgroundColor: Colors.orange));
      setState(() => _isSavingGrades = false);
      return;
    }

    try {
      bool success = await _gradingService.saveGradeEntries(entriesToSave, _currentUser!.uid);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? "Grades saved successfully!" : "Failed to save grades."), backgroundColor: success ? Colors.green : Colors.red),
        );
        if (success) _onAssessmentSelected(_selectedAssessment);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving grades: ${e.toString()}"), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isSavingGrades = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoadingInitialData) {
      return Scaffold(appBar: AppBar(title: const Text("Enter Grades")), body: const Center(child: CircularProgressIndicator()));
    }
    if (_currentUser == null || _currentUser!.role != UserRole.teacher) {
      return Scaffold(appBar: AppBar(title: const Text("Access Denied")), body: const Center(child: Text("Not authorized.")));
    }
    if (_activeAcademicYear == null) {
        return Scaffold(appBar: AppBar(title: const Text("Enter Grades")), body: const Center(child: Text("No active academic year set for the institution.")));
    }


    return Scaffold(
      appBar: AppBar(title: const Text('Enter Grades/Marks')),
      body: Form( // Wrap in a Form for potential validation triggers
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(children: [
                Row(children: [
                  Expanded(child: DropdownButtonFormField<ClassModel?>(
                    value: _selectedClass, hint: const Text("Select Class"),
                    items: _teacherClasses.map((c) => DropdownMenuItem(value: c, child: Text(c.name, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: _onClassSelected, decoration: const InputDecoration(border: OutlineInputBorder()),
                    isExpanded: true,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: DropdownButtonFormField<SubjectModel?>(
                    value: _selectedSubject, hint: const Text("Select Subject"),
                    items: _classSubjects.map((s) => DropdownMenuItem(value: s, child: Text("${s.name} (${s.code})", overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: _onSubjectSelected, decoration: const InputDecoration(border: OutlineInputBorder()),
                    disabledHint: _selectedClass == null ? const Text("Select Class First") : null,
                    isExpanded: true,
                  )),
                ]),
                const SizedBox(height: 10),
                 DropdownButtonFormField<AssessmentModel?>(
                    value: _selectedAssessment, hint: const Text("Select Assessment"),
                    items: _subjectAssessments.map((a) => DropdownMenuItem(value: a, child: Text("${a.name} (Max: ${a.maxMarks.toStringAsFixed(0)})", overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: _onAssessmentSelected, decoration: const InputDecoration(border: OutlineInputBorder()),
                    disabledHint: _selectedSubject == null ? const Text("Select Subject First") : null,
                    isExpanded: true,
                 ),
              ]),
            ),
            if (_isLoadingContext)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_selectedAssessment == null)
              const Expanded(child: Center(child: Text("Please select a class, subject, and assessment.")))
            else if (_studentsInClass.isEmpty)
              const Expanded(child: Center(child: Text("No students found for the selected class.")))
            else
              Expanded(child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: _studentsInClass.length,
                itemBuilder: (context, index) {
                  final student = _studentsInClass[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(student.displayName ?? student.customLoginId ?? student.uid, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _marksControllers[student.uid],
                            decoration: InputDecoration(labelText: 'Marks (Max: ${_selectedAssessment!.maxMarks.toStringAsFixed(0)})', border: const OutlineInputBorder()),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) return null;
                              final marks = double.tryParse(value);
                              if (marks == null) return "Invalid number";
                              if (marks < 0 || marks > _selectedAssessment!.maxMarks) return "Out of range";
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _commentsControllers[student.uid],
                            decoration: const InputDecoration(labelText: 'Comments (Optional)', border: const OutlineInputBorder()),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )),
          ],
        ),
      ),
      floatingActionButton: (_selectedAssessment != null && _studentsInClass.isNotEmpty && !_isLoadingContext)
          ? FloatingActionButton.extended(
              onPressed: _isSavingGrades ? null : _saveGrades,
              label: _isSavingGrades ? const Text("Saving...") : const Text("Save All Grades"),
              icon: _isSavingGrades ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
