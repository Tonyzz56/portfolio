import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/src/models/fee_structure_model.dart';
import 'package:school_management_system/src/services/fee_service.dart';
// For selecting AcademicYear, Term, Class if they are not fixed context
// import 'package:school_management_system/src/models/academic_year_model.dart';
// import 'package:school_management_system/src/models/term_model.dart';
// import 'package:school_management_system/src/models/class_model.dart';
// import 'package:school_management_system/src/services/academic_service.dart';

class FeeStructureFormScreen extends StatefulWidget {
  final String institutionId;
  final String academicYearId; // Context: Fee structure is for this AY
  final String? termId;         // Optional context
  final String? classId;        // Optional context: Fee structure for a specific class
  final FeeStructureModel? feeStructure; // Null if creating new

  const FeeStructureFormScreen({
    super.key,
    required this.institutionId,
    required this.academicYearId,
    this.termId,
    this.classId,
    this.feeStructure,
  });

  @override
  State<FeeStructureFormScreen> createState() => _FeeStructureFormScreenState();
}

class _FeeStructureFormScreenState extends State<FeeStructureFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final FeeService _feeService = FeeService();
  // final AcademicService _academicService = AcademicService(); // For dropdowns if needed
  bool _isLoading = false;

  late TextEditingController _nameController; // Overall name for this fee entry/structure
  late TextEditingController _descriptionController;
  late TextEditingController _feeItemNameController; // Specific item like "Tuition", "Exam"
  late TextEditingController _amountController;
  late TextEditingController _currencyController;
  DateTime? _dueDate;
  bool _isActive = true;

  // String? _selectedClassIdInternal; // If class is selectable on this form
  // List<ClassModel> _availableClasses = [];

  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.feeStructure?.name);
    _descriptionController = TextEditingController(text: widget.feeStructure?.description);
    _feeItemNameController = TextEditingController(text: widget.feeStructure?.feeItemName);
    _amountController = TextEditingController(text: widget.feeStructure?.amount.toStringAsFixed(2) ?? '');
    _currencyController = TextEditingController(text: widget.feeStructure?.currency ?? 'KES');
    _dueDate = widget.feeStructure?.dueDate;
    _isActive = widget.feeStructure?.isActive ?? true;

    // _selectedClassIdInternal = widget.classId ?? widget.feeStructure?.classId;
    // if (widget.classId == null) _fetchClassesForDropdown();

    if (widget.feeStructure == null && _dueDate == null) {
      _dueDate = DateTime.now().add(const Duration(days: 30)); // Default due date
    }
  }

  // Future<void> _fetchClassesForDropdown() async { ... }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _feeItemNameController.dispose();
    _amountController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate(BuildContext context) async {
    final DateTime initialDate = _dueDate ?? DateTime.now().add(const Duration(days: 30));
    final DateTime firstDate = DateTime.now();
    final DateTime lastDate = DateTime(DateTime.now().year + 5);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (pickedDate != null) {
      setState(() => _dueDate = pickedDate);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a due date.'), backgroundColor: Colors.red),
      );
      return;
    }
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      bool success;
      String message;

      FeeStructureModel feeData = FeeStructureModel(
        id: widget.feeStructure?.id ?? '',
        institutionId: widget.institutionId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        academicYearId: widget.academicYearId,
        termId: widget.termId, // Passed from context
        classId: widget.classId, // Passed from context (or _selectedClassIdInternal if selectable)
        feeItemName: _feeItemNameController.text.trim(),
        amount: double.tryParse(_amountController.text.trim()) ?? 0.0,
        currency: _currencyController.text.trim(),
        dueDate: _dueDate!,
        isActive: _isActive,
        createdAt: widget.feeStructure?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.feeStructure == null) { // Creating new
        FeeStructureModel? createdFee = await _feeService.createFeeStructure(feeData);
        success = createdFee != null;
        message = success ? 'Fee structure "${createdFee!.name}" created successfully!' : 'Failed to create fee structure.';
      } else { // Editing existing
        Map<String, dynamic> updateData = feeData.toMap();
        updateData.remove('id');
        updateData.remove('institutionId');
        updateData.remove('createdAt');
        // Context IDs (academicYearId, termId, classId) are usually not editable for an existing fee structure.
        updateData.remove('academicYearId');
        updateData.remove('termId');
        updateData.remove('classId');

        success = await _feeService.updateFeeStructure(widget.feeStructure!.id, updateData);
        message = success ? 'Fee structure "${feeData.name}" updated successfully!' : 'Failed to update fee structure.';
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
        title: Text(widget.feeStructure == null ? 'Add New Fee Structure' : 'Edit Fee Structure'),
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
                    Text("Context:", style: Theme.of(context).textTheme.titleSmall),
                    Text("Academic Year ID: ${widget.academicYearId.characters.take(8)}..."),
                    if(widget.termId != null) Text("Term ID: ${widget.termId!.characters.take(8)}..."),
                    if(widget.classId != null) Text("Class ID: ${widget.classId!.characters.take(8)}... (Name TODO)"),
                    const Divider(height:20, thickness:1),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Structure Name (e.g., Grade 1 Term 1 Fees)', border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? 'Structure name is required' : null,
                    ),
                    const SizedBox(height: 16),
                     TextFormField(
                      controller: _feeItemNameController,
                      decoration: const InputDecoration(labelText: 'Fee Item Name (e.g., Tuition, Exam, Bus)', border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? 'Fee item name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Amount is required';
                        if (double.tryParse(value) == null || double.parse(value) <= 0) return 'Enter a valid positive amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _currencyController,
                      decoration: const InputDecoration(labelText: 'Currency (e.g., KES)', border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? 'Currency is required' : null,
                    ),
                     const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _pickDueDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Due Date', border: OutlineInputBorder()),
                        child: Text(_dueDate != null ? _dateFormatter.format(_dueDate!) : 'Select Due Date'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description (Optional)', border: OutlineInputBorder()),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    // If classId is not passed as fixed context, a dropdown would be here:
                    // DropdownButtonFormField<String?>(
                    //   value: _selectedClassIdInternal, ... items: _availableClasses ... onChanged: ... )
                    SwitchListTile(
                      title: const Text('Is Active'),
                      value: _isActive,
                      onChanged: (bool value) => setState(() => _isActive = value),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: Text(widget.feeStructure == null ? 'Create Fee Structure' : 'Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
