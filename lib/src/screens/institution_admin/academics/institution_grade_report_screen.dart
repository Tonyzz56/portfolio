import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/screens/placeholders/placeholder_screen.dart';

class InstitutionGradeReportScreen extends StatefulWidget {
  // final String institutionId; // This will come from currentUser
  const InstitutionGradeReportScreen({super.key});

  @override
  State<InstitutionGradeReportScreen> createState() => _InstitutionGradeReportScreenState();
}

class _InstitutionGradeReportScreenState extends State<InstitutionGradeReportScreen> {
  // Services needed: GradingService, AcademicService (for class/subject names)
  // Filters: AcademicYear, Term, Class, Subject, Student?

  @override
  Widget build(BuildContext context) {
    final UserModel? currentUser = Provider.of<UserModel?>(context);

    if (currentUser == null || currentUser.role != UserRole.institutionAdmin || currentUser.institutionId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Access Denied")),
        body: const Center(child: Text("You do not have permission or required data is missing.")),
      );
    }

    return const PlaceholderScreen(
      title: "Grade Reports & Analysis (Admin)",
      message: "This screen will allow Institution Administrators to view and generate various grade reports, analyze performance, and manage grading policies.\n\n"
               "Features will include filtering by academic year, term, class, subject, and student.\n"
               "It will display statistics, class averages, student ranking (if applicable), and facilitate report card generation preparation.\n\n"
               "This requires significant backend logic for data aggregation and report formatting, as well as UI for defining grading scales.",
    );
  }
}
