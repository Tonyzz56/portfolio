import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/screens/placeholders/placeholder_screen.dart';

class StudentMyTimetableScreen extends StatelessWidget {
  const StudentMyTimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserModel? currentUser = Provider.of<UserModel?>(context);

    if (currentUser == null || currentUser.role != UserRole.student) {
      // Timetable is usually specific to the student, not directly viewed by parent in this format.
      // Parents might see a combined schedule or child's timetable via child's profile.
      return Scaffold(
        appBar: AppBar(title: const Text("Access Denied")),
        body: const Center(child: Text("You do not have permission to view this page directly. Parents can view child's schedule via their profile.")),
      );
    }

    // Real implementation:
    // 1. Fetch the student's class timetable.
    // 2. Display it in a weekly or daily view.

    return const PlaceholderScreen(
      title: 'My Timetable',
      message: 'This screen will display your weekly class schedule, showing subjects, timings, and teachers.\n\n'
               'Full timetable functionality will be implemented as part of the Timetable Module.',
    );
  }
}
