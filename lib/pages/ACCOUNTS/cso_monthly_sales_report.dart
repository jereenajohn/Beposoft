import 'dart:convert';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/add_attribute.dart';
import 'package:beposoft/pages/ACCOUNTS/add_bank.dart';
import 'package:beposoft/pages/ACCOUNTS/add_company.dart';
import 'package:beposoft/pages/ACCOUNTS/add_department.dart';
import 'package:beposoft/pages/ACCOUNTS/add_family.dart';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
import 'package:beposoft/pages/ACCOUNTS/add_state.dart';
import 'package:beposoft/pages/ACCOUNTS/add_supervisor.dart';
import 'package:beposoft/pages/ACCOUNTS/cso_invoice_report.dart';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/invoice_report.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:intl/intl.dart'; // Import the intl package for date formatting
import 'package:beposoft/pages/ACCOUNTS/customer.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/methods.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:intl/intl.dart';

class CsoMonthlySalesReport extends StatefulWidget {
  const CsoMonthlySalesReport({super.key});

  @override
  State<CsoMonthlySalesReport> createState() => _CsoMonthlySalesReportState();
}

class _CsoMonthlySalesReportState extends State<CsoMonthlySalesReport> {
  List<Map<String, dynamic>> sta = [];
  List<Map<String, dynamic>> todayOrders = [];
  List<Map<String, dynamic>> currentMonthOrdersList = [];
List<Map<String, dynamic>> previousMonthOrdersList = [];


  String? selectedstaff;
  DateTime? fromMonth;
  DateTime? toMonth;

  DateTime? selectedDate; // For single date filter
  DateTime? startDate; // For date range filter
  DateTime? endDate; // For date range filter

  int currentMonthOrderCount = 0;
  double currentMonthTotalValue = 0.0;

  int previousMonthOrderCount = 0;
  double previousMonthTotalValue = 0.0;

  @override
  void initState() {
    super.initState();
    getMonthlySalesSummary();
    getstaff();
  }
Future<void> _handleRefresh() async {
  fromMonth = null;
  toMonth = null;
  selectedstaff = null;

  await getMonthlySalesSummary();
  if (mounted) setState(() {});
}


Future<void> fetchComparisonData() async {
  if (fromMonth == null || toMonth == null) return;

  final token = await getTokenFromPrefs();

  Future<Map<String, dynamic>> getMonthData(DateTime date) async {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');

    final response = await http.get(
      Uri.parse('$api/api/orders/monthly/$year/$month/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['results'];

      final filtered = selectedstaff == null
          ? data
          : data
              .where((o) =>
                  o['staff_name'].toString().toLowerCase() ==
                  selectedstaff!.toLowerCase())
              .toList();

      final orderCount = filtered.length;
      final totalValue = filtered.fold<double>(
        0.0,
        (double sum, dynamic o) =>
            sum + (double.tryParse(o['total_amount'].toString()) ?? 0.0),
      );

      return {
        'count': orderCount,
        'value': totalValue,
        'orders': filtered, // ✅ Return order details
      };
    }

    return {
      'count': 0,
      'value': 0.0,
      'orders': [],
    };
  }

  // Get both months’ data before updating UI
  final fromData = await getMonthData(fromMonth!);
  final toData = await getMonthData(toMonth!);

  if (mounted) {
    setState(() {
      previousMonthOrderCount = fromData['count'];
      previousMonthTotalValue = fromData['value'];
      previousMonthOrdersList = List<Map<String, dynamic>>.from(fromData['orders']);

      currentMonthOrderCount = toData['count'];
      currentMonthTotalValue = toData['value'];
      currentMonthOrdersList = List<Map<String, dynamic>>.from(toData['orders']);
    });
  }
}

 Future<void> getMonthlySalesSummary() async {
 
  try {
    final token = await getTokenFromPrefs();
    DateTime now = DateTime.now();

    String currentYear = now.year.toString();
    String currentMonth = now.month.toString().padLeft(2, '0');

    DateTime prevDate = DateTime(now.year, now.month - 1, 1);
    String prevYear = prevDate.year.toString();
    String prevMonth = prevDate.month.toString().padLeft(2, '0');

    // Helper function to fetch and filter data
    Future<Map<String, dynamic>> fetchMonthData(String y, String m) async {
      var res = await http.get(
        Uri.parse('$api/api/orders/monthly/$y/$m/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['results'];

        List filtered = data;
        if (selectedstaff != null && selectedstaff!.isNotEmpty) {
          filtered = data
              .where((o) =>
                  o['staff_name'].toString().toLowerCase() ==
                  selectedstaff!.toLowerCase())
              .toList();
        }

        int orderCount = filtered.length;
        double total = 0;
        for (var order in filtered) {
          total += double.tryParse(order['total_amount'].toString()) ?? 0.0;
        }

        return {
          'count': orderCount,
          'value': total,
          'orders': filtered, // ✅ Add full order list
        };
      } else {
        return {
          'count': 0,
          'value': 0.0,
          'orders': [],
        };
      }
    }

    var current = await fetchMonthData(currentYear, currentMonth);
    var previous = await fetchMonthData(prevYear, prevMonth);

    setState(() {
      currentMonthOrderCount = current['count'];
      currentMonthTotalValue = current['value'];
      currentMonthOrdersList = List<Map<String, dynamic>>.from(current['orders']);

      previousMonthOrderCount = previous['count'];
      previousMonthTotalValue = previous['value'];
      previousMonthOrdersList = List<Map<String, dynamic>>.from(previous['orders']);
    });
  } catch (e) {
  }
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
      );

      List<Map<String, dynamic>> stafflist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          if ((productData['department_name'] ?? '').toString().toLowerCase() ==
                  'bdm' ||
              (productData['department_name'] ?? '').toString().toLowerCase() ==
                  'bdo') {
            stafflist.add({
              'id': productData['id'],
              'name': productData['name'],
              'department_name': productData['department_name'],
            });
          }
        }
        setState(() {
          sta = stafflist;
        });
      }
    } catch (error) {}
  }

  drower d = drower();

  // Get token from SharedPreferences
  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Widget _buildRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.toString(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('token');

    // Use a post-frame callback to show the SnackBar after the current frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ScaffoldMessenger.of(context).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged out successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });

    // Wait for the SnackBar to disappear before navigating
    await Future.delayed(Duration(seconds: 2));

    // Navigate to the HomePage after the snackbar is shown
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => login()),
    );
  }

  Widget _buildDropdownTile(
      BuildContext context, String title, List<String> options) {
    return ExpansionTile(
      title: Text(title),
      children: options.map((option) {
        return ListTile(
          title: Text(option),
          onTap: () {
            Navigator.pop(context);
            d.navigateToSelectedPage(
                context, option); // Navigate to selected page
          },
        );
      }).toList(),
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

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
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
    } else if(dep=="CEO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ceo_dashboard()), // Replace AnotherPage with your target page
            );
}
else if(dep=="COO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ceo_dashboard()), // Replace AnotherPage with your target page
            );
}
else if (dep == "CSO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                cso_dashboard()), // Replace AnotherPage with your target page
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
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            "Monthly Sales Report",
            style: TextStyle(fontSize: 14, color: Colors.grey),
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
              } else if (dep == "CSO") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          cso_dashboard()), // Replace AnotherPage with your target page
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
    icon: Icon(Icons.calendar_month),
    onPressed: () async {
      final pickedFrom = await showMonthPicker(
        context: context,
        initialDate: fromMonth ?? DateTime.now(),
      );

      if (pickedFrom != null) {
        final pickedTo = await showMonthPicker(
          context: context,
          initialDate: pickedFrom,
          firstDate: pickedFrom,
        );

        if (pickedTo != null) {
          fromMonth = pickedFrom;
          toMonth = pickedTo;

          await fetchComparisonData(); // fetch first
          if (mounted) setState(() {}); // then update UI
        }
      }
    },
  ),
],

        ),
        body: RefreshIndicator(
           onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),

            child: Column(
              children: [
                if (fromMonth != null && toMonth != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "Comparing: ${DateFormat.yMMM().format(fromMonth!)} ➜ ${DateFormat.yMMM().format(toMonth!)}",
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    height: 49,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 20),
                        Container(
                          width: 276,
                          child: InputDecorator(
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 1),
                              ),
                              child: DropdownSearch<String>(
                                  items: sta
                                      .map<String>((e) => e['name'].toString())
                                      .toList(),
                                  selectedItem: selectedstaff,
                                  dropdownDecoratorProps: DropDownDecoratorProps(
                                    dropdownSearchDecoration: InputDecoration(
                                      hintText: "Select Staff",
                                      contentPadding:
                                          EdgeInsets.symmetric(horizontal: 12),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                  popupProps: PopupProps.menu(
                                    showSearchBox: true,
                                    searchFieldProps: TextFieldProps(
                                      decoration: InputDecoration(
                                        hintText: "Search staff...",
                                      ),
                                    ),
                                  ),
                                  onChanged: (value) async {
  selectedstaff = value;

  await getMonthlySalesSummary(); // refresh default data

  if (fromMonth != null && toMonth != null) {
    await fetchComparisonData(); // re-fetch for range
  }

  if (mounted) setState(() {}); // update UI after fetching
},
)),
                        ),
                      ],
                    ),
                  ),
                ),
                Builder(
                  builder: (context) {
                    String growthLabel;
                    Color growthColor;
          
                    if (currentMonthTotalValue > previousMonthTotalValue) {
                      growthLabel = "Growth";
                      growthColor = Colors.green;
                    } else if (currentMonthTotalValue < previousMonthTotalValue) {
                      growthLabel = "De-growth";
                      growthColor = Colors.red;
                    } else {
                      growthLabel = "Same";
                      growthColor = Colors.grey;
                    }
          
                    return Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                         _buildSummaryBox(
  title: "Current Month",
  subtitle: toMonth != null ? DateFormat.yMMM().format(toMonth!) : null,
  orderCount: currentMonthOrderCount,
  totalValue: currentMonthTotalValue,
  color: Colors.blue.shade50,
  orderDetails: currentMonthOrdersList, // ← Add this
),
_buildSummaryBox(
  title: "Previous Month",
  subtitle: fromMonth != null ? DateFormat.yMMM().format(fromMonth!) : null,
  orderCount: previousMonthOrderCount,
  totalValue: previousMonthTotalValue,
  color: Colors.grey.shade200,
  orderDetails: previousMonthOrdersList, // ← Add this
),

                          _buildSummaryBox(
                            title: "Difference",
                            orderCount:
                                currentMonthOrderCount - previousMonthOrderCount,
                            totalValue:
                                currentMonthTotalValue - previousMonthTotalValue,
                            color: Colors.green.shade100,
                            statusLabel: growthLabel,
                            statusColor: growthColor,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
Widget _buildSummaryBox({
  required String title,
  String? subtitle,
  required int orderCount,
  required double totalValue,
  required Color color,
  String? statusLabel,
  Color? statusColor,
  List<Map<String, dynamic>>? orderDetails,
}) {
  bool isExpanded = false;

  return StatefulBuilder(
    builder: (context, setInnerState) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon, title and toggle arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: Colors.grey.shade800,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (statusLabel != null && statusColor != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                if (orderDetails != null && orderDetails.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 24,
                    ),
                    onPressed: () {
                      setInnerState(() {
                        isExpanded = !isExpanded;
                      });
                    },
                  )
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryDetail("Total Orders", orderCount.toString()),
                _summaryDetail("Total Value", "₹${totalValue.toStringAsFixed(2)}"),
              ],
            ),
            if (isExpanded && orderDetails != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: orderDetails.map((order) {
                    return Container(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(order['invoice'],
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                Text(order['order_date'],
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "₹${(double.tryParse(order['total_amount'].toString()) ?? 0.0).toStringAsFixed(2)}",
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              )
          ],
        ),
      );
    },
  );
}


Widget _summaryDetail(String label, String value) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade700,
        ),
      ),
      SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    ],
  );
}
