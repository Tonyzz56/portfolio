import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/models/class_model.dart';
import 'package:school_management_system/src/models/subject_model.dart';
import 'package:school_management_system/src/models/academic_year_model.dart';
import 'package:school_management_system/src/models/term_model.dart';
import 'package:school_management_system/src/models/attendance_record_model.dart';
import 'package:school_management_system/src/services/academic_service.dart'; // To get classes, subjects, students
import 'package:school_management_system/src/services/auth_service.dart'; // Or UserService to get student details
import 'package:school_management_system/src/services/attendance_service.dart';


class TeacherMarkAttendanceScreen extends StatefulWidget {
  const TeacherMarkAttendanceScreen({super.key});

  @override
  State<TeacherMarkAttendanceScreen> createState() => _TeacherMarkAttendanceScreenState();
}

class _TeacherMarkAttendanceScreenState extends State<TeacherMarkAttendanceScreen> {
  final AcademicService _academicService = AcademicService();
  final AuthService _authService = AuthService(); // Assuming student details can be fetched via this
  final AttendanceService _attendanceService = AttendanceService();

  UserModel? _currentUser;
  AcademicYearModel? _activeAcademicYear;
  TermModel? _currentTerm;

  List<ClassModel> _assignedClasses = []; // Classes assigned to the teacher
  ClassModel? _selectedClass;

  List<SubjectModel> _classSubjects = []; // Subjects for the selected class
  SubjectModel? _selectedSubject; // If attendance is per subject

  DateTime _selectedDate = DateTime.now();
  String? _selectedPeriodSlot; // e.g., "Period 1", "09:00-09:45" - needs definition

  List<UserModel> _studentsInClass = [];
  Map<String, AttendanceStatus> _attendanceStatusMap = {}; // studentUid -> AttendanceStatus
  Map<String, String?> _attendanceRemarksMap = {}; // studentUid -> remarks
  Map<String, String> _existingRecordIds = {}; // studentUid -> existing attendanceRecordId

  bool _isLoading = false;
  bool _isFetchingStudents = false;
  bool _isFetchingAttendance = false;

  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentUser = Provider.of<UserModel?>(context);
    if (_currentUser != null && _assignedClasses.isEmpty) {
      _fetchInitialData();
    }
  }

  Future<void> _fetchInitialData() async {
    if (_currentUser == null || _currentUser!.institutionId == null) return;
    setState(() => _isLoading = true);
    try {
      // 1. Fetch active Academic Year and current Term (simplified)
      List<AcademicYearModel> years = await _academicService.getAcademicYears(_currentUser!.institutionId!).first;
      _activeAcademicYear = years.firstWhere((y) => y.isActive, orElse: () => years.isNotEmpty ? years.first : null);
      if (_activeAcademicYear != null) {
        List<TermModel> terms = await _academicService.getTerms(_currentUser!.institutionId!, _activeAcademicYear!.id).first;
        _currentTerm = terms.firstWhere((t) => t.isCurrentTerm, orElse: () => terms.isNotEmpty ? terms.first : null);
      }

      // 2. Fetch classes assigned to this teacher
      // This logic is complex: requires knowing teacher-class assignments.
      // For now, let's assume a teacher can see all classes in their institution and pick one.
      // Or, a more specific service method: _academicService.getClassesForTeacher(_currentUser.uid, _activeAcademicYear.id, _currentTerm?.id)
      _assignedClasses = await _academicService.getClasses(
          _currentUser!.institutionId!,
          academicYearId: _activeAcademicYear?.id
      ).first; // Simplified: gets all classes for the AY

      if (_assignedClasses.isNotEmpty) {
        // _selectedClass = _assignedClasses.first; // Auto-select first class
        // await _onClassSelected(_selectedClass);
      }

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching initial data: $e"), backgroundColor: Colors.red,));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onClassSelected(ClassModel? classModel) async {
    if (classModel == null) {
      setState(() {
        _selectedClass = null;
        _studentsInClass = [];
        _classSubjects = [];
        _selectedSubject = null;
        _attendanceStatusMap = {};
        _attendanceRemarksMap = {};
        _existingRecordIds = {};
      });
      return;
    }
    setState(() {
      _selectedClass = classModel;
      _isFetchingStudents = true;
      _studentsInClass = [];
      _attendanceStatusMap = {};
      _attendanceRemarksMap = {};
      _existingRecordIds = {};
      // Fetch subjects for this class (if attendance is per subject)
      // _fetchSubjectsForClass(classModel.id);
    });

    try {
      if (classModel.studentUids != null && classModel.studentUids!.isNotEmpty) {
        // Fetch student details for each UID. This could be a batch fetch method.
        List<UserModel> students = [];
        for (String uid in classModel.studentUids!) {
          // UserModel? student = await _authService.getUserById(uid); // Needs getUserById in AuthService
          // For placeholder, creating dummy students based on UID
          students.add(UserModel(uid: uid, email: "$uid@email.com", displayName: "Student $uid", role: UserRole.student, createdAt: DateTime.now(), updatedAt: DateTime.now()));
        }
        _studentsInClass = students;
      }
    } catch (e) {
       if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching students: $e"), backgroundColor: Colors.red,));
    } finally {
      if(mounted) {
        setState(() => _isFetchingStudents = false);
        if (_selectedClass != null) _loadExistingAttendance(); // Load attendance after students are fetched
      }
    }
  }

  // Future<void> _fetchSubjectsForClass(String classId) async { ... } // If needed

  Future<void> _loadExistingAttendance() async {
    if (_selectedClass == null || _activeAcademicYear == null || _currentUser == null) return;
    setState(() => _isFetchingAttendance = true);
    _attendanceStatusMap = {};
    _attendanceRemarksMap = {};
    _existingRecordIds = {};

    try {
      List<AttendanceRecordModel> existingRecords = await _attendanceService.getAttendanceForClassOnDate(
        classId: _selectedClass!.id,
        institutionId: _currentUser!.institutionId!,
        date: _selectedDate,
        subjectId: _selectedSubject?.id, // Optional
        periodSlot: _selectedPeriodSlot,   // Optional
      ).first;

      for (var record in existingRecords) {
        _attendanceStatusMap[record.studentUid] = record.status;
        _attendanceRemarksMap[record.studentUid] = record.remarks;
        _existingRecordIds[record.studentUid] = record.id;
      }
      // For students not in existingRecords, default to a status (e.g., Present or null to force selection)
      for (var student in _studentsInClass) {
        _attendanceStatusMap.putIfAbsent(student.uid, () => AttendanceStatus.present); // Default to present
      }

    } catch (e) {
       if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading existing attendance: $e"), backgroundColor: Colors.red,));
    } finally {
      if(mounted) setState(() => _isFetchingAttendance = false);
    }
  }


  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadExistingAttendance(); // Reload attendance for new date
    }
  }

  Future<void> _saveAttendance() async {
    if (_selectedClass == null || _currentUser == null || _activeAcademicYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select class and ensure context is loaded."),backgroundColor: Colors.red));
      return;
    }
    if (_studentsInClass.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No students in class to mark attendance for."),backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);
    List<AttendanceRecordModel> recordsToSave = [];
    for (var student in _studentsInClass) {
      final status = _attendanceStatusMap[student.uid];
      if (status != null) { // Only save if a status is set
        recordsToSave.add(AttendanceRecordModel(
          id: _existingRecordIds[student.uid] ?? "TEMPORARY_ID_FOR_NEW_RECORD", // Let service handle if it's new or update
          institutionId: _currentUser!.institutionId!,
          academicYearId: _activeAcademicYear!.id,
          termId: _currentTerm?.id,
          classId: _selectedClass!.id,
          studentUid: student.uid,
          date: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day), // Normalize date
          subjectId: _selectedSubject?.id,
          periodSlot: _selectedPeriodSlot,
          status: status,
          markedByUid: _currentUser!.uid,
          remarks: _attendanceRemarksMap[student.uid],
          createdAt: _existingRecordIds[student.uid] != null ? DateTime.now() : DateTime.now(), // This needs to be actual created at from existing record
          updatedAt: DateTime.now(),
        ));
      }
    }

    try {
      bool success = await _attendanceService.markBatchAttendance(recordsToSave, _currentUser!.uid);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Attendance saved successfully!' : 'Failed to save attendance.'), backgroundColor: success ? Colors.green : Colors.red),
        );
      }
    } catch (e) {
       if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving attendance: ${e.toString()}'), backgroundColor: Colors.red));
    } finally {
       if(mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading && _assignedClasses.isEmpty) { // Initial loading for classes
      return Scaffold(appBar: AppBar(title: const Text("Mark Attendance")), body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        actions: [
          if (_studentsInClass.isNotEmpty && !_isFetchingStudents && !_isFetchingAttendance)
            IconButton(icon: const Icon(Icons.save), onPressed: _isLoading ? null : _saveAttendance, tooltip: "Save Attendance")
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<ClassModel?>(
                      value: _selectedClass,
                      hint: const Text("Select Class"),
                      items: _assignedClasses.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                      onChanged: _onClassSelected,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_dateFormatter.format(_selectedDate)),
                    onPressed: () => _pickDate(context),
                  ),
                ]),
                // TODO: Add Subject dropdown if attendance is per subject
                // TODO: Add Period Slot input/dropdown if needed
              ],
            ),
          ),
          if (_isFetchingStudents || _isFetchingAttendance)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_selectedClass == null)
            const Expanded(child: Center(child: Text("Please select a class.")))
          else if (_studentsInClass.isEmpty)
            const Expanded(child: Center(child: Text("No students found in the selected class.")))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _studentsInClass.length,
                itemBuilder: (context, index) {
                  final student = _studentsInClass[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(student.displayName ?? student.customLoginId ?? student.uid, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: AttendanceStatus.values.map((status) {
                              return ChoiceChip(
                                label: Text(attendanceStatusToString(status)),
                                selected: _attendanceStatusMap[student.uid] == status,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _attendanceStatusMap[student.uid] = status;
                                    });
                                  }
                                },
                                selectedColor: status == AttendanceStatus.present ? Colors.green.shade100 :
                                               status == AttendanceStatus.absent ? Colors.red.shade100 :
                                               status == AttendanceStatus.late ? Colors.yellow.shade100 :
                                               Colors.blue.shade100,
                              );
                            }).toList(),
                          ),
                          TextFormField(
                            initialValue: _attendanceRemarksMap[student.uid],
                            decoration: const InputDecoration(labelText: "Remarks (Optional)", hintText: "e.g., Left early at 2 PM"),
                            onChanged: (value) {
                              _attendanceRemarksMap[student.uid] = value.trim();
                            },
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          if (_isLoading && !_isFetchingStudents && !_isFetchingAttendance) // Saving loader
            const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }
}
