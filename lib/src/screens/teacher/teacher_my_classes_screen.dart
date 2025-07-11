import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/screens/placeholders/placeholder_screen.dart'; // Using the generic placeholder

class TeacherMyClassesScreen extends StatelessWidget {
  const TeacherMyClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserModel? currentUser = Provider.of<UserModel?>(context);

    if (currentUser == null || currentUser.role != UserRole.teacher) {
      // This screen should only be accessible by teachers.
      // AuthWrapper and route guards should ideally prevent this state.
      return Scaffold(
        appBar: AppBar(title: const Text("Access Denied")),
        body: const Center(child: Text("You do not have permission to view this page.")),
      );
    }

    // In a real implementation, this screen would:
    // 1. Fetch the classes/subjects assigned to this teacher (currentUser.uid or currentUser.staffId).
    // 2. List these classes/subjects.
    // 3. Allow navigation to view students in a class, manage class-specific materials, etc.

    return const PlaceholderScreen(
      title: 'My Classes & Students',
      message: 'This screen will list the classes and subjects assigned to you, '
               'and allow you to view enrolled students for each.\n\n'
               'Functionality to be implemented in a later Academic Management phase.',
    );
  }
}
