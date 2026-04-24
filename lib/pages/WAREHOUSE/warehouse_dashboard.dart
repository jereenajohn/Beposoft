import 'dart:convert';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
import 'package:beposoft/pages/ACCOUNTS/order_list.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:beposoft/pages/logout_hekper.dart';
import 'package:intl/intl.dart';

import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/add_attribute.dart';
import 'package:beposoft/pages/ACCOUNTS/add_bank.dart';
import 'package:beposoft/pages/ACCOUNTS/add_company.dart';
import 'package:beposoft/pages/ACCOUNTS/add_department.dart';
import 'package:beposoft/pages/ACCOUNTS/add_family.dart';
import 'package:beposoft/pages/ACCOUNTS/add_state.dart';
import 'package:beposoft/pages/ACCOUNTS/add_supervisor.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/methods.dart';
import 'package:beposoft/pages/ACCOUNTS/profilepage.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
class WarehouseDashboard extends StatefulWidget {
  @override
  State<WarehouseDashboard> createState() => _WarehouseDashboardState();
}

class _WarehouseDashboardState extends State<WarehouseDashboard> {
  List<String> statusOptions = ["pending", "approved", "rejected"];
  List<Map<String, dynamic>> grvlist = [];
  List<Map<String, dynamic>> proforma = [];
  List<Map<String, dynamic>> salesReportList = [];
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  List<Map<String, dynamic>> shippedOrders = [];

  String? username = '';
  @override
  void initState() {
    super.initState();
    _getUsername(); // Get the username when the page loads
    getGrvList();
    fetchproformaData();
    getSalesReport();
    fetchOrderData();
         WidgetsBinding.instance.addPostFrameCallback((_) {
    checkAppUpdate(context);
  });
  }

int toprint=0;
int packed=0;
Future<bool> checkAppUpdate(BuildContext context) async {
  final packageInfo = await PackageInfo.fromPlatform();
  final currentVersion = packageInfo.version;

  try {
    final response = await http.get(Uri.parse(
      'https://play.google.com/store/apps/details?id=com.bepositive.beposoft&hl=en',
    ));

    if (response.statusCode == 200) {
      final content = response.body;
      final versionRegex = RegExp(r'\[\[\["([0-9.]+)"\]\]');
      final match = versionRegex.firstMatch(content);

      if (match != null) {
        final storeVersion = match.group(1);
        if (storeVersion != null && storeVersion != currentVersion) {
          final result = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.only(top: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              title: Column(
                children: [
                  Icon(Icons.system_update, size: 48, color: Colors.green),
                  const SizedBox(height: 10),
                  const Text(
                    'Update Available',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Text(
                'A new version ($storeVersion) is available.\n\nYou are using $currentVersion.\n\nPlease update the app to continue enjoying the latest features and improvements.',
                style: const TextStyle(fontSize: 16),
              ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  label: const Text("Update Now"),
                  onPressed: () async {
                    final playStoreUrl = Uri.parse(
                      'https://play.google.com/store/apps/details?id=com.bepositive.beposoft');
                    if (await canLaunchUrl(playStoreUrl)) {
                      await launchUrl(playStoreUrl, mode: LaunchMode.externalApplication);
                    }
                    Navigator.of(context).pop(false); // Prevent app from loading
                  },
                ),
                TextButton(
                  child: const Text("Maybe Later"),
                  onPressed: () => Navigator.of(context).pop(true), // Continue with app
                ),
              ],
            ),
          );
          return result == true;
        }
      }
    }
  } catch (e) {
    // Optionally log error
  }

  return true; // Proceed normally if no update
}

 Future<void> fetchOrderData() async {
  try {
    final token = await getTokenFromPrefs();
    var response = await http.get(
      Uri.parse('$api/api/orders/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    

    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);
      var productsData = parsed;
      List<Map<String, dynamic>> orderList = [];

      for (var productData in productsData) {
        String rawOrderDate = productData['order_date'];
        String formattedOrderDate = rawOrderDate;

        try {
          DateTime parsedOrderDate = DateFormat('yyyy-MM-dd').parse(rawOrderDate);
          formattedOrderDate = DateFormat('yyyy-MM-dd').format(parsedOrderDate); // Convert to desired format
        } catch (e) {
          
        }

        // Add to orderList if status is "Shipped" or "To "
       
          orderList.add({
            'id': productData['id'],
            'invoice': productData['invoice'],
            'manage_staff': productData['manage_staff'],
            'customer': {
              'name': productData['customer']['name'],
              'phone': productData['customer']['phone'],
              'email': productData['customer']['email'],
              'address': productData['customer']['address'],
            },
            'billing_address': {
              'name': productData['billing_address']['name'],
              'email': productData['billing_address']['email'],
              'zipcode': productData['billing_address']['zipcode'],
              'address': productData['billing_address']['address'],
              'phone': productData['billing_address']['phone'],
              'city': productData['billing_address']['city'],
              'state': productData['billing_address']['state'],
            },
            'bank': {
              'name': productData['bank']['name'],
              'account_number': productData['bank']['account_number'],
              'ifsc_code': productData['bank']['ifsc_code'],
              'branch': productData['bank']['branch'],
            },
            'items': productData['items'] != null
                ? productData['items'].map((item) {
                    return {
                      'id': item['id'],
                      'name': item['name'],
                      'quantity': item['quantity'],
                      'price': item['price'],
                      'tax': item['tax'],
                      'discount': item['discount'],
                      'images': item['images'],
                    };
                  }).toList()
                : [],
            'status': productData['status'],
            'total_amount': productData['total_amount'],
            'order_date': formattedOrderDate, // Use the formatted string
          });
           if (productData['status'] == 'To Print') {
            toprint++;


        }
        else if(productData['status'] == 'Packed'){
          packed++;
        }
      }


      setState(() {
        orders = orderList;
        
        filteredOrders = orderList;
      });
    }
  } catch (error) {
    
  }
}


  Future<void> getSalesReport() async {
    setState(() {});
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/salesreport'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var salesData = parsed['Sales report'];

        List<Map<String, dynamic>> salesReportDataList = [];
        for (var reportData in salesData) {
          salesReportDataList.add({
            'date': reportData['date'],
            'total_bills_in_date': reportData['total_bills_in_date'],
            'amount': reportData['amount'],
            'approved': {
              'bills': reportData['approved']['bills'],
              'amount': reportData['approved']['amount']
            },
            'rejected': {
              'bills': reportData['rejected']['bills'],
              'amount': reportData['rejected']['amount']
            }
          });
        }

        setState(() {
          salesReportList = salesReportDataList;
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
      setState(() {});
    }
  }

  String getTodaysBills() {
    // Get today's date in the same format as in the response (yyyy-MM-dd)
    String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Find today's report entry
    var todaysReport = salesReportList.firstWhere(
      (report) => report['date'] == currentDate,
      orElse: () => {}, // Return null if no report for today
    );

    if (todaysReport['total_bills_in_date'] != null) {
      return todaysReport['total_bills_in_date'].toString();
    } else {
      return '0'; // Return '0' if no report is found for today
    }
  }



  Future<void> fetchproformaData() async {
    try {
      final token = await getTokenFromPrefs();
      final response = await http.get(
        Uri.parse('$api/api/perfoma/invoices/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
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
          proforma = performaInvoiceList;
        });
        int proformalistcount = proforma.length;
        
      } else {
        
      }
    } catch (error) {
      
    }
  }

// Get token from SharedPreferences
  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

// Function to fetch GRV data
  Future<void> getGrvList() async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/grvget/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        List<Map<String, dynamic>> grvDataList = [];
        for (var productData in productsData) {
          grvDataList.add({
            'id': productData['id'],
            'product': productData['product'],
            'returnreason': productData['returnreason'],
            'invoice': productData['invoice'],
            'customer': productData['customer'],
            'staff': productData['staff'],
            'remark': productData['remark'],
            'status': productData['status'] ?? statusOptions[0],
            'order_date': productData['order_date'],
          });
        }
        setState(() {
          grvlist = grvDataList;
        });

        // Get the count of grvlist
        int grvListCount = grvlist.length;
        
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to fetch GRV data'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error fetching GRV data'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
 Future<String?> getusernameFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }
  // Retrieve the username from SharedPreferences
  Future<void> _getUsername() async {
          final name = await getusernameFromPrefs();
    setState(() {
      username =name??
          'Guest'; // Default to 'Guest' if no username
    });
  }

 void logout(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  // await prefs.remove('userId');
  // await prefs.remove('token');
  // await prefs.remove('username');
  // await prefs.remove('department');
  // await prefs.remove('warehouse');
  await Future.delayed(Duration(milliseconds: 100));
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => login()),
  );
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          // leading: Icon(Icons.arrow_back, color: Colors.black),
          actions: [
            //  IconButton(
            //     icon: Image.asset('lib/assets/profile.png'),

            //     onPressed: () {
            //       Navigator.push(context, MaterialPageRoute(builder: (context)=>EditProfileScreen()));

            //     },
            //   ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "lib/assets/logo.png",
                        width: 150, // Change width to desired size
                        height: 150, // Change height to desired size
                        fit: BoxFit
                            .contain, // Use BoxFit.contain to maintain aspect ratio
                      ),
                    ],
                  )),
              ListTile(
                leading: Icon(Icons.dashboard),
                title: Text('Dashboard'),
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => WarehouseDashboard()));
                },
              ),
             
              Divider(),
              
              _buildDropdownTile(context, 'Delivery Note',
                  ['Delivery Note List(All)','Delivery Note List(To Print)','Delivery Note List(Packing under Progress)','Delivery Note List(Packed)','Delivery Note List(Ready to ship)','Delivery Note List(Shipped)', 'Daily Goods Movement']),
           



              _buildDropdownTile(
                  context, 'GRV', ['Create New GRV', 'GRVs List']),
            
              Divider(),
             
             
              Divider(),
             ListTile(
  leading: const Icon(Icons.logout),
  title: const Text('Logout'),
  onTap: () async {
    await logoutUser(context);
  },
),
            ],
          ),
        ),
        body: SafeArea(
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Section
        Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 25,
                backgroundImage: AssetImage(
                    'lib/assets/female.jpeg'), // Replace with your new image
              ),
            ),
            SizedBox(width: 16),
            Text(
              '$username',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),

        SizedBox(height: 10),

        Expanded(
          child: ListView(
            children: [
              // Display the count of today's shipped orders in cards
              GestureDetector(
                onTap: () {
                  Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => WarehouseOrderView(status:'To Print' ,)),
        );
                },
                child: _buildCard(
                  Icons.local_shipping,
                  'Waiting For Packing  ',
                  toprint
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => WarehouseOrderView(status:'Packed')),
        );
                  
                },
                child: _buildCard(
                  Icons.request_quote, 
                  'Waiting For Shipping', 
                  packed
                ),
              ),
              
            ],
          ),
        ),
      ],
    ),
  ),
),


      ),
    );
  }
Widget _buildCard(IconData icon, String title, [int count = 0]) {
  return Container(
    height: 120.0, // Set a fixed height for each card
    margin: EdgeInsets.symmetric(vertical: 8.0),
    child: Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Stack(
        children: [
          
          Column(
            children: [
              SizedBox(height: 20,),
              ListTile(
                leading: Icon(icon, size: 40, color: Colors.blue),
                title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  // Handle item tap if needed
                },
              ),
            ],
          ),
          if (count > 0) 
            Positioned(
              top: 8.0,
              right: 8.0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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
