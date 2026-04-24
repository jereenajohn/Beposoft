import 'dart:convert';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class EmiReport extends StatefulWidget {
  final int emid;
  const EmiReport({super.key, required this.emid});

  @override
  State<EmiReport> createState() => _EmiReportState();
}

class _EmiReportState extends State<EmiReport> {
  Map<String, dynamic>? emiData;
  List<Map<String, dynamic>> emiPayments = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    getEmiReport();
  }

  Future<String?> getToken() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString('token');
  }

  Future<void> getEmiReport() async {
    final token = await getToken();
    try {
      final response = await http.get(
        Uri.parse('$api/apis/emiexpense/${widget.emid}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        print("============>>>>>$parsed");

        setState(() {
          emiData = {
            'emi_name': parsed['emi_name'],
            'principal': parsed['principal'],
            'tenure_months': parsed['tenure_months'],
            'annual_interest_rate': parsed['annual_interest_rate'],
            'down_payment': parsed['down_payment'],
            'total_amount_paid': parsed['total_amount_paid'],
            'emi_amount': parsed['emi_amount'],
            'total_interest': parsed['total_interest'],
            'total_payment': parsed['total_payment'],
            'startdate': parsed['startdate'],
            'enddate': parsed['enddate'],
          };

          List<Map<String, dynamic>> payments =
              List<Map<String, dynamic>>.from(parsed['emidata']);

          // Process missing months
          emiPayments = fillMissingMonths(payments);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load data';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: $e';
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> fillMissingMonths(
      List<Map<String, dynamic>> payments) {
    if (payments.isEmpty) return [];

    List<Map<String, dynamic>> filledPayments = [];
    payments.sort((a, b) => a['date'].compareTo(b['date'])); // Sort by date

    DateTime startDate = DateTime.parse(payments.first['date']);
    DateTime endDate = DateTime.parse(payments.last['date']);

    // Ensure the set is explicitly of type Set<String>
    Set<String> existingMonths =
        payments.map<String>((p) => p['date'].substring(0, 7)).toSet();
    Map<String, Map<String, dynamic>> paymentMap = {
      for (var payment in payments) payment['date']: payment
    };

    DateTime currentDate = DateTime(startDate.year, startDate.month, 1);

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      String monthKey =
          "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}";

      // If there's an exact date payment in this month, add it
      bool found = false;
      for (var payment in payments) {
        if (payment['date'].startsWith(monthKey)) {
          filledPayments.add(payment);
          found = true;
        }
      }

      // If the month is missing, add a "Pending" entry
      if (!found) {
        filledPayments.add({
          'date': monthKey, // Only Year-Month for missing months
          'amount': 0.0,
        });
      }

      currentDate = DateTime(currentDate.year, currentDate.month + 1, 1);
    }

    return filledPayments;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
        'EMI Report',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      )),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Text(errorMessage!,
                      style: const TextStyle(color: Colors.red)),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEmiDetailsCard(),
                      const SizedBox(height: 20),
                      _buildEmiPaymentsCard(),
                    ],
                  ),
                ),
    );
  }

  /// EMI Details Card
  Widget _buildEmiDetailsCard() {
    double totalPayment = emiData!['total_payment'];
    double totalAmountPaid = emiData!['total_amount_paid'];
    double totalPaymentPending = totalPayment - totalAmountPaid;

    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EMI Details',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.blue),
            ),
            const Divider(),
            _buildDetailRow('EMI Name', emiData!['emi_name']),
            _buildDetailRow('Principal Amount', emiData!['principal']),
            _buildDetailRow('Tenure (Months)', emiData!['tenure_months']),
            _buildDetailRow(
                'Annual Interest Rate', emiData!['annual_interest_rate']),
            _buildDetailRow('Down Payment', emiData!['down_payment']),
            _buildDetailRow('Total Amount Paid', emiData!['total_amount_paid']),
            _buildDetailRow(
              'EMI Amount Per Month',
              emiData!['emi_amount'],
              valueColor: Colors.red,
            ),
            _buildDetailRow('Total Interest', emiData!['total_interest']),
            _buildDetailRow('Total Payment', emiData!['total_payment']),
            _buildDetailRow('Start Date', emiData!['startdate']),
            _buildDetailRow('End Date', emiData!['enddate']),
            _buildDetailRow(
              'Total Payment Pending',
              totalPaymentPending.toStringAsFixed(2), // Ensure 2 decimal places
              valueColor: Colors.red, // Apply red color only to this value
            ),
          ],
        ),
      ),
    );
  }

  /// EMI Payments Card
  Widget _buildEmiPaymentsCard() {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EMI Payments',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.blue),
            ),
            const Divider(),
            ...emiPayments.map((payment) {
              double amount =
                  double.tryParse(payment['amount'].toString()) ?? 0;
              Color amountColor = amount == 0 ? Colors.red : Colors.green;

              return Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.payment, color: amountColor),
                    title: Text(
                      'Date: ${payment['date']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Amount: ₹${payment['amount']}',
                      style: TextStyle(
                          color: amountColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Divider(),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Reusable Row for EMI Details with optional text color
  Widget _buildDetailRow(String title, dynamic value,
      {Color valueColor = Colors.blue}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            value.toString(),
            style: TextStyle(color: valueColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
