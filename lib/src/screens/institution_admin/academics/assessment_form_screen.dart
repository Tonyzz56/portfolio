import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/src/models/assessment_model.dart';
import 'package:school_management_system/src/services/grading_service.dart';
// For Subject/Class selection dropdowns (if not passed as fixed context)
// import 'package:school_management_system/src/models/subject_model.dart';
// import 'package:school_management_system/src/models/class_model.dart';
// import 'package:school_management_system/src/services/academic_service.dart';

class AssessmentFormScreen extends StatefulWidget {
  final String institutionId;
  final String academicYearId;
  final String? termId;
  final String? classId; // If creating an assessment for a specific class
  final String? subjectId; // Assessment is usually tied to a subject. If null, admin might be creating a general template.
  final String createdByUid;
  final AssessmentModel? assessment; // Null if creating new

  const AssessmentFormScreen({
    super.key,
    required this.institutionId,
    required this.academicYearId,
    this.termId,
    this.classId,
    this.subjectId, // Made optional if creating general assessment templates
    required this.createdByUid,
    this.assessment,
  });

  @override
  State<AssessmentFormScreen> createState() => _AssessmentFormScreenState();
}

class _AssessmentFormScreenState extends State<AssessmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final GradingService _gradingService = GradingService();
  // final AcademicService _academicService = AcademicService(); // For fetching subjects/classes if dropdowns are used
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _maxMarksController;
  late TextEditingController _weightageController;
  DateTime? _assessmentDate;

  // These would be used if subject/class are selectable on this form
  // String? _selectedSubjectIdInternal;
  // String? _selectedClassIdInternal;
  // List<SubjectModel> _availableSubjects = [];
  // List<ClassModel> _availableClasses = [];


  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.assessment?.name);
    _descriptionController = TextEditingController(text: widget.assessment?.description);
    _maxMarksController = TextEditingController(text: widget.assessment?.maxMarks.toStringAsFixed(0) ?? ''); // Avoid .0 for integers
    _weightageController = TextEditingController(text: widget.assessment?.weightage != null ? (widget.assessment!.weightage! * 100).toStringAsFixed(0) : '');
    _assessmentDate = widget.assessment?.assessmentDate;

    // Initialize internal selections if they were to be editable here
    // _selectedSubjectIdInternal = widget.subjectId ?? widget.assessment?.subjectId;
    // _selectedClassIdInternal = widget.classId ?? widget.assessment?.classId;

    // If needed, fetch subjects/classes for dropdowns here.
    // _fetchDropdownData();
  }

  /*
  Future<void> _fetchDropdownData() async {
    // Example:
    // _availableSubjects = await _academicService.getSubjects(widget.institutionId).first;
    // if (_selectedSubjectIdInternal == null && _availableSubjects.isNotEmpty) _selectedSubjectIdInternal = _availableSubjects.first.id;
    // setState((){});
  }
  */


  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _maxMarksController.dispose();
    _weightageController.dispose();
    super.dispose();
  }

  Future<void> _pickAssessmentDate(BuildContext context) async {
    final DateTime initialDate = _assessmentDate ?? DateTime.now();
    final DateTime firstDate = DateTime(initialDate.year - 1);
    final DateTime lastDate = DateTime(initialDate.year + 2);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (pickedDate != null) {
      setState(() => _assessmentDate = pickedDate);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.subjectId == null /* && _selectedSubjectIdInternal == null */) {
        // If subject ID is neither passed as context nor selected from a dropdown (if implemented)
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Subject is required for an assessment.'), backgroundColor: Colors.red),
        );
        return;
    }
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    double? weightage;
    if (_weightageController.text.trim().isNotEmpty) {
        double? percent = double.tryParse(_weightageController.text.trim());
        if (percent != null) {
            weightage = percent / 100.0; // Convert percentage to decimal
        }
    }


    try {
      bool success;
      String message;

      AssessmentModel assessmentData = AssessmentModel(
        id: widget.assessment?.id ?? '',
        institutionId: widget.institutionId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        academicYearId: widget.academicYearId,
        termId: widget.termId,
        classId: widget.classId, //  ?? _selectedClassIdInternal, // Use context or selected
        subjectId: widget.subjectId!, // ?? _selectedSubjectIdInternal!, // Subject must be present
        maxMarks: double.tryParse(_maxMarksController.text.trim()) ?? 100.0,
        weightage: weightage,
        assessmentDate: _assessmentDate,
        createdByUid: widget.createdByUid,
        createdAt: widget.assessment?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.assessment == null) { // Creating new
        AssessmentModel? createdAssessment = await _gradingService.createAssessment(assessmentData, widget.createdByUid);
        success = createdAssessment != null;
        message = success ? 'Assessment "${createdAssessment!.name}" created successfully!' : 'Failed to create assessment.';
      } else { // Editing existing
        Map<String, dynamic> updateData = assessmentData.toMap();
        updateData.remove('id');
        updateData.remove('institutionId');
        updateData.remove('createdByUid');
        updateData.remove('createdAt');
        // Context fields like academicYearId, termId, classId, subjectId are usually not changed for an existing assessment.
        // If they were part of the form for editing, they'd be included here.
        updateData.remove('academicYearId');
        updateData.remove('termId');
        updateData.remove('classId');
        updateData.remove('subjectId');


        success = await _gradingService.updateAssessment(widget.assessment!.id, updateData);
        message = success ? 'Assessment "${assessmentData.name}" updated successfully!' : 'Failed to update assessment.';
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
        title: Text(widget.assessment == null ? 'Add New Assessment' : 'Edit Assessment'),
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
                    // Context Display (Read-only)
                    Text("For Academic Year ID: ${widget.academicYearId.characters.take(8)}..."),
                    if(widget.termId != null) Text("For Term ID: ${widget.termId!.characters.take(8)}..."),
                    if(widget.classId != null) Text("For Class ID: ${widget.classId!.characters.take(8)}... (Name TODO)"),
                    if(widget.subjectId != null) Text("For Subject ID: ${widget.subjectId!.characters.take(8)}... (Name TODO)"),
                    const Divider(height: 20),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Assessment Name (e.g., Mid-Term, Quiz 1)', border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? 'Assessment name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description (Optional)', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _maxMarksController,
                            decoration: const InputDecoration(labelText: 'Max Marks', border: OutlineInputBorder()),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Max marks are required';
                              if (double.tryParse(value) == null || double.parse(value) <=0) return 'Enter a valid positive number';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _weightageController,
                            decoration: const InputDecoration(labelText: 'Weightage % (Optional)', border: OutlineInputBorder()),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                             validator: (value) {
                              if (value != null && value.isNotEmpty && (double.tryParse(value) == null || double.parse(value) < 0 || double.parse(value) > 100)) {
                                return 'Enter valid % (0-100)';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                     InkWell(
                        onTap: () => _pickAssessmentDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Assessment/Due Date (Optional)',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(_assessmentDate != null ? _dateFormatter.format(_assessmentDate!) : 'Select Date'),
                        ),
                      ),

                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: Text(widget.assessment == null ? 'Create Assessment' : 'Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
