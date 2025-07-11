import 'package:flutter/material.dart';
import 'package:school_management_system/src/models/announcement_model.dart';
import 'package:school_management_system/src/models/user_model.dart'; // To get current user's role and institutionId
import 'package:school_management_system/src/services/announcement_service.dart';
import 'package:intl/intl.dart'; // For date formatting
// import 'package:provider/provider.dart'; // To get current user

class ViewAnnouncementsScreen extends StatelessWidget {
  final UserModel currentUser; // Passed in or from Provider

  const ViewAnnouncementsScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final AnnouncementService announcementService = AnnouncementService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
      ),
      body: StreamBuilder<List<Announcement>>(
        // Stream should be tailored to the current user's role and institution
        stream: announcementService.getAnnouncementsForUser(
          userInstitutionId: currentUser.institutionId,
          userRole: currentUser.role,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print('Error fetching announcements: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No announcements available at the moment.'));
          }

          List<Announcement> announcements = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(8.0),
            itemCount: announcements.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              Announcement announcement = announcements[index];
              return Card(
                elevation: 2.0,
                margin: const EdgeInsets.symmetric(vertical: 6.0),
                child: ListTile(
                  title: Text(announcement.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(announcement.content, maxLines: 3, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Text(
                        'By: ${announcement.createdByName} on ${DateFormat.yMMMd().add_jm().format(announcement.publishDate ?? announcement.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (announcement.scope == AnnouncementScope.system)
                        Chip(label: Text('System-Wide', style: TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero)
                      else if (announcement.scope == AnnouncementScope.institution)
                        Chip(label: Text('Institution', style: TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),

                       if (announcement.targetRoles != null && announcement.targetRoles!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top:4.0),
                          child: Text("For: ${announcement.targetRoles!.join(', ')}", style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade600)),
                        )

                    ],
                  ),
                  isThreeLine: true, // Adjust if content makes it taller
                  onTap: () {
                    // Navigate to a detailed view if content is long
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(announcement.title),
                        content: SingleChildScrollView(child: Text(announcement.content)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          )
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      // FloatingActionButton for SuperAdmin or InstitutionAdmin to create announcements
      floatingActionButton: (currentUser.role == UserRole.superAdmin || currentUser.role == UserRole.institutionAdmin)
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateAnnouncementScreen(
                      currentUser: currentUser,
                      institutionId: currentUser.institutionId, // Will be null for SuperAdmin creating system announcement
                    ),
                  ),
                );
              },
              tooltip: 'Create Announcement',
              child: const Icon(Icons.add_comment),
            )
          : null,
    );
  }
}
