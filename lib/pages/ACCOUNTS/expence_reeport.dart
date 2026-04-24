import 'dart:convert';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/update_Expense.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:intl/intl.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Expence_Report extends StatefulWidget {
  const Expence_Report({super.key});

  @override
  State<Expence_Report> createState() => _Expence_ReportState();
}

class _Expence_ReportState extends State<Expence_Report> {
  List<Map<String, dynamic>> expensedata = [];
  List<Map<String, dynamic>> filteredData = [];
  List<Map<String, dynamic>> bank = [];
  DateTime? selectedDate;
  DateTime? startDate;
  DateTime? endDate;
  double totalAmount = 0;

  @override
  void initState() {
    super.initState();
    getexpenselist(); // Fetch the full list of expenses only once
    // getbank();
    // getcompany();
    // getstaff();
  }

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
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

  // Method to filter expenses by the selected date
  void _filterOrdersByDateRange() {
    if (startDate != null && endDate != null) {
      setState(() {
        filteredData = expensedata.where((order) {
          // Parse the 'expense_date' from string to DateTime if needed
          final orderDate = DateFormat('yyyy-MM-dd')
              .parse(order['expense_date']); // Adjust format if needed

          // Check if the order date is within the selected range
          return orderDate.isAfter(startDate!.subtract(Duration(days: 1))) &&
              orderDate.isBefore(endDate!.add(Duration(days: 1)));
        }).toList();
      });
    }
  }

  // Method to filter expenses by single date
  void _filterOrdersBySingleDate() {
    if (selectedDate != null) {
      setState(() {
        filteredData = expensedata.where((order) {
          // Parse the 'expense_date' from string to DateTime if needed
          final orderDate = DateFormat('yyyy-MM-dd')
              .parse(order['expense_date']); // Adjust format if needed

          // Compare only the date part (ignoring time)
          return orderDate.year == selectedDate!.year &&
              orderDate.month == selectedDate!.month &&
              orderDate.day == selectedDate!.day;
        }).toList();
      });
    }
  }

  // Method to select a single date
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
      _filterOrdersBySingleDate(); // Re-filter after selecting a new date
    }
  }

  // Method to select a date range (start date and end date)
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: DateTime.now(),
        end: DateTime.now(),
      ),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      _filterOrdersByDateRange(); // Re-filter after selecting a date range
    }
  }

  // Future<void> getbank() async {
  //   final token = await gettokenFromPrefs();
  //   try {
  //     final response = await http.get(Uri.parse('$api/api/banks/'), headers: {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Bearer $token',
  //     });
  //     List<Map<String, dynamic>> banklist = [];

  //     if (response.statusCode == 200) {
  //       final parsed = jsonDecode(response.body);
  //       var productsData = parsed['data'];

  //       for (var productData in productsData) {
  //         banklist.add({
  //           'id': productData['id'],
  //           'name': productData['name'],
  //           'branch': productData['branch']
  //         });
  //       }
  //       setState(() {
  //         bank = banklist;
  //       });
  //     }
  //   } catch (e) {

  //   }
  // }

  // List<Map<String, dynamic>> company = [];

  // Future<void> getcompany() async {
  //   try {
  //     final token = await gettokenFromPrefs();
  //     var response = await http.get(
  //       Uri.parse('$api/api/company/data/'),
  //       headers: {
  //         'Authorization': ' Bearer $token',
  //         'Content-Type': 'application/json',
  //       },
  //     );
  //     List<Map<String, dynamic>> companylist = [];

  //     if (response.statusCode == 200) {
  //       final productsData = jsonDecode(response.body);

  //       for (var productData in productsData) {
  //         companylist.add({
  //           'id': productData['id'],
  //           'name': productData['name'],
  //         });
  //       }
  //       setState(() {
  //         company = companylist;
  //       });
  //     }
  //   } catch (error) {

  //   }
  // }

  // List<Map<String, dynamic>> sta = [];
  // Future<void> getstaff() async {
  //   try {
  //     final token = await gettokenFromPrefs();
  //     var response = await http.get(
  //       Uri.parse('$api/api/staffs/'),
  //       headers: {
  //         'Authorization': 'Bearer $token',
  //         'Content-Type': 'application/json',
  //       },
  //     );
  //     List<Map<String, dynamic>> stafflist = [];

  //     if (response.statusCode == 200) {
  //       final parsed = jsonDecode(response.body);
  //       var productsData = parsed['data'];

  //       for (var productData in productsData) {
  //         stafflist.add({
  //           'id': productData['id'],
  //           'name': productData['name'],
  //           'allocated_states': productData['allocated_states']
  //         });
  //       }
  //       setState(() {
  //         sta = stafflist;
  //       });
  //     }
  //   } catch (error) {

  //   }
  // }
  Future<void> getexpenselist() async {
    try {
      final token = await gettokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/expense/add/'), // Ensure the endpoint is correct
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        if (parsed['data'] != null && parsed['data'] is List) {
          final productsdata = parsed['data'];

          List<Map<String, dynamic>> expenselist = [];
          double total = 0.0;

          for (var productData in productsdata) {
            try {
              double amount = productData['amount'] != null
                  ? double.tryParse(productData['amount'].toString()) ?? 0.0
                  : 0.0;
              total += amount;

              expenselist.add({
                'id': productData['id']?.toString() ?? '',
                'purpose_of_payment':
                    productData['purpose_of_payment']?.toString() ?? '',
                'purpose_of_pay': productData['purpose_of_pay'],
                // 'bank': productData['bank']?.toString() ?? '',
                'amount': amount,
                'company': productData['company']['name']?.toString() ?? '',
                'added_by': productData['added_by']?.toString() ?? '',
                'transaction_id':
                    productData['transaction_id']?.toString() ?? '',
                'payed_by': productData['payed_by']['name']?.toString() ?? '',
                'expense_date': productData['expense_date']?.toString() ?? '',
                'catrgory': productData['categoryname']?.toString() ?? '',
                'name': productData['name']?.toString() ?? '',
                'quantity': productData['quantity']?.toString() ?? '',
              });
            } catch (e) {}
          }

          setState(() {
            expensedata = expenselist;
            filteredData = expenselist;
            totalAmount = total;
          });
        } else {}
      } else {}
    } catch (error) {}
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

  // Method for showing total amount with two decimal places
  Widget _buildRowWithTwoColumns(String label1, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '₹${amount.toStringAsFixed(2)}', // Format totalAmount to two decimal places
                  style: TextStyle(
                    fontSize: 16,
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
        backgroundColor: Color.fromARGB(242, 255, 255, 255),
        appBar: AppBar(
          title: Text(
            "Expense Report",
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
            // Icon button to open start date picker
            IconButton(
              icon: Icon(Icons.calendar_today), // Calendar icon
              onPressed: () => _selectSingleDate(
                  context), // Call the method to select start date
            ),
            // Icon button to open date range picker
            IconButton(
              icon: Icon(Icons.date_range), // Date range icon
              onPressed: () => _selectDateRange(
                  context), // Call the method to select date range
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: filteredData.isEmpty
                      ? Center(child: CircularProgressIndicator())
                      : ListView.builder(
  itemCount: filteredData.length,
  itemBuilder: (context, index) {
    final expense = filteredData[index];
    return Card(
      color: Colors.white,
      elevation: 4,
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Table(
              border: TableBorder.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
              columnWidths: const {
                0: FlexColumnWidth(2), // Label small
                1: FlexColumnWidth(3), // Value wider
              },
              children: [
                _buildTableRow("Purpose of Payment", expense['purpose_of_pay']),
                _buildTableRow("Amount", "₹${expense['amount']}"),
                if (expense['name'] != null)
                  _buildTableRow("Name", expense['name']),
                if (expense['quantity'] != null)
                  _buildTableRow("Quantity", expense['quantity']),
                if (expense['category'] != null)
                  _buildTableRow("Category", expense['category']),
                _buildTableRow("Company", expense['company']),
                _buildTableRow("Payed By", expense['payed_by']),
                _buildTableRow("Added By", expense['added_by']),
                _buildTableRow("Transaction Id", expense['transaction_id']),
                _buildTableRow("Expense Date", expense['expense_date']),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => update_expence(id: expense['id']),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text(
                  "View",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  },
)

                ),
                SizedBox(height: 100),
              ],
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
                      const SizedBox(height: 8),

                      /// Table with just one row
                      Table(
                        border: TableBorder.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                        columnWidths: const {
                          0: FlexColumnWidth(),
                          1: FlexColumnWidth(),
                        },
                        children: [
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Total Amount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  '₹${totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
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
    );
  }

//   String getNameById(List<Map<String, dynamic>> dataList, dynamic id) {
//     if (id == null || dataList.isEmpty) return 'Unknown';
//     final item = dataList.firstWhere(
//       (element) => element['id'] == id,
//       orElse: () => {},
//     );
//     return item != null ? item['name'] : 'Unknown';
//   }
}
TableRow _buildTableRow(String label, dynamic value) {
  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          value?.toString() ?? 'N/A',
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
      ),
    ],
  );
}
