import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/services/notification_service.dart';

class AppBarNotificationIcon extends StatelessWidget {
  const AppBarNotificationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserModel?>(context);
    final notificationService = Provider.of<NotificationService?>(context);

    if (currentUser == null || notificationService == null) {
      // If no user or service, don't show the icon or show a disabled state
      return IconButton(
        icon: const Icon(Icons.notifications_none_outlined),
        tooltip: 'Notifications (Unavailable)',
        onPressed: () {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Notifications currently unavailable.")),
          );
        },
      );
    }

    return StreamBuilder<int>(
      stream: notificationService.getUnreadNotificationCount(currentUser.uid),
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData) {
          unreadCount = snapshot.data!;
        }

        return IconButton(
          icon: Badge(
            label: Text(unreadCount > 9 ? '9+' : unreadCount.toString()),
            isLabelVisible: unreadCount > 0,
            child: const Icon(Icons.notifications_outlined),
          ),
          tooltip: 'Notifications ($unreadCount unread)',
          onPressed: () {
            Navigator.pushNamed(context, '/notifications');
          },
        );
      },
    );
  }
}
