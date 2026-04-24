import 'dart:convert';
import 'package:beposoft/pages/ACCOUNTS/codsale_date_report.dart';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart' show cso_dashboard;
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

class CodSales2 extends StatefulWidget {
  const CodSales2({super.key});

  @override
  State<CodSales2> createState() => _CodSales2State();
}

class _CodSales2State extends State<CodSales2> {
  List<Map<String, dynamic>> allCodReportList = [];
  List<Map<String, dynamic>> stat = [];
  List<Map<String, dynamic>> allStaffList = []; // Store the full staff list
  double grandTotalAmount = 0.0;
  int grandTotalOrders = 0;
  double grandTotalPaidAmount = 0.0;
  double grandBalanceAmount = 0.0;

  double sumTotalAmount = 0.0;
  int sumTotalOrders = 0;
  double sumTotalPaidAmount = 0.0;
  double sumBalanceAmount = 0.0;

  List<Map<String, dynamic>> fam = [];
  String? selectedFamily;
  String? selectedStaff;
  String? selectedState;
  List<Map<String, dynamic>> sta = [];

  @override
  void initState() {
    super.initState();
    getCODsaleReport();
    getfamily();
    getstaff();
    getstate();
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> getstate() async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/states/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> statelist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          statelist.add({
            'id': productData['id'],
            'name': productData['name'],
          });
        }
        setState(() {
          stat = statelist;
        });
      }
    } catch (error) {}
  }

  // Fetch staff list from the API
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
          stafflist.add({
            'id': productData['id'],
            'name': productData['name'],
            'family': productData['family_name'],
            'allocated_states': productData['allocated_states'], // ✅ added here
          });
        }

        setState(() {
          allStaffList = stafflist;
          sta = stafflist; // show all initially
        });
      }
    } catch (error) {
      // Handle error
    }
  }

  // Fetch family list from the API
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

  List<Map<String, dynamic>> filteredStates = [];

  Future<void> getCODsaleReport() async {
    setState(() {});
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/COD/sales/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final salesData = jsonDecode(response.body);

        List<Map<String, dynamic>> salesReportDataList = [];

        for (var reportData in salesData) {
          // Filter orders based on the selected family, staff name, and state
          if (selectedFamily != null) {
            reportData['orders'] = reportData['orders'].where((order) {
              return order['family_name'] == selectedFamily;
            }).toList();
          }

          if (selectedStaff != null) {
            reportData['orders'] = reportData['orders'].where((order) {
              return order['staff_name'] == selectedStaff;
            }).toList();
          }

          if (selectedState != null) {
            reportData['orders'] = reportData['orders'].where((order) {
              return order['state'] == selectedState;
            }).toList();
          }

          double totalAmount = 0.0;
          int totalOrders = 0;
          double totalPaidAmount = 0.0;
          double balanceAmount = 0.0;

          for (var order in reportData['orders']) {
            totalAmount += order['total_amount'];
          }

          totalOrders = reportData['orders'].length;
          totalPaidAmount = reportData['orders']
              .fold(0.0, (sum, order) => sum + order['total_paid_amount']);
          balanceAmount = reportData['orders']
              .fold(0.0, (sum, order) => sum + order['balance_amount']);

          salesReportDataList.add({
            'date': reportData['date'],
            'total_amount': totalAmount,
            'total_orders': totalOrders,
            'total_paid_amount': totalPaidAmount,
            'balance_amount': balanceAmount,
          });
        }

        setState(() {
          allCodReportList = salesReportDataList;
        });

        calculateSummaryTotals(salesReportDataList);
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
      setState(() {});
    }
  }

  void calculateSummaryTotals(List<Map<String, dynamic>> salesReportDataList) {
    // Reset all values before summing
    grandTotalAmount = 0.0;
    grandTotalOrders = 0;
    grandTotalPaidAmount = 0.0;
    grandBalanceAmount = 0.0;

    for (var report in salesReportDataList) {
      grandTotalAmount += (report['total_amount'] ?? 0.0) as double;
      grandTotalOrders += (report['total_orders'] ?? 0) as int;
      grandTotalPaidAmount += (report['total_paid_amount'] ?? 0.0) as double;
      grandBalanceAmount += (report['balance_amount'] ?? 0.0) as double;
    }
    setState(() {
      sumTotalOrders = grandTotalOrders;
      sumTotalAmount = grandTotalAmount;
      sumTotalPaidAmount = grandTotalPaidAmount;
      sumBalanceAmount = grandBalanceAmount;
    });
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
          title: Text(
            "COD Sales Report",
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
              } else if (dep == "CSO") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          cso_dashboard()), // Replace AnotherPage with your target page
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
                selectedFamily = null; // Reset family filter
                selectedStaff = null; // Reset staff filter
                selectedState = null;
                getCODsaleReport();
                getstaff();
              },
            ),

            // IconButton(
            //   icon: Icon(Icons.date_range),
            //   onPressed: () => _selectDateRange(context),
            // ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Select Family',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 1.5),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: Text("Select Family"),
                    value: selectedFamily,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedFamily = newValue;
                        selectedStaff = null; // Reset selected staff
                        sta = allStaffList
                            .where((staff) => staff['family'] == selectedFamily)
                            .toList();
                      });
                      getCODsaleReport();
                    },
                    items: fam.map((family) {
                      return DropdownMenuItem<String>(
                        value: family['name'],
                        child: Text(family['name']),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Select Staff',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 1.5),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: Text("Select Staff"),
                    value: selectedStaff,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedStaff = newValue;
                        selectedState = null; // Clear state when staff changes

                        // Find the selected staff object
                        final staff = sta.firstWhere(
                            (s) => s['name'] == newValue,
                            orElse: () => {});

                        if (staff.isNotEmpty &&
                            staff['allocated_states'] != null) {
                          List allocatedStateIds =
                              staff['allocated_states']; // e.g., [1, 2]

                          // Filter states based on allocated state IDs
                          filteredStates = stat
                              .where((state) =>
                                  allocatedStateIds.contains(state['id']))
                              .toList();
                        } else {
                          filteredStates = [];
                        }
                      });

                      getCODsaleReport();
                    },
                    items: sta.map((staff) {
                      return DropdownMenuItem<String>(
                        value: staff['name'],
                        child: Text(staff['name']),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(5.0),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Select State',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 1.5),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: Text("Select State"),
                    value: selectedState,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedState = newValue;
                      });
                      getCODsaleReport(); // Filter report based on state
                    },
                    items: filteredStates.map((state) {
                      return DropdownMenuItem<String>(
                        value: state['name'],
                        child: Text(state['name']),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            // Show the total orders and amounts for the selected family

            allCodReportList.isEmpty
                ? Center(
                    child: CircularProgressIndicator()) // Loading indicator
                : Expanded(
                    child: ListView.builder(
                      itemCount: allCodReportList.length,
                      itemBuilder: (context, index) {
                        final report = allCodReportList[index];
                        return Card(
                          color: Colors.white,
                          margin: EdgeInsets.all(8.0),
                          elevation: 5.0,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date: ${report['date']}',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Divider(color: Colors.grey),

                                // Table Layout
                                Table(
                                  columnWidths: const {
                                    0: FlexColumnWidth(2), // label small
                                    1: FlexColumnWidth(3), // amount wider
                                  },
                                  border: TableBorder.all(
                                      color: Colors.grey.shade300),
                                  children: [
                                    _buildRow("Total Orders",
                                        report['total_orders'].toString()),
                                    _buildRow("Total Amount",
                                        "₹${report['total_amount']}"),
                                    _buildRow("Paid Amount",
                                        "₹${report['total_paid_amount']}"),
                                    _buildRow("Balance",
                                        "₹${report['balance_amount']}"),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                if (selectedFamily == null &&
                                    selectedStaff == null &&
                                    selectedState == null)
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              codsalereport_datewise_view(
                                                  date: report['date']),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                    ),
                                    child: const Text(
                                      'View',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Material(
                elevation: 12,
                color: const Color.fromARGB(255, 12, 80, 163),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
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
                          1: FlexColumnWidth(),
                          2: FlexColumnWidth(),
                          3: FlexColumnWidth(),
                        },
                        children: [
                          _buildCardTableRow(
                            'Total Orders',
                            sumTotalOrders.toString(),
                          ),
                          _buildCardTableRow(
                            'Total Amount',
                            sumTotalAmount.toStringAsFixed(2),
                          ),
                          _buildCardTableRow(
                            'Paid Amount',
                            sumTotalPaidAmount.toStringAsFixed(2),
                          ),
                          _buildCardTableRow(
                            'Balance Amount',
                            sumBalanceAmount.toStringAsFixed(2),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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

TableRow _buildCardTableRow(String label, String value) {
  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white, // ✅ White text
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          value,
          textAlign: TextAlign.right, // right-align numbers
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white, // ✅ White value text
          ),
        ),
      ),
    ],
  );
}

/// Helper function to build table rows
TableRow _buildRow(String label, String value) {
  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    ],
  );
}
