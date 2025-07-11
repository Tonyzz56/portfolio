import 'package:flutter/material.dart';
import 'package:school_management_system/src/models/subject_model.dart';
import 'package:school_management_system/src/services/academic_service.dart';

class SubjectFormScreen extends StatefulWidget {
  final String institutionId;
  final SubjectModel? subject; // Null if creating new

  const SubjectFormScreen({
    super.key,
    required this.institutionId,
    this.subject,
  });

  @override
  State<SubjectFormScreen> createState() => _SubjectFormScreenState();
}

class _SubjectFormScreenState extends State<SubjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final AcademicService _academicService = AcademicService();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subject?.name);
    _codeController = TextEditingController(text: widget.subject?.code);
    _descriptionController = TextEditingController(text: widget.subject?.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      bool success;
      String message;

      SubjectModel subjectData = SubjectModel(
        id: widget.subject?.id ?? '', // ID for update, ignored by create
        institutionId: widget.institutionId,
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        description: _descriptionController.text.trim(),
        createdAt: widget.subject?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.subject == null) { // Creating new
        SubjectModel? createdSubject = await _academicService.createSubject(subjectData);
        success = createdSubject != null;
        message = success ? 'Subject "${createdSubject!.name}" created successfully!' : 'Failed to create subject.';
      } else { // Editing existing
        Map<String, dynamic> updateData = subjectData.toMap();
        updateData.remove('id');
        updateData.remove('institutionId');
        updateData.remove('createdAt');

        success = await _academicService.updateSubject(widget.subject!.id, updateData);
        message = success ? 'Subject "${subjectData.name}" updated successfully!' : 'Failed to update subject.';
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
        title: Text(widget.subject == null ? 'Add New Subject' : 'Edit Subject'),
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
                      decoration: const InputDecoration(labelText: 'Subject Name (e.g., Mathematics)', border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? 'Subject name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(labelText: 'Subject Code (e.g., MATH101)', border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? 'Subject code is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description (Optional)', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    // TODO: Add UI for assigning teachers to subject or subject to department if those fields are re-added to model.
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: Text(widget.subject == null ? 'Create Subject' : 'Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
