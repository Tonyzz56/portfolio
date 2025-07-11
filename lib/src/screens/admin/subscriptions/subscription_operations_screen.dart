import 'package:flutter/material.dart';
import 'package:school_management_system/src/services/institution_subscription_processor_service.dart';
import 'package:school_management_system/src/models/batch_process_result_model.dart';

class SubscriptionOperationsScreen extends StatefulWidget {
  const SubscriptionOperationsScreen({super.key});

  @override
  State<SubscriptionOperationsScreen> createState() => _SubscriptionOperationsScreenState();
}

class _SubscriptionOperationsScreenState extends State<SubscriptionOperationsScreen> {
  final InstitutionSubscriptionProcessorService _processorService = InstitutionSubscriptionProcessorService();
  bool _isProcessing = false;
  StringBuffer _processLogBuffer = StringBuffer();
  BatchProcessResult? _lastResult;

  void _log(String message) {
    if (mounted) {
      setState(() {
        _processLogBuffer.writeln(message);
      });
    }
    print(message); // Also print to console for debugging
  }

  Future<void> _runSubscriptionChecks() async {
    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _processLogBuffer.clear();
      _lastResult = null;
    });
    _log("Starting subscription status processing...");

    try {
      final result = await _processorService.processAllInstitutions(
        onProgress: (message) {
          _log(message);
        },
      );
      if (mounted) {
        setState(() {
          _lastResult = result;
          _log("\n--- Processing Summary ---");
          _log(result.toDisplayString());
        });
      }
    } catch (e, s) {
      _log("An unexpected error occurred: $e");
      _log("Stack trace: $s");
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Critical error during processing: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Operations'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Manual Subscription Processing',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'This tool allows you to manually trigger the process that checks institution subscription statuses, updates them (e.g., to grace_period or suspended if expired), and triggers relevant email notifications. This is typically run automatically by the system, but can be triggered here if needed.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.published_with_changes_rounded),
                  label: const Text('Run Subscription Status Checks'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    textStyle: const TextStyle(fontSize: 16),
                    // backgroundColor: Colors.orangeAccent, // Example color
                  ),
                  onPressed: _runSubscriptionChecks,
                ),
              ),
            const SizedBox(height: 24),
            if (_processStatus.isNotEmpty) ...[
              Text(
                'Processing Log:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12.0),
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 100, maxHeight: 400),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _processStatus,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ],
            // TODO: Display formatted _lastResult when available
          ],
        ),
      ),
    );
  }
}
