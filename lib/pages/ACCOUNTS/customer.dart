import 'dart:convert';
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
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/customer_ledger.dart';
import 'package:beposoft/pages/ACCOUNTS/customer_singleview.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/navigateback.dart';
import 'package:beposoft/pages/ACCOUNTS/view_customer.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/MARKETING/marketing_dashboard.dart';
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

class customer_list extends StatefulWidget {
  const customer_list({super.key});

  @override
  State<customer_list> createState() => _customer_listState();
}

class _customer_listState extends State<customer_list> {
  List<Map<String, dynamic>> fam = [];
  List<bool> _checkboxValues = [];
  String? _selectedFamily;
  TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> filteredProducts = [];
  List<Map<String, dynamic>> searchFiltered = [];
  List<Map<String, dynamic>> familyFiltered = [];
  List<Map<String, dynamic>> stateFiltered = [];
  List<Map<String, dynamic>> sta = [];

  String? selectedFamilyFilter = "All";
  String? selectedStateFilter = "All";
  String? selectedStaffFilter = "All";
  int currentPage = 1;
  int totalPages = 1;
  bool loadingPage = false;

  List<String> categories = ["cycling", 'skating', 'fitness', 'bepocart'];
  String selectededu = "cycling";

  drower d = drower();

  List<Map<String, dynamic>> customer = [];
  List<Map<String, dynamic>> stat = [];

  @override
  void initState() {
    super.initState();
    getcustomer();
    getfamily();
    getstate();
    getstaff();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
            d.navigateToSelectedPage(context, option);
          },
        );
      }).toList(),
    );
  }

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<void> getcustomer({int page = 1}) async {
    try {
      setState(() {
        loadingPage = true;
      });

      final token = await gettokenFromPrefs();

      final Map<String, String> queryParams = {
        'page': page.toString(),
      };

      if (searchController.text.trim().isNotEmpty) {
        queryParams['search'] = searchController.text.trim();
      }

      final uri = Uri.parse('$api/api/customers/').replace(
        queryParameters: queryParams,
      );

      var response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List data = parsed['results'];
        int count = parsed['count'];
        totalPages = (count / 10).ceil();

        List<Map<String, dynamic>> newCustomers = [];

        for (var item in data) {
          newCustomers.add({
            'id': item['id'],
            'name': item['name'],
            'created_at': item['created_at'],
            'phone': item['phone'],
            'family': item['family'],
            'state_name': item['state_name'],
            'manager': item['manager'],
          });
        }

        setState(() {
          currentPage = page;
          customer = newCustomers;
        });

        applyFilters();
      } else {
        setState(() {
          customer = [];
          filteredProducts = [];
          totalPages = 1;
        });
      }
    } catch (e) {
      setState(() {
        customer = [];
        filteredProducts = [];
      });
    } finally {
      setState(() {
        loadingPage = false;
      });
    }
  }

  void applyFilters() {
    List<Map<String, dynamic>> temp = List.from(customer);

    if (selectedFamilyFilter != null && selectedFamilyFilter != "All") {
      temp = temp
          .where((cust) =>
              (cust['family'] ?? '').toString().toLowerCase() ==
              selectedFamilyFilter!.toLowerCase())
          .toList();
    }

    if (selectedStateFilter != null && selectedStateFilter != "All") {
      temp = temp
          .where((cust) =>
              (cust['state_name'] ?? '').toString().toLowerCase() ==
              selectedStateFilter!.toLowerCase())
          .toList();
    }

    if (selectedStaffFilter != null && selectedStaffFilter != "All") {
      temp = temp
          .where((cust) =>
              (cust['manager'] ?? '').toString() == selectedStaffFilter)
          .toList();
    }

    setState(() {
      filteredProducts = temp;
    });
  }

  Future<void> getstaff() async {
    try {
      final token = await gettokenFromPrefs();

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
            'email': productData['email']
          });
        }
        setState(() {
          sta = stafflist;
        });
      }
    } catch (error) {}
  }

  Future<void> getfamily() async {
    try {
      final token = await gettokenFromPrefs();
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
    } catch (error) {}
  }

  Future<void> getstate() async {
    try {
      final token = await gettokenFromPrefs();
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

  Widget paginationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed:
              currentPage > 1 ? () => getcustomer(page: currentPage - 1) : null,
          child: Text(
            "Prev",
            style: TextStyle(color: Colors.white),
          ),
        ),
        SizedBox(width: 10),
        Text(
          "Page $currentPage / $totalPages",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(width: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: currentPage < totalPages
              ? () => getcustomer(page: currentPage + 1)
              : null,
          child: Text(
            "Next",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('token');

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

    await Future.delayed(Duration(seconds: 2));

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
    } else if (dep == "CEO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ceo_dashboard()),
      );
    } else if (dep == "COO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ceo_dashboard()),
      );
    } else if (dep == "CSO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => cso_dashboard()),
      );
    } else if (dep == "Marketing") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => marketing_dashboard()),
      );
    } else if (dep == "Warehouse Admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WarehouseAdmin()),
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
        _navigateBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            "Customer List",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
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
              } else if (dep == "CEO") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ceo_dashboard()),
                );
              } else if (dep == "COO") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ceo_dashboard()),
                );
              } else if (dep == "CSO") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => cso_dashboard()),
                );
              } else if (dep == "Marketing") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => marketing_dashboard()),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => dashboard()),
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
        //  drawer: Drawer(
        //     child: ListView(
        //       padding: EdgeInsets.zero,
        //       children: <Widget>[
        //         DrawerHeader(
        //             decoration: BoxDecoration(
        //               color: Colors.grey[200],
        //             ),
        //             child: Row(
        //               mainAxisAlignment: MainAxisAlignment.center,
        //               children: [
        //                 Image.asset(
        //                   "lib/assets/logo.png",
        //                   width: 150,
        //                   height: 150,
        //                   fit: BoxFit.contain,
        //                 ),
        //               ],
        //             )),
        //         ListTile(
        //           leading: Icon(Icons.dashboard),
        //           title: Text('Dashboard'),
        //           onTap: () {
        //             Navigator.push(context,
        //                 MaterialPageRoute(builder: (context) => dashboard()));
        //           },
        //         ),
        //
        //         ListTile(
        //           leading: Icon(Icons.person),
        //           title: Text('Company'),
        //           onTap: () {
        //             Navigator.push(context,
        //                 MaterialPageRoute(builder: (context) => add_company()));
        //           },
        //         ),
        //         ListTile(
        //           leading: Icon(Icons.person),
        //           title: Text('Departments'),
        //           onTap: () {
        //             Navigator.push(
        //                 context,
        //                 MaterialPageRoute(
        //                     builder: (context) => add_department()));
        //           },
        //         ),
        //         ListTile(
        //           leading: Icon(Icons.person),
        //           title: Text('Supervisors'),
        //           onTap: () {
        //             Navigator.push(
        //                 context,
        //                 MaterialPageRoute(
        //                     builder: (context) => add_supervisor()));
        //           },
        //         ),
        //         ListTile(
        //           leading: Icon(Icons.person),
        //           title: Text('Family'),
        //           onTap: () {
        //             Navigator.push(context,
        //                 MaterialPageRoute(builder: (context) => add_family()));
        //           },
        //         ),
        //         ListTile(
        //           leading: Icon(Icons.person),
        //           title: Text('Bank'),
        //           onTap: () {
        //             Navigator.push(context,
        //                 MaterialPageRoute(builder: (context) => add_bank()));
        //           },
        //         ),
        //         ListTile(
        //           leading: Icon(Icons.person),
        //           title: Text('States'),
        //           onTap: () {
        //             Navigator.push(context,
        //                 MaterialPageRoute(builder: (context) => add_state()));
        //           },
        //         ),
        //         ListTile(
        //           leading: Icon(Icons.person),
        //           title: Text('Attributes'),
        //           onTap: () {
        //             Navigator.push(context,
        //                 MaterialPageRoute(builder: (context) => add_attribute()));
        //           },
        //         ),
        //         ListTile(
        //           leading: Icon(Icons.person),
        //           title: Text('Services'),
        //           onTap: () {
        //             Navigator.push(
        //                 context,
        //                 MaterialPageRoute(
        //                     builder: (context) => CourierServices()));
        //           },
        //         ),
        //         ListTile(
        //           leading: Icon(Icons.person),
        //           title: Text('Delivery Notes'),
        //           onTap: () {
        //             Navigator.push(
        //                 context,
        //                 MaterialPageRoute(
        //                     builder: (context) => WarehouseOrderView(status: null,)));
        //           },
        //         ),
        //         Divider(),
        //         _buildDropdownTile(context, 'Reports', [
        //           'Sales Report',
        //           'Credit Sales Report',
        //           'COD Sales Report',
        //           'Statewise Sales Report',
        //           'Expence Report',
        //           'Delivery Report',
        //           'Product Sale Report',
        //           'Stock Report',
        //           'Damaged Stock'
        //         ]),
        //         _buildDropdownTile(context, 'Customers', [
        //           'Add Customer',
        //           'Customers',
        //         ]),
        //         _buildDropdownTile(context, 'Staff', [
        //           'Add Staff',
        //           'Staff',
        //         ]),
        //         _buildDropdownTile(context, 'Credit Note', [
        //           'Add Credit Note',
        //           'Credit Note List',
        //         ]),
        //         _buildDropdownTile(context, 'Proforma Invoice', [
        //           'New Proforma Invoice',
        //           'Proforma Invoice List',
        //         ]),
        //         _buildDropdownTile(context, 'Delivery Note',
        //             ['Delivery Note List', 'Daily Goods Movement']),
        //         _buildDropdownTile(
        //             context, 'Orders', ['New Orders', 'Orders List']),
        //         Divider(),
        //         Text("Others"),
        //         Divider(),
        //         _buildDropdownTile(context, 'Product', [
        //           'Product List',
        //           'Product Add',
        //           'Stock',
        //         ]),
        //         _buildDropdownTile(context, 'Expence', [
        //           'Add Expence',
        //           'Expence List',
        //         ]),
        //         _buildDropdownTile(
        //             context, 'GRV', ['Create New GRV', 'GRVs List']),
        //         _buildDropdownTile(context, 'Banking Module',
        //             ['Add Bank ', 'List', 'Other Transfer']),
        //         Divider(),
        //         ListTile(
        //           leading: Icon(Icons.settings),
        //           title: Text('Methods'),
        //           onTap: () {
        //             Navigator.push(context,
        //                 MaterialPageRoute(builder: (context) => Methods()));
        //           },
        //         ),
        //         ListTile(
        //           leading: Icon(Icons.chat),
        //           title: Text('Chat'),
        //           onTap: () {
        //             Navigator.pop(context);
        //           },
        //         ),
        //         Divider(),
        //         ListTile(
        //           leading: Icon(Icons.exit_to_app),
        //           title: Text('Logout'),
        //           onTap: () {
        //             logout();
        //           },
        //         ),
        //       ],
        //     ),
        //   ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search customers..",
                      prefixIcon: Icon(Icons.search, color: Colors.blue),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide:
                            BorderSide(color: Colors.blueAccent, width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      getcustomer(page: 1);
                    },
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Flexible(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: "Family",
                            labelStyle: TextStyle(color: Colors.blue),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide:
                                  BorderSide(color: Colors.blue, width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(
                                  color: Colors.blueAccent, width: 2),
                            ),
                          ),
                          value: selectedFamilyFilter,
                          items: [
                            DropdownMenuItem(
                                value: "All", child: Text("All Family")),
                            ...fam.map(
                              (f) => DropdownMenuItem(
                                value: f['name'],
                                child: Text(
                                  f['name'],
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                          ],
                          onChanged: (val) {
                            setState(() {
                              selectedFamilyFilter = val;
                              selectedStateFilter = "All";
                              selectedStaffFilter = "All";
                            });
                            applyFilters();
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: "State",
                            labelStyle: TextStyle(color: Colors.blue),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide:
                                  BorderSide(color: Colors.blue, width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(
                                  color: Colors.blueAccent, width: 2),
                            ),
                          ),
                          value: selectedStateFilter,
                          items: [
                            DropdownMenuItem(
                                value: "All", child: Text("All States")),
                            ...stat.map(
                              (s) => DropdownMenuItem(
                                value: s['name'],
                                child: Text(
                                  s['name'],
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                          ],
                          onChanged: (val) {
                            setState(() {
                              selectedStateFilter = val;
                              selectedFamilyFilter = "All";
                              selectedStaffFilter = "All";
                            });
                            applyFilters();
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: "Staff",
                            labelStyle: TextStyle(color: Colors.blue),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide:
                                  BorderSide(color: Colors.blue, width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(
                                  color: Colors.blueAccent, width: 2),
                            ),
                          ),
                          value: selectedStaffFilter,
                          items: [
                            DropdownMenuItem(
                                value: "All", child: Text("All Staff")),
                            ...sta.map(
                              (s) => DropdownMenuItem(
                                value: s['id'].toString(),
                                child: Text(
                                  "${s['name']}",
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                          ],
                          onChanged: (val) {
                            setState(() {
                              selectedStaffFilter = val;
                              selectedFamilyFilter = "All";
                              selectedStateFilter = "All";
                            });
                            applyFilters();
                          },
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            paginationControls(),
            SizedBox(height: 10),
            if (loadingPage)
              Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final customerData = filteredProducts[index];
                  return Card(
                    color: Colors.white,
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, color: Colors.blue),
                            onSelected: (value) {
                              if (value == 'View') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => view_customer(
                                      customerid: customerData['id'],
                                    ),
                                  ),
                                );
                              } else if (value == 'Add Address') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => add_address(
                                      customerid: customerData['id'],
                                      name: customerData['name'],
                                    ),
                                  ),
                                );
                              } else if (value == 'View Ledger') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CustomerLedger(
                                      customerid: customerData['id'],
                                      customerName: customerData['name'],
                                    ),
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
            ),
          ],
        ),
      ),
    );
  }
}