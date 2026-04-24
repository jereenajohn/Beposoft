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
import 'package:url_launcher/url_launcher.dart';

class OrderRequest extends StatefulWidget {
  final id;
  const OrderRequest({super.key, required this.id});

  @override
  State<OrderRequest> createState() => _OrderRequestState();
}

class _OrderRequestState extends State<OrderRequest> {
  Drawer d = Drawer();
  var ord;
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> bank = [];
  List<Map<String, dynamic>> warehouse = [];

  String? selectedBank;
  String? createdBy;
  String? companyname;
  DateTime selectedDate = DateTime.now();
  TextEditingController amountController = TextEditingController();
  TextEditingController transactionIdController = TextEditingController();
  TextEditingController remarkController = TextEditingController();
  TextEditingController receivedDateController = TextEditingController();
  String? selectedStatus;
  double shippingCharge = 0.0; // Define at the class level
  double actualamount = 0.0; // Define at the class level
  final TextEditingController noteController = TextEditingController();

  List<String> statuses = [];
  @override
  void initState() {
    super.initState();
    initData();
    getbank();
    receivedDateController.text = DateFormat('dd-MM-yyyy').format(selectedDate);
  }

  Future<void> initData() async {
    await fetchOrderItems();
    final dep = await getdepFromPrefs();
    if (dep == "BDM") {
      statuses = [
        'Invoice Approved',
        'Invoice Rejectd',
      ];
    } else if (dep == "Accounts / Accounting") {
      statuses = [
        'Shipped',
        'Waiting For Confirmation',
        'Invoice Rejectd',
      ];
    } else if (dep == "Admin") {
      statuses = [
        'To Print',
        'Invoice Rejectd',
      ];
    } else if (dep == "warehouse") {
      statuses = [
        'Packing under progress',
        'Packing',
        'Ready to ship'
            'Invoice Rejectd',
      ];
    } else {
      statuses = [
        'Invoice Approved',
        'Waiting For Confirmation',
        'To Print',
        'Packing under progress',
        'Packed',
        'Ready to ship',
        'Shipped',
        'Invoice Rejectd',
      ];
    }
  }

  bool showAllProducts = false;
  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  // final List<String> statuses = [
  //   'Pending',
  //   'Approved',
  //   'Invoice Created',
  //   'Invoice Approved',
  //   'Waiting For Confirmation',
  //   'To Print',
  //   'Invoice Rejectd',
  //   'Processing',
  //   'Refunded',
  //   'Return',
  //   'Completed',
  //   'Cancelled',
  //   'Shipped'
  // ];
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

  Future<void> updatestatus(var status) async {
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
            'status': status,
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
        Uri.parse('$api/api/company/data/'),
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
    } catch (error) {}
  }

  void showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
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
                    SizedBox(height: 10), // Add spacing between fields
                    TextField(
                      controller: amountController,
                      decoration: InputDecoration(labelText: 'Amount'),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 10),
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
                          selectedBank = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Bank',
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 10.0,
                        ),
                        border: OutlineInputBorder(),
                        isDense: true, // Makes the dropdown compact
                      ),
                      isExpanded:
                          true, // Ensures the dropdown text fits properly
                    ),

                    SizedBox(height: 10),
                    TextField(
                      controller: transactionIdController,
                      decoration: InputDecoration(
                        labelText: 'Tracking ID',
                        prefixIcon: Icon(Icons.receipt),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      readOnly: true, // Make this field non-editable
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.person),
                        hintText: createdBy ??
                            'Loading...', // Display the creator's name
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: remarkController,
                      decoration: InputDecoration(
                        labelText: 'Remark',
                        border: OutlineInputBorder(),
                      ),
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
    if (noteController != null && selectedAddressId != null) {
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
            MaterialPageRoute(
                builder: (context) => OrderRequest(id: widget.id)),
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
    } catch (error) {}
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
    } catch (e) {}
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
                builder: (context) => OrderRequest(
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
    } catch (e) {}
  }

  bool flag = false;
  double paymentreceipt = 0.0; // Define at the class level
  double updateamount = 0.0; // Define at the class level

  double totalDiscount = 0.0; // Define at the class level
  Future<void> fetchOrderItems() async {
    try {
      final token = await getTokenFromPrefs();

      if (token == null) {
        return;
      }
      final jwt = JWT.decode(token);
      var name = jwt.payload['name'] ?? 'Unknown'; // Provide a default value
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

        ord = parsed['order'] ?? {};

        noteController.text = ord['note'] ?? '';

        selectedAddressId = ord['billing_address']['id'];
        List<dynamic> itemsData = parsed['items'] ?? [];
        List<dynamic> warehouseData =
            (parsed['order'] != null && parsed['order']['warehouse'] is List)
                ? parsed['order']['warehouse']
                : [];

        selectedStatus = ord['status'] ?? '';
        shippingCharge = ord['shipping_charge']?.toDouble() ?? 0.0;
        actualamount = ord['total_amount']?.toDouble() ?? 0.0;
        getaddress(ord['customer']?['id']);

        List<Map<String, dynamic>> orderList = [];
        List<Map<String, dynamic>> warehouseList = [];
        double calculatedNetAmount = 0.0;
        double calculatedTotalTax = 0.0;
        double calculatedPayableAmount = 0.0;
        double calculatedTotalDiscount = 0.0;
        // Process each item and calculate totals
        for (var item in itemsData) {
          orderList.add({
            'id': item['id'],
            'name': item['name'] ?? '',
            'quantity': item['quantity'] ?? 0,
            'rate': item['rate'] ?? 0.0,
            'tax': item['tax'] ?? 0.0,
            'discount': item['discount'] ?? 0.0,
            'actual_price': item['actual_price'] ?? 0.0,
            'exclude_price': item['exclude_price'] ?? 0.0,
            'images': item['image'] ?? '',
          });

          double price = double.tryParse(item['rate'].toString()) ?? 0.0;
          double price_discount =
              double.tryParse(item['price_discount'].toString()) ?? 0.0;
          double excludePrice =
              double.tryParse(item['exclude_price'].toString()) ?? 0.0;
          double actualPrice =
              double.tryParse(item['actual_price'].toString()) ?? 0.0;
          double discount = double.tryParse(item['discount'].toString()) ?? 0.0;
          int quantity = int.tryParse(item['quantity'].toString()) ?? 1;

          calculatedTotalTax += (price_discount - excludePrice) * quantity;
          calculatedNetAmount += excludePrice * quantity;
          calculatedTotalDiscount += discount * quantity;
          calculatedPayableAmount += price * quantity;
        }

        // Process each warehouse item
        for (var warehouse in warehouseData) {
          warehouseList.add({
            'id': warehouse['id'],
            'box': warehouse['box'] ?? '',
            'weight': warehouse['weight'] ?? '0',
            'length': warehouse['length'] ?? '0',
            'breadth': warehouse['breadth'] ?? '0',
            'height': warehouse['height'] ?? '0',
            'image': warehouse['image'] ?? '',
            'parcel_service': warehouse['parcel_service'] ?? '',
            'tracking_id': warehouse['tracking_id'] ?? '',
            'shipping_charge': warehouse['shipping_charge'] ?? '0.0',
            'status': warehouse['status'] ?? '',
            'shipped_date': warehouse['shipped_date'] ?? '',
            'actual_weight': warehouse['actual_weight'] ?? '0.0',
            'parcel_amount': warehouse['parcel_amount'] ?? '0.0',
            'postoffice_date': warehouse['postoffice_date'] ?? '',
            'message_status': warehouse['message_status'] ?? '',
          });
        }

        double paymentReceiptsSum = 0.0;

        for (var receipt in parsed['order']['recived_payment'] ?? []) {
          paymentReceiptsSum +=
              double.tryParse(receipt['amount'].toString()) ?? 0.0;
        }

        double remainingAmount;
        if (actualamount > paymentReceiptsSum) {
          remainingAmount = actualamount - paymentReceiptsSum;
        } else {
          remainingAmount = paymentReceiptsSum - actualamount;
        }
        setState(() {
          items = orderList;
          warehouse = warehouseList;
          netAmountBeforeTax = calculatedNetAmount;
          totalTaxAmount = calculatedTotalTax;
          payableAmount = calculatedPayableAmount;
          totalDiscount = calculatedTotalDiscount;
          Balance = remainingAmount;
          paymentreceipt = remainingAmount;
          updateamount = netAmountBeforeTax + totalTaxAmount + shippingCharge;
        });
// fetchCustomerLedgerDetails();
        updatingamount();
      } else {}
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching order items'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> updatingamount() async {
    try {
      final token = await getTokenFromPrefs();

      Map<String, dynamic> body = {
        'total_amount': updateamount,
      };

      var response = await http.put(
        Uri.parse('$api/api/shipping/${widget.id}/order/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Total updated successfully'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green, // Add green background color
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red, // Add red background color
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

  // void showPopupDialog(BuildContext context, Map<String, dynamic> item) {
  //   TextEditingController quantityController =
  //       TextEditingController(text: item['quantity']?.toString() ?? '');
  //   TextEditingController discountController =
  //       TextEditingController(text: item['discount']?.toString() ?? '');

  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text(
  //           'Edit Item Details',
  //           style: TextStyle(fontWeight: FontWeight.bold),
  //         ),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             TextField(
  //               controller: quantityController,
  //               decoration: InputDecoration(labelText: 'Quantity'),
  //               keyboardType: TextInputType.number,
  //             ),
  //             TextField(
  //               controller: discountController,
  //               decoration: InputDecoration(
  //                   labelText: 'Discount (in Rs for each product)'),
  //               keyboardType: TextInputType.number,
  //             ),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             child: Text('Cancel'),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //           TextButton(
  //             style: TextButton.styleFrom(
  //               backgroundColor: Colors.blue,
  //               foregroundColor: Colors.white,
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(8),
  //               ),
  //             ),
  //             onPressed: () {
  //               final quantity =
  //                   int.tryParse(quantityController.text) ?? item['quantity'];
  //               final discount = double.tryParse(discountController.text) ??
  //                   item['discount'];

  //               updatedetails(item['id'], quantity, discount);
  //               Navigator.of(context).pop();
  //             },
  //             child: Text('Save'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

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
//  Future<void> _launchURL(String url) async {
//     final Uri _url = Uri.parse(url);
//     if (await canLaunch(_url.toString())) {
//       await launch(_url.toString());
//     } else {
//       throw 'Could not launch $url';
//     }
//   }

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
              height: 160,
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              IconButton(
                                onPressed: () async {
                                  final Uri url =
                                      Uri.parse('$api/invoice/${ord['id']}/');

                                  if (!await launchUrl(url,
                                      mode: LaunchMode.externalApplication)) {
                                    // Handle error case
                                  }
                                },
                                icon: Icon(
                                  Icons.download,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        ord != null
                            ? ord['company']['name'] ?? 'Company'
                            : 'Loading...',
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 5,
                  )
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
                          SizedBox(height: 4.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  updatestatus('Invoice Approved');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: EdgeInsets.symmetric(
                                      vertical: 12.0, horizontal: 24.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                                child: Text(
                                  'Approve',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  updatestatus('Invoice Rejectd');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: EdgeInsets.symmetric(
                                      vertical: 12.0, horizontal: 24.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.white),
                                ),
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
                        //showPopupDialog(context, item);
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
                                    image:
                                        NetworkImage('$api${item["images"]}'),
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
                                          'discount: ${item["discount"]}',
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
                                      'Rate After Discount: ₹${item["rate"] ?? 0.0 - item["discount"] ?? 0.0}',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),

                                    Text(
                                      'Total: ₹${(((double.tryParse(item["exclude_price"].toString()) ?? 0.0) + (((double.tryParse(item["rate"].toString()) ?? 0.0) - (double.tryParse(item["discount"].toString()) ?? 0.0)) - (double.tryParse(item["exclude_price"].toString()) ?? 0.0))) * (int.tryParse(item["quantity"].toString()) ?? 1)).toStringAsFixed(2)}',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                    // ...existing code...
                                    Text(
                                      'Excluded price: ${item["exclude_price"]}',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                    // ...existing code...
                                    Row(
                                      children: [
                                        Text(
                                          'Total: ${(((double.tryParse(item["exclude_price"].toString()) ?? 0.0) + (((double.tryParse(item["rate"].toString()) ?? 0.0) - (double.tryParse(item["discount"].toString()) ?? 0.0)) - (double.tryParse(item["exclude_price"].toString()) ?? 0.0))) * (int.tryParse(item["quantity"].toString()) ?? 1)).toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black,
                                          ),
                                        ),
                                        // Spacer(),
                                        // if (dep != "BDM" && dep != "BDO")
                                        //   GestureDetector(
                                        //     onTap: () {
                                        //       removeproduct(item["id"]);
                                        //       fetchOrderItems();
                                        //     },
                                        //     child: Image.asset(
                                        //         height: 25,
                                        //         width: 25,
                                        //         "lib/assets/delete.png"),
                                        //   )
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
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Column(
                        //   crossAxisAlignment: CrossAxisAlignment.start,
                        //   children: [
                        //     Text(
                        //       'Account Holder',
                        //       style: TextStyle(
                        //         color: Colors.grey[400],
                        //         fontSize: 12,
                        //       ),
                        //     ),
                        //     Text(
                        //       ord != null
                        //           ? ord["customer"]["name"]
                        //           : 'Loading...',
                        //       style: TextStyle(
                        //         color: Colors.white,
                        //         fontWeight: FontWeight.bold,
                        //       ),
                        //     ),
                        //   ],
                        // ),
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
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: Card(
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(15.0),
            //     ),
            //     color: Colors.white,
            //     elevation: 4,
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Container(
            //           decoration: BoxDecoration(
            //             color: Colors.grey,
            //             borderRadius: BorderRadius.only(
            //               topLeft: Radius.circular(15.0),
            //               topRight: Radius.circular(15.0),
            //             ),
            //           ),
            //           padding: const EdgeInsets.all(12.0),
            //           child: Row(
            //             mainAxisAlignment: MainAxisAlignment.center,
            //             children: [
            //               Text(
            //                 'Informations',
            //                 style: TextStyle(
            //                   color: Colors.white,
            //                   fontWeight: FontWeight.bold,
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ),
            //         Padding(
            //           padding: const EdgeInsets.all(12.0),
            //           child: Column(
            //             crossAxisAlignment: CrossAxisAlignment.start,
            //             children: [
            //               SizedBox(height: .0),
            //               Row(
            //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //                 children: [
            //                   Text(
            //                     'Balance Payment Amount: ',
            //                     style: TextStyle(
            //                         fontSize: 12, fontWeight: FontWeight.w600),
            //                   ),
            //                   Text(
            //                     Balance == payableAmount || flag == true
            //                         ? 'Payment Completed'
            //                         : '\$${Balance.toStringAsFixed(2)}',
            //                     style: TextStyle(color: Colors.green),
            //                   )
            //                 ],
            //               ),
            //               SizedBox(height: 4.0),
            //               if (flag)
            //                 Row(
            //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //                   children: [
            //                     Text(
            //                       'Customer Ledger Credit:',
            //                       style: TextStyle(
            //                           fontSize: 12,
            //                           fontWeight: FontWeight.bold),
            //                     ),
            //                     Text(
            //                       Balance == 0
            //                           ? '\$${payableAmount.toStringAsFixed(2)}'
            //                           : '\$${Balance.toStringAsFixed(2)}',
            //                       style: TextStyle(color: Colors.green),
            //                     )
            //                   ],
            //                 ),
            //               if (flag == false)
            //                 Row(
            //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //                   children: [
            //                     Text(
            //                       'Customer Ledger Debit:',
            //                       style: TextStyle(
            //                           fontSize: 12,
            //                           fontWeight: FontWeight.bold),
            //                     ),
            //                     Text(
            //                       Balance == 0
            //                           ? '\$${payableAmount.toStringAsFixed(2)}'
            //                           : '\$${Balance.toStringAsFixed(2)}',
            //                     )
            //                   ],
            //                 ),
            //               SizedBox(height: 8.0),
            //               SizedBox(
            //                 width: double.infinity,
            //                 child: ElevatedButton(
            //                   style: ElevatedButton.styleFrom(
            //                     foregroundColor: Colors.white,
            //                     backgroundColor:
            //                         Colors.blue, // Text color (white)
            //                   ),
            //                   onPressed: () {
            //                     if (createdBy != null) {
            //                       showAddDialog(context);
            //                     } else {
            //                       ScaffoldMessenger.of(context).showSnackBar(
            //                         SnackBar(
            //                             content: Text(
            //                                 "Loading data, please wait...")),
            //                       );
            //                     }
            //                   },
            //                   child: Text("Add"),
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            // Padding(
            //   padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       if (ord != null && ord["recived_payment"].isNotEmpty)
            //         Text(
            //           'Receipt Details',
            //           style: TextStyle(
            //             color: Color.fromARGB(255, 0, 0, 0),
            //             fontSize: 13,
            //             fontWeight: FontWeight.bold,
            //           ),
            //         ),
            //       if (ord != null && ord["recived_payment"].isNotEmpty)
            //         SizedBox(height: 10),
            //       // Check if ord and ord["recived_payment"] are not null
            //       if (ord != null && ord["recived_payment"].isNotEmpty)
            //         Table(
            //           border: TableBorder.all(color: Colors.grey),
            //           columnWidths: const <int, TableColumnWidth>{
            //             0: IntrinsicColumnWidth(),
            //             1: FlexColumnWidth(),
            //             2: FlexColumnWidth(),
            //             3: FlexColumnWidth(),
            //             4: FlexColumnWidth(),
            //           },
            //           children: [
            //             // Header Row
            //             TableRow(
            //               children: [
            //                 Padding(
            //                   padding: const EdgeInsets.all(8.0),
            //                   child: Text('Receipt No',
            //                       style:
            //                           TextStyle(fontWeight: FontWeight.bold)),
            //                 ),
            //                 Padding(
            //                   padding: const EdgeInsets.all(8.0),
            //                   child: Text('Amount',
            //                       style:
            //                           TextStyle(fontWeight: FontWeight.bold)),
            //                 ),
            //                 Padding(
            //                   padding: const EdgeInsets.all(8.0),
            //                   child: Text('Transaction ID',
            //                       style:
            //                           TextStyle(fontWeight: FontWeight.bold)),
            //                 ),
            //                 Padding(
            //                   padding: const EdgeInsets.all(8.0),
            //                   child: Text('Received Date',
            //                       style:
            //                           TextStyle(fontWeight: FontWeight.bold)),
            //                 ),
            //                 Padding(
            //                   padding: const EdgeInsets.all(8.0),
            //                   child: Text('Remark',
            //                       style:
            //                           TextStyle(fontWeight: FontWeight.bold)),
            //                 ),
            //               ],
            //             ),
            //             // Data Rows
            //             for (var receipt in ord["recived_payment"])
            //               TableRow(
            //                 children: [
            //                   Padding(
            //                     padding: const EdgeInsets.all(8.0),
            //                     child:
            //                         Text(receipt["payment_receipt"] ?? 'N/A'),
            //                   ),
            //                   Padding(
            //                     padding: const EdgeInsets.all(8.0),
            //                     child: Text(receipt["amount"] ?? 'N/A'),
            //                   ),
            //                   Padding(
            //                     padding: const EdgeInsets.all(8.0),
            //                     child: Text(receipt["transactionID"] ?? 'N/A'),
            //                   ),
            //                   Padding(
            //                     padding: const EdgeInsets.all(8.0),
            //                     child: Text(receipt["received_at"] ?? 'N/A'),
            //                   ),
            //                   Padding(
            //                     padding: const EdgeInsets.all(8.0),
            //                     child: Text(receipt["remark"] ?? 'N/A'),
            //                   ),
            //                 ],
            //               ),
            //           ],
            //         )
            //       else
            //         // Display a loading or empty message if ord["recived_payment"] is null
            //         Text(
            //           'No receipt details available.',
            //           style: TextStyle(color: Colors.grey),
            //         ),
            //     ],
            //   ),
            // ),
            // SizedBox(height: 10),
            // Center(
            //   child: Padding(
            //     padding: const EdgeInsets.all(12.0),
            //     child: Container(
            //       padding: const EdgeInsets.all(16.0),
            //       decoration: BoxDecoration(
            //         color: Colors.white,
            //         borderRadius: BorderRadius.circular(12.0),
            //         boxShadow: [
            //           BoxShadow(
            //             color: Colors.grey.withOpacity(0.3),
            //             spreadRadius: 4,
            //             blurRadius: 6,
            //             offset: Offset(0, 3),
            //           ),
            //         ],
            //       ),
            //       child: Column(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           Container(
            //             decoration: BoxDecoration(
            //               color: Colors.grey,
            //               borderRadius: BorderRadius.only(
            //                 topLeft: Radius.circular(15.0),
            //                 topRight: Radius.circular(15.0),
            //               ),
            //             ),
            //             padding: const EdgeInsets.all(12.0),
            //             child: Row(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 Text(
            //                   'Update Informations',
            //                   style: TextStyle(
            //                     color: Colors.white,
            //                     fontWeight: FontWeight.bold,
            //                   ),
            //                 ),
            //               ],
            //             ),
            //           ),
            //           SizedBox(
            //             height: 10,
            //           ),
            //           DropdownButtonFormField<String>(
            //             value: selectedStatus,
            //             hint: Text('Select Status'),
            //             items: statuses.map((status) {
            //               return DropdownMenuItem<String>(
            //                 value: status,
            //                 child: Text(status),
            //               );
            //             }).toList(),
            //             onChanged: (value) {
            //               setState(() {
            //                 selectedStatus =
            //                     value; // This will store the selected status
            //               });
            //             },
            //             decoration: InputDecoration(
            //               border: OutlineInputBorder(),
            //               labelText: 'Status',
            //             ),
            //           ),
            //           SizedBox(height: 8),
            //           Text("Shipping Address",
            //               style: TextStyle(
            //                   fontSize: 12, fontWeight: FontWeight.bold)),
            //           SizedBox(height: 5),
            //           Padding(
            //             padding: const EdgeInsets.only(right: 10),
            //             child: Container(
            //               height: 50,
            //               width: 360,
            //               decoration: BoxDecoration(
            //                 border: Border.all(color: Colors.grey),
            //               ),
            //               child: Row(
            //                 children: [
            //                   SizedBox(width: 20),
            //                   Container(
            //                     width: 260,
            //                     child: InputDecorator(
            //                       decoration: InputDecoration(
            //                         border: InputBorder.none,
            //                         hintText: '',
            //                         contentPadding:
            //                             EdgeInsets.symmetric(horizontal: 1),
            //                       ),
            //                       child: DropdownButton<int>(
            //                         hint: Text(
            //                           'Address',
            //                           style: TextStyle(
            //                               fontSize: 12,
            //                               color: Theme.of(context).hintColor),
            //                         ),
            //                         value: selectedAddressId,
            //                         isExpanded: true,
            //                         underline:
            //                             Container(), // This removes the underline
            //                         onChanged: (int? newValue) {
            //                           setState(() {
            //                             selectedAddressId = newValue!;
            //
            //                           });
            //                         },
            //                         items: addres
            //                             .map<DropdownMenuItem<int>>((address) {
            //                           return DropdownMenuItem<int>(
            //                             value: address['id'],
            //                             child: Text("${address['address']}",
            //                                 style: TextStyle(fontSize: 12)),
            //                           );
            //                         }).toList(),
            //                         selectedItemBuilder:
            //                             (BuildContext context) {
            //                           return addres.map<Widget>((address) {
            //                             return Text(
            //                               selectedAddressId != null &&
            //                                       selectedAddressId ==
            //                                           address['id']
            //                                   ? "${address['address']}"
            //                                   : "Address",
            //                               style: TextStyle(
            //                                   fontSize: 12,
            //                                   color: Colors.black),
            //                             );
            //                           }).toList();
            //                         },
            //                         icon: Container(
            //                           alignment: Alignment.centerRight,
            //                           child: Icon(
            //                             Icons.arrow_drop_down,
            //                             color: const Color.fromARGB(
            //                                 255, 151, 150, 150),
            //                           ), // Dropdown arrow icon
            //                         ),
            //                       ),
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //             ),
            //           ),
            //           SizedBox(height: 16.0),
            //           TextField(
            //             controller: noteController,
            //             maxLines: 3,
            //             decoration: InputDecoration(
            //               border: OutlineInputBorder(),
            //               labelText: 'Add a Note',
            //             ),
            //           ),
            //           SizedBox(height: 16.0),
            //           ElevatedButton(
            //             onPressed: () {
            //               updateaddress();
            //               updatestatus();
            //             },
            //             style: ElevatedButton.styleFrom(
            //               backgroundColor:
            //                   Colors.blue, // Change background color
            //               shape: RoundedRectangleBorder(
            //                 borderRadius:
            //                     BorderRadius.circular(20), // Add border radius
            //               ),
            //             ),
            //             child: Text(
            //               'Submit',
            //               style: TextStyle(color: Colors.white),
            //             ),
            //           )
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
