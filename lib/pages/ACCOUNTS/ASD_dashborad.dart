import 'dart:convert';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
import 'package:beposoft/pages/ACCOUNTS/customer.dart';
import 'package:beposoft/pages/ACCOUNTS/grv_list.dart';
import 'package:beposoft/pages/ACCOUNTS/order_list.dart';
import 'package:beposoft/pages/ACCOUNTS/performa_invoice_list.dart';
import 'package:beposoft/pages/ACCOUNTS/view_staff.dart';
import 'package:beposoft/pages/BDM/bdm_customer_list.dart';
import 'package:beposoft/pages/BDM/bdm_grv_list.dart';
import 'package:beposoft/pages/BDM/bdm_order_list.dart';
import 'package:beposoft/pages/BDM/bdm_staff_list.dart';
import 'package:beposoft/pages/BDM/bdm_today_order_list.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
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

class asd_dashbord extends StatefulWidget {
  @override
  State<asd_dashbord> createState() => _asd_dashbordState();
}

class _asd_dashbordState extends State<asd_dashbord> {
  List<String> statusOptions = ["pending", "approved", "rejected"];
  List<Map<String, dynamic>> grvlist = [];
  List<Map<String, dynamic>> proforma = [];
  List<Map<String, dynamic>> salesReportList = [];
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  List<Map<String, dynamic>> shippedOrders = [];
  List<Map<String, dynamic>> fam = [];

  String? username = '';
  @override
  void initState() {
    super.initState();
    _getUsername(); // Get the username when the page loads
    fetchproformaData();
    getSalesReport();
    fetchOrderData();
    getcustomer();
    getfamily();
    getprofiledata();
  }

int approval=0;
int confirm=0;
int customers=0;
  List<Map<String, dynamic>> customer = [];
  List<Map<String, dynamic>> filteredProducts = [];

var family='';
String familyName='';
   
Future<void> getprofiledata() async {
    try {
      final token = await getTokenFromPrefs();

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
          
getGrvList();

             var matchingFamily = fam.firstWhere(
          (element) => element['id'].toString() == family,
          orElse: () => {'id': null, 'name': 'Unknown'},
        );

        // Store the matching family name
        familyName = matchingFamily['name'];
        
        });
    fetchbdmOrderData();

      }
    } catch (error) {
      
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

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];
        List<Map<String, dynamic>> familylist = [];

        for (var productData in productsData) {
          familylist.add({
            'id': productData['id'].toString(), // Convert the ID to String
            'name': productData['name'],
          });
        }

        setState(() {
          fam = familylist;
          

        
        });
      }
    } catch (error) {
      
    }
  }



Future<void> getcustomer() async {
    try {
      final token = await getTokenFromPrefs();
            final username = await getusernameFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/customers/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

    

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];
        List<Map<String, dynamic>> managerlist = [];

        for (var productData in productsData) {
          if(username==productData['manager']){
          managerlist.add({
            'id': productData['id'],
            'name': productData['name'],
            'created_at': productData['created_at']
          });
          customers++;
          
          }


        }

        setState(() {
          customer = managerlist; // Update full customer list
          filteredProducts = List.from(customer); // Show all customers initially
        });
      }
    } catch (error) {
      
    }
  }

      // Variables to track the totals
      int totalOrdersToday = 0;
      int totalOrdersInvoiceCreated = 0;
      int Shippedorders=0;
        // Variables to track the totals
      int todaysbill = 0;
      int shippedbills=0;

      int waitingbills = 0;
  Future<void> fetchbdmOrderData() async {
  try {
    final token = await getTokenFromPrefs();
    

    String url = '$api/api/orders/';
    List<Map<String, dynamic>> orderList = [];

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

      List<Map<String, dynamic>> newOrders = [];



      DateTime currentDate = DateTime.now();
      String today = DateFormat('yyyy-MM-dd').format(currentDate);

      for (var orderData in ordersData) {
        String rawOrderDate = orderData['order_date'] ?? "";
        String formattedOrderDate = rawOrderDate;
        try {
          DateTime parsedOrderDate = DateFormat('yyyy-MM-dd').parse(rawOrderDate);
          formattedOrderDate = DateFormat('yyyy-MM-dd').format(parsedOrderDate);
        } catch (e) {}

        
          if (orderData['status'] != "Order Request by Warehouse") {
            if (familyName == orderData['family']) {
              newOrders.add({
                'id': orderData['id'],
                'family': orderData['family'],
                'invoice': orderData['invoice'],
                'manage_staff': orderData['manage_staff'],
                'customer': {
                  'id': orderData['customer']['id'],
                  'name': orderData['customer']['name'],
                  'phone': orderData['customer']['phone'],
                  'email': orderData['customer']['email'],
                  'address': orderData['customer']['address'],
                },
                'status': orderData['status'],
                'total_amount': orderData['total_amount'],
                'order_date': formattedOrderDate,
              });

              // Count orders for today
              if (formattedOrderDate == today) {
                totalOrdersToday++;
              }

              // Count orders with status "Invoice Created"
              if (orderData['status'] == "Invoice Created") {
                totalOrdersInvoiceCreated++;
              }
               if (formattedOrderDate == today && orderData['status'] == "Shipped") {
                Shippedorders++;
              }
            }
          }
        
      }

      setState(() {
        orders = newOrders;
        todaysbill=totalOrdersToday;
        waitingbills=totalOrdersInvoiceCreated;
shippedbills=Shippedorders;
        filteredOrders = newOrders;
      });

      // Print the counts (or use them as needed)
    
    } else {
      throw Exception("Failed to load order data");
    }
  } catch (error) {
  }
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
            DateTime parsedOrderDate =
                DateFormat('yyyy-MM-dd').parse(rawOrderDate);
            formattedOrderDate = DateFormat('yyyy-MM-dd')
                .format(parsedOrderDate); // Convert to desired format
          } catch (e) {
            
          }

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
           if (productData['status'] == 'Invoice Created') {
            approval++;


        }
        else if(productData['status'] == 'Invoice Approved'){
          confirm++;
        }
        }

        // Filter orders by 'Shipped' status and today's date
        DateTime today = DateTime.now();
        String formattedToday = DateFormat('yyyy-MM-dd').format(today);

        var shippedOrdersToday = orderList.where((order) {
          return order['status'] == 'Shipped' &&
              order['order_date'] == formattedToday; // Match today's date
        }).toList();

        // Get the length of today's shipped orders
        

        setState(() {
          orders = orderList;
          filteredOrders = orderList;
          shippedOrders =
              shippedOrdersToday; // Set filtered today's shipped orders
          
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
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text('Failed to fetch sales report data'),
        //     duration: Duration(seconds: 2),
        //   ),
        // );
      }
    } catch (error) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text('Error fetching sales report data'),
      //     duration: Duration(seconds: 2),
      //   ),
      // );
    } finally {
      setState(() {});
    }
  }
bool _isDisposed = false;

@override
void dispose() {
  _isDisposed = true;
  super.dispose();
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
      Uri.parse('$api/api/performa/invoice/staff/'),
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
          'customer_name': productData['customermame'], // corrected key
          'status': productData['status'],
          'total_amount': productData['total_amount'],
          'order_date': productData['order_date'],
          'created_at': '', // No such key in your sample, use empty or handle differently
        });
      }

      if (mounted) {
        setState(() {
          proforma = performaInvoiceList;
        });
      }

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
   Future<String?> getusernameFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }
int grv=0;
var grvpending;
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

    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);
      var productsData = parsed['data'];

      List<Map<String, dynamic>> grvDataList = [];
      int grv = 0;

      for (var productData in productsData) {
        if (family.toString() == productData['family'].toString()) {
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
          if (productData['status'] == "pending") {
            grv = grv + 1;
          }
        }
      }

      if (mounted) {
        setState(() {
          grvlist = grvDataList;
          grvpending = grv;
        });
      }

    }
  } catch (error) {
  }
}


  // Retrieve the username from SharedPreferences
  Future<void> _getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
          final name = await getusernameFromPrefs();
          

    setState(() {
      username = name ??
          'Guest'; // Default to 'Guest' if no username
    });
  }

 void logout() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  // await prefs.remove('department');
  // await prefs.remove('token');
  //   await prefs.remove('username');


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
            d.navigateToSelectedPage3(
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
                      MaterialPageRoute(builder: (context) => asd_dashbord()));
                },
              ),
              
              Divider(),
              _buildDropdownTile(context, 'Customers', [
                'Add Customer',
                'Customers',
              ]),
              // _buildDropdownTile(context, 'Staff', [
               
              //   'Staff',
              // ]),
             
              _buildDropdownTile(context, 'Proforma Invoice', [
                'New Proforma Invoice',
                'Proforma Invoice List',
              ]),
               _buildDropdownTile(
                  context, 'Orders', ['New Orders', 'Orders List']),
             
              Divider(),
        //        ListTile(
        //         leading: Icon(Icons.person_2),
        //         title: Text('Staff'),
        //         onTap: () {
        //          Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context) => bdm_staff_list(family: familyName,)),
        // );
        //         },
        //       ),
             
           
              Divider(),
              ListTile(
                leading: Icon(Icons.exit_to_app),
                title: Text('Logout'),
                onTap: () {
                  logout();
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

                // Discount/Bonus Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector
                      (
                        onTap: () {
                           Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => bdm_today_OrderList(status: null,)),
        );
                          

                        },
                        child: _buildInfoCard(todaysbill.toString(), 'Todays Bills', 0)),
                      GestureDetector(
                        onTap: () {
                           Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => bdm_OrderList(status: "Invoice Created",)),
        );
                        },
                        child: _buildInfoCard(waitingbills.toString(), 'Waiting For Approval', 0)),
                     
                    ],
                  ),
                ),

                SizedBox(height: 10),

                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.9,
                    children: [
                      // Display the count of today's shipped orders
                      GestureDetector(
                          onTap: () {
                         Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => bdm_today_OrderList(status: "Shipped",)),
        );
                      },
                        child: _buildGridItem(
                          Icons.local_shipping,
                          'Todays Shipped Orders',
                        shippedbills
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                         Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProformaInvoiceList()),
        );
                      },

                        child: _buildGridItem(Icons.request_quote, 'Proforma Invoice',
                            proforma.length),
                      ),
                    GestureDetector(
                      onTap: () {
                         Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => bdm_GrvList(status:'pending',family:familyName)),
        );
                      },
                        child: _buildGridItem(
                            Icons.receipt_long, 'GRV Created', grvpending),
                      ),
                      GestureDetector(
                         onTap: () {
                         Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => bdm_customer_list()),
        );
                      },
                        child: _buildGridItem(
                            Icons.pending_actions, 'Customers',customers),
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

  Widget _buildInfoCard(String value, String label, int notificationCount) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (notificationCount > 0)
              Positioned(
                top: -8,
                right: -8,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.red,
                  child: Text(
                    notificationCount.toString(),
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
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
