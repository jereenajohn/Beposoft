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
import 'package:beposoft/pages/ACCOUNTS/cso_statewise_orderlist.dart';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/methods.dart';
import 'package:beposoft/pages/ACCOUNTS/statewise_order_list.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Import the intl package for date formatting
class cso_StateWiseReport2 extends StatefulWidget {
  const cso_StateWiseReport2({super.key});

  @override
  State<cso_StateWiseReport2> createState() => _cso_StateWiseReport2State();
}

class _cso_StateWiseReport2State extends State<cso_StateWiseReport2> {
  List<Map<String, dynamic>> expensedata = [];
  List<Map<String, dynamic>> filteredData = [];
  List<Map<String, dynamic>> filteredOrders = [];
  DateTime? startDate;
  DateTime? endDate;
double totalAmount = 0.0;
        int totalOrdersCount = 0;
  TextEditingController searchController = TextEditingController();
List<Map<String, dynamic>> sta = [];
    int? selectedstaffId;

  @override
  void initState() {
    super.initState();
    getstatewisereport();
    getstaff();
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
  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
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
      _filterOrdersByDateRange();
    }
  }

  // Method to filter expenses by single date
void _filterOrdersByDateRange() {
  
  
  

  if (startDate != null && endDate != null) {
    setState(() {
      // Normalize startDate and endDate to remove time components
      startDate = DateTime(startDate!.year, startDate!.month, startDate!.day);
      endDate = DateTime(endDate!.year, endDate!.month, endDate!.day);

      // Filter states and their orders
      filteredData = expensedata
          .where((stateData) {
            List<dynamic> orders = stateData['orders'] ?? [];

            // Check if any orders match the date range
            List<dynamic> filteredOrders = orders.where((o) {
              final orderDateString = o['order_date'];
              try {
                final orderDate = DateFormat('yyyy-MM-dd').parse(orderDateString).toLocal();
                return (orderDate.isAtSameMomentAs(startDate!) || orderDate.isAfter(startDate!)) &&
                       (orderDate.isAtSameMomentAs(endDate!) || orderDate.isBefore(endDate!));
              } catch (e) {
                
                return false;
              }
            }).toList();

            // Only keep the state if there are matching orders
            if (filteredOrders.isNotEmpty) {
              // Replace the 'orders' with filtered orders
              stateData['orders'] = filteredOrders;
              return true;
            }
            return false;
          })
          .toList(); // Ensure final result is a List<Map<String, dynamic>>

      ;

      // Aggregate totals based on the filtered data
      List<Map<String, dynamic>> aggregatedData = [];

      for (var stateData in filteredData) {
        int totalOrdersCount = 0;
        double totalAmount = 0.0;

        int completedOrdersCount = 0;
        double completedAmount = 0.0;

        int cancelledOrdersCount = 0;
        double cancelledAmount = 0.0;

        int refundedOrdersCount = 0;
        double refundedAmount = 0.0;

        int returnedOrdersCount = 0;
        double returnedAmount = 0.0;

        // Iterate through the filtered orders
        List<dynamic> orders = stateData['orders'] ?? [];
        for (var order in orders) {
          // Increment total orders count and amount
          totalOrdersCount += 1;
          totalAmount += (order['total_amount'] as num?)?.toDouble() ?? 0.0;

          String status = order['status']?.toString() ?? '';

          // Handle different statuses
          switch (status) {
            case 'Shipped':
              completedOrdersCount += 1;
              completedAmount += (order['total_amount'] as num?)?.toDouble() ?? 0.0;
              break;
            case 'Invoice Rejected':
              cancelledOrdersCount += 1;
              cancelledAmount += (order['total_amount'] as num?)?.toDouble() ?? 0.0;
              break;
            case 'Refunded':
              refundedOrdersCount += 1;
              refundedAmount += (order['total_amount'] as num?)?.toDouble() ?? 0.0;
              break;
            case 'Return':
              returnedOrdersCount += 1;
              returnedAmount += (order['total_amount'] as num?)?.toDouble() ?? 0.0;
              break;
            default:
              
              break;
          }
        }

        // Add the aggregated data for this state
        aggregatedData.add({
          'id': stateData['id'] ?? 'Unknown ID',
          'name': stateData['name'] ?? 'Unknown Name',
          'total_orders_count': totalOrdersCount,
          'total_amount': totalAmount,
          'completed_orders_count': completedOrdersCount,
          'completed_amount': completedAmount,
          'cancelled_orders_count': cancelledOrdersCount,
          'cancelled_amount': cancelledAmount,
          'refunded_orders_count': refundedOrdersCount,
          'refunded_amount': refundedAmount,
          'returned_orders_count': returnedOrdersCount,
          'returned_amount': returnedAmount,
        });
      }

      // Update the state with the aggregated data
      filteredData = aggregatedData;
      
    });
  }
}
void _filterOrdersByStaffId() {
  
  

  if (selectedstaffId != null) {
    setState(() {
      

      // Debug: Check all orders for each state
      expensedata.forEach((stateData) {
        
      });

      // Filter states containing orders with the selected staff ID
      filteredData = expensedata
          .where((stateData) {
            List<dynamic> orders = stateData['orders'] ?? [];
            // Check if any order matches the selected staff ID
            bool hasMatchingOrders = orders.any((order) {
              
              return order['staffID'].toString() == selectedstaffId.toString();
            });
            return hasMatchingOrders;
          })
          .map<Map<String, dynamic>>((stateData) {
            List<dynamic> orders = stateData['orders'] ?? [];

            // Filter orders based on the selected staff ID
            List<dynamic> filteredOrders = orders
                .where((order) => order['staffID'].toString() == selectedstaffId.toString())
                .toList();

            

            // Initialize counters for order statuses
            int totalOrdersCount = 0;
            double totalAmount = 0.0;

            int completedOrdersCount = 0;
            double completedAmount = 0.0;

            int cancelledOrdersCount = 0;
            double cancelledAmount = 0.0;

            int refundedOrdersCount = 0;
            double refundedAmount = 0.0;

            int returnedOrdersCount = 0;
            double returnedAmount = 0.0;

            // Process the filtered orders
            for (var order in filteredOrders) {
              totalOrdersCount++;
              totalAmount += (order['total_amount'] as num?)?.toDouble() ?? 0.0;

              String status = order['status']?.toString() ?? '';
              
              switch (status) {
                case 'Shipped':
                  completedOrdersCount++;
                  completedAmount += (order['total_amount'] as num?)?.toDouble() ?? 0.0;
                  break;
                case 'Invoice Rejected':
                  cancelledOrdersCount++;
                  cancelledAmount += (order['total_amount'] as num?)?.toDouble() ?? 0.0;
                  break;
                case 'Refunded':
                  refundedOrdersCount++;
                  refundedAmount += (order['total_amount'] as num?)?.toDouble() ?? 0.0;
                  break;
                case 'Return':
                  returnedOrdersCount++;
                  returnedAmount += (order['total_amount'] as num?)?.toDouble() ?? 0.0;
                  break;
              }
            }

            // Return the updated state with filtered orders and counts
            return {
              ...stateData, // Spread original state data
              'orders': filteredOrders, // Replace orders with filtered list
              'total_orders_count': totalOrdersCount,
              'total_amount': totalAmount,
              'completed_orders_count': completedOrdersCount,
              'completed_amount': completedAmount,
              'cancelled_orders_count': cancelledOrdersCount,
              'cancelled_amount': cancelledAmount,
              'refunded_orders_count': refundedOrdersCount,
              'refunded_amount': refundedAmount,
              'returned_orders_count': returnedOrdersCount,
              'returned_amount': returnedAmount,
            };
          })
          .toList();

      
      
    });
  }
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
           if ((productData['department_name'] ?? '').toString().toLowerCase() == 'bdm' ||
    (productData['department_name'] ?? '').toString().toLowerCase() == 'bdo') {

          stafflist.add({
            'id': productData['id'],
            'name': productData['name'],
          });
        }}
        setState(() {
          sta = stafflist;
          
        });
      }
    } catch (error) {
      
    }
  }

var count;
var amount;
Future<void> getstatewisereport() async {
  try {
    final token = await gettokenFromPrefs();

    var response = await http.get(
      Uri.parse('$api/api/state/wise/report/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);

      // Debugging the API response
      

      if (parsed is Map && parsed.containsKey('data')) {
        final List<dynamic> statewiseData = parsed['data'];
        List<Map<String, dynamic>> statewiselist = [];
        

        for (var stateData in statewiseData) {
          int totalOrdersCount = 0;
          double totalAmount = 0.0;

          int completedOrdersCount = 0;
          double completedAmount = 0.0;

          int cancelledOrdersCount = 0;
          double cancelledAmount = 0.0;

          int refundedOrdersCount = 0;
          double refundedAmount = 0.0;

          int returnedOrdersCount = 0;
          double returnedAmount = 0.0;

          // Process orders for the current state
          List<dynamic> orders = stateData['orders'] ?? [];
          List<Map<String, dynamic>> processedOrders = [];

          for (var order in orders) {
            List<dynamic> waitingOrders = order['waiting_orders'] ?? [];

            for (var waitingOrder in waitingOrders) {
              // Skip orders with family == "bepocart"
              if ((waitingOrder['family'] ?? '').toString().toLowerCase() == 'bepocart') {
                continue;
              }

              // Aggregate totals
              totalOrdersCount += 1;
              totalAmount += (waitingOrder['total_amount'] as num?)?.toDouble() ?? 0.0;

              String status = waitingOrder['status'];

              switch (status) {
                case 'Shipped':
                  completedOrdersCount += 1;
                  completedAmount += (waitingOrder['total_amount'] as num).toDouble();
                  break;

                case 'Invoice Rejected':
                  cancelledOrdersCount += 1;
                  cancelledAmount += (waitingOrder['total_amount'] as num).toDouble();
                  break;

                case 'Refunded':
                  refundedOrdersCount += 1;
                  refundedAmount += (waitingOrder['total_amount'] as num).toDouble();
                  break;

                case 'Return':
                  returnedOrdersCount += 1;
                  returnedAmount += (waitingOrder['total_amount'] as num).toDouble();
                  break;
              }

              // Transform the waiting order into the required format
              processedOrders.add({
                'id': waitingOrder['id'],
                'manage_staff': waitingOrder['manage_staff'] ?? '',
                'staffID': waitingOrder['staffID'] ?? '',
                'order_date': waitingOrder['order_date'] ?? '',
                'status': waitingOrder['status'] ?? '',
                'total_amount': (waitingOrder['total_amount'] as num?)?.toDouble() ?? 0.0,
              });
            }
          }

          // Add calculated data and processed orders to the statewise list
          statewiselist.add({
            'id': stateData['id'] ?? 'Unknown ID',
            'name': stateData['name'] ?? 'Unknown Name',
            'total_orders_count': totalOrdersCount,
            'total_amount': totalAmount,
            'completed_orders_count': completedOrdersCount,
            'completed_amount': completedAmount,
            'cancelled_orders_count': cancelledOrdersCount,
            'cancelled_amount': cancelledAmount,
            'refunded_orders_count': refundedOrdersCount,
            'refunded_amount': refundedAmount,
            'returned_orders_count': returnedOrdersCount,
            'returned_amount': returnedAmount,
            'orders': processedOrders, // Assign the processed orders here
          });
        }

        setState(() {
          expensedata = statewiselist;
          filteredData = statewiselist;
                    

          
        });
      } else {
        
      }
    } else {
      
    }
  } catch (error) {
    
  }
}


 void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredData = List.from(expensedata); // Show all if search is empty
      } else {
        filteredData = expensedata
            .where((product) =>
                product['name'].toLowerCase().contains(query.toLowerCase()))
            .toList(); // Filter based on query
      }
    });
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();
   if(dep=="BDO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => bdo_dashbord()), // Replace AnotherPage with your target page
            );

}
else if(dep=="BDM" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => bdm_dashbord()), // Replace AnotherPage with your target page
            );
}
else if(dep=="warehouse" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => WarehouseDashboard()), // Replace AnotherPage with your target page
            );
}
else if(dep=="CEO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ceo_dashboard()), // Replace AnotherPage with your target page
            );
}
else if(dep=="COO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ceo_dashboard()), // Replace AnotherPage with your target page
            );
}


else if(dep=="CSO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => cso_dashboard()), // Replace AnotherPage with your target page
            );
}
else if(dep=="Warehouse Admin" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => WarehouseAdmin()), // Replace AnotherPage with your target page
            );
}else {
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
          title: const Text(
            "State Wise Report",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back), // Custom back arrow
            onPressed: () async {
              final dep = await getdepFromPrefs();
              if(dep=="BDO" ){
     Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => bdo_dashbord()), // Replace AnotherPage with your target page
              );
    
    }
    else if(dep=="CSO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => cso_dashboard()), // Replace AnotherPage with your target page
            );
}
    else if(dep=="BDM" ){
     Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => bdm_dashbord()), // Replace AnotherPage with your target page
              );
    }
    else if(dep=="CEO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ceo_dashboard()), // Replace AnotherPage with your target page
            );
}
else if(dep=="COO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ceo_dashboard()), // Replace AnotherPage with your target page
            );
}

    else if(dep=="warehouse" ){
     Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => WarehouseDashboard()), // Replace AnotherPage with your target page
              );
    }
    else if(dep=="Warehouse Admin" ){
     Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => WarehouseAdmin()), // Replace AnotherPage with your target page
              );
    }
              
              else {
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
              icon: Icon(Icons.date_range),
              onPressed: () => _selectDateRange(context),
            ),
          ],
        ),
         
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search...",
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
                    color: Colors.blue, // Border color when TextField is not focused
                    width: 2.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(
                    color: Colors.blueAccent, // Border color when TextField is focused
                    width: 2.0,
                  ),
                ),
              ),
              onChanged: _filterProducts,
            ),
          ),
            Padding(
                          padding: const EdgeInsets.only(right: 10,left: 10),
                          child: Container(
                            
                            height: 49,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                SizedBox(width: 20),
                                Container(
                                  width: 276,
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: '',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 1),
                                    ),
                                    child: DropdownButton<int>(
                                      value: selectedstaffId,
                                        isExpanded: true,
                                      underline: Container(), // This removes the underline
                                      onChanged: (int? newValue) {
                                        setState(() {
                                          selectedstaffId = newValue!;
                                          
                                          _filterOrdersByStaffId();
                                        });
                                      },
                                      items: sta.map<DropdownMenuItem<int>>((staff) {
                                        return DropdownMenuItem<int>(
                                          value:staff['id'],
                                          child: Text(staff['name'],style: TextStyle(fontSize: 12),),
                                        );
                                      }).toList(),
                                      icon: Container(
                                        alignment: Alignment.centerRight,
                                        child: Icon(Icons.arrow_drop_down), // Dropdown arrow icon
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: RefreshIndicator(
                onRefresh: getstatewisereport, // Trigger data reload when the user swipes down
                child: ListView.builder(
                  itemCount: filteredData.length, // Use filteredData here
                  itemBuilder: (context, index) {
                    final stateData = filteredData[index];
                    return GestureDetector(
                      onTap: () {
                          Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => cso_StatewiseOrderList(state:stateData["name"])));
                      },
                      child: Card(
                        color: Colors.white,
                        elevation: 4, // Adds shadow
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15), // Rounded edges
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0), // Padding inside the card
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // State name with a bold header
                              Text(
                                stateData["name"],
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black, // Highlight color
                                ),
                              ),
                              const Divider(), // Separator line
                              const SizedBox(height: 0), // Space between items
                              
                              // Data rows with icons
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(width: 5),
                                  Text("Completed Orders: ${stateData["completed_orders_count"]} "),
                                  Spacer(),
                                  Text("₹ ${stateData["completed_amount"]}")
                                ],
                              ),
                              SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(
                                    Icons.cancel,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(width: 5),
                                  Text("Cancelled Orders: ${stateData["cancelled_orders_count"]} "),
                                  Spacer(),
                                  Text("₹ ${stateData["cancelled_amount"]}")
                                ],
                              ),
                              SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(
                                    Icons.undo,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(width: 5),
                                  Text("Refunded Orders: ${stateData["refunded_orders_count"]} "),
                                  Spacer(),
                                  Text("₹ ${stateData["refunded_amount"]}")
                                ],
                              ),
                              SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(
                                    Icons.block,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(width: 5),
                                  Text("Returned Orders: ${stateData["returned_orders_count"]} "),
                                  Spacer(),
                                  Text("₹ ${stateData["returned_amount"]}")
                                ],
                              ),
                              SizedBox(height: 2),
                              Divider(),
                              SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(
                                    Icons.summarize,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: 5),
                                  Text("Total Orders: ${stateData["total_orders_count"]} "),
                                  Spacer(),
                                  Text("₹ ${stateData["total_amount"]}", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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
