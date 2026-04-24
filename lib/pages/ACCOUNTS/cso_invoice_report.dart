import 'dart:convert';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/invoicereportstaffwise.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class cso_Invoice_Report extends StatefulWidget {
  final date;
  const cso_Invoice_Report({super.key, required this.date});

  @override
  State<cso_Invoice_Report> createState() => _cso_Invoice_ReportState();
}

class _cso_Invoice_ReportState extends State<cso_Invoice_Report> {
  List<Map<String, dynamic>> invoicedata = [];
  List<Map<String, dynamic>> filteredProducts = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getSalesReport();
    
  }

  Future<String?> getTokenFromPrefs() async {
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

 // ...existing code...
// ...existing code...
Future<void> getSalesReport() async {
  setState(() {}); // Update UI
  try {
    final token = await getTokenFromPrefs();
    var response = await http.get(
      Uri.parse('$api/api/invoice/report/${widget.date}/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);
      var salesData = parsed['data'];

      List<Map<String, dynamic>> salesReportDataList = [];
      List<String> approvedStatuses = [
        "Completed",
        "Shipped",
        "Waiting For Confirmation",
        "Invoice Created",
        "Invoice Approved",
        "To Print",
        "Processing"
        "Packing under progress",
        "Ready to ship"
      ];
      List<String> rejectedStatuses = ["Cancelled", "Refunded", "Return", "Invoice Rejected"];

      for (var reportData in salesData) {
        // Skip entries where family is 'bepocart'
        if ((reportData['family'] ?? '').toString().toLowerCase() == 'bepocart') {
          continue;
        }
        List<dynamic> staffOrders = reportData['orders_details'] ?? [];
        int totalApprovedBills = 0;
        double totalApprovedAmount = 0.0;
        int totalRejectedBills = 0;
        double totalRejectedAmount = 0.0;

        // Iterate through each staff order and classify based on status
        for (var order in staffOrders) {
          double orderAmount = (order['total_amount'] ?? 0.0).toDouble();
          if (approvedStatuses.contains(order['status'])) {
            totalApprovedBills++;
            totalApprovedAmount += orderAmount;
          } else if (rejectedStatuses.contains(order['status'])) {
            totalRejectedBills++;
            totalRejectedAmount += orderAmount;
          }
        }

        salesReportDataList.add({
          'date': reportData['order_date'],
          'staff_orders': staffOrders,
          'total_bills_in_date': reportData['total_bills'],
          'amount': reportData['total_amount'],
          'staff_name': reportData['name'],
          'family': reportData['family'],
          'approved': {
            'bills': totalApprovedBills,
            'amount': totalApprovedAmount,
          },
          'rejected': {
            'bills': totalRejectedBills,
            'amount': totalRejectedAmount,
          },
        });
      }

      setState(() {
        invoicedata = salesReportDataList;
        filteredProducts = salesReportDataList;
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
    setState(() {}); // Final UI update
  }
}
// ...existing code...
// ...existing code...
double totalBills = 0.0;
  double totalAmount = 0.0;
  double approvedBills = 0.0;
  double approvedAmount = 0.0;
  double rejectedBills = 0.0;
  double rejectedAmount = 0.0;
 void _updateTotals() {
    double tempTotalBills = 0.0;
    double tempTotalAmount = 0.0;
    double tempApprovedBills = 0.0;
    double tempApprovedAmount = 0.0;
    double tempRejectedBills = 0.0;
    double tempRejectedAmount = 0.0;

    for (var reportData in filteredProducts) {


      ;
      tempTotalBills += reportData['total_bills_in_date'];
      tempTotalAmount += reportData['amount'];
      tempApprovedBills += reportData['approved']['bills'];
      tempApprovedAmount += reportData['approved']['amount'];
      tempRejectedBills += reportData['rejected']['bills'];
      tempRejectedAmount += reportData['rejected']['amount'];
    }

    setState(() {
      totalBills = tempTotalBills;
      totalAmount = tempTotalAmount;
      approvedBills = tempApprovedBills;
      approvedAmount = tempApprovedAmount;
      rejectedBills = tempRejectedBills;
      rejectedAmount = tempRejectedAmount;
    });
  }



  // Method to filter products based on search input
void _filterProducts(String query) {
  setState(() {
    if (query.isEmpty) {
      filteredProducts = List.from(invoicedata);
    } else {
      filteredProducts = invoicedata.where((invoice) {
        final staffName = (invoice['staff_name'] ?? '').toString().toLowerCase();
        final family = (invoice['family'] ?? '').toString().toLowerCase();
        
        // Check match in staff_name or family
        bool matchesTopLevel = staffName.contains(query.toLowerCase()) || family.contains(query.toLowerCase());

        // Check inside staff_orders
        final orders = invoice['staff_orders'] as List<dynamic>? ?? [];
        bool matchesOrder = orders.any((order) {
          final state = (order['state'] ?? '').toString().toLowerCase();
          final customer = (order['customer'] ?? '').toString().toLowerCase();
          final invoiceNo = (order['invoice'] ?? '').toString().toLowerCase();
          return state.contains(query.toLowerCase()) ||
                 customer.contains(query.toLowerCase()) ||
                 invoiceNo.contains(query.toLowerCase());
        });

        return matchesTopLevel || matchesOrder;
      }).toList();
    }
  });
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

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User: ${invoice['staff_name']} / ${invoice['family']}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            Divider(color: Colors.grey),
            SizedBox(height: 8),
            _buildRow('Total Bills:',invoice['total_bills_in_date']),
            _buildRow('Total Amount:', invoice['amount']),
            _buildRow('Approved Bills:',invoice['approved']['bills']),
            _buildRow('Approved Amount:', invoice['approved']['amount']),
            _buildRow('Rejected Bills:', invoice['rejected']['bills']),
            _buildRow('Rejected Amount:', invoice['rejected']['amount']),
            SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=>InvoiceReportStaffwise(id:invoice['staff_name'],date:widget.date))); 
                // Handle "View" button action
              },
              child: Text(
                "View",
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Invoice Report",
          style: TextStyle(fontSize: 14, color: Colors.grey),
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search by State...",
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
          Expanded(
            child: ListView.builder(
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                return _buildInvoiceCard(filteredProducts[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
