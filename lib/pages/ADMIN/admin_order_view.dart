import 'dart:convert';
import 'package:beposoft/pages/ACCOUNTS/customer.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/methods.dart';
import 'package:beposoft/pages/api.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class admin_OrderReview extends StatefulWidget {
  final id;
  const admin_OrderReview({super.key, required this.id});

  @override
  State<admin_OrderReview> createState() => _admin_OrderReviewState();
}

class _admin_OrderReviewState extends State<admin_OrderReview> {
  Drawer d = Drawer();
  var ord;
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> bank = [];
  String? selectedBank;
  String? createdBy;
  String? companyname;
  DateTime selectedDate = DateTime.now();
  TextEditingController amountController = TextEditingController();
  TextEditingController transactionIdController = TextEditingController();
  TextEditingController remarkController = TextEditingController();
  TextEditingController receivedDateController = TextEditingController();
  String? selectedStatus;
  final TextEditingController noteController = TextEditingController();
  @override
  void initState() {
    super.initState();
    initData();
    getbank();
    
    receivedDateController.text = DateFormat('dd-MM-yyyy').format(selectedDate);
  }

  Future<void> initData() async {
    await fetchOrderItems();
  }

  bool showAllProducts = false;
  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  final List<String> statuses = [
    'Pending',
    'Approved',
    'Invoice Created',
    'Invoice Approved',
    'Waiting For Confirmation',
    'To Print',
    'Invoice Rejectd',
    'Processing',
    'Refunded',
    'Return',
    'Completed',
    'Cancelled',
    'Shipped'
  ];
  double netAmountBeforeTax = 0.0; // Define at the class level
  double totalTaxAmount = 0.0; // Define at the class level
  double payableAmount = 0.0; // Define at the class level
  double Balance = 0.0; // Define at the class level
  int? selectedAddressId; // Variable to store the selected address ID

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        receivedDateController.text =
            DateFormat('dd-MM-yyyy').format(selectedDate);
      });
    }
  }

  Future<void> updatestatus() async {
    try {
      final token = await getTokenFromPrefs();

    
      String formattedTime = DateFormat("HH:mm").format(DateTime.now());

      
      

      var response = await http.put(
        Uri.parse('$api/api/order/status/update/${widget.id}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          {
            'status': selectedStatus,
            'time': formattedTime,
            'updated_at': DateTime.now().toIso8601String().split('T')[0],
          },
        ),
      );

      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('status updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  List<Map<String, dynamic>> company = [];

  Future<void> getcompany(id) async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/company/getadd/'),
        headers: {
          'Authorization': ' Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      
      List<Map<String, dynamic>> companylist = [];

      if (response.statusCode == 200) {
        final productsData = jsonDecode(response.body);

    
        for (var productData in productsData) {
          String imageUrl = "${productData['image']}";
          companylist.add({
            'id': productData['id'],
            'name': productData['name'],
          });

          if (id == productData['id']) {
            companyname = productData['name'];
          }
        }

        setState(() {
          company = companylist;
        });
      }
    } catch (error) {
      
    }
  }

  void showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Receipt Against Invoice Generate'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Received Date field with default today's date
                TextField(
                  readOnly: true,
                  controller: receivedDateController,
                  decoration: InputDecoration(
                    labelText: 'Received Date',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context),
                    ),
                  ),
                ),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: selectedBank,
                  items: bank
                      .map((bankItem) => DropdownMenuItem<String>(
                            value: bankItem['id'].toString(),
                            child: Text(bankItem['name']),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedBank = value; // Update selected bank
                    });
                  },
                  decoration: InputDecoration(labelText: 'Bank'),
                ),
                TextField(
                  controller: transactionIdController,
                  decoration: InputDecoration(
                      labelText: 'Transaction ID',
                      prefixIcon: Icon(Icons.receipt)),
                ),
                TextField(
                  readOnly: true, // Make this field non-editable
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person),
                    hintText:
                        createdBy ?? 'Loading...', // Display the creator's name
                  ),
                ),

                TextField(
                  controller: remarkController,
                  decoration: InputDecoration(labelText: 'Remark (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              onPressed: () {
                // Handle save action here

                AddReceipt(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            value,
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Future<String?> gettoken() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString('token');
  }

  Future<void> updateaddress() async {
    try {
      final token = await gettoken();

      var response = await http.put(
        Uri.parse('$api/api/shipping/${widget.id}/order/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          {
            'billing_address': selectedAddressId,
            'note': noteController.text,
          },
        ),
      );

      

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Address updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => admin_OrderReview(id: widget.id)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to update Address'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  List<Map<String, dynamic>> addres = [];

  Future<void> getaddress(var id) async {
    try {
      final token = await gettoken();
      
      var response = await http.get(
        Uri.parse('$api/api/add/customer/address/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      List<Map<String, dynamic>> addresslist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        
        for (var productData in productsData) {
          String imageUrl = "${productData['image']}";
          addresslist.add({
            'id': productData['id'],
            'name': productData['name'],
            'email': productData['email'],
            'zipcode': productData['zipcode'],
            'address': productData['address'],
            'phone': productData['phone'],
            'country': productData['country'],
            'city': productData['city'],
            'state': productData['state'],
          });
        }
        setState(() {
          addres = addresslist;
          
        });
      }
    } catch (error) {
      
    }
  }

  Future<void> getbank() async {
    final token = await gettoken();
    try {
      final response = await http.get(Uri.parse('$api/api/banks/'), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      List<Map<String, dynamic>> banklist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        
        for (var productData in productsData) {
          String imageUrl = "${productData['image']}";
          banklist.add({
            'id': productData['id'],
            'name': productData['name'],
            'branch': productData['branch']
          });
        }
        setState(() {
          bank = banklist;
          
        });
      }
    } catch (e) {
      
    }
  }

  Future<void> AddReceipt(
    BuildContext scaffoldContext,
  ) async {
    final token = await gettoken();
    try {
      String formattedReceivedDate =
          DateFormat('yyyy-MM-dd').format(selectedDate);
      final response =
          await http.post(Uri.parse('$api/api/payment/${widget.id}/reciept/'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'amount': amountController.text,
                'bank': selectedBank,
                'transactionID': transactionIdController.text,
                'received_at': formattedReceivedDate,
                'created_by': createdBy,
                'remark': remarkController.text
              }));
      
      

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Receipt added Successfully.'),
          ),
        );
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => admin_OrderReview(
                      id: widget.id,
                    )));
      } else {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Adding receipt failed.'),
          ),
        );
      }
    } catch (e) {
      
    }
  }

  bool flag = false;

  double totalDiscount = 0.0; // Define at the class level
  Future<void> fetchOrderItems() async {
    try {
      
      final token = await getTokenFromPrefs();
      final jwt = JWT.decode(token!);
      var name = jwt.payload['name'];
      setState(() {
        createdBy = name;
      });
      
      
      var response = await http.get(
        Uri.parse('$api/api/order/${widget.id}/items/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        ord = parsed['order'];
        List<dynamic> itemsData = parsed['items'];
        getaddress(ord['customer']['id']);

        List<Map<String, dynamic>> orderList = [];
        double calculatedNetAmount = 0.0;
        double calculatedTotalTax = 0.0;
        double calculatedPayableAmount = 0.0;
        double calculatedTotalDiscount = 0.0;

        // Process each item and calculate totals
        for (var item in itemsData) {
          orderList.add({
            'id': item['id'],
            'name': item['name'],
            'quantity': item['quantity'],
            'rate': item['rate'],
            'tax': item['tax'],
            'discount': item['discount'],
            'actual_price': item['actual_price'],
            'exclude_price': item['exclude_price'],
            'images': item['images'],
          });

          // Convert values to double for safe calculation
          double excludePrice = (item['exclude_price'] ?? 0).toDouble();
          double actualPrice = (item['actual_price'] ?? 0).toDouble();
          double discount = (item['discount'] ?? 0).toDouble();
          int quantity = item['quantity'] ?? 1;

          // Add the exclude_price to net amount
          calculatedNetAmount += excludePrice;

          // Calculate and add the tax amount for each product
          double taxAmountForItem = actualPrice - excludePrice;
          calculatedTotalTax += taxAmountForItem;

          // Add discount amount for each product
          calculatedTotalDiscount += discount * quantity;

          // Calculate payable amount after subtracting discount
          double payableForItem = (actualPrice - discount) * quantity;
          calculatedPayableAmount += payableForItem;
        }

        // Calculate the sum of payment receipts
        double paymentReceiptsSum = 0.0;
        for (var receipt in parsed['order']['payment_receipts']) {
          paymentReceiptsSum +=
              double.tryParse(receipt['amount'].toString()) ?? 0.0;
          
        }

        // Calculate remaining amount after comparing with calculatedPayableAmount
        double remainingAmount = 0.0;
        if (paymentReceiptsSum > calculatedPayableAmount) {
          remainingAmount = paymentReceiptsSum - calculatedPayableAmount;
          flag = true;
        } else {
          remainingAmount = calculatedPayableAmount - paymentReceiptsSum;
          flag = false;
        }
        getcompany(ord['company']);

        setState(() {
          items = orderList;
          netAmountBeforeTax = calculatedNetAmount;
          totalTaxAmount = calculatedTotalTax;
          payableAmount = calculatedPayableAmount;
          totalDiscount = calculatedTotalDiscount;
          Balance = remainingAmount;
          
          
          
          
          
          
        });
      } else {
        
      }
    } catch (error) {
      
    }
  }

  Future<void> removeproduct(int Id) async {
    final token = await getTokenFromPrefs();

    try {
      final response = await http.delete(
        Uri.parse('$api/api/remove/order/$Id/item/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color.fromARGB(255, 49, 212, 4),
            content: Text('Deleted sucessfully'),
          ),
        );
        // Navigator.push(context, MaterialPageRoute(builder: (context)=>OrderReview(id:widget.id)));
        await fetchOrderItems();
      }

      if (response.statusCode == 204) {
      } else {
        throw Exception('Failed to delete wishlist ID: $Id');
      }
    } catch (error) {}
  }

  void removeProductindex(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  void showPopupDialog(BuildContext context, Map<String, dynamic> item) {
    TextEditingController quantityController =
        TextEditingController(text: item['quantity']?.toString() ?? '');
    TextEditingController discountController =
        TextEditingController(text: item['discount']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Edit Item Details',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                decoration: InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: discountController,
                decoration: InputDecoration(
                    labelText: 'Discount (in Rs for each product)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                final quantity =
                    int.tryParse(quantityController.text) ?? item['quantity'];
                final discount = double.tryParse(discountController.text) ??
                    item['discount'];

                updatedetails(item['id'], quantity, discount);
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> updatedetails(int id, int quantity, double discount) async {
    try {
      final token = await getTokenFromPrefs();
      final response = await http.put(
        Uri.parse('$api/api/remove/order/$id/item/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'quantity': quantity,
          'discount': discount,
        }),
      );

      

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cart item updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await fetchOrderItems();
        // Navigator.push(context, MaterialPageRoute(builder: (context)=>OrderReview(id: widget.id)));
      } else {
        throw Exception('Failed to update cart item');
      }
    } catch (error) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update cart item'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = showAllProducts ? items : items.take(2).toList();
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              height: 140,
              child: Column(
                children: [
                  SizedBox(height: 50),
                  Row(
                    children: [
                      SizedBox(width: 13),
                      Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 220, 220, 220),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.local_shipping,
                            size: 40, color: Colors.blue),
                      ),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ord != null
                                ? ord['invoice'] ?? 'Invoice Number'
                                : 'Loading...',
                            style: TextStyle( 
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                          Text(
                            companyname != null
                                ? companyname ?? 'Company'
                                : 'Loading...',
                            style: TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
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
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15.0),
                          topRight: Radius.circular(15.0),
                        ),
                      ),
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            ord != null
                                ? ord['manage_staff'] ?? 'manage_staff'
                                : 'Loading...',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            ord != null
                                ? ord["order_date"] ?? 'Date Not Available'
                                : '',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: .0),
                          Row(
                            children: [
                              Text(
                                'Status: ',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              Spacer(),
                              Text(
                                ord != null ? '${ord["status"]}' : 'Loading...',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Family',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              Spacer(),
                              Text(
                                ord != null ? '${ord["family"]}' : 'Loading...',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.0),
                          SizedBox(height: 4.0),
                          if (ord != null && ord['shipping_mode'] != null)
                            Row(
                              children: [
                                Text(
                                  'Shipping Mode',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                                Spacer(),
                                Text(
                                  '${ord['shipping_mode']}',
                                  style: TextStyle(
                                      color: const Color.fromARGB(255, 0, 0, 0),
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          if (ord != null &&
                              ord['code_charge'] != null &&
                              ord['code_charge'] != 0)
                            SizedBox(height: 4.0),
                          if (ord != null &&
                              ord['code_charge'] != null &&
                              ord['code_charge'] != 0)
                            Row(
                              children: [
                                Text(
                                  'Code Charge',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                                Spacer(),
                                Text(
                                  ' ${ord['code_charge']}',
                                  style: TextStyle(
                                      color: const Color.fromARGB(255, 0, 0, 0),
                                      fontSize: 12),
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
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Billing Address',
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    ord != null ? '${ord["customer"]["name"]}' : 'Loading...',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 0, 0, 0),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    ord != null
                        ? '${ord["customer"]["address"]}, ${ord["customer"]["city"]}, ${ord["customer"]["state"]}, ${ord["customer"]["zip_code"]}'
                        : 'Loading...',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    ord != null
                        ? 'Phone: ${ord["customer"]["phone"]}'
                        : 'Loading...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    ord != null
                        ? 'Email: ${ord["customer"]["email"]}'
                        : 'Loading...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 15, left: 15),
              child: Divider(),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shipping Address',
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    ord != null
                        ? '${ord["billing_address"]["name"]}'
                        : 'Loading...',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 0, 0, 0),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    ord != null
                        ? '${ord["billing_address"]["address"]}, ${ord["billing_address"]["city"]}, ${ord["billing_address"]["state"]}, ${ord["billing_address"]["zipcode"]}'
                        : 'Loading...',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    ord != null
                        ? 'Phone: ${ord["billing_address"]["phone"]}'
                        : 'Loading...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    ord != null
                        ? 'Email: ${ord["billing_address"]["email"]}'
                        : 'Loading...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10, right: 15, left: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Products',
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),

                  // Display each item in the visibleItems list within a card
                  for (var item in visibleItems)
                    GestureDetector(
                      onTap: () {
                        showPopupDialog(context, item);
                      },
                      child: Card(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Display the first image in a small container
                              Container(
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                        '$api${item["images"][0]}'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              // Display product details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Quantity: ${item["quantity"]}, Rate: ${item["rate"]}',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'Excluded price: ${item["exclude_price"]}',
                                          style: TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                        SizedBox(
                                          width: 4,
                                        ),
                                        if (item["tax"] != 0)
                                          Text(
                                            'Tax: ${item["tax"]}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey),
                                          )
                                      ],
                                    ),
                                    Text(
                                      'Tax Amount: ${item["rate"] - item["exclude_price"]}',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'Total: ${item["actual_price"] * item["quantity"]}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black),
                                        ),
                                        Spacer(),
                                        GestureDetector(
                                          onTap: () {
                                            removeproduct(item["id"]);
                                          },
                                          child: Image.asset(
                                              height: 25,
                                              width: 25,
                                              "lib/assets/delete.png"),
                                        )
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

                  // "See More" or "See Less" Button
                  if (items.length >
                      3) // Show button only if there are more than 3 items
                    TextButton(
                      onPressed: () {
                        setState(() {
                          showAllProducts =
                              !showAllProducts; // Toggle the visibility
                        });
                      },
                      child: Text(
                        showAllProducts ? 'See Less' : 'See More',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 2, 65, 96),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 3,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bank Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Icon(
                          Icons.credit_card,
                          color: Colors.white,
                          size: 24,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          ord != null ? ord["bank"]["name"] : 'Loading...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            letterSpacing: 2,
                          ),
                        ),
                        Spacer(),
                        Image.asset(
                            height: 40, width: 40, 'lib/assets/money.png')
                      ],
                    ),
                    SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Holder',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              ord != null
                                  ? ord["customer"]["name"]
                                  : 'Loading...',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Account No: ',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  ord != null
                                      ? ord["bank"]["account_number"]
                                      : 'Loading...',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  'IFSC CODE: ',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  ord != null
                                      ? ord["bank"]["ifsc_code"]
                                      : 'Loading...',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  'Branch: ',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  ord != null
                                      ? ord["bank"]["branch"]
                                      : 'Loading...',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  'Open Balance: ',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  ord != null
                                      ? ord["bank"]["open_balance"]
                                          .toStringAsFixed(
                                              2) // Formats to 2 decimal places
                                      : 'Loading...',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 3,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Billing Summary',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Net Amount Before Tax',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '\$${netAmountBeforeTax.toStringAsFixed(2)}', // Format to 2 decimal places
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 4,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Discount',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '\$${totalDiscount.toStringAsFixed(2)}', // Format to 2 decimal places
                          style: TextStyle(
                            color: const Color.fromARGB(255, 3, 3, 3),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 4,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Tax Amount',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '\$${totalTaxAmount.toStringAsFixed(2)}', // Format to 2 decimal places
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 4,
                    ),
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Payable Amount ',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '\$${payableAmount.toStringAsFixed(2)}', // Format to 2 decimal places
                          style: TextStyle(
                            color: const Color.fromARGB(255, 1, 155, 24),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
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
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15.0),
                          topRight: Radius.circular(15.0),
                        ),
                      ),
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Informations',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: .0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Balance Payment Amount: ',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                Balance == payableAmount || flag == true
                                    ? 'Payment Completed'
                                    : '\$${Balance.toStringAsFixed(2)}',
                                style: TextStyle(color: Colors.green),
                              )
                            ],
                          ),
                          SizedBox(height: 4.0),
                          if (flag)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Customer Ledger Credit:',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  Balance == 0
                                      ? '\$${payableAmount.toStringAsFixed(2)}'
                                      : '\$${Balance.toStringAsFixed(2)}',
                                  style: TextStyle(color: Colors.green),
                                )
                              ],
                            ),
                          if (flag == false)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Customer Ledger Debit:',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  Balance == 0
                                      ? '\$${payableAmount.toStringAsFixed(2)}'
                                      : '\$${Balance.toStringAsFixed(2)}',
                                )
                              ],
                            ),
                          SizedBox(height: 8.0),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor:
                                    Colors.blue, // Text color (white)
                              ),
                              onPressed: () {
                                if (createdBy != null) {
                                  showAddDialog(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            "Loading data, please wait...")),
                                  );
                                }
                              },
                              child: Text("Add"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ord != null && ord["payment_receipts"].isNotEmpty)
                    Text(
                      'Receipt Details',
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (ord != null && ord["payment_receipts"].isNotEmpty)
                    SizedBox(height: 10),
                  // Check if ord and ord["payment_receipts"] are not null
                  if (ord != null && ord["payment_receipts"].isNotEmpty)
                    Table(
                      border: TableBorder.all(color: Colors.grey),
                      columnWidths: const <int, TableColumnWidth>{
                        0: IntrinsicColumnWidth(),
                        1: FlexColumnWidth(),
                        2: FlexColumnWidth(),
                        3: FlexColumnWidth(),
                        4: FlexColumnWidth(),
                      },
                      children: [
                        // Header Row
                        TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Receipt No',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Amount',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Transaction ID',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Received Date',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Remark',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        // Data Rows
                        for (var receipt in ord["payment_receipts"])
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child:
                                    Text(receipt["payment_receipt"] ?? 'N/A'),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(receipt["amount"] ?? 'N/A'),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(receipt["transactionID"] ?? 'N/A'),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(receipt["received_at"] ?? 'N/A'),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(receipt["remark"] ?? 'N/A'),
                              ),
                            ],
                          ),
                      ],
                    )
                  else
                    // Display a loading or empty message if ord["payment_receipts"] is null
                    Text(
                      'No receipt details available.',
                      style: TextStyle(color: Colors.grey),
                    ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 4,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        hint: Text('Select Status'),
                        items: statuses.map((status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedStatus =
                                value; // This will store the selected status
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Status',
                        ),
                      ),
                      SizedBox(height: 8),
                      Text("Shipping Address",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Container(
                          height: 50,
                          width: 340,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: 20),
                              Container(
                                width: 260,
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: '',
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 1),
                                  ),
                                  child: DropdownButton<int>(
                                    hint: Text(
                                      'Address',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).hintColor),
                                    ),
                                    value: selectedAddressId,
                                    isExpanded: true,
                                    underline:
                                        Container(), // This removes the underline
                                    onChanged: (int? newValue) {
                                      setState(() {
                                        selectedAddressId = newValue!;
                                        
                                      });
                                    },
                                    items: addres
                                        .map<DropdownMenuItem<int>>((address) {
                                      return DropdownMenuItem<int>(
                                        value: address['id'],
                                        child: Text("${address['address']}",
                                            style: TextStyle(fontSize: 12)),
                                      );
                                    }).toList(),
                                    selectedItemBuilder:
                                        (BuildContext context) {
                                      return addres.map<Widget>((address) {
                                        return Text(
                                          selectedAddressId != null &&
                                                  selectedAddressId ==
                                                      address['id']
                                              ? "${address['address']}"
                                              : "Address",
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black),
                                        );
                                      }).toList();
                                    },
                                    icon: Container(
                                      alignment: Alignment.centerRight,
                                      child: Icon(
                                        Icons.arrow_drop_down,
                                        color: const Color.fromARGB(
                                            255, 151, 150, 150),
                                      ), // Dropdown arrow icon
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16.0),
                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Add a Note',
                        ),
                      ),
                      SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: () {
                          updateaddress();
                          updatestatus();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.blue, // Change background color
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(20), // Add border radius
                          ),
                        ),
                        child: Text(
                          'Submit',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
