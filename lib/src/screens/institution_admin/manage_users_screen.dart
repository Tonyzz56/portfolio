import 'package:flutter/material.dart';
import 'package:school_management_system/src/models/institution_model.dart'; // For InstitutionType
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/services/auth_service.dart';
import 'package:school_management_system/src/services/subscription_feature_service.dart'; // Import
import 'package:school_management_system/src/config/feature_tags.dart'; // Import
import 'user_form_screen.dart'; // For adding/editing users

class ManageUsersScreen extends StatefulWidget {
  final String institutionId;
  final InstitutionType institutionType; // To tailor UI/options if needed

  const ManageUsersScreen({
    super.key,
    required this.institutionId,
    required this.institutionType,
  });

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final AuthService _authService = AuthService();
  final SubscriptionFeatureService _featureService = SubscriptionFeatureService(); // Instantiate
  String _selectedRoleFilter = "All"; // "All", "Teacher", "Student", "NonTeachingStaff"
  bool _canAddMoreStudents = true;
  bool _canAddMoreStaff = true;
  bool _isLoadingLimits = true;
  int _currentStudentCount = 0;
  int _currentStaffCount = 0; // Combined Teacher + NonTeachingStaff
  Stream<List<UserModel>>? _usersStream;


  @override
  void initState() {
    super.initState();
    _usersStream = _authService.getUsersForInstitution(widget.institutionId);
    _initializeLimitsAndCounts();
     _usersStream!.listen((users) { // Listen to user changes to update counts
      if (mounted) _updateCountsAndLimits(users);
    });
  }

  Future<void> _initializeLimitsAndCounts() async {
    // Initial fetch of users to set counts before first limit check
    // This is a bit redundant if the stream fires quickly, but ensures counts are set.
    try {
        List<UserModel> initialUsers = await _usersStream!.first; // Get first emission
         if (mounted) _updateCountsAndLimits(initialUsers); // This will also call _checkUserLimits
    } catch (e) {
        print("Error fetching initial users for limits: $e");
        if (mounted) setState(() => _isLoadingLimits = false); // Stop loading on error
    }
  }


  Future<void> _updateCountsAndLimits(List<UserModel> users) async {
    _currentStudentCount = users.where((u) => u.role == UserRole.student).length;
    _currentStaffCount = users.where((u) => u.role == UserRole.teacher || u.role == UserRole.nonTeachingStaff).length;
    await _checkUserLimits(setLoadingState: mounted); // update internal flags based on new counts
    if (mounted) setState(() {}); // then update UI for counts potentially
  }


  Future<void> _checkUserLimits({bool setLoadingState = true}) async {
    if (setLoadingState && mounted) setState(() => _isLoadingLimits = true);

    await _featureService.forceReloadData();

    bool studentLimitActive = await _featureService.isFeatureEnabled(FT_LIMIT_STUDENTS);
    bool staffLimitActive = await _featureService.isFeatureEnabled(FT_LIMIT_STAFF);

    if (studentLimitActive) {
      final int? maxStudents = await _featureService.getLimit('MAX_STUDENTS');
      _canAddMoreStudents = (maxStudents == null || _currentStudentCount < maxStudents);
    } else {
      _canAddMoreStudents = true;
    }

    if (staffLimitActive) {
      final int? maxStaff = await _featureService.getLimit('MAX_STAFF');
      _canAddMoreStaff = (maxStaff == null || _currentStaffCount < maxStaff);
    } else {
      _canAddMoreStaff = true;
    }

    if (setLoadingState && mounted) setState(() => _isLoadingLimits = false);
  }


  Future<void> _onAddUserPressed({UserModel? user}) async { // Changed to _onAddUserPressed
    await _checkUserLimits(); // Ensure limits are fresh before this check

    if (user == null) { // Only apply full blocking logic if adding a new user
      bool canAddAnyUserRole = _canAddMoreStudents || _canAddMoreStaff;
      String limitMessage = "";

      if (!_canAddMoreStudents && !_canAddMoreStaff) {
        canAddAnyUserRole = false;
        limitMessage = "Student and Staff limits reached for your current subscription package.";
      } else if (!_canAddMoreStudents) {
        // Student limit hit, but staff might still be addable
        if(!_canAddMoreStaff) { // If staff also cannot be added (e.g. specific staff type limit hit, or general staff limit)
            canAddAnyUserRole = false; // effectively
            limitMessage = "Student limit reached, and staff cannot be added at this time.";
        } else {
            limitMessage = "Student limit reached. You can only add Staff if allowed by their specific limits.";
        }
      } else if (!_canAddMoreStaff) {
        // Staff limit hit, but students might still be addable
         if(!_canAddMoreStudents) { // If students also cannot be added
            canAddAnyUserRole = false; // effectively
            limitMessage = "Staff limit reached, and students cannot be added at this time.";
        } else {
            limitMessage = "Staff limit reached. You can only add Students if allowed by their specific limits.";
        }
      }

      if (!canAddAnyUserRole) {
           ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(limitMessage), backgroundColor: Colors.red),
          );
          return;
      }
      // If one limit is hit, but not the other, UserFormScreen will handle disabling role choices.
      // Show a warning if one of the categories is full but the other isn't.
      else if (limitMessage.isNotEmpty) {
           ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(limitMessage), backgroundColor: Colors.orange),
          );
      }
    }
    // If editing (user != null) or if at least one role type can be added, proceed to form.
    _navigateToActualForm(user: user);
  }

  // Renamed original navigation to avoid confusion
  void _navigateToActualForm({UserModel? user}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserFormScreen(
          institutionId: widget.institutionId,
          institutionType: widget.institutionType,
          userToEdit: user,
          canAddMoreStudents: _canAddMoreStudents,
          canAddMoreStaff: _canAddMoreStaff,
        ),
      ),
    ).then((_) {
      // Stream listener handles most updates. Explicit re-check can be added if needed.
      // _initializeLimitsAndCounts();
    });
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    bool success = await _authService.toggleUserActiveStatus(user.uid, !user.isActive);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ${user.displayName ?? user.email} status updated.')),
      );
      setState(() {}); // Refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status for ${user.displayName ?? user.email}.')),
      );
    }
  }

  // In a real app, deleting a user requires careful consideration:
  // - What happens to their data? (e.g., student grades, teacher assignments)
  // - Do you delete their Firebase Auth account or just the Firestore profile?
  // - For now, this is a placeholder for "hard delete" which is generally discouraged without proper cascade logic.
  Future<void> _confirmDeleteUser(UserModel user) async {
     bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete User'),
          content: Text('Are you sure you want to permanently delete user ${user.displayName ?? user.email}? This action is irreversible and will remove their login access and profile. Associated data (grades, etc.) will NOT be automatically cleaned up by this action.'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete User Permanently'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      // This is highly simplified. Deleting a Firebase Auth user is a separate step.
      // And deleting Firestore document.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deletion (Firebase Auth + Firestore) not fully implemented in this placeholder. Conceptual delete.'), backgroundColor: Colors.orange),
      );
      // Example conceptual steps (NEEDS PROPER IMPLEMENTATION):
      // 1. Delete Firebase Auth user: await FirebaseAuth.instance.currentUser.delete() (requires re-auth or admin SDK)
      //    OR use Admin SDK: admin.auth().deleteUser(user.uid)
      // 2. Delete Firestore user document: await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      // For now, just toggle active to false as a "safer" temporary action
      // await _authService.toggleUserActiveStatus(user.uid, false);
      // setState(() {});
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Institution Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add New User',
            onPressed: () => _navigateToUserForm(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _authService.getUsersForInstitution(widget.institutionId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print("Error fetching users: ${snapshot.error}");
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No users found in this institution. Add some!'));
                }

                List<UserModel> users = snapshot.data!;
                List<UserModel> filteredUsers = users.where((user) {
                  if (_selectedRoleFilter == "All") return true;
                  return userRoleToString(user.role) == _selectedRoleFilter;
                }).toList();

                if (filteredUsers.isEmpty && _selectedRoleFilter != "All") {
                    return Center(child: Text('No users found for role: $_selectedRoleFilter'));
                }
                if (filteredUsers.isEmpty && users.isNotEmpty) {
                    return const Center(child: Text('No users match the filter.'));
                }


                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    UserModel user = filteredUsers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: ListTile(
                        leading: Icon(
                          user.isActive ? Icons.person : Icons.person_off,
                          color: user.isActive ? Colors.green : Colors.grey,
                        ),
                        title: Text(user.displayName ?? user.email, style: TextStyle(fontWeight: user.isActive ? FontWeight.normal : FontWeight.w300)),
                        subtitle: Text("Role: ${userRoleToString(user.role)} - Email: ${user.email}"),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _navigateToUserForm(user: user);
                            } else if (value == 'toggle_status') {
                              _toggleUserStatus(user);
                            } else if (value == 'delete_user') {
                               _confirmDeleteUser(user);
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: ListTile(leading: Icon(Icons.edit), title: Text('Edit')),
                            ),
                            PopupMenuItem<String>(
                              value: 'toggle_status',
                              child: ListTile(leading: Icon(user.isActive ? Icons.visibility_off : Icons.visibility), title: Text(user.isActive ? 'Deactivate' : 'Activate')),
                            ),
                            // const PopupMenuDivider(),
                            // const PopupMenuItem<String>( // Deletion is complex, placeholder for now
                            //   value: 'delete_user',
                            //   child: ListTile(leading: Icon(Icons.delete_forever, color: Colors.red), title: Text('Delete User', style: TextStyle(color: Colors.red))),
                            // ),
                          ],
                        ),
                        onTap: () => _navigateToUserForm(user: user),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    List<String> roles = ["All", ...getManagableUserRoles().map((r) => userRoleToString(r))];
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 50,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: roles.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            String role = roles[index];
            return ChoiceChip(
              label: Text(role),
              selected: _selectedRoleFilter == role,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedRoleFilter = role;
                  });
                }
              },
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.7),
              labelStyle: TextStyle(color: _selectedRoleFilter == role ? Colors.white : Colors.black),
            );
          },
        ),
      ),
    );
  }
}
