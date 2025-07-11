import 'package:flutter/material.dart';
import 'package:school_management_system/src/models/class_model.dart';
import 'package:school_management_system/src/services/academic_service.dart';
// For selecting teachers/students in future:
// import 'package:school_management_system/src/models/user_model.dart';
// import 'package:school_management_system/src/services/auth_service.dart'; // Or a UserService

class ClassFormScreen extends StatefulWidget {
  final String institutionId;
  final String academicYearId;
  final String? termId; // Optional, if classes are term-specific
  final ClassModel? classModel; // Null if creating new

  const ClassFormScreen({
    super.key,
    required this.institutionId,
    required this.academicYearId,
    this.termId,
    this.classModel,
  });

  @override
  State<ClassFormScreen> createState() => _ClassFormScreenState();
}

class _ClassFormScreenState extends State<ClassFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final AcademicService _academicService = AcademicService();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _roomNumberController;
  late TextEditingController _capacityController;
  late TextEditingController _classTeacherUidController; // Placeholder for UID input
  late TextEditingController _studentUidsController; // Placeholder for comma-separated UIDs

  // List<UserModel> _availableTeachers = []; // For dropdown in future
  // List<UserModel> _availableStudents = []; // For multi-select in future
  // List<String> _selectedStudentUids = [];


  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.classModel?.name);
    _roomNumberController = TextEditingController(text: widget.classModel?.roomNumber);
    _capacityController = TextEditingController(text: widget.classModel?.capacity?.toString());
    _classTeacherUidController = TextEditingController(text: widget.classModel?.classTeacherUid);
    _studentUidsController = TextEditingController(text: widget.classModel?.studentUids?.join(', '));
    // _selectedStudentUids = List<String>.from(widget.classModel?.studentUids ?? []);
    // _fetchTeachersAndStudents(); // For future dropdowns
  }

  /*
  Future<void> _fetchTeachersAndStudents() async {
    // Simplified: Fetch all teachers and students from the institution.
    // In reality, filter by those not already assigned or suitable.
    // final authService = Provider.of<AuthService>(context, listen: false);
    // _availableTeachers = await authService.getUsersForInstitutionByRole(widget.institutionId, UserRole.teacher).first;
    // _availableStudents = await authService.getUsersForInstitutionByRole(widget.institutionId, UserRole.student).first;
    // setState(() {});
  }
  */

  @override
  void dispose() {
    _nameController.dispose();
    _roomNumberController.dispose();
    _capacityController.dispose();
    _classTeacherUidController.dispose();
    _studentUidsController.dispose();
    super.dispose();
  }

  List<String>? _parseUids(String? text) {
    if (text == null || text.trim().isEmpty) return []; // Return empty list for no input
    return text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }


  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    List<String>? studentUidsList = _parseUids(_studentUidsController.text);

    try {
      bool success;
      String message;

      ClassModel classData = ClassModel(
        id: widget.classModel?.id ?? '', // ID for update, ignored by create
        institutionId: widget.institutionId,
        name: _nameController.text.trim(),
        academicYearId: widget.academicYearId,
        termId: widget.termId,
        classTeacherUid: _classTeacherUidController.text.trim().isEmpty ? null : _classTeacherUidController.text.trim(),
        roomNumber: _roomNumberController.text.trim(),
        capacity: int.tryParse(_capacityController.text.trim()),
        studentUids: studentUidsList,
        createdAt: widget.classModel?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.classModel == null) { // Creating new
        ClassModel? createdClass = await _academicService.createClass(classData);
        success = createdClass != null;
        message = success ? 'Class "${createdClass!.name}" created successfully!' : 'Failed to create class.';
      } else { // Editing existing
        // For studentUids, if using a proper multi-select, _selectedStudentUids would be used directly.
        // Here, we are parsing the text field.
        Map<String, dynamic> updateData = classData.toMap();
        // Remove fields that should not be directly updatable in this simplified form or are IDs
        updateData.remove('id');
        updateData.remove('institutionId');
        updateData.remove('createdAt');


        success = await _academicService.updateClass(widget.classModel!.id, updateData);
        message = success ? 'Class "${classData.name}" updated successfully!' : 'Failed to update class.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: success ? Colors.green : Colors.red),
        );
        if (success) Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classModel == null ? 'Add New Class' : 'Edit Class'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Class Name (e.g., Grade 1A, Form 2 Blue)', border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? 'Class name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _classTeacherUidController,
                      decoration: const InputDecoration(labelText: 'Class Teacher UID (Optional)', hintText: 'Enter User UID of Class Teacher', border: OutlineInputBorder()),
                    ),
                     Padding(
                      padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                      child: Text(
                        "Note: Assigning Teacher via UID is a placeholder. A user selection dropdown will be implemented later.",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _roomNumberController,
                            decoration: const InputDecoration(labelText: 'Room Number (Optional)', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _capacityController,
                            decoration: const InputDecoration(labelText: 'Capacity (Optional)', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _studentUidsController,
                      decoration: const InputDecoration(
                        labelText: 'Student UIDs (comma-separated, Optional)',
                        hintText: 'UID1, UID2, UID3...',
                        border: OutlineInputBorder()
                      ),
                      maxLines: 3,
                    ),
                     Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "Note: Assigning students via comma-separated UIDs is a placeholder. A multi-select user interface will be implemented later.",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: Text(widget.classModel == null ? 'Create Class' : 'Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
