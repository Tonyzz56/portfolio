import 'package:flutter/material.dart';
import 'package:school_management_system/src/models/subscription_package_model.dart';
import 'package:school_management_system/src/services/subscription_service.dart';
import 'subscription_package_form_screen.dart';

class ManageSubscriptionPackagesScreen extends StatefulWidget {
  const ManageSubscriptionPackagesScreen({super.key});

  @override
  State<ManageSubscriptionPackagesScreen> createState() => _ManageSubscriptionPackagesScreenState();
}

class _ManageSubscriptionPackagesScreenState extends State<ManageSubscriptionPackagesScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();

  void _navigateToForm({SubscriptionPackageModel? package}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubscriptionPackageFormScreen(package: package),
      ),
    ).then((_) => setState(() {})); // Refresh list on return
  }

  Future<void> _toggleActiveStatus(SubscriptionPackageModel package) async {
    bool success = await _subscriptionService.togglePackageActiveStatus(package.id, !package.isActive);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Package ${package.name} status updated.'), backgroundColor: success ? Colors.green : Colors.red),
      );
      if (success) setState(() {});
    }
  }

  Future<void> _confirmDelete(SubscriptionPackageModel package) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to permanently delete package "${package.name}"? This action cannot be undone. Ensure no institutions are currently using this package.'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete Permanently'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        bool success = await _subscriptionService.deletePackageHard(package.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Package "${package.name}" permanently deleted.'), backgroundColor: Colors.green),
          );
          if (success) setState(() {});
        }
      } catch (e) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete "${package.name}": ${e.toString()}'), backgroundColor: Colors.red),
            );
         }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Subscription Packages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add New Package',
            onPressed: () => _navigateToForm(),
          ),
        ],
      ),
      body: StreamBuilder<List<SubscriptionPackageModel>>(
        stream: _subscriptionService.getPackages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No subscription packages found. Add one!'));
          }

          List<SubscriptionPackageModel> packages = snapshot.data!;

          return ListView.builder(
            itemCount: packages.length,
            itemBuilder: (context, index) {
              SubscriptionPackageModel package = packages[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  title: Text(package.name, style: TextStyle(fontWeight: package.isActive ? FontWeight.bold : FontWeight.normal)),
                  subtitle: Text('${package.currency} ${package.price.toStringAsFixed(2)} / ${billingCycleToString(package.billingCycle)}\nFeatures: ${package.features.take(2).join(', ')}${package.features.length > 2 ? '...' : ''}\nMax Students: ${package.maxStudents ?? 'N/A'}, Max Staff: ${package.maxStaff ?? 'N/A'}'),
                  isThreeLine: true,
                  leading: Icon(package.isActive ? Icons.check_circle : Icons.cancel, color: package.isActive ? Colors.green : Colors.grey),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _navigateToForm(package: package);
                      } else if (value == 'toggle_status') {
                        _toggleActiveStatus(package);
                      } else if (value == 'delete_hard') {
                        _confirmDelete(package);
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(leading: Icon(Icons.edit), title: Text('Edit')),
                      ),
                      PopupMenuItem<String>(
                        value: 'toggle_status',
                        child: ListTile(leading: Icon(package.isActive ? Icons.visibility_off : Icons.visibility), title: Text(package.isActive ? 'Deactivate' : 'Activate')),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'delete_hard',
                        child: ListTile(leading: Icon(Icons.delete_forever, color: Colors.red), title: Text('Delete Permanently', style: TextStyle(color: Colors.red))),
                      ),
                    ],
                  ),
                  onTap: () => _navigateToForm(package: package),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
