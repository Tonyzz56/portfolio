import 'package:flutter/material.dart';
import 'package:school_management_system/src/models/announcement_model.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/services/announcement_service.dart';
// import 'package:provider/provider.dart'; // To get current user

class CreateAnnouncementScreen extends StatefulWidget {
  final UserModel currentUser; // The admin creating the announcement
  final String? institutionId; // Required if scope is institution

  const CreateAnnouncementScreen({
    super.key,
    required this.currentUser,
    this.institutionId, // If null, implies SuperAdmin creating system announcement
  });

  @override
  State<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final AnnouncementService _announcementService = AnnouncementService();
  bool _isLoading = false;

  late TextEditingController _titleController;
  late TextEditingController _contentController;
  AnnouncementScope _selectedScope = AnnouncementScope.institution;
  List<UserRole> _selectedTargetRoles = []; // Empty means all users in scope

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    // If institutionId is null, this must be a system announcement by SuperAdmin
    if (widget.institutionId == null && widget.currentUser.role == UserRole.superAdmin) {
      _selectedScope = AnnouncementScope.system;
    } else {
      _selectedScope = AnnouncementScope.institution;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      await _announcementService.createAnnouncement(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        createdByUid: widget.currentUser.uid,
        createdByName: widget.currentUser.displayName ?? widget.currentUser.email,
        scope: _selectedScope,
        institutionId: _selectedScope == AnnouncementScope.institution ? widget.institutionId : null,
        targetUserRoles: _selectedTargetRoles.isEmpty ? null : _selectedTargetRoles,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement created successfully!'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating announcement: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if scope selection should be enabled
    // SuperAdmins can choose, InstitutionAdmins are fixed to their institution.
    bool canSelectScope = widget.currentUser.role == UserRole.superAdmin;


    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Announcement'),
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
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(labelText: 'Content', border: OutlineInputBorder()),
                      maxLines: 5,
                      validator: (value) => value == null || value.isEmpty ? 'Content is required' : null,
                    ),
                    const SizedBox(height: 16),
                    if (canSelectScope)
                      DropdownButtonFormField<AnnouncementScope>(
                        value: _selectedScope,
                        decoration: const InputDecoration(labelText: 'Scope', border: OutlineInputBorder()),
                        items: AnnouncementScope.values.map((AnnouncementScope scope) {
                          return DropdownMenuItem<AnnouncementScope>(
                            value: scope,
                            child: Text(scope.toString().split('.').last),
                          );
                        }).toList(),
                        onChanged: (AnnouncementScope? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedScope = newValue;
                            });
                          }
                        },
                      )
                    else // For Institution Admin, scope is fixed
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text("Scope: Institution (${widget.institutionId ?? 'Your Institution'})", style: Theme.of(context).textTheme.titleMedium),
                      ),

                    const SizedBox(height: 16),
                    Text('Target Roles (Optional - leave empty for all users in scope):', style: Theme.of(context).textTheme.titleMedium),
                    Wrap(
                      spacing: 8.0,
                      children: UserRole.values.where((role) => role != UserRole.unknown && role != UserRole.superAdmin).map((UserRole role) {
                        bool isSelected = _selectedTargetRoles.contains(role);
                        return FilterChip(
                          label: Text(userRoleToString(role)),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                _selectedTargetRoles.add(role);
                              } else {
                                _selectedTargetRoles.remove(role);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: const Text('Create Announcement'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
