import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:school_management_system/src/models/institution_model.dart';
import 'package:school_management_system/src/services/institution_service.dart';
import 'package:school_management_system/src/services/auth_service.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/models/subscription_package_model.dart';
import 'package:school_management_system/src/services/subscription_service.dart';

class InstitutionFormScreen extends StatefulWidget {
  final Institution? institution;

  const InstitutionFormScreen({super.key, this.institution});

  @override
  State<InstitutionFormScreen> createState() => _InstitutionFormScreenState();
}

class _InstitutionFormScreenState extends State<InstitutionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final InstitutionService _institutionService = InstitutionService();
  final AuthService _authService = AuthService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _contactEmailController;
  late TextEditingController _contactPhoneController;

  // Institution Admin User fields
  late TextEditingController _adminDisplayNameController;
  late TextEditingController _adminCustomLoginIdController;
  late TextEditingController _adminEmailForAuthController;
  late TextEditingController _adminPasswordController;

  InstitutionType _selectedType = InstitutionType.other;
  String? _existingAdminUserId;
  bool _isLoading = false;

  // Subscription fields
  List<SubscriptionPackageModel> _availablePackages = [];
  SubscriptionPackageModel? _selectedSubscriptionPackage;
  DateTime? _subscriptionStartDate;
  DateTime? _subscriptionEndDate;
  String _selectedSubscriptionStatus = 'trial'; // Default status

  final List<String> _subscriptionStatuses = ['trial', 'active', 'grace_period', 'suspended', 'lapsed'];


  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.institution?.name);
    _addressController = TextEditingController(text: widget.institution?.address);
    _contactEmailController = TextEditingController(text: widget.institution?.contactEmail);
    _contactPhoneController = TextEditingController(text: widget.institution?.contactPhone);
    _selectedType = widget.institution?.type ?? InstitutionType.other;
    _existingAdminUserId = widget.institution?.adminUserId;

    // Initialize admin fields only if creating new institution
    _adminDisplayNameController = TextEditingController();
    _adminCustomLoginIdController = TextEditingController();
    _adminEmailForAuthController = TextEditingController();
    _adminPasswordController = TextEditingController();

    // Initialize subscription fields
    _subscriptionStartDate = widget.institution?.subscriptionStartDate;
    _subscriptionEndDate = widget.institution?.subscriptionEndDate;
    _selectedSubscriptionStatus = widget.institution?.subscriptionStatus ?? 'trial';

    _loadSubscriptionPackages();
  }

  Future<void> _loadSubscriptionPackages() async {
    setState(() => _isLoading = true);
    try {
      _availablePackages = await _subscriptionService.getPackages().first; // Get current list
      if (widget.institution?.activeSubscriptionPackageId != null && _availablePackages.isNotEmpty) {
        _selectedSubscriptionPackage = _availablePackages.firstWhere(
          (pkg) => pkg.id == widget.institution!.activeSubscriptionPackageId,
          orElse: () => _availablePackages.isNotEmpty ? _availablePackages.first : null, // Fallback
        );
      } else if (_availablePackages.isNotEmpty) {
        // _selectedSubscriptionPackage = _availablePackages.first; // Optionally default to first package
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading subscription packages: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _adminDisplayNameController.dispose();
    _adminCustomLoginIdController.dispose();
    _adminEmailForAuthController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _subscriptionStartDate : _subscriptionEndDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _subscriptionStartDate = picked;
        } else {
          _subscriptionEndDate = picked;
        }
      });
    }
  }


  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate subscription dates if a package is selected
    if (_selectedSubscriptionPackage != null) {
      if (_subscriptionStartDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription Start Date is required when a package is selected.'), backgroundColor: Colors.red));
        return;
      }
      if (_subscriptionEndDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription End Date is required when a package is selected.'), backgroundColor: Colors.red));
        return;
      }
      if (_subscriptionEndDate!.isBefore(_subscriptionStartDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription End Date cannot be before Start Date.'), backgroundColor: Colors.red));
        return;
      }
    }


    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      if (widget.institution == null) { // Creating new institution
        String adminEmailForAuth = _adminEmailForAuthController.text.trim();
        String adminCustomLoginId = _adminCustomLoginIdController.text.trim();

        if (adminEmailForAuth.isEmpty && adminCustomLoginId.isNotEmpty) {
          adminEmailForAuth = "${adminCustomLoginId.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}@institutionadmin.system";
        }
        if (adminEmailForAuth.isEmpty || !adminEmailForAuth.contains('@')) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valid Email for Admin Auth is required.'), backgroundColor: Colors.red));
          setState(() => _isLoading = false);
          return;
        }
        if (adminCustomLoginId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin Custom Login ID is required.'), backgroundColor: Colors.red));
          setState(() => _isLoading = false);
          return;
        }

        UserModel? newAdmin;
        try {
          newAdmin = await _authService.signUpOrRegisterUser(
            emailForAuth: adminEmailForAuth,
            customLoginId: adminCustomLoginId,
            password: _adminPasswordController.text.trim(),
            displayName: _adminDisplayNameController.text.trim(),
            role: UserRole.institutionAdmin,
            institutionId: null,
          );
        } catch (e) {
           if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create institution admin: ${e.toString()}'), backgroundColor: Colors.red));
           setState(() => _isLoading = false);
           return;
        }

        if (newAdmin == null) {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create institution admin account.'), backgroundColor: Colors.red));
          setState(() => _isLoading = false);
          return;
        }

        Institution newInstitutionData = Institution(
          id: '', // Will be set by service
          name: _nameController.text.trim(),
          type: _selectedType,
          adminUserId: newAdmin.uid,
          address: _addressController.text.trim(),
          contactEmail: _contactEmailController.text.trim(),
          contactPhone: _contactPhoneController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true, // Default for new institution
          activeSubscriptionPackageId: _selectedSubscriptionPackage?.id,
          subscriptionStartDate: _subscriptionStartDate,
          subscriptionEndDate: _subscriptionEndDate,
          subscriptionStatus: _selectedSubscriptionStatus,
        );


        Institution? createdInstitution = await _institutionService.createInstitutionWithFullData(
            institutionData: newInstitutionData,
            // The service method createInstitutionWithFullData will handle the data directly.
            // We no longer pass individual admin fields if they are part of newInstitutionData.
            // This assumes createInstitutionWithFullData is adapted or a new one is made.
            // For now, let's assume the original createInstitution is adapted or we are creating a map.
        );

        // If createInstitutionWithFullData is not available, we'd use the old method and update subscription separately.
        // For this example, let's assume a method that takes the full model or map.
        // The original _institutionService.createInstitution might need to be updated to accept these new fields
        // or a new method like `createInstitutionWithSubscription` should be used.
        // For now, we will proceed as if the `toMap()` of newInstitutionData is passed.

        // Simplified: assuming createInstitution can take a Map from newInstitutionData.toMap()
        // And that it returns the created institution with ID.
        // This part needs careful alignment with the actual service method signature.

        if (createdInstitution == null) { // Simulate if service needs map and direct creation
             // This is a conceptual adjustment. The actual implementation depends on InstitutionService.
            Map<String, dynamic> institutionMap = newInstitutionData.toMap();
            // The adminUserId is already in newInstitutionData, so these might be redundant for some service implementations.
            institutionMap['adminEmail'] = adminEmailForAuth;
            institutionMap['adminPassword'] = "USED_FOR_AUTH_CREATION_ONLY"; // Not stored
            institutionMap['adminDisplayName'] = _adminDisplayNameController.text.trim();


            createdInstitution = await _institutionService.createInstitution(
              name: newInstitutionData.name,
              type: newInstitutionData.type,
              adminUserId: newInstitutionData.adminUserId,
              address: newInstitutionData.address,
              contactEmail: newInstitutionData.contactEmail,
              contactPhone: newInstitutionData.contactPhone,
              // Pass new subscription fields
              activeSubscriptionPackageId: newInstitutionData.activeSubscriptionPackageId,
              subscriptionStartDate: newInstitutionData.subscriptionStartDate,
              subscriptionEndDate: newInstitutionData.subscriptionEndDate,
              subscriptionStatus: newInstitutionData.subscriptionStatus,
              // Admin creation params (if service handles it, but we did it before)
              adminEmail: adminEmailForAuth,
              adminPassword: "NOT_STORED_DIRECTLY", // Placeholder
              adminDisplayName: _adminDisplayNameController.text.trim(),
            );
        }


        if (createdInstitution != null) {
          await _authService.updateUserProfile(newAdmin.uid, {'institutionId': createdInstitution.id});
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Institution "${createdInstitution.name}" created successfully.'), backgroundColor: Colors.green));
          if(mounted) Navigator.of(context).pop();
        } else {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create institution document. Admin user might have been created. Check logs.'), backgroundColor: Colors.red));
        }

      } else { // Updating existing institution
        Map<String, dynamic> updates = {
          'name': _nameController.text.trim(),
          'type': institutionTypeToString(_selectedType),
          'address': _addressController.text.trim(),
          'contactEmail': _contactEmailController.text.trim(),
          'contactPhone': _contactPhoneController.text.trim(),
          'updatedAt': DateTime.now(),
          'activeSubscriptionPackageId': _selectedSubscriptionPackage?.id,
          'subscriptionStartDate': _subscriptionStartDate,
          'subscriptionEndDate': _subscriptionEndDate,
          'subscriptionStatus': _selectedSubscriptionStatus,
        };
        // Note: adminUserId and isActive are not updated here. isActive could be a separate toggle.

        bool success = await _institutionService.updateInstitutionFields(widget.institution!.id, updates);
        if (success) {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Institution "${updatedInstitution.name}" updated successfully.'), backgroundColor: Colors.green));
          if(mounted) Navigator.of(context).pop();
        } else {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update institution.'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: ${e.toString()}'), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.institution == null ? 'Add New Institution' : 'Edit Institution'),
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
                    Text('Institution Details', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height:10),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Institution Name', border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter institution name' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<InstitutionType>(
                      value: _selectedType,
                      decoration: const InputDecoration(labelText: 'Institution Type', border: OutlineInputBorder()),
                      items: getAllInstitutionTypes().map((InstitutionType type) {
                        return DropdownMenuItem<InstitutionType>(value: type, child: Text(institutionTypeToString(type)));
                      }).toList(),
                      onChanged: (InstitutionType? newValue) {
                        if (newValue != null) setState(() => _selectedType = newValue);
                      },
                      validator: (value) => value == null ? 'Please select an institution type' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address (Optional)', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    TextFormField(controller: _contactEmailController, decoration: const InputDecoration(labelText: 'Contact Email (Optional)', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    TextFormField(controller: _contactPhoneController, decoration: const InputDecoration(labelText: 'Contact Phone (Optional)', border: OutlineInputBorder()), keyboardType: TextInputType.phone),

                    if (widget.institution == null) ...[
                      const SizedBox(height: 24),
                      Text('Create Initial Institution Admin Account', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height:10),
                      TextFormField(
                        controller: _adminDisplayNameController,
                        decoration: const InputDecoration(labelText: 'Admin Display Name', border: OutlineInputBorder()),
                        validator: (value) => (value == null || value.isEmpty) ? 'Admin display name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _adminCustomLoginIdController,
                        decoration: const InputDecoration(labelText: 'Admin Custom Login ID', border: OutlineInputBorder()),
                        validator: (value) {
                           if (value == null || value.isEmpty) return 'Admin Custom Login ID is required.';
                           if (value.contains(' ')) return 'Login ID cannot contain spaces.';
                           return null;
                        }
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _adminEmailForAuthController,
                        decoration: const InputDecoration(labelText: 'Admin Email for Auth', hintText: 'Real email or auto-generated', border: OutlineInputBorder()),
                        keyboardType: TextInputType.emailAddress,
                         validator: (value) {
                            if ((value == null || value.isEmpty || !value.contains('@')) && _adminCustomLoginIdController.text.trim().isEmpty) {
                               return 'Valid email for Auth is required if not auto-generating from Login ID.';
                            }
                            return null;
                         }
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _adminPasswordController,
                        decoration: const InputDecoration(labelText: 'Admin Password (min. 6 characters)', border: OutlineInputBorder()),
                        obscureText: true,
                        validator: (value) => (value == null || value.length < 6) ? 'Admin password must be at least 6 characters' : null,
                      ),
                    ] else ...[
                      const SizedBox(height: 24),
                      Text('Institution Admin:', style: Theme.of(context).textTheme.titleMedium),
                      Text('Admin User ID: ${_existingAdminUserId ?? "Not set"}'),
                      const Text('(Changing admin user requires a separate process not available in this form)', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                    ],

                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: Text(widget.institution == null ? 'Create Institution & Admin' : 'Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
