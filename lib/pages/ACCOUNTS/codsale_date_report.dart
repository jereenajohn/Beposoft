import 'dart:convert';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/order.review.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class codsalereport_datewise_view extends StatefulWidget {
  final date;
  const codsalereport_datewise_view({super.key, required this.date});

  @override
  State<codsalereport_datewise_view> createState() =>
      _codsalereport_datewise_viewState();
}

class _codsalereport_datewise_viewState
    extends State<codsalereport_datewise_view> {
  List<Map<String, dynamic>> codsalesreport = [];
  List<Map<String, dynamic>> customer = [];
  List<Map<String, dynamic>> sta = [];

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  void initState() {
    super.initState();
    
    getcoddatewisedetails();
    getcustomer();
    getstaff();
  }

  Future<void> getcustomer() async {
    try {
      final token = await gettokenFromPrefs();
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
          managerlist.add({
            'id': productData['id'],
            'name': productData['name'],
          });
        }

        setState(() {
          customer = managerlist;
        });
      }
    } catch (error) {
      
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
          stafflist.add({
            'id': productData['id'],
            'name': productData['name'],
          });
        }
        setState(() {
          sta = stafflist;
        });
      }
    } catch (error) {
      
    }
  }

  Future<void> getcoddatewisedetails() async {
    final token = await gettokenFromPrefs();
    try {
      final response = await http.get(
        Uri.parse('$api/api/COD/bills/${widget.date}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      List<Map<String, dynamic>> codsaleslist = [];
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          codsaleslist.add({
            'id': productData['id'],
            'invoice': productData['invoice'],
            'order_date': productData['order_date'],
            'payment_status': productData['payment_status'],
            'status': productData['status'],
            'manage_staff': productData['manage_staff'],
            'customer': productData['customer'],
            'total_paid': productData['total_paid'],
          });
        }
        setState(() {
          codsalesreport = codsaleslist;
        });
      }
    } catch (e) {
      
    }
  }

  // Helper function to get customer name by id
  String getCustomerNameById(int id) {
    final customerData = customer.firstWhere((cust) => cust['id'] == id, orElse: () => {'name': 'Unknown'});
    return customerData['name'];
  }

  // Helper function to get staff name by id
  String getStaffNameById(int id) {
    final staffData = sta.firstWhere((staff) => staff['id'] == id, orElse: () => {'name': 'Unknown'});
    return staffData['name'];
  }
Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          
           title: Text(
          "COD Sales Report",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
       
        actions: [
          // Icon button to open start date picker
          // IconButton(
          //   icon: Icon(Icons.calendar_today),  // Calendar icon
          //   onPressed: () => _selectSingleDate(context), // Call the method to select start date
          // ),
          // // Icon button to open date range picker
          // IconButton(
          //   icon: Icon(Icons.date_range),  // Date range icon
          //   onPressed: () => _selectDateRange(context), // Call the method to select date range
          // ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: codsalesreport.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: codsalesreport.length,
                itemBuilder: (context, index) {
                  final salesData = codsalesreport[index];
                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invoice: ${salesData['invoice']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue
                            ),
                          ),
                          SizedBox(height: 8),
                          Divider(color: Colors.blue,),
                          SizedBox(height: 8),
                          Text(
                            'Order Date: ${salesData['order_date']}',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Payment Status: ${salesData['payment_status']}',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Status: ${salesData['status']}',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Customer: ${getCustomerNameById(salesData['customer'])}',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Staff: ${getStaffNameById(salesData['manage_staff'])}',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Total Paid: ₹${salesData['total_paid']}',
                            style: TextStyle(fontSize: 14),
                          ),

                           SizedBox(height: 20),  // Adding space between the content and the button
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context)=>OrderReview(id:salesData['id'],customer: salesData['customer'],)));
                              // Add your view action here
                              
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white, backgroundColor: Colors.blue,  // White text color
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),  // Curved corners
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                            child: Text(
                              'View',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                  );
                },
              ),
      ),
    );
  }
}
