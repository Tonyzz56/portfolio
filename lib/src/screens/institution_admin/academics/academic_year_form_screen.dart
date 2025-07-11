import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/src/models/academic_year_model.dart';
import 'package:school_management_system/src/services/academic_service.dart';

class AcademicYearFormScreen extends StatefulWidget {
  final String institutionId;
  final AcademicYearModel? academicYear; // Null if creating new

  const AcademicYearFormScreen({
    super.key,
    required this.institutionId,
    this.academicYear,
  });

  @override
  State<AcademicYearFormScreen> createState() => _AcademicYearFormScreenState();
}

class _AcademicYearFormScreenState extends State<AcademicYearFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final AcademicService _academicService = AcademicService();
  bool _isLoading = false;

  late TextEditingController _nameController;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isActive = false;

  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.academicYear?.name);
    _startDate = widget.academicYear?.startDate;
    _endDate = widget.academicYear?.endDate;
    _isActive = widget.academicYear?.isActive ?? false;

    // If creating new and no dates are set, default start date to today
    // and end date to one year from today for convenience.
    if (widget.academicYear == null) {
        _startDate = DateTime.now();
        _endDate = DateTime(_startDate!.year + 1, _startDate!.month, _startDate!.day);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isStartDate) async {
    final DateTime initialDate = (isStartDate ? _startDate : _endDate) ?? DateTime.now();
    final DateTime firstDate = DateTime(DateTime.now().year - 5); // Allow 5 years back
    final DateTime lastDate = DateTime(DateTime.now().year + 5);  // Allow 5 years forward

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
          // If end date is before new start date, or null, adjust it
          if (_endDate == null || _endDate!.isBefore(_startDate!)) {
            _endDate = DateTime(_startDate!.year + 1, _startDate!.month, _startDate!.day);
          }
        } else {
          _endDate = pickedDate;
           // If start date is after new end date, or null, adjust it (less common scenario)
          if (_startDate == null || _startDate!.isAfter(_endDate!)) {
            _startDate = DateTime(_endDate!.year - 1, _endDate!.month, _endDate!.day);
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

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      bool success;
      String message;

      if (widget.academicYear == null) { // Creating new
        AcademicYearModel newYearData = AcademicYearModel(
          id: '', // Will be set by service
          institutionId: widget.institutionId,
          name: _nameController.text.trim(),
          startDate: _startDate!,
          endDate: _endDate!,
          isActive: _isActive,
          createdAt: DateTime.now(), // Will be set by service, this is for model consistency
          updatedAt: DateTime.now(), // Will be set by service
        );
        AcademicYearModel? createdYear = await _academicService.createAcademicYear(newYearData);
        success = createdYear != null;
        message = success ? 'Academic Year "${createdYear!.name}" created successfully!' : 'Failed to create academic year.';
      } else { // Editing existing
        Map<String, dynamic> updateData = {
          'name': _nameController.text.trim(),
          'startDate': Timestamp.fromDate(_startDate!),
          'endDate': Timestamp.fromDate(_endDate!),
          'isActive': _isActive,
          // updatedAt will be handled by the service
        };
        success = await _academicService.updateAcademicYear(widget.academicYear!.id, updateData, widget.institutionId);
        message = success ? 'Academic Year "${_nameController.text.trim()}" updated successfully!' : 'Failed to update academic year.';
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
        title: Text(widget.academicYear == null ? 'Add New Academic Year' : 'Edit Academic Year'),
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
                      decoration: const InputDecoration(labelText: 'Academic Year Name (e.g., 2023-2024)', border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(context, true),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Date',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(_startDate != null ? _dateFormatter.format(_startDate!) : 'Select Date'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(context, false),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'End Date',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(_endDate != null ? _dateFormatter.format(_endDate!) : 'Select Date'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Set as Active Academic Year'),
                      subtitle: const Text('Note: Setting this active will deactivate any other active year for this institution.'),
                      value: _isActive,
                      onChanged: (bool value) => setState(() => _isActive = value),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: Text(widget.academicYear == null ? 'Create Academic Year' : 'Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
