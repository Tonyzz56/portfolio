import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/models/payment_transaction_model.dart';
import 'package:school_management_system/src/services/payment_service.dart';

class PaymentTransactionsLogScreen extends StatefulWidget {
  // final String institutionId; // From currentUser
  const PaymentTransactionsLogScreen({super.key});

  @override
  State<PaymentTransactionsLogScreen> createState() => _PaymentTransactionsLogScreenState();
}

class _PaymentTransactionsLogScreenState extends State<PaymentTransactionsLogScreen> {
  final PaymentService _paymentService = PaymentService();
  UserModel? _currentUser;

  List<PaymentTransactionModel> _transactions = [];
  bool _isLoading = true;
  String? _error;

  // TODO: Add filters: DateTimeRange, PaymentStatus, Student Search
  DateTimeRange? _selectedDateRange;
  PaymentStatus? _selectedStatusFilter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentUser == null) {
      _currentUser = Provider.of<UserModel?>(context);
      if (_currentUser != null && _currentUser!.institutionId != null) {
        _fetchTransactions();
      }
    }
  }

  Future<void> _fetchTransactions() async {
    if (_currentUser == null || _currentUser!.institutionId == null) {
      setStateIfMounted(() { _error = "User or institution data not available."; _isLoading = false; });
      return;
    }
    setStateIfMounted(() { _isLoading = true; _error = null; });

    try {
      _paymentService.getAllTransactionsForInstitution(
        institutionId: _currentUser!.institutionId!,
        startDate: _selectedDateRange?.start,
        endDate: _selectedDateRange?.end,
        status: _selectedStatusFilter,
        limit: 100, // Example limit, add pagination for real app
      ).listen((transactions) {
        if (mounted) {
          setStateIfMounted(() {
            _transactions = transactions;
            _isLoading = false;
          });
        }
      }, onError: (e) {
        if (mounted) {
          setStateIfMounted(() { _error = "Error fetching transactions: ${e.toString()}"; _isLoading = false; });
        }
      });
    } catch (e) {
      if (mounted) {
        setStateIfMounted(() { _error = "Failed to initiate transaction fetching: ${e.toString()}"; _isLoading = false;});
      }
    }
  }

  void setStateIfMounted(VoidCallback f) {
    if (mounted) setState(f);
  }

  // TODO: Implement _pickDateRange and filter UI for status/student

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormatter = NumberFormat.currency(symbol: 'KES ');
    final DateFormat dateTimeFormatter = DateFormat('MMM d, yyyy hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Transaction Logs'),
        // TODO: Add filter button
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center)))
              : _transactions.isEmpty
                  ? const Center(child: Text('No payment transactions found matching current filters.'))
                  : ListView.builder(
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final tx = _transactions[index];
                        IconData statusIcon;
                        Color statusColor;
                        switch (tx.status) {
                            case PaymentStatus.successful: statusIcon = Icons.check_circle; statusColor = Colors.green; break;
                            case PaymentStatus.pending: statusIcon = Icons.hourglass_empty; statusColor = Colors.orange; break;
                            case PaymentStatus.failed: statusIcon = Icons.error; statusColor = Colors.red; break;
                            case PaymentStatus.refunded: statusIcon = Icons.undo; statusColor = Colors.blueGrey; break;
                            case PaymentStatus.cancelled: statusIcon = Icons.cancel; statusColor = Colors.grey; break;
                            default: statusIcon = Icons.help; statusColor = Colors.grey;
                        }
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: ListTile(
                            leading: Icon(statusIcon, color: statusColor),
                            title: Text("${paymentMethodToString(tx.paymentMethod)} - ${currencyFormatter.format(tx.amountPaid)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Student UID: ${tx.studentUid.substring(0,6)}..."), // TODO: Display Student Name
                                Text("Date: ${dateTimeFormatter.format(tx.paymentDate.toLocal())}"),
                                Text("Ref: ${tx.transactionReference ?? tx.paymentGatewayCheckoutId ?? 'N/A'}"),
                                Text("Status: ${paymentStatusToString(tx.status).toUpperCase()}"),
                                if (tx.notes != null && tx.notes!.isNotEmpty) Text("Notes: ${tx.notes}"),
                                Text("Recorded by: ${tx.recordedByUid.substring(0,6)}...", style: TextStyle(fontSize: 10, color: Colors.grey.shade600)), // TODO: Display Recorder Name
                              ],
                            ),
                            isThreeLine: true, // Adjust based on content
                            // onTap: () { /* View more details? */ },
                          ),
                        );
                      },
                    ),
    );
  }
}
