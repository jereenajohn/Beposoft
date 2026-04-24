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
import 'package:beposoft/pages/ACCOUNTS/update_bank_transfer.dart';
import 'package:beposoft/pages/ACCOUNTS/update_bankrecipt.dart';
import 'package:beposoft/pages/ACCOUNTS/update_cod_transfer_list.dart';
import 'package:beposoft/pages/ACCOUNTS/update_recipt.dart';
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
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class cod_transfer_list extends StatefulWidget {
  const cod_transfer_list({super.key});

  @override
  State<cod_transfer_list> createState() => cod_transfer_listState();
}

class cod_transfer_listState extends State<cod_transfer_list> {
  List<Map<String, dynamic>> salesReportList = [];
  List<Map<String, dynamic>> allSalesReportList = []; // Original data
  double totalstock = 0.0;
  double totalsold = 0.0;
  double remaingitem = 0.0;
  double approvedAmount = 0.0;
  double rejectedBills = 0.0;
  double rejectedAmount = 0.0;
  int totalReceipts = 0; // Add this line
  double totalAmount = 0.0; // Add this line
  TextEditingController searchController = TextEditingController();
  DateTime? selectedDate; // For single date filter
  DateTime? startDate; // For date range filter
  DateTime? endDate; // For date range filter

  @override
  void initState() {
    super.initState();
    getreciptReport();
    getbank();
    getcustomer();
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

  // Method to filter orders by single date

  // Function to update totals based on filtered data
  void _updateTotals() {
    ;
    int tempTotalReceipts = 0; // Add this line
    double tempTotalAmount = 0.0; // Add this line

    for (var reportData in salesReportList) {
      // Increment total receipts and total amount
      tempTotalReceipts++; // Add this line
      tempTotalAmount += reportData['amount']; // Add this line
    }

    setState(() {
      totalReceipts = tempTotalReceipts; // Add this line
      totalAmount = tempTotalAmount; // Add this line
    });
    ;
    ;
  }

  drower d = drower();

  // Get token from SharedPreferences
  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  List<Map<String, dynamic>> bank = [];

  Future<void> getbank() async {
    final token = await getTokenFromPrefs();
    try {
      final response = await http.get(Uri.parse('$api/api/banks/'), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      List<Map<String, dynamic>> banklist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          // String imageUrl = "${productData['image']}";
          banklist.add({
            'id': productData['id'],
            'name': productData['name'],
            'branch': productData['branch']
          });
        }
        setState(() {
          bank = banklist;
        });
      }
    } catch (e) {}
  }

  List<Map<String, dynamic>> customer = [];

  Future<void> getcustomer() async {
    try {
      final dep = await getdepFromPrefs();
      final token = await getTokenFromPrefs();

      final jwt = JWT.decode(token!);
      var name = jwt.payload['name'];

      var response = await http.get(
        Uri.parse('$api/api/customers/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      ;

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData =
            parsed['data']; // Directly accessing 'data' since no pagination

        List<Map<String, dynamic>> newCustomers = [];

        for (var productData in productsData) {
          newCustomers.add({
            'id': productData['id'],
            'name': productData['name'],
            'created_at': productData['created_at'],
          });
        }

        // Update UI
        setState(() {
          customer = newCustomers;
        });
      } else {
        throw Exception("Failed to load customer data");
      }
    } catch (error) {
      ;
    }
  }

  String formatCreatedAtDate(Map<String, dynamic> reportData) {
    final rawDate = reportData[
        'created_at']; // Assuming it is a String like "2025-07-25T12:34:56Z"
    if (rawDate == null) return '';

    final parsedDate = DateTime.tryParse(rawDate);
    if (parsedDate == null) return '';

    final formattedDate = DateFormat('yyyy-MM-dd').format(parsedDate);
    return formattedDate;
  }

  Future<void> getreciptReport() async {
    setState(() {});
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/cod/transfers/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List<Map<String, dynamic>> reciptList = [];

        // Helper to get bank name by id
        String getBankName(dynamic bankId) {
          if (bankId == null) return '';
          final found = bank.firstWhere(
            (b) => b['id'] == bankId,
            orElse: () => {},
          );
          return found != null && found['name'] != null
              ? found['name'].toString()
              : '';
        }

        // The response is a List, so iterate directly
        for (var reportData in parsed) {
          reciptList.add({
            'type': 'Advance Receipt', // Or set type as needed
            'id': reportData['id'],

            'transactionID': reportData['transactionID'] ?? '',
            'amount': double.tryParse(reportData['amount'].toString()) ?? 0.0,

            'bank': reportData['bank'] ?? '',
            'receiver_bank_name': reportData['receiver_bank_name'],
            'bank_name': reportData['sender_bank_name'],
            'date': formatCreatedAtDate(reportData),
            'created_by_name': reportData['created_by_name'] ?? '',
            'remark': reportData['remark'] ?? '',
          });
        }

        setState(() {
          allSalesReportList = reciptList;
          salesReportList = allSalesReportList;
        });
        _updateTotals();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to fetch data'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error fetching data'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {});
    }
  }

// ...existing code...
  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        salesReportList =
            List.from(allSalesReportList); // Restore original data
      } else {
        salesReportList = allSalesReportList.where((product) {
          final bankName = product['bank_name']?.toString().toLowerCase() ?? '';
          final transactionId =
              product['transactionID']?.toString().toLowerCase() ?? '';
          final amount = product['amount']?.toString().toLowerCase() ?? '';

          return bankName.contains(query.toLowerCase()) ||
              transactionId.contains(query.toLowerCase()) ||
              amount.contains(query.toLowerCase());
        }).toList();
      }
    });

    _updateTotals();
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
                fontSize: 12,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
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
            "Cod Transfer List",
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
          ],
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search ...",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(
                      color: Colors.blue, // Set your desired border color here
                      width: 2.0, // Set the border width
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(
                      color: Colors
                          .blue, // Border color when TextField is not focused
                      width: 2.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(
                      color: Colors
                          .blueAccent, // Border color when TextField is focused
                      width: 2.0,
                    ),
                  ),
                ),
                onChanged: _filterProducts, // Filtering logic
              ),
            ),

            // Main content in Stack
            Expanded(
              child: RefreshIndicator(
                onRefresh: getreciptReport,
                child: Stack(
                  children: [
                    // Main content: Sales report list
                    SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: 260),
                      child: Column(
                        children: salesReportList.map((reportData) {
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
                                  SizedBox(height: 8),
                                  if (reportData['invoice'] != null &&
                                      reportData['invoice']
                                          .toString()
                                          .isNotEmpty)
                                    _buildRow(
                                        'Invoice:', reportData['invoice']),
                                  if (reportData['customer_name'] != null &&
                                      reportData['customer_name']
                                          .toString()
                                          .isNotEmpty)
                                    _buildRow('customer:',
                                        reportData['customer_name']),
                                  // ...rest of the code...

                                  _buildRow('Transaction ID:',
                                      reportData['transactionID']),
                                  _buildRow('Amount:', reportData['amount']),
                                  _buildRow('Received At:', reportData['date']),
                                  _buildRow(
                                      'Sender Bank:', reportData['bank_name']),
                                  _buildRow('Reciver Bank:',
                                      reportData['receiver_bank_name']),

                                  _buildRow('Created By:',
                                      reportData['created_by_name']),

                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  UpdateCodTransferList(
                                                    id: reportData['id'],
                                                  )));
                                      // Handle "View" button action
                                    },
                                    child: Text(
                                      "View",
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Bottom summary card
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Material(
                        elevation: 12,
                        color: const Color.fromARGB(255, 12, 80, 163),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                            color: const Color.fromARGB(255, 12, 80, 163),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
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
                                indent: 0,
                                endIndent: 0,
                              ),
                              Row(
                                children: [
                                  Text('Total Receipts: ',
                                      style: TextStyle(
                                          color:
                                              Colors.white)), // Add this line
                                  Spacer(),
                                  Text('$totalReceipts',
                                      style: TextStyle(
                                          color:
                                              Colors.white)), // Add this line
                                ],
                              ),
                              Row(
                                children: [
                                  Text('Total Amount: ',
                                      style: TextStyle(
                                          color:
                                              Colors.white)), // Add this line
                                  Spacer(),
                                  Text('$totalAmount',
                                      style: TextStyle(
                                          color:
                                              Colors.white)), // Add this line
                                ],
                              ),
                              SizedBox(height: 40),
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
