import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/src/models/term_model.dart';
import 'package:school_management_system/src/services/academic_service.dart';

class TermFormScreen extends StatefulWidget {
  final String institutionId;
  final String academicYearId;
  final String academicYearName; // For display purposes
  final TermModel? term; // Null if creating new

  const TermFormScreen({
    super.key,
    required this.institutionId,
    required this.academicYearId,
    required this.academicYearName,
    this.term,
  });

  @override
  State<TermFormScreen> createState() => _TermFormScreenState();
}

class _TermFormScreenState extends State<TermFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final AcademicService _academicService = AcademicService();
  bool _isLoading = false;

  late TextEditingController _nameController;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCurrentTerm = false;

  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.term?.name);
    _startDate = widget.term?.startDate;
    _endDate = widget.term?.endDate;
    _isCurrentTerm = widget.term?.isCurrentTerm ?? false;

    if (widget.term == null) {
      // Default dates if creating new, relative to something (e.g., today or academic year start)
      // This might need context from the AcademicYear's start/end dates if available here.
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(const Duration(days: 90)); // Default to a 3-month term
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isStartDate) async {
    final DateTime initialDate = (isStartDate ? _startDate : _endDate) ?? DateTime.now();
    // TODO: Constrain firstDate and lastDate based on the parent AcademicYear's dates
    final DateTime firstDate = DateTime(initialDate.year - 1);
    final DateTime lastDate = DateTime(initialDate.year + 1);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
          if (_endDate == null || _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate!.add(const Duration(days: 90));
          }
        } else {
          _endDate = pickedDate;
          if (_startDate == null || _startDate!.isAfter(_endDate!)) {
            _startDate = _endDate!.subtract(const Duration(days: 90));
          }
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and end dates.'), backgroundColor: Colors.red),
      );
      return;
    }
     if (_endDate!.isBefore(_startDate!) || _endDate!.isAtSameMomentAs(_startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after the start date.'), backgroundColor: Colors.red),
      );
      return;
    }
    // TODO: Add validation that term dates are within the parent AcademicYear's dates.

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      bool success;
      String message;

      if (widget.term == null) { // Creating new
        TermModel newTermData = TermModel(
          id: '', // Will be set by service
          institutionId: widget.institutionId,
          academicYearId: widget.academicYearId,
          name: _nameController.text.trim(),
          startDate: _startDate!,
          endDate: _endDate!,
          isCurrentTerm: _isCurrentTerm,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        TermModel? createdTerm = await _academicService.createTerm(newTermData);
        success = createdTerm != null;
        message = success ? 'Term "${createdTerm!.name}" created successfully!' : 'Failed to create term.';
      } else { // Editing existing
        Map<String, dynamic> updateData = {
          'name': _nameController.text.trim(),
          'startDate': Timestamp.fromDate(_startDate!),
          'endDate': Timestamp.fromDate(_endDate!),
          'isCurrentTerm': _isCurrentTerm,
        };
        success = await _academicService.updateTerm(widget.term!.id, updateData, widget.institutionId, widget.academicYearId);
        message = success ? 'Term "${_nameController.text.trim()}" updated successfully!' : 'Failed to update term.';
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
        title: Text(widget.term == null ? 'Add New Term' : 'Edit Term'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20.0),
          child: Text('For Academic Year: ${widget.academicYearName}', style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor?.withOpacity(0.7) ?? Colors.white70)),
        ),
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
                      decoration: const InputDecoration(labelText: 'Term Name (e.g., Term 1, Spring Semester)', border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? 'Term name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(context, true),
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Start Date', border: OutlineInputBorder()),
                              child: Text(_startDate != null ? _dateFormatter.format(_startDate!) : 'Select Date'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(context, false),
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'End Date', border: OutlineInputBorder()),
                              child: Text(_endDate != null ? _dateFormatter.format(_endDate!) : 'Select Date'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                     SwitchListTile(
                      title: const Text('Set as Current Term for this Academic Year'),
                      subtitle: const Text('Note: Setting this active will deactivate any other current term within this academic year.'),
                      value: _isCurrentTerm,
                      onChanged: (bool value) => setState(() => _isCurrentTerm = value),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: Text(widget.term == null ? 'Create Term' : 'Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
