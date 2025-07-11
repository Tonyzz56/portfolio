import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_management_system/src/models/user_model.dart';
// import 'package:school_management_system/src/screens/student/student_my_attendance_screen.dart'; // For navigation with args
// import 'package:school_management_system/src/services/auth_service.dart'; // Or UserService to fetch child details by UID

class ParentMyChildrenScreen extends StatefulWidget {
  const ParentMyChildrenScreen({super.key});

  @override
  State<ParentMyChildrenScreen> createState() => _ParentMyChildrenScreenState();
}

class _ParentMyChildrenScreenState extends State<ParentMyChildrenScreen> {
  // List<UserModel> _childrenDetails = []; // In future, populate this by fetching UserModels for each childUid
  // bool _isLoadingChildren = true;

  @override
  void initState() {
    super.initState();
    // final currentUser = Provider.of<UserModel?>(context, listen: false);
    // if (currentUser != null && currentUser.childUids != null && currentUser.childUids!.isNotEmpty) {
    //   _fetchChildrenDetails(currentUser.childUids!);
    // } else {
    //   if(mounted) setState(() => _isLoadingChildren = false);
    // }
  }

  // Future<void> _fetchChildrenDetails(List<String> childUids) async {
  //   // setState(() => _isLoadingChildren = true);
  //   // try {
  //   //   // final authService = Provider.of<AuthService>(context, listen: false); // or UserService
  //   //   List<UserModel> details = [];
  //   //   for (String uid in childUids) {
  //   //     // UserModel? child = await authService.getUserById(uid); // Assuming getUserById exists
  //   //     // if (child != null) details.add(child);
  //   //     // For placeholder:
  //   //     details.add(UserModel(uid: uid, email: "child@email.com", displayName: "Child $uid", role: UserRole.student, createdAt: DateTime.now(), updatedAt: DateTime.now()));
  //   //   }
  //   //   if(mounted) setState(() => _childrenDetails = details);
  //   // } catch (e) {
  //   //    if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching children details: $e")));
  //   // } finally {
  //   //    if(mounted) setState(() => _isLoadingChildren = false);
  //   // }
  // }

  void _navigateToChildAttendance(BuildContext context, String childUid, String? childName) {
    Navigator.pushNamed(
      context,
      '/student/my-attendance',
      arguments: {'childUid': childUid, 'childNameForParentView': childName ?? 'Child'},
    );
  }

  void _navigateToChildGrades(BuildContext context, String childUid, String? childName) {
     Navigator.pushNamed(
      context,
      '/student/my-grades',
      arguments: {'childUid': childUid, 'childNameForParentView': childName ?? 'Child'},
    );
  }


  @override
  Widget build(BuildContext context) {
    final UserModel? currentUser = Provider.of<UserModel?>(context);

    if (currentUser == null || currentUser.role != UserRole.parent) {
      return Scaffold(
        appBar: AppBar(title: const Text("Access Denied")),
        body: const Center(child: Text("You do not have permission to view this page.")),
      );
    }

    // if (_isLoadingChildren) {
    //   return Scaffold(appBar: AppBar(title: const Text("My Children")), body: const Center(child: CircularProgressIndicator()));
    // }

    final List<String> childUids = currentUser.childUids ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Children'),
      ),
      body: childUids.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No children are currently linked to your account. Please contact the school administration if this is incorrect or to link your children.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          : ListView.builder(
              itemCount: childUids.length,
              itemBuilder: (context, index) {
                final childUid = childUids[index];
                // TODO: Fetch actual child name and class for display using a FutureBuilder or similar per list item.
                // For now, just using UID.
                // Example: final childDetail = _childrenDetails.firstWhere((c) => c.uid == childUid, orElse: () => UserModel(uid: childUid, email: '', displayName: 'Child (Loading...)', role: UserRole.student, createdAt: DateTime.now(), updatedAt: DateTime.now()));

                String childDisplayName = "Child (UID: ${childUid.substring(0, 6)}...)";
                // String childDisplayName = childDetail.displayName ?? "Child ${childUid.substring(0,6)}";


                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.child_care, size: 30),
                    title: Text(childDisplayName),
                    // subtitle: Text("Class: ${childDetail.currentClassId ?? 'N/A'}"), // Requires fetching class name
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'view_attendance') {
                          _navigateToChildAttendance(context, childUid, childDisplayName);
                        } else if (value == 'view_grades') {
                           _navigateToChildGrades(context, childUid, childDisplayName);
                        }
                        // Add more actions like view timetable, view profile etc.
                        // These would also pass childUid as argument to respective student screens.
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'view_attendance',
                          child: ListTile(leading: Icon(Icons.event_available), title: Text('View Attendance')),
                        ),
                        const PopupMenuItem<String>(
                          value: 'view_grades',
                          child: ListTile(leading: Icon(Icons.assessment_outlined), title: Text('View Grades')),
                        ),
                        // const PopupMenuItem<String>(value: 'view_timetable', child: Text('View Timetable')),
                      ],
                    ),
                    onTap: () {
                       // Default action could be to show a summary or navigate to the first available option.
                       _navigateToChildAttendance(context, childUid, childDisplayName);
                    },
                  ),
                );
              },
            ),
    );
  }
}
