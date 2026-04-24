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
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/invoice_report.dart';
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

class Stock_Report extends StatefulWidget {
  const Stock_Report({super.key});

  @override
  State<Stock_Report> createState() => _Stock_ReportState();
}

class _Stock_ReportState extends State<Stock_Report> {
  List<Map<String, dynamic>> salesReportList = [];
    List<Map<String, dynamic>> allSalesReportList = []; // Original data
  double totalstock = 0.0;
  double totalsold = 0.0;
  double remaingitem = 0.0;
  double approvedAmount = 0.0;
  double rejectedBills = 0.0;
  double rejectedAmount = 0.0;
 TextEditingController searchController = TextEditingController();
  DateTime? selectedDate; // For single date filter
  DateTime? startDate; // For date range filter
  DateTime? endDate; // For date range filter

  @override
  void initState() {
    super.initState();
    getStockReport();
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
  double tempTotalstock = 0.0;
  double tempTotalsold = 0.0;
  double tempTotalPrice = 0.0;

  for (var reportData in salesReportList) {
    // Accumulate stock quantities
    tempTotalstock += reportData['stock_quantity'];

    // Calculate total price for each product (price * quantity)
    tempTotalsold += reportData['items_sold']; // Total items sold (this seems to represent price as well)
    
    // Assuming 'items_sold' is the price, and 'stock_quantity' is the quantity.
    tempTotalPrice += reportData['stock_quantity'] * reportData['items_sold'];
  }

  setState(() {
    totalstock = tempTotalstock;
    totalsold = tempTotalsold;
    remaingitem = tempTotalstock - tempTotalsold; // You can calculate remaining items as stock - sold
    approvedAmount = tempTotalPrice; // If you want to show approved amounts in the summary, use this
  });
}

  drower d = drower();

  // Get token from SharedPreferences
  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> getStockReport() async {
    setState(() {});
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/product/stock/report/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var salesData = parsed['data'];
        

        List<Map<String, dynamic>> salesReportDataList = [];
        for (var reportData in salesData) {
      String imageUrl = "${reportData['image']}";

          salesReportDataList.add({
            'product_title': reportData['name'],
            'stock_quantity': reportData['stock'],
            'items_sold': reportData['selling_price'],
            'image':imageUrl,            
          });
        }
        setState(() {
              allSalesReportList = salesReportDataList; // Save original data
          salesReportList = allSalesReportList;
          _updateTotals();
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

 void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        salesReportList = List.from(salesReportList); // Show all if search is empty
      } else {
        salesReportList = salesReportList
            .where((product) =>
                product['product_title'].toLowerCase().contains(query.toLowerCase()))
            .toList(); // Filter based on query
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
                fontSize: 14,
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

 else if (dep == "CSO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                cso_dashboard()), // Replace AnotherPage with your target page
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
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            "Stock Report",
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
      else if(dep=="Warehouse Admin" ){
         Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => WarehouseAdmin()), // Replace AnotherPage with your target page
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

      else if (dep == "CSO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                cso_dashboard()), // Replace AnotherPage with your target page
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
              icon: Image.asset('lib/assets/profile.png'),
              onPressed: () {},
            ),
            // IconButton(
            //   icon: Icon(Icons.calendar_today),
            //   onPressed: () {
                
            //      _selectSingleDate(context);
            //   }
            // ),
            // IconButton(
            //   icon: Icon(Icons.date_range),
            //   onPressed: () => _selectDateRange(context),
            // ),
          ],
        ),
          
        body:Column(
        children: [
      // Search bar
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: "Search product...",
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
          onChanged: _filterProducts, // Filtering logic
        ),
      ),
      
      // Main content in Stack
      Expanded(
        child: RefreshIndicator(
          onRefresh: getStockReport,
          child: Stack(
            children: [
              // Main content: Sales report list
             SingleChildScrollView(
  padding: EdgeInsets.only(bottom: 260),
  child: Column(
    children: salesReportList.map((reportData) {
      return Card(
        color: Colors.white,
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Table(
            border: TableBorder.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
            columnWidths: const {
              0: FlexColumnWidth(),  // Label column
              1: FlexColumnWidth(2),  // Value column
            },
            children: [
              _kvRowBlack('Product', reportData['product_title'].toString()),
              _kvRowBlack('Price', reportData['items_sold'].toString()),
              _kvRowBlack('Stock', reportData['stock_quantity'].toString()),
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
    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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

          /// Table version
          Table(
            border: TableBorder.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
            columnWidths: const {
              0: FlexColumnWidth(0.5), // label
              1: FlexColumnWidth(1),   // value
            },
            children: [
              _kvRow('Total Stocks', '$totalstock'),
              _kvRow('Total Price', '$approvedAmount'), 
              // If approvedAmount is a double and you want ₹ + 2 decimals:
              // _kvRow('Total Price', '₹${approvedAmount.toStringAsFixed(2)}'),
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
      ),
        ],
      )
      
      ),
    );
  }
}
/// Helper: key-value table row with right-aligned value
TableRow _kvRow(String key, String value) {
  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          key,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    ],
  );
}
/// Helper: black text table row (for product cards)
TableRow _kvRowBlack(String key, String value) {
  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          key,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ],
  );
}
