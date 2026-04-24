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
import 'package:beposoft/pages/ACCOUNTS/invoice_report.dart';
import 'package:beposoft/pages/ACCOUNTS/invoicereportstaffwise.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/ADMIN/family_date_salesreport.dart';
import 'package:beposoft/pages/ADMIN/familywise_salesreport.dart';
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

class Sales_Report extends StatefulWidget {
  const Sales_Report({super.key});

  @override
  State<Sales_Report> createState() => _Sales_ReportState();
}

class _Sales_ReportState extends State<Sales_Report> {
  List<Map<String, dynamic>> salesReportList = [];
  List<Map<String, dynamic>> filterdata = [];
  List<Map<String, dynamic>> sta = [];
  List<Map<String, dynamic>> sortedSta = [];
  List<Map<String, dynamic>> fam = [];

  double totalBills = 0.0;
  double totalAmount = 0.0;
  double approvedBills = 0.0;
  double approvedAmount = 0.0;
  double rejectedBills = 0.0;
  double rejectedAmount = 0.0;
  String? selectedstaff;
  String? selectedFamily;

  DateTime? selectedDate; // For single date filter
  DateTime? startDate; // For date range filter
  DateTime? endDate; // For date range filter

  @override
  void initState() {
    super.initState();
    getSalesReport();
    getstaff();
    getfamily();
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
          String imageUrl = "${productData['image']}";
          stafflist.add({
            'id': productData['id'],
            'name': productData['name'],
            'family_name': productData['family_name'],
          });
        }
        setState(() {
          sta = stafflist;
          sortedSta = stafflist;
        });
      }
    } catch (error) {}
  }

  void _filterOrdersBySingleDate() {
    if (selectedDate != null) {
      setState(() {
        filterdata = filterdata.where((order) {
          // Parse the 'expense_date' from string to DateTime if needed
          final orderDate = DateFormat('yyyy-MM-dd')
              .parse(order['date']); // Adjust format if needed

          // Compare only the date part (ignoring time)
          return orderDate.year == selectedDate!.year &&
              orderDate.month == selectedDate!.month &&
              orderDate.day == selectedDate!.day;
        }).toList();
        _updateTotals();
      });
    }
  }

  // Method to filter orders between two dates, inclusive of start and end dates
  void _filterOrdersByDateRange() {
    if (startDate != null && endDate != null) {
      setState(() {
        filterdata = filterdata.where((order) {
          // Parse the 'expense_date' from string to DateTime if needed
          final orderDate = DateFormat('yyyy-MM-dd')
              .parse(order['date']); // Adjust format if needed

          // Check if the order date is within the selected range
          return orderDate.isAfter(startDate!.subtract(Duration(days: 1))) &&
              orderDate.isBefore(endDate!.add(Duration(days: 1)));
        }).toList();
        _updateTotals();
      });
    }
  }

  // Function to parse both MM/dd/yy and yyyy-MM-dd formats
  DateTime _parseDate(String dateString) {
    try {
      return DateFormat('MM/dd/yy').parseStrict(dateString);
    } catch (e) {
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        throw FormatException('Invalid date format: $dateString');
      }
    }
  }

  // Function to update totals based on filtered data
  void _updateTotals() {
    double tempTotalBills = 0.0;
    double tempTotalAmount = 0.0;
    double tempApprovedBills = 0.0;
    double tempApprovedAmount = 0.0;
    double tempRejectedBills = 0.0;
    double tempRejectedAmount = 0.0;

    for (var reportData in filterdata) {
      tempTotalBills += reportData['total_bills_in_date'];
      tempTotalAmount += reportData['amount'];
      tempApprovedBills += reportData['approved']['bills'];
      tempApprovedAmount += reportData['approved']['amount'];
      tempRejectedBills += reportData['rejected']['bills'];
      tempRejectedAmount += reportData['rejected']['amount'];
    }

    setState(() {
      totalBills = tempTotalBills;
      totalAmount = tempTotalAmount;
      approvedBills = tempApprovedBills;
      approvedAmount = tempApprovedAmount;
      rejectedBills = tempRejectedBills;
      rejectedAmount = tempRejectedAmount;
    });
  }

  Future<void> _selectSingleDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _filterOrdersBySingleDate();
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
      _filterOrdersByDateRange();
    }
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
      );
      List<Map<String, dynamic>> familylist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

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
      // Handle error
    }
  }

  drower d = drower();

  // Get token from SharedPreferences
  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  void _filterDataByStaff(staffId) {
    setState(() {
      if (salesReportList == null || salesReportList.isEmpty) {
        filterdata = [];
        return;
      }
      filterdata = filterdata
          .map((report) {
            List<dynamic> staffOrders = report['filteredOrders'] ?? [];

            List<dynamic> filteredOrders = staffOrders
                .where((order) =>
                    order['manage_staff__name'] == staffId &&
                    order['family__name'] == selectedFamily)
                .toList();

            if (filteredOrders.isEmpty) return null;

            int approvedBills = 0;
            double approvedAmount = 0.0;
            int rejectedBills = 0;
            double rejectedAmount = 0.0;
            int totalBillsInDate = 0;
            double totalAmount = 0.0;

            List<String> approvedStatuses = [
              "Completed",
              "Shipped",
              "Waiting For Confirmation",
              "Invoice Created",
              "Invoice Approved",
              "To Print",
              "Processing",
              "Ready to ship",
              "Packing under progress"
            ];
            List<String> rejectedStatuses = [
              "Cancelled",
              "Refunded",
              "Return",
              "Invoice Rejected"
            ];

            for (var order in filteredOrders) {
              totalBillsInDate++;
              totalAmount += order['total_amount'] ?? 0.0;

              if (approvedStatuses.contains(order['status'])) {
                approvedBills++;
                approvedAmount += order['total_amount'] ?? 0.0;
              } else if (rejectedStatuses.contains(order['status'])) {
                rejectedBills++;
                rejectedAmount += order['total_amount'] ?? 0.0;
              }
            }

            return {
              'date': report['date'],
              'total_bills_in_date': totalBillsInDate,
              'amount': totalAmount,
              'approved': {
                'bills': approvedBills,
                'amount': approvedAmount,
              },
              'rejected': {
                'bills': rejectedBills,
                'amount': rejectedAmount,
              },
              'filteredOrders': filteredOrders,
            };
          })
          .where((report) => report != null)
          .cast<Map<String, dynamic>>()
          .toList();

      _updateTotals();
    });
  }

  Future<void> _fetchAndFilterByFamily(String familyName) async {
    setState(() {
      filterdata = [];
    });

    try {
      final token = await getTokenFromPrefs();
      var response = await http.get(
        Uri.parse('$api/api/salesreport/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var salesData = parsed['sales_report'];

        Map<String, List<dynamic>> groupedByDate = {};

        for (var report in salesData) {
          List<dynamic> staffOrders = report['order_details'] ?? [];
          for (var order in staffOrders) {
            if (order['family__name']?.toString().toLowerCase() ==
                familyName.toLowerCase()) {
              groupedByDate.putIfAbsent(report['date'], () => []);
              groupedByDate[report['date']]!.add(order);
            }
          }
        }

        List<Map<String, dynamic>> familyFilteredData = [];

        List<String> approvedStatuses = [
          "Completed",
          "Shipped",
          "Waiting For Confirmation",
          "Invoice Created",
          "Invoice Approved",
          "To Print",
          "Processing",
          "Ready to ship",
          "Packing under progress"
        ];
        List<String> rejectedStatuses = [
          "Cancelled",
          "Refunded",
          "Return",
          "Invoice Rejected"
        ];

        groupedByDate.forEach((date, orders) {
          int approvedBills = 0;
          double approvedAmount = 0.0;
          int rejectedBills = 0;
          double rejectedAmount = 0.0;
          int totalBillsInDate = 0;
          double totalAmount = 0.0;

          for (var order in orders) {
            totalBillsInDate++;
            totalAmount += order['total_amount'] ?? 0.0;

            if (approvedStatuses.contains(order['status'])) {
              approvedBills++;
              approvedAmount += order['total_amount'] ?? 0.0;
            } else if (rejectedStatuses.contains(order['status'])) {
              rejectedBills++;
              rejectedAmount += order['total_amount'] ?? 0.0;
            }
          }

          familyFilteredData.add({
            'date': date,
            'total_bills_in_date': totalBillsInDate,
            'amount': totalAmount,
            'approved': {
              'bills': approvedBills,
              'amount': approvedAmount,
            },
            'rejected': {
              'bills': rejectedBills,
              'amount': rejectedAmount,
            },
            'filteredOrders': orders,
          });
        });

        setState(() {
          filterdata = familyFilteredData;
          _updateTotals();
        });
      }
    } catch (error) {
      setState(() {
        filterdata = [];
      });
    }
  }

  var staff;
  Future<void> getSalesReport() async {
    setState(() {}); // Update UI
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/salesreport/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var salesData = parsed['sales_report'];

        List<Map<String, dynamic>> salesReportDataList = [];
        List<String> approvedStatuses = [
          "Completed",
          "Shipped",
          "Waiting For Confirmation",
          "Invoice Created",
          "Invoice Approved",
          "To Print",
          "Processing",
          "Ready to ship",
          "Packed",
          "Packing under progress"
        ];
        List<String> rejectedStatuses = [
          "Cancelled",
          "Refunded",
          "Return",
          "Invoice Rejected"
        ];

        for (var reportData in salesData) {
          List<dynamic> staffOrders = reportData['order_details'] ?? [];
          int totalApprovedBills = 0;
          double totalApprovedAmount = 0.0;
          int totalRejectedBills = 0;
          double totalRejectedAmount = 0.0;

          // Iterate through each staff order and classify based on status
          for (var order in staffOrders) {
            double orderAmount = (order['total_amount'] ?? 0.0).toDouble();
            if (approvedStatuses.contains(order['status'])) {
              totalApprovedBills++;
              totalApprovedAmount += orderAmount;
            } else if (rejectedStatuses.contains(order['status'])) {
              totalRejectedBills++;
              totalRejectedAmount += orderAmount;
            }
          }

          salesReportDataList.add({
            'date': reportData['date'],
            'staff_orders': staffOrders,
            'total_bills_in_date': reportData['total_bills_in_date'],
            'amount': reportData['amount'],
            'approved': {
              'bills': totalApprovedBills,
              'amount': totalApprovedAmount,
            },
            'rejected': {
              'bills': totalRejectedBills,
              'amount': totalRejectedAmount,
            },
          });
        }

        setState(() {
          salesReportList = salesReportDataList;
          filterdata = salesReportDataList;
          _updateTotals();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to fetch sales report data'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error fetching sales report data'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {}); // Final UI update
    }
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
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            "Sales Report",
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
              icon: Icon(Icons.refresh),
              onPressed: () {
                getSalesReport();
                _updateTotals();
                getstaff();
                selectedFamily = null; // Reset family filter
                selectedstaff = null; // Reset staff filter
                startDate = null; // Reset start date
                endDate = null; // Reset end date
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(left: 10.0, right: 10.0, top: 10.0),
              child: Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueAccent, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Note: Please select Division first and then Date and Staff",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Row(
  children: [
    // ===== Division Dropdown =====
    Expanded(
      flex: 1, // you can change flex to control relative width
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blueAccent, width: 1),
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: DropdownButton<String>(
            value: selectedFamily,
            hint: const Text(
              'Select Division',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            isExpanded: true,
            underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down,
                size: 18, color: Colors.blue),
            items: fam.map((family) {
              return DropdownMenuItem<String>(
                value: family['name'],
                child: Text(
                  family['name'],
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedFamily = newValue;
                if (selectedFamily != null &&
                    selectedFamily!.isNotEmpty) {
                  sortedSta = sta
                      .where((staff) =>
                          staff['family_name'] == selectedFamily)
                      .toList();
                  selectedstaff = null; // reset staff
                  _fetchAndFilterByFamily(selectedFamily!);
                } else {
                  sortedSta = sta;
                  filterdata = [];
                }
              });
            },
          ),
        ),
      ),
    ),

    // ===== Staff Dropdown =====
    Expanded(
      flex: 1,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blueAccent, width: 1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: DropdownButton<String>(
            value: selectedstaff,
            isExpanded: true,
            hint: const Text(
              "Select Staff",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down,
                size: 18, color: Colors.blue),
            onChanged: (newValue) {
              setState(() {
                selectedstaff = newValue;
              });
              if (selectedstaff != null) {
                _filterDataByStaff(selectedstaff!);
              }
            },
            items: sortedSta.map<DropdownMenuItem<String>>((staff) {
              return DropdownMenuItem<String>(
                value: staff['name'],
                child: Text(
                  staff['name'],
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    ),
  ],
),
            Expanded(
              child: RefreshIndicator(
                onRefresh: getSalesReport,
                child: Stack(
                  children: [
                    // Main content: Sales report list
                    SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: 260),
                      child: Column(
                        children: filterdata.map((reportData) {
                          // Handle case where 'filteredOrders' might be null
                          List<dynamic> orders =
                              reportData['filteredOrders'] ?? [];

                          return Card(
                            color: Colors.white,
                            margin: EdgeInsets.symmetric(
                                vertical: 10, horizontal: 15),
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date: ${reportData['date']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Divider(color: Colors.grey),

                                  /// Table for data
                                  Table(
                                    columnWidths: const {
                                      0: FlexColumnWidth(
                                          2), // label column smaller
                                      1: FlexColumnWidth(
                                          3), // value column bigger
                                    },
                                    border: TableBorder.all(
                                        color: Colors.grey.shade300, width: 1),
                                    children: [
                                      TableRow(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text('Bills:',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                                '${reportData['approved']['bills'] ?? 0}'),
                                          ),
                                        ],
                                      ),
                                      TableRow(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text('Amount:',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                                '₹${reportData['approved']['amount'] ?? 0.0}'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueAccent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 10),
                                      ),
                                      onPressed: () {
                                        if (selectedstaff == null &&
                                            selectedFamily == null &&
                                            startDate == null &&
                                            endDate == null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  Invoice_Report(
                                                      date: reportData['date']),
                                            ),
                                          );
                                        } else if (selectedFamily != null &&
                                            selectedstaff == null &&
                                            startDate == null &&
                                            endDate == null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  FamilywiseSalesreport(
                                                family: selectedFamily,
                                                date: reportData['date'],
                                              ),
                                            ),
                                          );
                                        } else {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  InvoiceReportStaffwise(
                                                id: selectedstaff!,
                                                date: reportData['date'],
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: Text(
                                        "View",
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
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
                              Row(
                                children: [
                                  const Text(
                                    'Total Summary',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    startDate != null && endDate != null
                                        ? '${DateFormat('MM/dd/yyyy').format(startDate!)} - ${DateFormat('MM/dd/yyyy').format(endDate!)}'
                                        : 'All Dates',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.date_range,
                                        color: Colors.white),
                                    onPressed: () {
                                      _selectDateRange(context);
                                    },
                                  ),
                                ],
                              ),
                              Divider(
                                color: Colors.white.withOpacity(0.5),
                                thickness: 1,
                              ),

                              /// Table Design
                              /// Table Design
                              Table(
                                border: TableBorder.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                                columnWidths: const {
                                  0: FlexColumnWidth(1), // Label 1 -> smaller
                                  1: FlexColumnWidth(2), // Value 1 -> bigger
                                  2: FlexColumnWidth(1), // Label 2 -> smaller
                                  3: FlexColumnWidth(2), // Value 2 -> bigger
                                },
                                children: [
                                  _buildTableRow('TB', '$totalBills', 'TA',
                                      totalAmount.toStringAsFixed(2)),
                                  _buildTableRow('AB', '$approvedBills', 'AA',
                                      approvedAmount.toStringAsFixed(2)),
                                  _buildTableRow('CB', '$rejectedBills', 'CA',
                                      rejectedAmount.toStringAsFixed(2)),
                                ],
                              ),

                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper for cleaner rows
TableRow _buildTableRow(
    String label1, String value1, String label2, String value2) {
  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(label1,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(value1,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(label2,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(value2,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ),
    ],
  );
}
