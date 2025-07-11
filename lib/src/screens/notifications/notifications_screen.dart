import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/models/notification_model.dart';
import 'package:school_management_system/src/services/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationService? _notificationService;
  UserModel? _currentUser;
  Stream<List<NotificationModel>>? _notificationsStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure services and user are available before fetching
    final ns = Provider.of<NotificationService?>(context);
    final user = Provider.of<UserModel?>(context);

    if (ns != null && user != null && (_notificationService == null || _currentUser == null)) {
      _notificationService = ns;
      _currentUser = user;
      _loadNotifications();
    } else if (user == null && _currentUser != null) {
      // User logged out, clear stream
      setState(() {
        _currentUser = null;
        _notificationsStream = null;
      });
    }
  }

  void _loadNotifications() {
    if (_currentUser != null && _notificationService != null) {
      setState(() {
        _notificationsStream = _notificationService!.getNotificationsForUser(_currentUser!.uid);
      });
    }
  }

  Future<void> _markNotificationAsRead(String notificationId) async {
    if (_notificationService == null) return;
    await _notificationService!.markAsRead(notificationId);
    // StreamBuilder will rebuild, no explicit setState needed here for the list itself
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    if (_notificationService == null) return;

    if (!notification.isRead) {
      await _notificationService!.markAsRead(notification.id);
    }
    if (notification.routeName != null && notification.routeName!.isNotEmpty) {
      // Ensure context is still valid before navigating
      if (mounted) {
         // Note: Passing complex objects via routeArguments with basic named routes can be tricky.
         // Consider using a proper routing package like GoRouter for type-safe argument passing.
         // For now, assuming arguments are simple Maps or can be handled by target screens.
        Navigator.pushNamed(context, notification.routeName!, arguments: notification.routeArguments);
      }
    } else {
      // Show full notification in a dialog if no route
      if(mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(notification.title),
            content: SingleChildScrollView(child: Text(notification.body)),
            actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Close"))],
          )
        );
      }
    }
  }


  Future<void> _markAllAsRead() async {
    if (_currentUser == null || _notificationService == null) return;
    bool success = await _notificationService!.markAllAsRead(_currentUser!.uid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? "All marked as read." : "Failed to mark all as read."), backgroundColor: success ? Colors.green : Colors.red),
      );
    }
  }

  Future<void> _clearAllNotifications() async {
     if (_currentUser == null || _notificationService == null) return;
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            title: const Text('Confirm Clear All'),
            content: const Text('Are you sure you want to delete all your notifications? This action cannot be undone.'),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
              TextButton(style: TextButton.styleFrom(foregroundColor: Colors.red), onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Clear All')),
            ],
          );
        });

    if (confirm == true) {
        bool success = await _notificationService!.deleteAllNotificationsForUser(_currentUser!.uid);
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(success ? "All notifications cleared." : "Failed to clear notifications."), backgroundColor: success ? Colors.green : Colors.red),
        );
        }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_currentUser == null || _notificationService == null) {
      // This can happen briefly during init or if Provider is not set up correctly higher in the tree.
      return Scaffold(
        appBar: AppBar(title: const Text("Notifications")),
        body: const Center(child: Text("Loading user data or notification service...")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: "Mark all as read",
            onPressed: _markAllAsRead,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: "Clear all notifications",
            onPressed: _clearAllNotifications,
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading notifications: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('You have no notifications.'));
          }

          List<NotificationModel> notifications = snapshot.data!;

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                leading: Icon(
                  notification.isRead ? Icons.notifications_none : Icons.notifications_active,
                  color: notification.isRead ? Colors.grey : Theme.of(context).primaryColor,
                ),
                title: Text(
                  notification.title,
                  style: TextStyle(fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.yMMMd().add_jm().format(notification.createdAt.toLocal()),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                isThreeLine: true,
                onTap: () => _handleNotificationTap(notification),
              );
            },
          );
        },
      ),
    );
  }
}
