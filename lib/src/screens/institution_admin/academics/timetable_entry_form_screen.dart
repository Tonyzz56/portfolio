import 'package:flutter/material.dart';
import 'package:school_management_system/src/models/timetable_entry_model.dart';
import 'package:school_management_system/src/services/timetable_service.dart';
import 'package:school_management_system/src/models/class_model.dart'; // For class context
import 'package:school_management_system/src/models/subject_model.dart'; // For subject dropdown
import 'package:school_management_system/src/models/user_model.dart'; // For teacher dropdown
import 'package:school_management_system/src/services/academic_service.dart'; // To fetch subjects
import 'package:school_management_system/src/services/auth_service.dart'; // To fetch teachers (or use a UserService)
import 'package:intl/intl.dart'; // For TimeOfDay formatting (if needed)


class TimetableEntryFormScreen extends StatefulWidget {
  final String institutionId;
  final String academicYearId;
  final String? termId;
  final ClassModel selectedClass; // Class for which this entry is being made
  final TimetableEntryModel? entryToEdit;

  const TimetableEntryFormScreen({
    super.key,
    required this.institutionId,
    required this.academicYearId,
    this.termId,
    required this.selectedClass,
    this.entryToEdit,
  });

  @override
  State<TimetableEntryFormScreen> createState() => _TimetableEntryFormScreenState();
}

class _TimetableEntryFormScreenState extends State<TimetableEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TimetableService _timetableService = TimetableService();
  final AcademicService _academicService = AcademicService(); // To fetch subjects
  final AuthService _authService = AuthService(); // To fetch teachers

  bool _isLoading = false;
  DayOfWeek _selectedDay = DayOfWeek.monday;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _selectedSubjectId;
  String? _selectedTeacherUid;
  late TextEditingController _roomIdController;

  List<SubjectModel> _availableSubjects = [];
  List<UserModel> _availableTeachers = [];

  @override
  void initState() {
    super.initState();
    _roomIdController = TextEditingController(text: widget.entryToEdit?.roomId);

    if (widget.entryToEdit != null) {
      _selectedDay = widget.entryToEdit!.dayOfWeek;
      _startTime = _timeOfDayFromString(widget.entryToEdit!.startTime);
      _endTime = _timeOfDayFromString(widget.entryToEdit!.endTime);
      _selectedSubjectId = widget.entryToEdit!.subjectId;
      _selectedTeacherUid = widget.entryToEdit!.teacherUid;
    }
    _fetchSubjectsAndTeachers();
  }

  TimeOfDay _timeOfDayFromString(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _timeOfDayToString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _fetchSubjectsAndTeachers() async {
    setState(() => _isLoading = true);
    try {
      // Fetch subjects for the institution
      _academicService.getSubjects(widget.institutionId).first.then((subjects) {
        if(mounted) setState(() => _availableSubjects = subjects);
      });

      // Fetch teachers for the institution
      _authService.getUsersForInstitution(widget.institutionId).first.then((users) {
         if(mounted) {
            setState(() {
              _availableTeachers = users.where((user) => user.role == UserRole.teacher).toList();
            });
         }
      });

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching data: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }


  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: (isStartTime ? _startTime : _endTime) ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select start and end times.'), backgroundColor: Colors.red));
      return;
    }
    // Basic time validation (endTime after startTime)
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End time must be after start time.'), backgroundColor: Colors.red));
      return;
    }


    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    final entryData = TimetableEntryModel(
      id: widget.entryToEdit?.id ?? '', // Ignored on create
      institutionId: widget.institutionId,
      classId: widget.selectedClass.id,
      academicYearId: widget.academicYearId,
      termId: widget.termId,
      dayOfWeek: _selectedDay,
      startTime: _timeOfDayToString(_startTime!),
      endTime: _timeOfDayToString(_endTime!),
      subjectId: _selectedSubjectId!,
      teacherUid: _selectedTeacherUid!,
      roomId: _roomIdController.text.trim().isEmpty ? null : _roomIdController.text.trim(),
      createdAt: widget.entryToEdit?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      bool success;
      if (widget.entryToEdit == null) {
        TimetableEntryModel? created = await _timetableService.createTimetableEntry(entryData);
        success = created != null;
      } else {
        Map<String, dynamic> updateMap = entryData.toMap();
        // Remove fields that should not be updated directly or are IDs
        updateMap.remove('id');
        updateMap.remove('institutionId');
        updateMap.remove('classId');
        updateMap.remove('academicYearId');
        updateMap.remove('createdAt');
        success = await _timetableService.updateTimetableEntry(widget.entryToEdit!.id, updateMap);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Timetable entry saved!' : 'Failed to save entry.'), backgroundColor: success ? Colors.green : Colors.red),
        );
        if (success) Navigator.of(context).pop();
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entryToEdit == null ? 'Add Timetable Slot' : 'Edit Timetable Slot'),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(20.0),
            child: Text('For Class: ${widget.selectedClass.name}', style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor?.withOpacity(0.7) ?? Colors.white70)),
        )
      ),
      body: _isLoading && _availableSubjects.isEmpty && _availableTeachers.isEmpty // Show loading only on initial data fetch
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    DropdownButtonFormField<DayOfWeek>(
                      value: _selectedDay,
                      decoration: const InputDecoration(labelText: 'Day of the Week', border: OutlineInputBorder()),
                      items: DayOfWeek.values.map((DayOfWeek day) {
                        return DropdownMenuItem<DayOfWeek>(value: day, child: Text(dayOfWeekToString(day)));
                      }).toList(),
                      onChanged: (DayOfWeek? newValue) {
                        if (newValue != null) setState(() => _selectedDay = newValue);
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(context, true),
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Start Time', border: OutlineInputBorder()),
                            child: Text(_startTime != null ? _startTime!.format(context) : 'Select Time'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(context, false),
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'End Time', border: OutlineInputBorder()),
                            child: Text(_endTime != null ? _endTime!.format(context) : 'Select Time'),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      value: _selectedSubjectId,
                      decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
                      hint: const Text('Select Subject'),
                      items: _availableSubjects.map((SubjectModel subject) {
                        return DropdownMenuItem<String?>(value: subject.id, child: Text("${subject.name} (${subject.code})"));
                      }).toList(),
                      onChanged: (String? newValue) => setState(() => _selectedSubjectId = newValue),
                      validator: (value) => value == null ? 'Please select a subject' : null,
                    ),
                    const SizedBox(height: 16),
                     DropdownButtonFormField<String?>(
                      value: _selectedTeacherUid,
                      decoration: const InputDecoration(labelText: 'Teacher', border: OutlineInputBorder()),
                      hint: const Text('Select Teacher'),
                      items: _availableTeachers.map((UserModel teacher) {
                        return DropdownMenuItem<String?>(value: teacher.uid, child: Text(teacher.displayName ?? teacher.email));
                      }).toList(),
                      onChanged: (String? newValue) => setState(() => _selectedTeacherUid = newValue),
                      validator: (value) => value == null ? 'Please select a teacher' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _roomIdController,
                      decoration: const InputDecoration(labelText: 'Room / Location (Optional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: Text(widget.entryToEdit == null ? 'Add Slot' : 'Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
