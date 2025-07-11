import 'package:flutter/material.dart';
import 'package:school_management_system/src/models/institution_model.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/models/department_model.dart';
import 'package:school_management_system/src/services/auth_service.dart';
import 'package:school_management_system/src/services/department_service.dart';

class UserFormScreen extends StatefulWidget {
  final String institutionId;
  final InstitutionType institutionType;
  final UserModel? userToEdit;
  final bool canAddMoreStudents;
  final bool canAddMoreStaff;

  const UserFormScreen({
    super.key,
    required this.institutionId,
    required this.institutionType,
    this.userToEdit,
    required this.canAddMoreStudents,
    required this.canAddMoreStaff,
  });

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final DepartmentService _departmentService = DepartmentService();
  bool _isLoading = false;

  late TextEditingController _emailForAuthController;
  late TextEditingController _customLoginIdController;
  late TextEditingController _displayNameController;
  late TextEditingController _passwordController;

  late TextEditingController _admissionNumberController;
  late TextEditingController _staffIdController;
  late TextEditingController _vendorCompanyNameController;
  late TextEditingController _parentUidsController;
  late TextEditingController _childUidsController;

  UserRole _selectedRole = UserRole.student;
  String? _selectedDepartmentId;
  List<DepartmentModel> _availableDepartments = [];


  @override
  void initState() {
    super.initState();

    _emailForAuthController = TextEditingController(text: widget.userToEdit?.email);
    _customLoginIdController = TextEditingController(text: widget.userToEdit?.customLoginId);
    _displayNameController = TextEditingController(text: widget.userToEdit?.displayName);
    _passwordController = TextEditingController();

    _selectedRole = widget.userToEdit?.role ?? UserRole.student;

    if (widget.userToEdit == null) {
      if (_selectedRole == UserRole.student && !widget.canAddMoreStudents) {
        if (widget.canAddMoreStaff) {
          _selectedRole = UserRole.teacher;
        }
      } else if ((_selectedRole == UserRole.teacher || _selectedRole == UserRole.nonTeachingStaff) && !widget.canAddMoreStaff) {
        if (widget.canAddMoreStudents) {
          _selectedRole = UserRole.student;
        }
      }
    }

    _admissionNumberController = TextEditingController(text: widget.userToEdit?.admissionNumber);
    _staffIdController = TextEditingController(text: widget.userToEdit?.staffId);
    _selectedDepartmentId = widget.userToEdit?.department;
    _vendorCompanyNameController = TextEditingController(text: widget.userToEdit?.vendorCompanyName);
    _parentUidsController = TextEditingController(text: widget.userToEdit?.parentUids?.join(', '));
    _childUidsController = TextEditingController(text: widget.userToEdit?.childUids?.join(', '));

    if (_selectedRole == UserRole.nonTeachingStaff) {
      _fetchDepartments();
    }
  }

  Future<void> _fetchDepartments() async {
    _departmentService.getDepartmentsForInstitution(widget.institutionId).listen((departments) {
      if (mounted) {
        setState(() {
          _availableDepartments = departments;
          if (widget.userToEdit?.department != null && !_availableDepartments.any((d) => d.id == widget.userToEdit!.department)) {
            _selectedDepartmentId = null;
          }
        });
      }
    });
  }

  List<DropdownMenuItem<UserRole>> _buildRoleDropdownItems() {
    List<UserRole> allRoles = getAllAssignableUserRoles();
    List<DropdownMenuItem<UserRole>> items = [];

    if (widget.userToEdit != null) { // If editing, all roles are generally available to switch to
      items = allRoles.map((UserRole role) {
        return DropdownMenuItem<UserRole>(
          value: role,
          child: Text(userRoleToString(role)),
        );
      }).toList();
    } else { // If adding new user, filter based on limits
      for (UserRole role in allRoles) {
        bool canAddThisRole = true;
        String? disabledReason;

        if (role == UserRole.student && !widget.canAddMoreStudents) {
          canAddThisRole = false;
          disabledReason = " (Limit Reached)";
        } else if ((role == UserRole.teacher || role == UserRole.nonTeachingStaff) && !widget.canAddMoreStaff) {
          canAddThisRole = false;
          disabledReason = " (Limit Reached)";
        }

        items.add(DropdownMenuItem<UserRole>(
          value: role,
          enabled: canAddThisRole, // Disable item if limit is reached
          child: Text(userRoleToString(role) + (canAddThisRole ? "" : disabledReason!)),
        ));
      }
      // If all roles are disabled due to limits, ensure _selectedRole is one of them to avoid validation errors before user interaction
      // Or, ensure validator handles this state gracefully.
      // The current initState logic tries to pick an available role if the default is unavailable.
      // If no roles are addable at all, ManageUsersScreen should prevent opening this form.
      // If items list is empty or all disabled, the DropdownButtonFormField might show an error or be unusable.
      // Consider adding a "No roles available" item if all are disabled.
       if (items.where((item) => item.enabled).isEmpty && items.isNotEmpty) {
        // This scenario means no roles can be added.
        // The form should ideally not be reachable, or display a clear message.
        // For now, the validator on DropdownButtonFormField will catch this if user tries to submit.
      }
    }
    return items;
  }


  @override
  void dispose() {
    _emailForAuthController.dispose();
    _customLoginIdController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    _admissionNumberController.dispose();
    _staffIdController.dispose();
    _vendorCompanyNameController.dispose();
    _parentUidsController.dispose();
    _childUidsController.dispose();
    super.dispose();
  }

  List<String>? _parseUids(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    return text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.userToEdit == null) {
      if (_selectedRole == UserRole.student && !widget.canAddMoreStudents) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot add more students. Student limit reached.'), backgroundColor: Colors.red),
        );
        return;
      }
      if ((_selectedRole == UserRole.teacher || _selectedRole == UserRole.nonTeachingStaff) && !widget.canAddMoreStaff) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot add more staff. Staff limit reached.'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    String emailForAuth = _emailForAuthController.text.trim();
    if (emailForAuth.isEmpty && _customLoginIdController.text.trim().isNotEmpty) {
      emailForAuth = "${_customLoginIdController.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}@institution.system";
    }

     if (emailForAuth.isEmpty || !emailForAuth.contains('@')) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A valid email for authentication (system or real) is required.'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
        return;
    }

    List<String>? parentUids = _parseUids(_parentUidsController.text);
    List<String>? childUids = _parseUids(_childUidsController.text);
    String? departmentValueToSave = _selectedDepartmentId;

    try {
      if (widget.userToEdit == null) {
        await _authService.signUpOrRegisterUser(
          emailForAuth: emailForAuth,
          customLoginId: _customLoginIdController.text.trim(),
          password: _passwordController.text.trim(),
          displayName: _displayNameController.text.trim(),
          role: _selectedRole,
          institutionId: widget.institutionId,
          admissionNumber: _selectedRole == UserRole.student ? _admissionNumberController.text.trim() : null,
          parentUids: _selectedRole == UserRole.student ? parentUids : null,
          staffId: (_selectedRole == UserRole.teacher || _selectedRole == UserRole.nonTeachingStaff) ? _staffIdController.text.trim() : null,
          department: _selectedRole == UserRole.nonTeachingStaff ? departmentValueToSave : null,
          childUids: _selectedRole == UserRole.parent ? childUids : null,
          vendorCompanyName: _selectedRole == UserRole.vendor ? _vendorCompanyNameController.text.trim() : null,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User created successfully.'), backgroundColor: Colors.green),
        );
      } else {
        Map<String, dynamic> updatedData = {
          'customLoginId': _customLoginIdController.text.trim(),
          'displayName': _displayNameController.text.trim(),
          'role': userRoleToString(_selectedRole),
          'admissionNumber': _selectedRole == UserRole.student ? _admissionNumberController.text.trim() : FieldValue.delete(),
          'parentUids': _selectedRole == UserRole.student ? (parentUids ?? FieldValue.delete()) : FieldValue.delete(),
          'staffId': (_selectedRole == UserRole.teacher || _selectedRole == UserRole.nonTeachingStaff) ? _staffIdController.text.trim() : FieldValue.delete(),
          'department': _selectedRole == UserRole.nonTeachingStaff ? (departmentValueToSave ?? FieldValue.delete()) : FieldValue.delete(),
          'childUids': _selectedRole == UserRole.parent ? (childUids ?? FieldValue.delete()) : FieldValue.delete(),
          'vendorCompanyName': _selectedRole == UserRole.vendor ? _vendorCompanyNameController.text.trim() : FieldValue.delete(),
        };

        if (widget.userToEdit!.email != emailForAuth) {
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Firebase Auth email cannot be changed from this form. Firestore record updated with new reference email if provided.'), backgroundColor: Colors.orange),
            );
            updatedData['email'] = emailForAuth;
        }
        if (widget.userToEdit!.customLoginId != _customLoginIdController.text.trim()) {
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Custom Login ID changed. Ensure it remains unique if other users need to find this account by ID.'), backgroundColor: Colors.orange),
            );
        }

        await _authService.updateUserProfile(widget.userToEdit!.uid, updatedData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully.'), backgroundColor: Colors.green),
        );
      }
      if(mounted) Navigator.of(context).pop();
    } catch (e) {
       if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
       }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure that _selectedRole is valid given the current limits, especially if no user is being edited.
    // This is a fallback if initState logic didn't perfectly set it or if limits change while form is open (unlikely without refresh).
    if (widget.userToEdit == null) {
        bool isCurrentRoleAddable = true;
        if (_selectedRole == UserRole.student && !widget.canAddMoreStudents) isCurrentRoleAddable = false;
        if ((_selectedRole == UserRole.teacher || _selectedRole == UserRole.nonTeachingStaff) && !widget.canAddMoreStaff) isCurrentRoleAddable = false;

        if (!isCurrentRoleAddable) {
            // Attempt to find the first available role
            List<DropdownMenuItem<UserRole>> availableItems = _buildRoleDropdownItems();
            UserRole? firstAvailableRole = availableItems.firstWhere((item) => item.enabled, orElse: () => DropdownMenuItem<UserRole>(value: _selectedRole /* keep current if none available */)).value;
            if (firstAvailableRole != null && _selectedRole != firstAvailableRole) {
                 // Post frame callback to avoid calling setState during build
                WidgetsBinding.instance.addPostFrameCallback((_) {
                   if(mounted) setState(() => _selectedRole = firstAvailableRole);
                });
            }
        }
    }


    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userToEdit == null ? 'Add New User' : 'Edit User'),
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
                      controller: _displayNameController,
                      decoration: const InputDecoration(labelText: 'Full Name / Display Name', border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? 'Display name is required' : null,
                    ),
                    const SizedBox(height: 16),
                     TextFormField(
                      controller: _customLoginIdController,
                      decoration: const InputDecoration(labelText: 'Custom Login ID (e.g., student001, staff01)', border: OutlineInputBorder()),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Custom Login ID is required.';
                        if (value.contains(' ')) return 'Login ID cannot contain spaces.';
                        return null;
                      }
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailForAuthController,
                      decoration: const InputDecoration(
                        labelText: 'Email for Authentication',
                        hintText: 'User\'s real email or system-generated (e.g., loginID@system.domain)',
                        border: OutlineInputBorder()
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if ((value == null || value.isEmpty || !value.contains('@')) && _customLoginIdController.text.trim().isEmpty) {
                           return 'Valid email for Auth is required if not auto-generating from Login ID.';
                        }
                        return null;
                      }
                    ),
                    if (widget.userToEdit == null) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Password (min. 6 characters)', border: OutlineInputBorder()),
                        obscureText: true,
                        validator: (value) => widget.userToEdit == null && (value == null || value.length < 6) ? 'Password must be at least 6 characters' : null,
                      ),
                    ],
                    const SizedBox(height: 16),
                    DropdownButtonFormField<UserRole>(
                      value: _selectedRole,
                      decoration: const InputDecoration(labelText: 'User Role', border: OutlineInputBorder()),
                      items: _buildRoleDropdownItems(),
                      onChanged: (UserRole? newValue) {
                        if (newValue != null) {
                          // When adding new user, check if the selected role is actually addable
                           if (widget.userToEdit == null) {
                                bool canSelectNewRole = true;
                                if (newValue == UserRole.student && !widget.canAddMoreStudents) canSelectNewRole = false;
                                if ((newValue == UserRole.teacher || newValue == UserRole.nonTeachingStaff) && !widget.canAddMoreStaff) canSelectNewRole = false;

                                if (!canSelectNewRole) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${userRoleToString(newValue)} limit reached. Cannot select this role.'), backgroundColor: Colors.red),
                                    );
                                    return; // Do not update _selectedRole
                                }
                           }
                          setState(() => _selectedRole = newValue);
                          if (_selectedRole == UserRole.nonTeachingStaff && _availableDepartments.isEmpty) {
                            _fetchDepartments();
                          } else if (_selectedRole != UserRole.nonTeachingStaff) {
                            // Clear department if role is not non-teaching staff
                            // _selectedDepartmentId = null; // Optional: clear selection if role changes from non-teaching
                          }
                        }
                      },
                      validator: (value) {
                        if (value == null) return 'Please select a role';
                        if (widget.userToEdit == null) {
                          if (value == UserRole.student && !widget.canAddMoreStudents) {
                            return 'Student limit reached. Cannot add more students.';
                          }
                          if ((value == UserRole.teacher || value == UserRole.nonTeachingStaff) && !widget.canAddMoreStaff) {
                            return 'Staff limit reached. Cannot add more staff.';
                          }
                        }
                        return null;
                      }
                    ),
                    const SizedBox(height: 20),

                    // Role-specific fields
                    if (_selectedRole == UserRole.student) ...[
                      Text('Student Specific Information', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _admissionNumberController,
                        decoration: const InputDecoration(labelText: 'Admission Number', border: OutlineInputBorder()),
                        validator: (value) => _selectedRole == UserRole.student && (value == null || value.isEmpty) ? 'Admission number is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _parentUidsController,
                        decoration: const InputDecoration(labelText: 'Parent User UIDs (comma-separated)', border: OutlineInputBorder(), hintText: "UID1, UID2... (placeholder)"),
                      ),
                    ],
                    if (_selectedRole == UserRole.teacher || _selectedRole == UserRole.nonTeachingStaff) ...[
                       Text('Staff Specific Information', style: Theme.of(context).textTheme.titleMedium),
                       const SizedBox(height: 10),
                       TextFormField(
                        controller: _staffIdController,
                        decoration: const InputDecoration(labelText: 'Staff ID', border: OutlineInputBorder()),
                         validator: (value) => (_selectedRole == UserRole.teacher || _selectedRole == UserRole.nonTeachingStaff) && (value == null || value.isEmpty) ? 'Staff ID is required' : null,
                      ),
                    ],
                    if (_selectedRole == UserRole.nonTeachingStaff) ...[
                       const SizedBox(height: 16),
                       _availableDepartments.isEmpty && _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<String?>(
                              value: _selectedDepartmentId,
                              decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
                              hint: const Text('Select Department'),
                              items: [
                                const DropdownMenuItem<String?>(value: null, child: Text('None / Not Applicable')),
                                ..._availableDepartments.map((DepartmentModel dept) {
                                  return DropdownMenuItem<String?>(
                                    value: dept.id,
                                    child: Text(dept.name),
                                  );
                                }).toList()
                              ],
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedDepartmentId = newValue;
                                });
                              },
                              validator: (value) => _selectedRole == UserRole.nonTeachingStaff && value == null
                                  ? 'Department is required for Non-Teaching Staff'
                                  : null,
                            ),
                    ],
                    if (_selectedRole == UserRole.parent) ...[
                       Text('Parent Specific Information', style: Theme.of(context).textTheme.titleMedium),
                       const SizedBox(height: 10),
                       TextFormField(
                        controller: _childUidsController,
                        decoration: const InputDecoration(labelText: 'Child User UIDs (comma-separated)', border: OutlineInputBorder(), hintText: "ChildUID1, ChildUID2... (placeholder)"),
                      ),
                    ],
                     if (_selectedRole == UserRole.vendor) ...[
                       Text('Vendor Specific Information', style: Theme.of(context).textTheme.titleMedium),
                       const SizedBox(height: 10),
                       TextFormField(
                        controller: _vendorCompanyNameController,
                        decoration: const InputDecoration(labelText: 'Company Name', border: OutlineInputBorder()),
                        validator: (value) => _selectedRole == UserRole.vendor && (value == null || value.isEmpty) ? 'Company name is required' : null,
                      ),
                    ],

                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: Text(widget.userToEdit == null ? 'Create User' : 'Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
