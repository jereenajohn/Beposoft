import 'dart:convert';
import 'package:beposoft/pages/ACCOUNTS/Bulk_Bepocart_Orders.dart';
import 'package:beposoft/pages/ACCOUNTS/Today_shipped_orders.dart';
import 'package:beposoft/pages/ACCOUNTS/add_EMI.dart';
import 'package:beposoft/pages/ACCOUNTS/add_category.dart';
import 'package:beposoft/pages/ACCOUNTS/add_purpose_of_payment.dart';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
import 'package:beposoft/pages/ACCOUNTS/add_warehouse.dart';
import 'package:beposoft/pages/ACCOUNTS/assetmanagement.dart';
import 'package:beposoft/pages/ACCOUNTS/assetmanegment2.dart';
import 'package:beposoft/pages/ACCOUNTS/bulk_customer_upload.dart';
// import 'package:beposoft/pages/ACCOUNTS/call_log.dart';
import 'package:beposoft/pages/ACCOUNTS/graph.dart';
import 'package:beposoft/pages/ACCOUNTS/grv_list.dart';
import 'package:beposoft/pages/ACCOUNTS/order_list.dart';
import 'package:beposoft/pages/ACCOUNTS/performa_invoice_list.dart';
import 'package:beposoft/pages/ACCOUNTS/todays_orders_list.dart';
import 'package:beposoft/pages/ACCOUNTS/uploadbulkorders.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_product_approval.dart';
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
class marketing_dashboard extends StatefulWidget {
  @override
  State<marketing_dashboard> createState() => _marketing_dashboardState();
}

class _marketing_dashboardState extends State<marketing_dashboard> {
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
   fetchshippedorders();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    checkAppUpdate(context);
  });
  }
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

int approval=0;
int confirm=0;
int approvalcount=0;
int confirmcount=0;
int billcount=0;
double amountsum=0;


void getTodaysBills() {

    // Get today's date in the same format as in the response (yyyy-MM-dd)
    String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    // Find today's report entry
    var todaysReport = salesReportList.firstWhere(
      (report) => report['date'] == currentDate,
      orElse: () => {}, // Return null if no report for today
    );
setState(() {
  if (todaysReport['total_bills_in_date'] != null) {
      totalbills= todaysReport['total_bills_in_date'].toString();
      ;
    } else {

      totalbills= '0'; // Return '0' if no report is found for today
    }
  
});
    
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
      var productsData = parsed['results'];

      if (productsData != null && productsData is Iterable) {
        List<Map<String, dynamic>> orderList = [];

        DateTime today = DateTime.now();
        String formattedToday = DateFormat('yyyy-MM-dd').format(today);

        int bepocartOrderCount = 0;
        double bepocartTotalAmount = 0.0;

        for (var productData in productsData) {
          // Parse order_date directly
          String rawOrderDate = productData['order_date'] ?? '';
          String formattedOrderDate = rawOrderDate;

          try {
            DateTime parsedOrderDate = DateTime.parse(rawOrderDate);
            formattedOrderDate = DateFormat('yyyy-MM-dd').format(parsedOrderDate);
          } catch (_) {
            // skip invalid date
          }

          String familyName = productData['family_name'] ?? '';

          // Add order to list
          Map<String, dynamic> order = {
            'id': productData['id'],
            'invoice': productData['invoice'],
            'manage_staff': productData['manage_staff'],
            'customer': {
              'id': productData['customer']['id'],
              'name': productData['customer']['name'],
              'address': productData['billing_address']['address'],
            },
            'status': productData['status'],
            'order_date': formattedOrderDate,
            'total_amount': productData['total_amount'],
            'family_name': familyName,
          };

          orderList.add(order);

          // Status counters
          if (productData['status'] == 'Invoice Created') approval++;
          if (productData['status'] == 'Invoice Approved') confirm++;

          // Bepocart + today filter
          if (formattedOrderDate == formattedToday && familyName == 'bepocart') {
            bepocartOrderCount++;
            bepocartTotalAmount += double.tryParse(productData['total_amount'].toString()) ?? 0.0;
          }
        }

        // Optional: shipped today
        var shippedOrdersToday = orderList.where((order) {
          return order['status'] == 'Shipped' &&
                 order['order_date'] == formattedToday;
        }).toList();

        setState(() {
          orders = orderList;
          filteredOrders = orderList;
          shippedOrders = shippedOrdersToday;

          approvalcount = parsed['invoice_created_count'];
          confirmcount = parsed['invoice_approved_count'];
          billcount=bepocartOrderCount;
          amountsum=bepocartTotalAmount;

          // Print or store Bepocart summary
        
        });
      }
    }
  } catch (error) {
  }
}


int todayShippedCount = 0;
int todayOrdersTotalAmount = 0; // Add this to your state

Future<void> fetchshippedorders() async {
  try {
    final token = await getTokenFromPrefs();
    String url = '$api/api/orders/';

    var response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
 
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final List ordersData = responseData['results'];

      DateTime currentDate = DateTime.now();
      String today = DateFormat('yyyy-MM-dd').format(currentDate);

      int shippedTodayCount = 0;
      double totalAmount = 0.0;

      for (var orderData in ordersData) {
        String rawOrderDate = orderData['order_date'] ?? "";
        try {
          DateTime parsedOrderDate = DateFormat('yyyy-MM-dd').parse(rawOrderDate);
          String formattedOrderDate = DateFormat('yyyy-MM-dd').format(parsedOrderDate);

          if (formattedOrderDate == today) {
            // Sum total_amount for today's orders
            totalAmount += (orderData['total_amount'] ?? 0).toDouble();
            if (orderData['status'] == "Shipped") {
              shippedTodayCount++;
            }
          }
        } catch (e) {
          continue;
        }
      }

      setState(() {
        todayShippedCount = shippedTodayCount;
        todayOrdersTotalAmount = totalAmount.toInt(); // Store as int, or keep as double if needed
      });
    } else {
      throw Exception("Failed to load order data");
    }
  } catch (error) {
    // Handle error if needed
  }
}


 Future<void> getSalesReport() async {
  setState(() {});  // Keep the loading state if needed
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

      // Corrected the key
      var salesData = parsed['sales_report'];  

      if (salesData != null && salesData is Iterable) {
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
          ;
        });
        getTodaysBills();  // Get today's bills count
      }
    } 
  } catch (error) {
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('An error occurred while fetching data')),
      // );
    });
  } finally {
    setState(() {});  // End loading state
  }
}

var totalbills="0";


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
int grv=0;
int grvcount=0;
// Function to fetch GRV data
  Future<void> getGrvList() async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/grv/data/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
;
;
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
          if(productData['status']=="pending"){
            grv=grv+1;
          }
        }
        setState(() {
          grvlist = grvDataList;
          grvcount=grv;
        });

        // Get the count of grvlist
        int grvListCount = grvlist.length;
        
      } else {
     
      }
    } catch (error) {
    
      
    }
  }

  // Retrieve the username from SharedPreferences
  Future<void> _getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ??
          'Guest'; // Default to 'Guest' if no username
    });
  }

 void logout() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  // await prefs.remove('userId');
  // await prefs.remove('token');
  // await prefs.remove('username');
  //   await prefs.remove('department');

  

  // Use a post-frame callback to show the SnackBar after the current frame
  // WidgetsBinding.instance.addPostFrameCallback((_) {
  //   if (ScaffoldMessenger.of(context).mounted) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Logged out successfully'),
  //         duration: Duration(seconds: 2),
  //       ),
  //     );
  //   }
  // });

  // // Wait for the SnackBar to disappear before navigating
  // await Future.delayed(Duration(seconds: 2));

  // Navigate to the HomePage after the snackbar is shown
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => login()),
  );
}


  drower d = drower();

Widget _buildDropdownTile(
    BuildContext context, String title, List<String> options) {
  return ExpansionTile(
    backgroundColor: Colors.white,
    collapsedBackgroundColor: Colors.white,
    iconColor: Colors.black,
    collapsedIconColor: Colors.black,
    title: Text(
      title,
      style: const TextStyle(color: Colors.black),
    ),
    children: options.map((option) {
      return ListTile(
        tileColor: Colors.white,
        title: Text(
          option,
          style: const TextStyle(color: Colors.black),
        ),
        onTap: () {
          Navigator.pop(context);
          d.navigateToSelectedPage(context, option);
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
            backgroundColor: Colors.white,
            child: Container(
              color: Colors.white,
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
               DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.asset(
                            "lib/assets/appstore.png",
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
              // ListTile(
              //   leading: Icon(Icons.dashboard),
              //   title: Text('Dashboard'),
              //   onTap: () {
              //     Navigator.push(context,
              //         MaterialPageRoute(builder: (context) => Graph()));
              //   },
              // ),

               _buildDropdownTile(context, 'Customers', [
                'Add Customer',
                'Customers',
              ]),
               
              // ListTile(
              //   leading: Icon(Icons.dashboard),
              //   title: Text('Call Report'),
              //   onTap: () {
              //     Navigator.push(context,
              //         MaterialPageRoute(builder: (context) => CallLog()));
              //   },
              // ),
             
              _buildDropdownTile(
                  context, 'Orders', ['New Orders', 'Orders']),
              Divider(),
              ListTile(
                leading: Icon(Icons.add_shopping_cart), 
                title: Text('Bulk Order Creation'),
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => OrderBulkUpload()));
                  // Navigate to the Settings page or perform any other action
                },
              ),
              
                Divider(),
              ListTile(
  leading: const Icon(Icons.logout),
  title: const Text('Logout'),
  onTap: () async {
    await logoutUser(context);
  },
),
              SizedBox(height: 50), // Add some space at the bottom
            ],
          ),
        ),),
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
                              builder: (context) => EditProfileScreen()),
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
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 10),


                  Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.lightBlueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
          color: Colors.black12,
          blurRadius: 10,
          offset: Offset(0, 6),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date and Icon Row
                Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.95),
              ),
            ),
          ],
                ),
                SizedBox(height: 12),
          
                // Divider
                Container(
          height: 1,
          color: Colors.white.withOpacity(0.3),
                ),
                SizedBox(height: 16),
          
                // Info Cards Row
                Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => today_OrderList(status: null)),
                // );
              },
              child: _buildCardWithIcon(
             
                label: 'Today\'s Bills',
                value: billcount.toString(),
                color: Colors.white,
              ),
            ),
            _buildCardWithIcon(
             
              label: 'Total Volume',
              value: amountsum.toString(),
              color: Colors.white,
            ),
            
          ],
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

 Widget _buildCardWithIcon({
  
  required String label,
  required String value,
  Color color = Colors.white,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
     
      SizedBox(height: 6),
      Text(
        value,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      SizedBox(height: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color.withOpacity(0.9),
        ),
      ),
    ],
  );
}
  Widget _buildGridItem(IconData icon, String title, [int? count]) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Stack(
          clipBehavior: Clip.none, // Prevents the badge from clipping the card
          children: [
            // Main content of the card - Center the text and icon
            Center(
              // Wrap the Column in a Center widget
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Vertically center
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Horizontally center
                children: [
                  Icon(icon, size: 36, color: Colors.blue),
                  SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            // Notification Badge
            if (count != null && count > 0)
              Positioned(
                top: -8,
                right: -8,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[600],
                  child: Text(
                    count.toString(),
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
