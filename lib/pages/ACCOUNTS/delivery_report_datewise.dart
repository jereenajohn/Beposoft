import 'dart:convert';
import 'package:intl/intl.dart'; // Add this import at the top if not present

import 'package:beposoft/loginpage.dart';

import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/order.review.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DeliveryReportDatewise extends StatefulWidget {
  final String date;
  const DeliveryReportDatewise({super.key, required this.date});

  @override
  State<DeliveryReportDatewise> createState() => _DeliveryReportDatewiseState();
}

class _DeliveryReportDatewiseState extends State<DeliveryReportDatewise> {
  List<Map<String, dynamic>> deliverydate = [];

  @override
  void initState() {
    super.initState();
    getdeliverydatewise();
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


  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> getdeliverydatewise() async {
    try {
      final token = await gettokenFromPrefs();
      var response = await http.get(
        Uri.parse('$api/api/deliverylist/report/${widget.date}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      List<Map<String, dynamic>> deliverylist = [];
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          deliverylist.add({
            'invoice_name': productData['invoice'],
            'customer': productData['customer'],
            'id':productData['id'],
            'customerid':productData['customer_id'],
            'order_id': productData['order_id'],

            'order_date': productData['order_date'],
            'weight': productData['weight'],
            'volume_weight': productData['volume_weight'],
            'shipping_charge': productData['shipping_charge'],
            'tracking_id': productData['tracking_id'],
            'status': productData['status'],
            'parcel_amount':productData['parcel_amount'],
          });
        }
        setState(() {
          deliverydate = deliverylist;
        });
      }
    } catch (error) {
      
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
          "Delivery Report",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Custom back arrow
          onPressed: () async{
                 Navigator.pop(context);   
          },
        ),
      ),
            
 

      body: ListView.builder(
        itemCount: deliverydate.length,
        itemBuilder: (context, index) {
          var delivery = deliverydate[index];

          return GestureDetector(
            onTap: () {
 Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    OrderReview(id:delivery['order_id'],customer: delivery['customerid'],),
                              ),
                            );
            },
            child: Card(
              elevation: 5,
              color: Colors.white,
              margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${delivery['invoice_name']}/${DateFormat('yyyy-MM-dd').format(DateTime.parse(delivery['order_date']))}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                       
                      ],
                    ),
                     Text(
                          '${delivery['status']}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: delivery['status'] == 'Shipped'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                    Divider(thickness: 1, color: Colors.grey),
                    SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer: ${delivery['customer']}',
                          style: TextStyle(fontSize: 16),
                        ),
                          SizedBox(height: 8),
                        Text(
                          'Tracking ID: ${delivery['tracking_id']}',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Weight: ${delivery['weight']} kg',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Volume Weight: ${delivery['volume_weight']} kg',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Amount: ₹${delivery['parcel_amount']}',
                          style: TextStyle(fontSize: 16),
                        ),
                      
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
