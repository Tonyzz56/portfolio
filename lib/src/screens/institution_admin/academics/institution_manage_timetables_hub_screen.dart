import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/screens/placeholders/placeholder_screen.dart';
// import 'manage_academic_years_screen.dart'; // To select year -> term -> class

class InstitutionManageTimetablesHubScreen extends StatelessWidget {
  const InstitutionManageTimetablesHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserModel? currentUser = Provider.of<UserModel?>(context);

    if (currentUser == null || currentUser.role != UserRole.institutionAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text("Access Denied")),
        body: const Center(child: Text("You do not have permission to view this page.")),
      );
    }

    return PlaceholderScreen(
      title: "Manage Timetables (Admin)",
      message: "This hub will allow Institution Administrators to manage timetables.\n\n"
               "Typically, you will first select an Academic Year, then a Term (if applicable), "
               "and then a Class to view or edit its timetable.\n\n"
               "Navigation to select these will be added here, likely by navigating to 'Manage Academic Years' first, "
               "then drilling down to the specific class's timetable management.",
      // child: ElevatedButton(
      //   onPressed: () {
      //     // Navigator.push(context, MaterialPageRoute(builder: (context) => ManageAcademicYearsScreen(institutionId: currentUser.institutionId!)));
      //   },
      //   child: Text("Go to Manage Academic Years to Select Class"),
      // ),
    );
  }
}
