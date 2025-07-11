import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_management_system/src/models/institution_model.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/services/institution_service.dart';
import 'package:school_management_system/src/screens/admin/super_admin_dashboard_screen.dart' show DynamicAppDrawer, DashboardCard;
import 'package:school_management_system/src/widgets/app_bar_notification_icon.dart'; // Import new widget


class InstitutionAdminDashboardScreen extends StatefulWidget {
  final String institutionId;

  const InstitutionAdminDashboardScreen({
    super.key,
    required this.institutionId,
  });

  @override
  State<InstitutionAdminDashboardScreen> createState() => _InstitutionAdminDashboardScreenState();
}

class _InstitutionAdminDashboardScreenState extends State<InstitutionAdminDashboardScreen> {
  final InstitutionService _institutionService = InstitutionService();
  Institution? _institution;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInstitutionDetails();
  }

  Future<void> _fetchInstitutionDetails() async {
    setState(() => _isLoading = true);
    try {
      _institution = await _institutionService.getInstitutionById(widget.institutionId);
    } catch (e) {
      print("Error fetching institution details: $e");
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading institution details: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserModel? currentUser = Provider.of<UserModel?>(context);

    if (currentUser == null) {
        return const Scaffold(body: Center(child: Text("User not authenticated.")));
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Institution Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_institution == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load institution details.'),
              ElevatedButton(onPressed: _fetchInstitutionDetails, child: const Text('Retry'))
            ],
          ),
        ),
      );
    }

    String dashboardTitle = "${institutionTypeToString(_institution!.type)} Dashboard";

    return Scaffold(
      appBar: AppBar(
        title: Text(dashboardTitle),
        actions: const [ // Add notification icon
          AppBarNotificationIcon(),
          SizedBox(width: 10),
        ],
      ),
      drawer: const DynamicAppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          _buildHeader(context, currentUser, _institution),
          const SizedBox(height: 20),
          DashboardCard(
            title: 'Manage Users',
            icon: Icons.people,
            onTap: () => Navigator.pushNamed(context, '/institution/manage-users'),
          ),
          DashboardCard(
            title: 'Manage Departments',
            icon: Icons.business_center,
            onTap: () => Navigator.pushNamed(context, '/institution/manage-departments'),
          ),
          DashboardCard(
            title: 'Academic Management',
            icon: Icons.school_outlined,
            onTap: () => Navigator.pushNamed(context, '/institution/academic-settings'),
          ),
          DashboardCard(
            title: 'Post/View Announcements',
            icon: Icons.campaign,
            onTap: () => Navigator.pushNamed(context, '/announcements'),
          ),
          ..._buildDynamicMenuItems(_institution!.type, context, currentUser),
          DashboardCard(
            title: 'Institution Settings',
            icon: Icons.settings,
            onTap: () => Navigator.pushNamed(context, '/institution/settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel currentUser, Institution? institution) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              institution?.name ?? 'Institution Name',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (institution != null) Text("Type: ${institutionTypeToString(institution.type)}"),
            Text("Admin: ${currentUser.displayName ?? currentUser.email}"),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDynamicMenuItems(InstitutionType type, BuildContext context, UserModel currentUser) {
    List<Widget> items = [];

    if (type == InstitutionType.university || type == InstitutionType.college) {
      items.add(DashboardCard(title: 'Manage Courses (Placeholder)', icon: Icons.book, onTap: () {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manage Courses (Not Implemented)')));
      }));
      items.add(DashboardCard(title: 'Exam Scheduling (Placeholder)', icon: Icons.schedule, onTap: () {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exam Scheduling (Not Implemented)')));
      }));
    }
    if (type == InstitutionType.eLearning) {
      items.add(DashboardCard(title: 'Online Course Content (Placeholder)', icon: Icons.video_library, onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Online Courses (Not Implemented)')));
      }));
    }
    return items;
  }
}
