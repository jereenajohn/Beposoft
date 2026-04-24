import 'dart:convert';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FinancialReport extends StatefulWidget {
  const FinancialReport({super.key});

  @override
  State<FinancialReport> createState() => _FinancialReportState();
}

class _FinancialReportState extends State<FinancialReport> {
  List<Map<String, dynamic>> Finance = [];

  DateTime? selectedDate; // For single date filter
  DateTime? startDate; // For date range filter
  DateTime? endDate; // For date range filter
  @override
  void initState() {
    super.initState();
    getFinancialReport();
  }

  double totalAdjustedOpeningBalance = 0.0;
  double totalClosingBalance = 0.0;
  double totalTodayPayments = 0.0;
  double totalTodayBanksAmount = 0.0;

  Future<void> getFinancialReport() async {
    final token = await getTokenFromPrefs();
    totalAdjustedOpeningBalance = 0.0;
    totalClosingBalance = 0.0;
    totalTodayPayments = 0.0;
    totalTodayBanksAmount = 0.0;

    try {
      final response = await http.get(
        Uri.parse('$api/api/finance-report/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final DateTime currentDate = DateTime.now();
        final DateTime today =
            DateTime(currentDate.year, currentDate.month, currentDate.day);

        List<Map<String, dynamic>> financeList = [];

        for (var bankData in parsed['bank_data'] ?? []) {
          String bankName = bankData['name'] ?? 'Unknown Bank';

          // Base opening balance
          double openBalance =
              (bankData['open_balance'] as num?)?.toDouble() ?? 0.0;

          // Calculate total payments before today
          double totalPaymentsBeforeDate = (bankData['payments']
                      as List<dynamic>?)
                  ?.where((payment) {
                final receivedAt =
                    DateTime.tryParse(payment['received_at'] ?? '');
                if (receivedAt == null) return false;

                // Normalize the date (remove time)
                final paymentDate =
                    DateTime(receivedAt.year, receivedAt.month, receivedAt.day);

                return paymentDate.isBefore(today);
              }).fold<double>(0.0, (sum, payment) {
                return sum + (double.tryParse(payment['amount'] ?? '') ?? 0.0);
              }) ??
              0.0;

          double totalBankExpensesBeforeDate =
              (bankData['banks'] as List<dynamic>?)?.where((bank) {
                    final expenseDate =
                        DateTime.tryParse(bank['expense_date'] ?? '');
                    if (expenseDate == null) return false;

                    final expenseDay = DateTime(
                        expenseDate.year, expenseDate.month, expenseDate.day);

                    return expenseDay.isBefore(today);
                  }).fold<double>(0.0, (sum, bank) {
                    return sum + (double.tryParse(bank['amount'] ?? '') ?? 0.0);
                  }) ??
                  0.0;

          // Adjusted opening balance
          double adjustedOpeningBalance = openBalance +
              totalPaymentsBeforeDate -
              totalBankExpensesBeforeDate;
          totalAdjustedOpeningBalance += adjustedOpeningBalance;

          // Calculate today's payments
          double todayPayments = (bankData['payments'] as List<dynamic>?)
                  ?.where((payment) {
                final receivedAt =
                    DateTime.tryParse(payment['received_at'] ?? '');
                if (receivedAt == null) return false;

                final paymentDate =
                    DateTime(receivedAt.year, receivedAt.month, receivedAt.day);
                return paymentDate.isAtSameMomentAs(today);
              }).fold<double>(0.0, (sum, payment) {
                return sum + (double.tryParse(payment['amount'] ?? '') ?? 0.0);
              }) ??
              0.0;

          ;
          totalTodayPayments += todayPayments;

          // Handle `banks` for today's expenses
          double todayBanksAmount =
              (bankData['banks'] as List<dynamic>?)?.where((bank) {
                    final expenseDate =
                        DateTime.tryParse(bank['expense_date'] ?? '');
                    if (expenseDate == null) return false;

                    final expenseDay = DateTime(
                        expenseDate.year, expenseDate.month, expenseDate.day);
                    return expenseDay.isAtSameMomentAs(today);
                  }).fold<double>(0.0, (sum, bank) {
                    return sum + (double.tryParse(bank['amount'] ?? '') ?? 0.0);
                  }) ??
                  0.0;

          ;
          totalTodayBanksAmount += todayBanksAmount;

          // Calculate closing balance
          double closingBalance =
              adjustedOpeningBalance + todayPayments - todayBanksAmount;

          totalClosingBalance += closingBalance;

          // Add to finance list
          financeList.add({
            'Bank Name': bankName,
            'Opening Balance': adjustedOpeningBalance.toStringAsFixed(2),
            'Closing Balance': closingBalance.toStringAsFixed(2),
            'Credit': todayPayments.toStringAsFixed(2),
            'Debit': todayBanksAmount.toStringAsFixed(2),
          });
        }

        // Update state to reflect the finance list in UI
        setState(() {
          Finance = List<Map<String, dynamic>>.from(financeList);

          // Ensure totals are updated in UI
          totalAdjustedOpeningBalance = totalAdjustedOpeningBalance;
          totalClosingBalance = totalClosingBalance;
          totalTodayPayments = totalTodayPayments;
          totalTodayBanksAmount = totalTodayBanksAmount;
        });
      } else {
        // Handle error response
        setState(() {
          Finance = [];
        });
      }
    } catch (e) {
      ;
    }
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      getFinancialReport2();
    }
  }

  Future<void> getFinancialReport2() async {
    final token = await getTokenFromPrefs();
    totalAdjustedOpeningBalance = 0.0;
    totalClosingBalance = 0.0;
    totalTodayPayments = 0.0;
    totalTodayBanksAmount = 0.0;

    try {
      final response = await http.get(
        Uri.parse('$api/api/finance-report/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        List<Map<String, dynamic>> financeList = [];

        if (startDate == null || endDate == null) return;

        final normalizedStart =
            DateTime(startDate!.year, startDate!.month, startDate!.day);
        final normalizedEnd =
            DateTime(endDate!.year, endDate!.month, endDate!.day);
        for (var bankData in parsed['bank_data'] ?? []) {
          String bankName = bankData['name'] ?? 'Unknown Bank';
          double openBalance =
              (bankData['open_balance'] as num?)?.toDouble() ?? 0.0;

          // Payments before start date
          double totalPaymentsBeforeStartDate =
              (bankData['payments'] as List<dynamic>? ?? []).where((payment) {
            final date =
                DateTime.tryParse(payment['received_at'] ?? '')?.toLocal();
            if (date == null) return false;
            final d = DateTime(date.year, date.month, date.day);
            return d.isBefore(normalizedStart);
          }).fold(
                  0.0,
                  (sum, payment) =>
                      sum + (double.tryParse(payment['amount'] ?? '') ?? 0.0));
          // Expenses before start date
          double totalExpensesBeforeStartDate =
              (bankData['banks'] as List<dynamic>? ?? []).where((expense) {
            final date =
                DateTime.tryParse(expense['expense_date'] ?? '')?.toLocal();
            if (date == null) return false;
            final d = DateTime(date.year, date.month, date.day);
            return d.isBefore(normalizedStart);
          }).fold(
                  0.0,
                  (sum, expense) =>
                      sum + (double.tryParse(expense['amount'] ?? '') ?? 0.0));
          double adjustedOpeningBalance = openBalance +
              totalPaymentsBeforeStartDate -
              totalExpensesBeforeStartDate;
          // Payments until end date
          double totalPaymentsUntilEndDate =
              (bankData['payments'] as List<dynamic>? ?? []).where((payment) {
            final date =
                DateTime.tryParse(payment['received_at'] ?? '')?.toLocal();
            if (date == null) return false;
            final d = DateTime(date.year, date.month, date.day);
            return !d.isAfter(normalizedEnd);
          }).fold(
                  0.0,
                  (sum, payment) =>
                      sum + (double.tryParse(payment['amount'] ?? '') ?? 0.0));
          // Expenses until end date
          double totalExpensesUntilEndDate =
              (bankData['banks'] as List<dynamic>? ?? []).where((expense) {
            final date =
                DateTime.tryParse(expense['expense_date'] ?? '')?.toLocal();
            if (date == null) return false;
            final d = DateTime(date.year, date.month, date.day);
            return !d.isAfter(normalizedEnd);
          }).fold(
                  0.0,
                  (sum, expense) =>
                      sum + (double.tryParse(expense['amount'] ?? '') ?? 0.0));
          // Payments between start and end date
          double totalPaymentsBetween =
              (bankData['payments'] as List<dynamic>? ?? []).where((payment) {
            final date =
                DateTime.tryParse(payment['received_at'] ?? '')?.toLocal();
            if (date == null) return false;
            final d = DateTime(date.year, date.month, date.day);
            return !d.isBefore(normalizedStart) && !d.isAfter(normalizedEnd);
          }).fold(
                  0.0,
                  (sum, payment) =>
                      sum + (double.tryParse(payment['amount'] ?? '') ?? 0.0));
          // Expenses between start and end date
          double totalExpensesBetween =
              (bankData['banks'] as List<dynamic>? ?? []).where((expense) {
            final date =
                DateTime.tryParse(expense['expense_date'] ?? '')?.toLocal();
            if (date == null) return false;
            final d = DateTime(date.year, date.month, date.day);
            return !d.isBefore(normalizedStart) && !d.isAfter(normalizedEnd);
          }).fold(
                  0.0,
                  (sum, expense) =>
                      sum + (double.tryParse(expense['amount'] ?? '') ?? 0.0));
          double closingBalance = openBalance +
              totalPaymentsUntilEndDate -
              totalExpensesUntilEndDate;
          totalAdjustedOpeningBalance += adjustedOpeningBalance;
          totalClosingBalance += closingBalance;
          totalTodayPayments += totalPaymentsBetween;
          totalTodayBanksAmount += totalExpensesBetween;

          financeList.add({
            'Bank Name': bankName,
            'Base Opening Balance': openBalance.toStringAsFixed(2),
            'Opening Balance': adjustedOpeningBalance.toStringAsFixed(2),
            'Credit Until End Date':
                totalPaymentsUntilEndDate.toStringAsFixed(2),
            'Debit Until End Date':
                totalExpensesUntilEndDate.toStringAsFixed(2),
            'Credit': totalPaymentsBetween.toStringAsFixed(2),
            'Debit': totalExpensesBetween.toStringAsFixed(2),
            'Closing Balance': closingBalance.toStringAsFixed(2),
          });
        }

        setState(() {
          Finance = financeList;
        });
      }
    } catch (e) {}
  }

  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();
    if (dep == "BDO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                bdo_dashbord()), // Replace AnotherPage with your target page
      );
    } else if (dep == "BDM") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                bdm_dashbord()), // Replace AnotherPage with your target page
      );
    } else if (dep == "warehouse") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                WarehouseDashboard()), // Replace AnotherPage with your target page
      );
    } else if (dep == "CEO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ceo_dashboard()), // Replace AnotherPage with your target page
      );
    } else if (dep == "COO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ceo_dashboard()), // Replace AnotherPage with your target page
      );
    } else if (dep == "Warehouse Admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                WarehouseAdmin()), // Replace AnotherPage with your target page
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => dashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent the swipe-back gesture (and back button)
        _navigateBack();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Financial Report',
            style: TextStyle(color: Color.fromARGB(255, 3, 3, 3), fontSize: 16),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back), // Custom back arrow
            onPressed: () async {
              final dep = await getdepFromPrefs();
              if (dep == "BDO") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          bdo_dashbord()), // Replace AnotherPage with your target page
                );
              } else if (dep == "BDM") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          bdm_dashbord()), // Replace AnotherPage with your target page
                );
              } else if (dep == "warehouse") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          WarehouseDashboard()), // Replace AnotherPage with your target page
                );
              } else if (dep == "Warehouse Admin") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          WarehouseAdmin()), // Replace AnotherPage with your target page
                );
              } else if (dep == "CEO") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ceo_dashboard()), // Replace AnotherPage with your target page
                );
              } else if (dep == "COO") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ceo_dashboard()), // Replace AnotherPage with your target page
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          dashboard()), // Replace AnotherPage with your target page
                );
              }
            },
          ),
          actions: [
            IconButton(
              icon: Image.asset('lib/assets/profile.png'),
              onPressed: () {},
            ),
            // IconButton(
            //   icon: Icon(Icons.calendar_today),
            //   onPressed: () => _selectSingleDate(context),
            // ),
            IconButton(
              icon: Icon(Icons.date_range),
              onPressed: () => _selectDateRange(context),
            ),
          ],
        ),
        body: Finance.isEmpty
            ? const Center(
                child:
                    CircularProgressIndicator()) // Show loader while data is being fetched
            : RefreshIndicator(
                onRefresh: getFinancialReport,
                child: Stack(
                  children: [
                    ListView.builder(
                      padding: const EdgeInsets.only(
                          bottom: 160), // Add padding to avoid overlapping
                      itemCount: Finance.length,
                      itemBuilder: (context, index) {
                        final item = Finance[index]; // Current bank data
                        ;
                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.all(8.0),
                          elevation: 4.0,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['Bank Name'] ?? 'Unknown Bank',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Table(
                                  border: TableBorder.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                  columnWidths: const {
                                    0: FlexColumnWidth(1), 
                                    1: FlexColumnWidth(2),
                                  },
                                  children: [
                                    _kvRowBlack(
                                        'OB', '₹${item['Opening Balance']}'),
                                    _kvRowColored(
                                        'Today Credit',
                                        '₹${item['Credit'] ?? '0.0'}',
                                        Colors.blue),
                                    _kvRowColored(
                                        'Today Debit',
                                        '₹${item['Debit'] ?? '0.0'}',
                                        Colors.red),
                                    _kvRowColored(
                                        'CB',
                                        '₹${item['Closing Balance']}',
                                        Colors.green),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Material(
                        elevation: 12,
                        color: const Color.fromARGB(255, 12, 80, 163),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 20),
                          decoration: const BoxDecoration(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                            color: Color.fromARGB(255, 12, 80, 163),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Report Summary',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Divider(
                                color: Colors.white.withOpacity(0.5),
                                thickness: 1,
                              ),

                              /// Table with two rows
                              Table(
                                border: TableBorder.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                                columnWidths: const {
                                  0: FlexColumnWidth(),
                                  1: FlexColumnWidth(2),
                                  2: FlexColumnWidth(),
                                  3: FlexColumnWidth(2),
                                },
                                children: [
                                  _buildTableRow(
                                    'OB',
                                    '₹${totalAdjustedOpeningBalance.toStringAsFixed(2)}',
                                    'CB',
                                    '₹${totalClosingBalance.toStringAsFixed(2)}',
                                  ),
                                  _buildTableRow(
                                    'Credits',
                                    '₹${totalTodayPayments.toStringAsFixed(2)}',
                                    'Debit',
                                    '₹${totalTodayBanksAmount.toStringAsFixed(2)}',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildRowWithTwoColumns(
      String label1, dynamic value1, String label2, dynamic value2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label1,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                Text(
                  value1.toString(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label2,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                Text(
                  value2.toString(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable table row helper
TableRow _buildTableRow(
    String label1, String value1, String label2, String value2) {
  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          label1,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          value1,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          label2,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          value2,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    ],
  );
}

/// Black text key-value row
TableRow _kvRowBlack(String key, String value) {
  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          key,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        ),
      ),
    ],
  );
}

/// Colored value row (for Credit, Debit, Closing Balance)
TableRow _kvRowColored(String key, String value, Color color) {
  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          key,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    ],
  );
}
