import 'package:flutter/material.dart';

class BankMonthlyReportPage extends StatefulWidget {
  final Map<String, dynamic> bankData;
  final int bankId;

  const BankMonthlyReportPage({
    super.key,
    required this.bankData,
    required this.bankId,
  });

  @override
  State<BankMonthlyReportPage> createState() => _BankMonthlyReportPageState();
}

class _BankMonthlyReportPageState extends State<BankMonthlyReportPage> {
  DateTimeRange? selectedRange;

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  DateTime _parseDate(String dateStr) {
    return DateTime.parse(dateStr);
  }

  Future<void> pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: selectedRange,
    );

    if (picked != null) {
      setState(() {
        selectedRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String bankName = widget.bankData["bank_name"] ?? "";
    List dailyData = widget.bankData["daily_data"] ?? [];

    // Sort daily data by date
    dailyData.sort((a, b) => a["date"].compareTo(b["date"]));

    List filteredData = [];

    if (selectedRange == null) {
      // Default show latest month data
      String latestMonth = "";
      if (dailyData.isNotEmpty) {
        latestMonth = dailyData.last["date"].toString().substring(0, 7);
      }

      filteredData = dailyData.where((d) {
        return d["date"].toString().startsWith(latestMonth);
      }).toList();
    } else {
      filteredData = dailyData.where((d) {
        DateTime dayDate = _parseDate(d["date"].toString());

        return dayDate.isAfter(selectedRange!.start.subtract(const Duration(days: 1))) &&
            dayDate.isBefore(selectedRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: Text(
          "$bankName (OD Account)",
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.black),
            onPressed: pickDateRange,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: filteredData.isEmpty
            ? const Center(
                child: Text(
                  "No Data Available",
                  style: TextStyle(fontSize: 16),
                ),
              )
            : ListView.builder(
                itemCount: filteredData.length,
                itemBuilder: (context, index) {
                  final day = filteredData[index];

                  double opening =
                      double.tryParse(day["opening"].toString()) ?? 0;

                  double closing =
                      double.tryParse(day["closing"].toString()) ?? 0;

                  double credit =
                      double.tryParse(day["total_credit"].toString()) ?? 0;

                  double debit =
                      double.tryParse(day["total_debit"].toString()) ?? 0;

                  double dailyInterest =
                      double.tryParse(day["daily_interest"].toString()) ?? 0;

                  double totalInterest =
                      double.tryParse(day["total_interest"].toString()) ?? 0;

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF02347C),
                            Color(0xFF82E49D),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Date: ${day["date"]}",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Table(
                              border: TableBorder.all(
                                color: Colors.white,
                                width: 1.2,
                              ),
                              children: [
                                TableRow(
                                  decoration: const BoxDecoration(
                                    color: Colors.black26,
                                  ),
                                  children: [
                                    _buildTableHeader("Opening"),
                                    _buildTableHeader("Closing"),
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    _buildTableCell(
                                        "₹${opening.toStringAsFixed(2)}"),
                                    _buildTableCell(
                                        "₹${closing.toStringAsFixed(2)}"),
                                  ],
                                ),
                                TableRow(
                                  decoration: const BoxDecoration(
                                    color: Colors.black26,
                                  ),
                                  children: [
                                    _buildTableHeader("Credit"),
                                    _buildTableHeader("Debit"),
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    _buildTableCell(
                                        "₹${credit.toStringAsFixed(2)}"),
                                    _buildTableCell(
                                        "₹${debit.toStringAsFixed(2)}"),
                                  ],
                                ),
                                TableRow(
                                  decoration: const BoxDecoration(
                                    color: Colors.black26,
                                  ),
                                  children: [
                                    _buildTableHeader("Daily Interest"),
                                    _buildTableHeader("Total Interest"),
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    _buildTableCell(
                                        "₹${dailyInterest.toStringAsFixed(4)}"),
                                    _buildTableCell(
                                        "₹${totalInterest.toStringAsFixed(4)}"),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
