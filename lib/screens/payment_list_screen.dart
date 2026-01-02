import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/PaymentService.dart';

class PaymentListScreen extends StatefulWidget {
  const PaymentListScreen({super.key});

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  final PaymentService _paymentService = PaymentService();
  List<dynamic> _payments = [];
  List<dynamic> _enrollments = [];
  bool _isLoading = true;
  bool _showAllRecords = false; // Toggle between paid only and all

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    setState(() => _isLoading = true);
    final result = await _paymentService.getAllEnrollmentsWithPayments();
    if (mounted) {
      if (result['success']) {
        setState(() {
          _enrollments = result['enrollments'];
          _updatePaymentsList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    }
  }

  void _updatePaymentsList() {
    if (_showAllRecords) {
      _payments = _enrollments;
    } else {
      _payments = _enrollments
          .where((e) => e['payment_status'] == 1 || e['payment_status'] == true)
          .toList();
    }
  }

  void _togglePaymentStatus(String enrollmentId) async {
    final result = await _paymentService.togglePaymentStatus(enrollmentId);
    if (mounted) {
      if (result['success']) {
        _fetchPayments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final parsedDate = DateTime.parse(date.toString());
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0 VND';
    try {
      final value = int.parse(amount.toString());
      return '$value VND';
    } catch (e) {
      return '$amount VND';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Records'),
        elevation: 2,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Tooltip(
                message: _showAllRecords ? 'Showing all records' : 'Showing paid only',
                child: FilterChip(
                  selected: _showAllRecords,
                  label: Text(_showAllRecords ? 'All Records' : 'Paid Only'),
                  onSelected: (bool value) {
                    setState(() {
                      _showAllRecords = value;
                      _updatePaymentsList();
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchPayments,
              child: _payments.isEmpty
                  ? Center(
                      child: Text(
                        _showAllRecords
                            ? 'No payment records found'
                            : 'No paid payments found',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _payments.length,
                      itemBuilder: (context, index) {
                        final payment = _payments[index];
                        final bool isPaid =
                            payment['payment_status'] == 1 ||
                            payment['payment_status'] == true;
                        final String paymentDate =
                            _formatDate(payment['payment_date']);
                        final String amount =
                            _formatCurrency(payment['tuition_fee']);

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          elevation: 2,
                          child: ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color:
                                    isPaid
                                        ? Colors.green.withAlpha(50)
                                        : Colors.orange.withAlpha(50),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(
                                  isPaid ? Icons.check_circle : Icons.pending,
                                  color: isPaid ? Colors.green : Colors.orange,
                                  size: 30,
                                ),
                              ),
                            ),
                            title: Text(
                              payment['student_name'] ?? 'Unknown Student',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Class: ${payment['class_name'] ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  'Amount: $amount',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Date: $paymentDate',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Chip(
                                  label: Text(
                                    isPaid ? 'Paid' : 'Unpaid',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor:
                                      isPaid ? Colors.green : Colors.orange,
                                ),
                              ],
                            ),
                            onTap: () {
                              _showPaymentDetails(context, payment, isPaid);
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  void _showPaymentDetails(BuildContext context, dynamic payment, bool isPaid) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _detailRow('Student', payment['student_name'] ?? 'N/A'),
            _detailRow('Class', payment['class_name'] ?? 'N/A'),
            _detailRow('Amount', _formatCurrency(payment['tuition_fee'])),
            _detailRow('Payment Date', _formatDate(payment['payment_date'])),
            _detailRow(
              'Status',
              isPaid ? 'Paid' : 'Unpaid',
              valueColor: isPaid ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _togglePaymentStatus(payment['id'].toString());
                  },
                  icon: Icon(isPaid ? Icons.undo : Icons.check),
                  label: Text(isPaid ? 'Mark Unpaid' : 'Mark Paid'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPaid ? Colors.orange : Colors.green,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

