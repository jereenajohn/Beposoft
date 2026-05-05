import 'dart:convert';

import 'package:beposoft/Sales%20Directors/SD_dashboard.dart';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/add_address.dart';
import 'package:beposoft/pages/ACCOUNTS/add_attribute.dart';
import 'package:beposoft/pages/ACCOUNTS/add_bank.dart';
import 'package:beposoft/pages/ACCOUNTS/add_company.dart';
import 'package:beposoft/pages/ACCOUNTS/add_department.dart';
import 'package:beposoft/pages/ACCOUNTS/add_family.dart';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
import 'package:beposoft/pages/ACCOUNTS/add_state.dart';
import 'package:beposoft/pages/ACCOUNTS/add_supervisor.dart';
import 'package:beposoft/pages/ACCOUNTS/customer_ledger.dart';
import 'package:beposoft/pages/ACCOUNTS/customer_singleview.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/view_customer.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import 'package:beposoft/main.dart';
import 'package:beposoft/pages/ACCOUNTS/add_credit_note.dart';
import 'package:beposoft/pages/ACCOUNTS/customer.dart';
import 'package:beposoft/pages/ACCOUNTS/recipts_list.dart';
import 'package:beposoft/pages/ACCOUNTS/add_new_stock.dart';
import 'package:beposoft/pages/ACCOUNTS/credit_note_list.dart';
import 'package:beposoft/pages/ACCOUNTS/methods.dart';
import 'package:beposoft/pages/ACCOUNTS/new_product.dart';
import 'package:beposoft/pages/ACCOUNTS/order_request.dart';
import 'package:beposoft/pages/ACCOUNTS/purchases_request.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:beposoft/pages/ACCOUNTS/add_new_customer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class bdm_customer_list extends StatefulWidget {
  const bdm_customer_list({super.key});

  @override
  State<bdm_customer_list> createState() => _bdm_customer_listState();
}

class _bdm_customer_listState extends State<bdm_customer_list> {
  List<Map<String, dynamic>> fam = [];
  List<bool> _checkboxValues = [];
  String? _selectedFamily;
  TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> filteredProducts = [];
  int currentPage = 1;
  int totalPages = 1;
  String? nextPageUrl;
  String? previousPageUrl;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    initdata();
  }

  void initdata() async {
    await getprofiledata();
  }

  List<String> categories = ["cycling", 'skating', 'fitness', 'bepocart'];
  String selectededu = "cycling";

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

  List<Map<String, dynamic>> customer = [];
  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  var family = '';
  String familyName = '';

  Future<void> getprofiledata() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        setState(() {
          family = productsData['family'].toString() ?? '';

          familyName = productsData['family_name'] ?? '';

          //      var matchingFamily = fam.firstWhere(
          //   (element) => element['id'].toString() == family,
          //   orElse: () => {'id': null, 'name': 'Unknown'},
          // );

          // // Store the matching family name
          // familyName = matchingFamily['name'];
        });
        getcustomer();
      }
    } catch (error) {}
  }

 Future<void> getcustomer({String? url}) async {
  try {
    final token = await gettokenFromPrefs();

    if (family.isEmpty) {
      print("Family ID is empty. Cannot fetch customers.");
      return;
    }

    final requestUrl = url ??
        '$api/api/customers/division/$family/?page=$currentPage&search=${Uri.encodeComponent(searchQuery)}';

    print("Customer API URL: $requestUrl");

    var response = await http.get(
      Uri.parse(requestUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print("Customer API Status: ${response.statusCode}");
    print("Customer API Body: ${response.body}");

    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);

      nextPageUrl = parsed['next'];
      previousPageUrl = parsed['previous'];

      int count = parsed['count'] ?? 0;
      totalPages = count == 0 ? 1 : (count / 10).ceil();

      List results = parsed['results'] ?? [];

      List<Map<String, dynamic>> managerlist = [];

      for (var productData in results) {
        managerlist.add({
          'id': productData['id'],
          'name': productData['name'],
          'created_at': productData['created_at'],
          'phone': productData['phone'],
          'state_name': productData['state_name'],
          'family': productData['family'],
        });
      }

      setState(() {
        customer = managerlist;
        filteredProducts = List.from(customer);
      });
    } else {
      print("Failed to fetch customers: ${response.statusCode}");
    }
  } catch (e) {
    print("Customer fetch error: $e");
  }
}

  void _filterProducts(String query) {
  searchQuery = query;
  currentPage = 1;
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

  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();
    if (dep == "BDO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                bdo_dashbord()), // Replace AnotherPage with your target page
      );
    }
     else if (dep == "SD") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                SdDashboard()), // Replace AnotherPage with your target page
      );
    }
     else if (dep == "BDM") {
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
        MaterialPageRoute(builder: (context) => dashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Trigger the navigation logic when the back swipe occurs
        _navigateBack();
        return false; // Prevent the default back navigation behavior
      },
      child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              "Customer List",
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
                }
                    else if (dep == "SD") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                SdDashboard()), // Replace AnotherPage with your target page
      );
    }
                 else if (dep == "CEO") {
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
              IconButton(
                icon: Image.asset('lib/assets/profile.png'),
                onPressed: () {},
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Search customers..",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(
                        color:
                            Colors.blue, // Set your desired border color here
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
                  onChanged: _filterProducts,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// PREVIOUS BUTTON
                    ElevatedButton(
                      
                      onPressed: previousPageUrl == null
                          ? null
                          : () {
                              currentPage--;
                              getcustomer(url: previousPageUrl);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[300],
                        foregroundColor: Colors.black,
                      ),
                      child: Text("Prev",style: TextStyle(color: Colors.white)),
                    ),

                    SizedBox(width: 20),

                    Text(
                      "Page $currentPage / $totalPages",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),

                    SizedBox(width: 20),

                    /// NEXT BUTTON
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[300],
                        foregroundColor: Colors.black,
                      ),
                      onPressed: nextPageUrl == null
                          ? null
                          : () {
                              currentPage++;
                              getcustomer(url: nextPageUrl);
                            },
                      child: Text("Next",style: TextStyle(color: Colors.white),),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final customerData = filteredProducts[index];

                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customerData['name'] ?? '',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Created on: ${customerData['created_at']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// KEEP THIS EXACTLY AS YOU WROTE
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: Colors.blue),
                              onSelected: (value) {
                                if (value == 'View') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => view_customer(
                                          customerid: customerData['id']),
                                    ),
                                  );
                                } else if (value == 'Add Address') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => add_address(
                                          customerid: customerData['id'],
                                          name: customerData['name']),
                                    ),
                                  );
                                } else if (value == 'View Ledger') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CustomerLedger(
                                          customerid: customerData['id'],
                                          customerName: customerData['name']),
                                    ),
                                  );
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                PopupMenuItem<String>(
                                  value: 'View',
                                  child: Text('View'),
                                ),
                                PopupMenuItem<String>(
                                  value: 'Add Address',
                                  child: Text('Add Address'),
                                ),
                                PopupMenuItem<String>(
                                  value: 'View Ledger',
                                  child: Text('View Ledger'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          )),
    );
  }
}
