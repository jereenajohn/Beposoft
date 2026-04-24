import 'dart:convert';
import 'package:beposoft/pages/ACCOUNTS/creditsale_date_report.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
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

  DateTime? selectedDate; // For single date filter
  DateTime? startDate; // For date range filter
  DateTime? endDate; // For date range filter

  String? selectedFamily;
  String? selectedStaff;

  @override
  void initState() {
    super.initState();
    getfamily();
    getCreditsaleReport();
    getstaff();
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
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
        var staffData = parsed['data'];

        allStaff = List<Map<String, dynamic>>.from(staffData);
        filterStaffByFamily();
      }
    } catch (error) {
      // Handle error
    }
  }

  void filterStaffByFamily() {
    List<Map<String, dynamic>> filteredStaff = [];

    for (var staff in allStaff) {
      if (staff['family_name'] == selectedFamily) {
        filteredStaff.add({
          'id': staff['id'],
          'name': staff['name'],
        });
      }
    }

    setState(() {
      sta = filteredStaff;
      selectedStaff = null; // Reset selected staff
    });
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

  // Fetch sales report
  Future<void> getCreditsaleReport() async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/credit/sales/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final salesData = jsonDecode(response.body);

        List<Map<String, dynamic>> salesReportDataList = [];

        // Summary counters
        double grandTotalAmount = 0.0;
        int grandTotalOrders = 0;
        double grandTotalPaidAmount = 0.0;
        double grandBalanceAmount = 0.0;

        for (var reportData in salesData) {
          String dateStr = reportData['date'] ?? 'Unknown';
          DateTime reportDate = DateTime.tryParse(dateStr) ?? DateTime(1900);

          // Skip if date range is set and the date is outside
          if (startDate != null && endDate != null) {
            if (reportDate.isBefore(startDate!) ||
                reportDate.isAfter(endDate!)) {
              continue;
            }
          }

          // Apply filters
          List<dynamic> filteredOrders = reportData['orders'];
          if (selectedFamily != null) {
            filteredOrders = filteredOrders.where((order) {
              return order['family_name'] == selectedFamily;
            }).toList();
          }

          if (selectedStaff != null) {
            filteredOrders = filteredOrders.where((order) {
              return order['staff_name'] == selectedStaff;
            }).toList();
          }

          // Per-date totals
          double dateTotalAmount = 0.0;
          int dateTotalOrders = 0;
          double dateTotalPaidAmount = 0.0;
          double dateBalanceAmount = 0.0;

          for (var order in filteredOrders) {
            dateTotalOrders++;
            double orderAmount = order['total_amount'];
            double totalReceivedPayment = 0.0;

            for (var payment in order['recived_payment']) {
              totalReceivedPayment +=
                  double.tryParse(payment['amount'].toString()) ?? 0.0;
            }

            dateTotalAmount += orderAmount;
            dateTotalPaidAmount += totalReceivedPayment;
            dateBalanceAmount += (orderAmount - totalReceivedPayment);
          }

          // Accumulate for global summary
          grandTotalOrders += dateTotalOrders;
          grandTotalAmount += dateTotalAmount;
          grandTotalPaidAmount += dateTotalPaidAmount;
          grandBalanceAmount += dateBalanceAmount;

          if (filteredOrders.isNotEmpty) {
            salesReportDataList.add({
              'date': dateStr,
              'total_amount': dateTotalAmount,
              'total_orders': dateTotalOrders,
              'total_paid_amount': dateTotalPaidAmount,
              'balance_amount': dateBalanceAmount,
            });
          }
        }

        setState(() {
          allSalesReportList = salesReportDataList;
          totalOrders = grandTotalOrders;
          totalAmount = grandTotalAmount;
          totalPaidAmount = grandTotalPaidAmount;
          balanceAmount = grandBalanceAmount;
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
    }
  }

  drower d = drower();
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
      getCreditsaleReport(); // Re-fetch with updated filters
    }
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
            'Credit Sale Report',
            style: TextStyle(fontSize: 12, color: Colors.grey),
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
                getCreditsaleReport();
                getstaff();
                selectedFamily = null; // Reset family filter
                selectedStaff = null; // Reset staff filter
              },
            ),

            IconButton(
              icon: Icon(Icons.date_range),
              onPressed: () => _selectDateRange(context),
            ),

            // IconButton(
            //   icon: Icon(Icons.date_range),
            //   onPressed: () => _selectDateRange(context),
            // ),
          ],
        ),
        body: Column(
          children: [
            // Dropdown for selecting a family
            Padding(
              padding: const EdgeInsets.all(8.0),
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
                        selectedStaff = null;
                      });
                      filterStaffByFamily(); // Filter locally
                      getCreditsaleReport(); // Your report logic
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
            // Dropdown for selecting staff
            Padding(
              padding: const EdgeInsets.all(8.0),
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
                      });
                      getCreditsaleReport();
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
            // Displaying the sales report data
            allSalesReportList.isEmpty
                ? Center(
                    child: CircularProgressIndicator()) // Loading indicator
                : Expanded(
                    child: ListView.builder(
                      itemCount: allSalesReportList.length,
                      itemBuilder: (context, index) {
                        final report = allSalesReportList[index];
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
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const Divider(color: Colors.grey),

        // Table-style layout
        Table(
          border: TableBorder.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
          columnWidths: const {
            0: FlexColumnWidth(2), // Label column
            1: FlexColumnWidth(3), // Value column
          },
          children: [
            _buildCardTableRow('Total Orders', '${report['total_orders']}'),
            _buildCardTableRow('Total Amount', '₹${report['total_amount']}'),
            _buildCardTableRow('Total Paid Amount', '₹${report['total_paid_amount']}'),
            _buildCardTableRow('Balance Amount', '₹${report['balance_amount']}'),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreditsaleDateReport(date: report['date']),
                ),
              );
            },
            child: const Text("View", style: TextStyle(fontSize: 14, color: Colors.white)),
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

                      /// Table Design
                      Table(
                        border: TableBorder.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                        columnWidths: const {
                          0: FlexColumnWidth(1.2), // Label 1 (smaller)
                          1: FlexColumnWidth(2), // Value 1 (wider)
                          2: FlexColumnWidth(1.2), // Label 2 (smaller)
                          3: FlexColumnWidth(2), // Value 2 (wider)
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

                      const SizedBox(height: 50),
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
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          value,
          textAlign: TextAlign.right, // right-align numbers
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
    ],
  );
}
