import 'dart:convert';
import 'package:beposoft/Sales%20Directors/SD_dashboard.dart';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/add_attribute.dart';
import 'package:beposoft/pages/ACCOUNTS/add_bank.dart';
import 'package:beposoft/pages/ACCOUNTS/add_company.dart';
import 'package:beposoft/pages/ACCOUNTS/add_department.dart';
import 'package:beposoft/pages/ACCOUNTS/add_family.dart';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
import 'package:beposoft/pages/ACCOUNTS/add_state.dart';
import 'package:beposoft/pages/ACCOUNTS/add_supervisor.dart';
import 'package:beposoft/pages/ACCOUNTS/customer.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/methods.dart';
import 'package:beposoft/pages/ACCOUNTS/performa_big_view.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ProformaInvoiceList extends StatefulWidget {
  const ProformaInvoiceList({super.key});

  @override
  State<ProformaInvoiceList> createState() => _ProformaInvoiceListState();
}

class _ProformaInvoiceListState extends State<ProformaInvoiceList> {
  drower d = drower();
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initdata();
  }

  var dep;
  void initdata() async {
    dep = await getdepFromPrefs();

    if (dep == "BDO" || dep == "BDM") {
      fetchOrderData2();
    } else {
      fetchOrderData();
    }
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchOrderData2() async {
  try {
    final token = await getTokenFromPrefs();

    final response = await http.get(
      Uri.parse('$api/api/performa/invoice/staff/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");
    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);
      final data = parsed['data'] as List;

      List<Map<String, dynamic>> performaInvoiceList = [];

      for (var productData in data) {
        performaInvoiceList.add({
          'id': productData['id'],
          'company': productData['company'],
          'invoice': productData['invoice'],
          'order_date': productData['order_date'],
          'code_charge': productData['code_charge'],
          'shipping_mode': productData['shipping_mode'] ?? 'N/A',
          'shipping_charge': productData['shipping_charge'],
          'payment_status': productData['payment_status'],
          'status': productData['status'],
          'total_amount': productData['total_amount'],
          'note': productData['note'] ?? 'No notes',
          'payment_method': productData['payment_method'],
          'manage_staff': productData['staffname'],
          'customer_name': productData['customermame'],
          'billing_address': productData['billing_address'],
          'family': productData['family'],
          'state': productData['state'],
          'bank': productData['bank'],
        });
      }

      setState(() {
        orders = performaInvoiceList.reversed.toList();
        filteredOrders = performaInvoiceList.reversed.toList();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  } catch (error) {
    setState(() {
      isLoading = false;
    });
  }
}

 Future<void> fetchOrderData() async {
  if (!mounted) return;
  try {
    final token = await getTokenFromPrefs();
    final response = await http.get(
      Uri.parse('$api/api/perfoma/invoices/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");
    if (response.statusCode == 200 && mounted) {
      final parsed = jsonDecode(response.body);
      final data = parsed['data'] as List;
      List<Map<String, dynamic>> performaInvoiceList = [];

      for (var productData in data) {
        performaInvoiceList.add({
          'id': productData['id'],
          'invoice': productData['invoice'],
          'manage_staff': productData['manage_staff'],
          'customer_name': productData['customer']['name'],
          'status': productData['status'],
          'total_amount': productData['total_amount'],
          'order_date': productData['order_date'],
          'created_at': productData['customer']['created_at'],
        });
      }

      setState(() {
        orders = performaInvoiceList;
        filteredOrders = performaInvoiceList;
        isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch orders data')),
      );
    }
  } catch (error) {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching orders data')),
      );
    }
  }
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

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  List<Map<String, dynamic>> filteredOrders = [];
  String searchQuery = '';

  void _filterOrders(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredOrders = orders;
        ;
      } else {
        ;
        filteredOrders = orders.where((order) {
          final customerName =
              order['customer_name']?.toString().toLowerCase() ?? '';
          final invoice = order['invoice']?.toString().toLowerCase() ?? '';
          final manageStaff =
              order['manage_staff']?.toString().toLowerCase() ?? '';
          final totalAmount =
              order['total_amount']?.toString().toLowerCase() ?? '';

          return customerName.contains(query.toLowerCase()) ||
              invoice.contains(query.toLowerCase()) ||
              manageStaff.contains(query.toLowerCase()) ||
              totalAmount.contains(query.toLowerCase());
        }).toList();
      }
    });
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
          title: const Text(
            'Performa Invoice List',
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
               else if (dep == "BDM") {
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
          centerTitle: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(color: Colors.blue, width: 2.0),
                  ),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: _filterOrders,
              ),
            ),
           Expanded(
  child: isLoading
      ? const Center(child: CircularProgressIndicator())
      : filteredOrders.isEmpty
          ? const Center(
              child: Text(
                'No performa data available',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            )
          : ListView.builder(
              itemCount: filteredOrders.length,
              padding: const EdgeInsets.all(8.0),
              itemBuilder: (context, index) {
                final order = filteredOrders[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PerformaInvoice_BigView_List(
                            invoice: order['invoice'],
                          ),
                        ),
                      );
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      color: Colors.white,
                      elevation: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(15.0),
                                topRight: Radius.circular(15.0),
                              ),
                            ),
                            padding: const EdgeInsets.all(5.0),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '#${order['invoice']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Date: ${order['order_date']}',
                                  style: const TextStyle(
                                      color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Staff: ${order['manage_staff']}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  'Customer: ${order['customer_name']}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8.0),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Billing Amount:',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${order['total_amount']}',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2.0),
                              ],
                            ),
                          ),
                        ],
                      ),
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
