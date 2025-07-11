import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatters
import 'package:school_management_system/src/models/subscription_package_model.dart';
import 'package:school_management_system/src/services/subscription_service.dart';
import 'package:school_management_system/src/config/feature_tags.dart'; // Import feature tags

class SubscriptionPackageFormScreen extends StatefulWidget {
  final SubscriptionPackageModel? package; // Null if creating new

  const SubscriptionPackageFormScreen({super.key, this.package});

  @override
  State<SubscriptionPackageFormScreen> createState() => _SubscriptionPackageFormScreenState();
}

class _SubscriptionPackageFormScreenState extends State<SubscriptionPackageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _currencyController;
  // late TextEditingController _featuresController; // Replaced by _selectedFeatureTags
  late TextEditingController _maxStudentsController;
  late TextEditingController _maxStaffController;

  BillingCycle _selectedBillingCycle = BillingCycle.monthly;
  bool _isActive = true;
  List<String> _selectedFeatureTags = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.package?.name);
    _priceController = TextEditingController(text: widget.package?.price.toString() ?? '');
    _currencyController = TextEditingController(text: widget.package?.currency ?? 'KES');
    // _featuresController = TextEditingController(text: widget.package?.features.join(', ') ?? '');
    _selectedFeatureTags = List<String>.from(widget.package?.features ?? []);
    _maxStudentsController = TextEditingController(text: widget.package?.maxStudents?.toString() ?? '');
    _maxStaffController = TextEditingController(text: widget.package?.maxStaff?.toString() ?? '');
    _selectedBillingCycle = widget.package?.billingCycle ?? BillingCycle.monthly;
    _isActive = widget.package?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _currencyController.dispose();
    // _featuresController.dispose();
    _maxStudentsController.dispose();
    _maxStaffController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
     if (_selectedFeatureTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one feature tag.'), backgroundColor: Colors.red),
      );
      return;
    }
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    // List<String> featuresList = _featuresController.text.split(',').map((f) => f.trim()).where((f) => f.isNotEmpty).toList();

    final packageData = SubscriptionPackageModel(
      id: widget.package?.id ?? '', // ID will be ignored by create, used by update
      name: _nameController.text.trim(),
      price: double.tryParse(_priceController.text.trim()) ?? 0.0,
      currency: _currencyController.text.trim(),
      billingCycle: _selectedBillingCycle,
      features: _selectedFeatureTags, // Use selected feature tags
      maxStudents: int.tryParse(_maxStudentsController.text.trim()),
      maxStaff: int.tryParse(_maxStaffController.text.trim()),
      isActive: _isActive,
      createdAt: widget.package?.createdAt ?? DateTime.now(), // Preserve original if editing
      updatedAt: DateTime.now(),
    );

    try {
      bool success;
      String message;

      if (widget.package == null) { // Creating new package
        SubscriptionPackageModel? newPackage = await _subscriptionService.createPackage(packageData);
        success = newPackage != null;
        message = success ? 'Subscription package "${newPackage!.name}" created successfully!' : 'Failed to create package.';
      } else { // Editing existing package
        success = await _subscriptionService.updatePackage(widget.package!.id, packageData.toMap());
        message = success ? 'Package "${packageData.name}" updated successfully!' : 'Failed to update package.';
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

  Widget _buildFeatureTagsSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Included Features', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: allFeatureTags.map((tag) {
            final isSelected = _selectedFeatureTags.contains(tag);
            return FilterChip(
              label: Text(tag.replaceAll('FT_', '').replaceAll('_', ' ').toLowerCase().capitalizeWords()),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _selectedFeatureTags.add(tag);
                  } else {
                    _selectedFeatureTags.remove(tag);
                  }
                });
              },
              checkmarkColor: Theme.of(context).colorScheme.onPrimary,
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
              ),
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
                  width: 1,
                ),
              ),
            );
          }).toList(),
        ),
        if (_selectedFeatureTags.isEmpty && _formKey.currentState != null && !_formKey.currentState!.validate()) // Show error if submitted and empty
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Please select at least one feature.',
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.package == null ? 'Add New Package' : 'Edit Package'),
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
                      decoration: const InputDecoration(labelText: 'Package Name (e.g., Basic, Premium)', border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? 'Package name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Price is required';
                        if (double.tryParse(value) == null) return 'Enter a valid price';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _currencyController,
                      decoration: const InputDecoration(labelText: 'Currency Code (e.g., KES, USD)', border: OutlineInputBorder()),
                       validator: (value) => value == null || value.isEmpty ? 'Currency code is required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<BillingCycle>(
                      value: _selectedBillingCycle,
                      decoration: const InputDecoration(labelText: 'Billing Cycle', border: OutlineInputBorder()),
                      items: BillingCycle.values.map((BillingCycle cycle) {
                        return DropdownMenuItem<BillingCycle>(value: cycle, child: Text(billingCycleToString(cycle)));
                      }).toList(),
                      onChanged: (BillingCycle? newValue) {
                        if (newValue != null) setState(() => _selectedBillingCycle = newValue);
                      },
                    ),
                    const SizedBox(height: 20),
                    // TextFormField( // Replaced by _buildFeatureTagsSelection
                    //   controller: _featuresController,
                    //   decoration: const InputDecoration(labelText: 'Features (comma-separated)', border: OutlineInputBorder()),
                    //   maxLines: 3,
                    //   validator: (value) => value == null || value.isEmpty ? 'At least one feature is required' : null,
                    // ),
                    _buildFeatureTagsSelection(),
                    const SizedBox(height: 20),
                     Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _maxStudentsController,
                            decoration: const InputDecoration(labelText: 'Max Students (Optional)', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _maxStaffController,
                            decoration: const InputDecoration(labelText: 'Max Staff (Optional)', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Package is Active'),
                      value: _isActive,
                      onChanged: (bool value) => setState(() => _isActive = value),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: Text(widget.package == null ? 'Create Package' : 'Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// Helper extension for capitalizing words in a string
extension StringExtension on String {
  String capitalizeWords() {
    if (trim().isEmpty) return '';
    return trim().split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
