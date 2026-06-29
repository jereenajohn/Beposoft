import 'dart:convert';

import 'package:beposoft/pages/ACCOUNTS/creditsale_date_report.dart';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Creditsalereport2 extends StatefulWidget {
  const Creditsalereport2({super.key});

  @override
  State<Creditsalereport2> createState() => _Creditsalereport2State();
}

class _Creditsalereport2State extends State<Creditsalereport2> {
  List<Map<String, dynamic>> allSalesReportList = [];
  List<Map<String, dynamic>> fam = [];
  List<Map<String, dynamic>> sta = [];
  List<Map<String, dynamic>> allStaff = [];

  double totalAmount = 0.0;
  int totalOrders = 0;
  double totalPaidAmount = 0.0;
  double balanceAmount = 0.0;

  bool isLoading = false;

  DateTime? selectedDate;
  DateTime? startDate;
  DateTime? endDate;

  String? selectedFamily;
  String? selectedStaff;

  drower d = drower();

  @override
  void initState() {
    super.initState();
    getfamily();
    getstaff();
    getCreditsaleReport();
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<void> getstaff() async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/staffs/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      debugPrint('STAFF STATUS: ${response.statusCode}');
      debugPrint('STAFF BODY: ${response.body}');

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var staffData = parsed['data'] ?? [];

        setState(() {
          allStaff = List<Map<String, dynamic>>.from(staffData);
        });

        filterStaffByFamily();
      }
    } catch (error) {
      debugPrint('STAFF FETCH ERROR: $error');
    }
  }

  void filterStaffByFamily() {
    List<Map<String, dynamic>> filteredStaff = [];

    for (var staff in allStaff) {
      if (selectedFamily == null || staff['family_name'] == selectedFamily) {
        filteredStaff.add({
          'id': staff['id'],
          'name': staff['name'],
        });
      }
    }

    setState(() {
      sta = filteredStaff;
      selectedStaff = null;
    });
  }

  Future<void> getfamily() async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/familys/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      debugPrint('FAMILY STATUS: ${response.statusCode}');
      debugPrint('FAMILY BODY: ${response.body}');

      List<Map<String, dynamic>> familylist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'] ?? [];

        for (var productData in productsData) {
          familylist.add({
            'id': productData['id'],
            'name': productData['name'],
          });
        }

        setState(() {
          fam = familylist;
        });
      }
    } catch (error) {
      debugPrint('FAMILY FETCH ERROR: $error');
    }
  }

  Future<void> getCreditsaleReport() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final token = await getTokenFromPrefs();

      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() {
            allSalesReportList = [];
            totalOrders = 0;
            totalAmount = 0.0;
            totalPaidAmount = 0.0;
            balanceAmount = 0.0;
            isLoading = false;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication token missing')),
        );
        return;
      }

      final response = await http.get(
        Uri.parse('$api/api/credit/sales/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      debugPrint('CREDIT STATUS: ${response.statusCode}');
      debugPrint('CREDIT BODY: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final List<dynamic> salesData =
            decoded is List ? decoded : (decoded['data'] ?? []);

        final List<Map<String, dynamic>> salesReportDataList = [];

        double grandTotalAmount = 0.0;
        int grandTotalOrders = 0;
        double grandTotalPaidAmount = 0.0;
        double grandBalanceAmount = 0.0;

        for (final reportData in salesData) {
          final String dateStr = reportData['date']?.toString() ?? 'Unknown';
          final DateTime reportDate =
              DateTime.tryParse(dateStr) ?? DateTime(1900);

          if (startDate != null && endDate != null) {
            final bool outOfRange = reportDate.isBefore(
                  DateTime(startDate!.year, startDate!.month, startDate!.day),
                ) ||
                reportDate.isAfter(
                  DateTime(
                    endDate!.year,
                    endDate!.month,
                    endDate!.day,
                    23,
                    59,
                    59,
                  ),
                );

            if (outOfRange) continue;
          }

          final List<dynamic> orders =
              reportData['orders'] is List ? reportData['orders'] : [];

          List<dynamic> filteredOrders = orders;

          if (selectedFamily != null && selectedFamily!.isNotEmpty) {
            filteredOrders = filteredOrders.where((order) {
              return order['family_name']?.toString() == selectedFamily;
            }).toList();
          }

          if (selectedStaff != null && selectedStaff!.isNotEmpty) {
            filteredOrders = filteredOrders.where((order) {
              return order['staff_name']?.toString() == selectedStaff;
            }).toList();
          }

          double dateTotalAmount = 0.0;
          int dateTotalOrders = 0;
          double dateTotalPaidAmount = 0.0;
          double dateBalanceAmount = 0.0;

          for (final order in filteredOrders) {
            dateTotalOrders++;

            final double orderAmount =
                double.tryParse(order['total_amount']?.toString() ?? '0') ??
                    0.0;

            double totalReceivedPayment = 0.0;

            final List<dynamic> receivedPayments =
                order['recived_payment'] is List
                    ? order['recived_payment']
                    : [];

            for (final payment in receivedPayments) {
              totalReceivedPayment +=
                  double.tryParse(payment['amount']?.toString() ?? '0') ?? 0.0;
            }

            dateTotalAmount += orderAmount;
            dateTotalPaidAmount += totalReceivedPayment;
            dateBalanceAmount += (orderAmount - totalReceivedPayment);
          }

          if (filteredOrders.isNotEmpty) {
            salesReportDataList.add({
              'date': dateStr,
              'total_amount': dateTotalAmount,
              'total_orders': dateTotalOrders,
              'total_paid_amount': dateTotalPaidAmount,
              'balance_amount': dateBalanceAmount,
            });

            grandTotalOrders += dateTotalOrders;
            grandTotalAmount += dateTotalAmount;
            grandTotalPaidAmount += dateTotalPaidAmount;
            grandBalanceAmount += dateBalanceAmount;
          }
        }

        if (mounted) {
          setState(() {
            allSalesReportList = salesReportDataList;
            totalOrders = grandTotalOrders;
            totalAmount = grandTotalAmount;
            totalPaidAmount = grandTotalPaidAmount;
            balanceAmount = grandBalanceAmount;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            allSalesReportList = [];
            totalOrders = 0;
            totalAmount = 0.0;
            totalPaidAmount = 0.0;
            balanceAmount = 0.0;
            isLoading = false;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch sales report (${response.statusCode})'),
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('CREDIT SALE ERROR: $error');
      debugPrint('CREDIT SALE STACK: $stackTrace');

      if (mounted) {
        setState(() {
          allSalesReportList = [];
          totalOrders = 0;
          totalAmount = 0.0;
          totalPaidAmount = 0.0;
          balanceAmount = 0.0;
          isLoading = false;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Credit sale error: $error')),
      );
    }
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

      getCreditsaleReport();
    }
  }

  void _resetFilters() {
    setState(() {
      selectedFamily = null;
      selectedStaff = null;
      startDate = null;
      endDate = null;
    });

    filterStaffByFamily();
    getCreditsaleReport();
  }

  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();

    if (dep == "BDO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => bdo_dashbord()),
      );
    } else if (dep == "BDM") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => bdm_dashbord()),
      );
    } else if (dep == "warehouse") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WarehouseDashboard()),
      );
    } else if (dep == "Warehouse Admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WarehouseAdmin()),
      );
    } else if (dep == "CEO" || dep == "COO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ceo_dashboard()),
      );
    } else if (dep == "CSO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => cso_dashboard()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => dashboard()),
      );
    }
  }

  Widget _buildFamilyDropdown() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Select Family',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.blue, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.grey, width: 1.5),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Text("Select Family"),
          value: selectedFamily,
          onChanged: (String? newValue) {
            setState(() {
              selectedFamily = newValue;
              selectedStaff = null;
            });

            filterStaffByFamily();
            getCreditsaleReport();
          },
          items: fam.map((family) {
            return DropdownMenuItem<String>(
              value: family['name'],
              child: Text(
                family['name'],
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStaffDropdown() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Select Staff',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.blue, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.grey, width: 1.5),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Text("Select Staff"),
          value: selectedStaff,
          onChanged: (String? newValue) {
            setState(() {
              selectedStaff = newValue;
            });

            getCreditsaleReport();
          },
          items: sta.map((staff) {
            return DropdownMenuItem<String>(
              value: staff['name'],
              child: Text(
                staff['name'],
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (isLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (allSalesReportList.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'No data found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 180),
        itemCount: allSalesReportList.length,
        itemBuilder: (context, index) {
          final report = allSalesReportList[index];

          return Card(
            color: Colors.white,
            margin: const EdgeInsets.all(8.0),
            elevation: 5.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date: ${report['date']}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Divider(color: Colors.grey),
                  Table(
                    border: TableBorder.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(3),
                    },
                    children: [
                      _buildCardTableRow(
                        'Total Orders',
                        '${report['total_orders']}',
                      ),
                      _buildCardTableRow(
                        'Total Amount',
                        '₹${(report['total_amount'] as num).toStringAsFixed(2)}',
                      ),
                      _buildCardTableRow(
                        'Total Paid Amount',
                        '₹${(report['total_paid_amount'] as num).toStringAsFixed(2)}',
                      ),
                      _buildCardTableRow(
                        'Balance Amount',
                        '₹${(report['balance_amount'] as num).toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreditsaleDateReport(
                              date: report['date'],
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        "View",
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Material(
      elevation: 12,
      color: const Color.fromARGB(255, 12, 80, 163),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
            Table(
              border: TableBorder.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
              columnWidths: const {
                0: FlexColumnWidth(1.2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(2),
              },
              children: [
                _buildTableRow(
                  'TO',
                  '$totalOrders',
                  'TA',
                  '₹${totalAmount.toStringAsFixed(2)}',
                ),
                _buildTableRow(
                  'TPA',
                  '₹${totalPaidAmount.toStringAsFixed(2)}',
                  'BA',
                  '₹${balanceAmount.toStringAsFixed(2)}',
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Credit Sale Report',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _navigateBack,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetFilters,
            ),
            IconButton(
              icon: const Icon(Icons.date_range),
              onPressed: () => _selectDateRange(context),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildFamilyDropdown(),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildStaffDropdown(),
                ),
                _buildBodyContent(),
              ],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildSummaryCard(),
            ),
          ],
        ),
      ),
    );
  }
}

TableRow _buildTableRow(
  String label1,
  String value1,
  String label2,
  String value2,
) {
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

TableRow _buildCardTableRow(String label, String value) {
  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
    ],
  );
}