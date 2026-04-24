import 'dart:convert';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/order.review.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CreditsaleDateReport extends StatefulWidget {
  final date;
  const CreditsaleDateReport({super.key, required this.date});

  @override
  State<CreditsaleDateReport> createState() => _CreditsaleDateReportState();
}

class _CreditsaleDateReportState extends State<CreditsaleDateReport> {
  List<Map<String, dynamic>> creditdata = [];
  List<Map<String, dynamic>> filteredProducts = [];
  TextEditingController searchController = TextEditingController();
List<Map<String, dynamic>> staff = [];
List<Map<String, dynamic>> customer = [];

  @override
  void initState() {
    super.initState();
    initdata();
    
  }

void initdata() async{
  await  getstaff();
  await getcustomer();
  await FetchCreditSaleDateReport();
   

}
  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

var sta;
  Future<void> getstaff() async {
    try {
      final token = await getTokenFromPrefs();

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
          });
          
        }
       
        setState(() {
          staff = stafflist;
          
        });
      }
    } catch (error) {
      
    }
  }
 Future<void> getcustomer() async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/customers/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
  
      List<Map<String, dynamic>> managerlist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

    
        for (var productData in productsData) {
          managerlist.add({
            'id': productData['id'],
            'name': productData['name'],
            'created_at': productData['created_at'],
            'manager':productData['manager']
          });
        }
        setState(() {
          customer = managerlist;

          
        });
      }
    } catch (error) {
      
    }
  }

  Future<void> FetchCreditSaleDateReport() async {
  try {
    final token = await getTokenFromPrefs();

    var response = await http.get(
      Uri.parse('$api/api/credit/bills/${widget.date}/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    

    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);
      var productsData = parsed['data'];

      List<Map<String, dynamic>> creditList = [];
      for (var productData in productsData) {
        // Find the corresponding staff name for manage_staff ID
        String? staffName;
        for (var staffMember in staff) {
          if (staffMember['id'] == productData['manage_staff']) {
            staffName = staffMember['name'];
            break;
          }
        }

        // Find the corresponding customer name for customer ID
        String? customerName;
        for (var customerData in customer) {
          if (customerData['id'] == productData['customer']) {
            customerName = customerData['name'];
            break;
          }
        }
;
        creditList.add({
          'id':productData['id'],
          'customerid':productData['customer'],
          'invoice': productData['invoice'],
          'order_date': productData['order_date'],
          'payment_status': productData['payment_status'],
          'status': productData['status'],
          'manage_staff': staffName ?? 'Unknown', // Default to 'Unknown' if no match found
          'customer': customerName ?? 'Unknown',  // Default to 'Unknown' if no match found
          'total_paid': productData['total_paid'],
        });
      }
      setState(() {
        creditdata = creditList;
        filteredProducts = creditList; // Initially show all data
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to fetch invoice report'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error fetching invoice report'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

  // Method to filter products based on search input
  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredProducts = List.from(creditdata); // Show all if search is empty
      } else {
        filteredProducts = creditdata
            .where((invoice) =>
                invoice['staff_name']
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                invoice['family']
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                invoice['state_name']
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList(); // Filter based on query
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
              ' ${invoice['manage_staff']} / ${invoice['order_date']}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            Divider(color: Colors.grey),
            SizedBox(height: 4),
            _buildRow('Invoice:', invoice['invoice']),
            _buildRow('Payment Status:', invoice['payment_status']),
            _buildRow('status:', invoice['status']),
            _buildRow('customer:', invoice['customer']),
            _buildRow('Total Paid :', invoice['total_paid']),
            SizedBox(height: 2),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                  Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    OrderReview(id:invoice['id'],customer: invoice['customerid'],),
                              ),
                            );
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
