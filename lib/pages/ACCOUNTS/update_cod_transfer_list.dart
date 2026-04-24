import 'dart:convert';

import 'package:beposoft/pages/ACCOUNTS/cod_transfer.dart';
import 'package:beposoft/pages/ACCOUNTS/cod_transfer_list.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/internal_tranfer.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Import the intl package for date formatting

class UpdateCodTransferList extends StatefulWidget {
  final int id;
  const UpdateCodTransferList({super.key, required this.id});

  @override
  State<UpdateCodTransferList> createState() => _UpdateCodTransferListState();
}

class _UpdateCodTransferListState extends State<UpdateCodTransferList> {
  List<Map<String, dynamic>> bank = [];
  List<Map<String, dynamic>> salesReportList = [];
  List<Map<String, dynamic>> allSalesReportList = []; // Original data
  int totalReceipts = 0; // Add this line
  double totalAmount = 0.0; // Add this line

  TextEditingController uname = TextEditingController();
  TextEditingController amount = TextEditingController();
  TextEditingController transactionid = TextEditingController();
  TextEditingController Remark = TextEditingController();

  String? selectedInvoiceId; // Variable to store the selected invoice ID
  String? selectedBankId; // Variable to store the selected bank ID
  String? selectedrecieverId; // Variable to store the selected bank ID
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Initialize any necessary data or state here

    getreciptReport();
    getbank();
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> updatebanktransfer() async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.put(
        Uri.parse('$api/api/cod/transfers/${widget.id}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "amount": amount.text,
          "transactionID": transactionid.text,
          "sender_bank": int.tryParse(selectedBankId ?? '0'),
          "receiver_bank": int.tryParse(selectedrecieverId ?? '0'),
          "description": Remark.text,
          "created_at": selectedDate.toIso8601String(),
        }),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transfer updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => cod_transfer_list()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update Transfer'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating transfer'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> getbank() async {
    final token = await getTokenFromPrefs();
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
          // String imageUrl = "${productData['image']}";
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

  void _updateTotals() {
    ;
    int tempTotalReceipts = 0; // Add this line
    double tempTotalAmount = 0.0; // Add this line

    for (var reportData in salesReportList) {
      // Increment total receipts and total amount
      tempTotalReceipts++; // Add this line
      tempTotalAmount += reportData['amount']; // Add this line
    }

    setState(() {
      totalReceipts = tempTotalReceipts; // Add this line
      totalAmount = tempTotalAmount; // Add this line
    });
    ;
    ;
  }

  String formatCreatedAtDate(Map<String, dynamic> reportData) {
    final rawDate = reportData[
        'created_at']; // Assuming it is a String like "2025-07-25T12:34:56Z"
    if (rawDate == null) return '';

    final parsedDate = DateTime.tryParse(rawDate);
    if (parsedDate == null) return '';

    final formattedDate = DateFormat('yyyy-MM-dd').format(parsedDate);
    return formattedDate;
  }

  Future<void> getreciptReport() async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/cod/transfers/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        List<Map<String, dynamic>> reciptList = [];

        for (var reportData in parsed) {
          reciptList.add({
            'id': reportData['id'],
            'transactionID': reportData['transactionID'] ?? '',
            'amount': double.tryParse(reportData['amount'].toString()) ?? 0.0,
            'bank': reportData['bank'],
            'receiver_bank_name': reportData['receiver_bank_name'],
            'sender_bank_name': reportData['sender_bank_name'],
            'receiver_bank': reportData['receiver_bank'],
            'created_by_name': reportData['created_by_name'] ?? '',
            'remark': reportData['remark'] ?? '',
            'created_at': reportData['created_at'],
          });

          // ✅ Set form fields if it's the selected ID
          if (reportData['id'] == widget.id) {
            setState(() {
              amount.text = reportData['amount'].toString();
              transactionid.text = reportData['transactionID'] ?? '';
              selectedBankId =
                  reportData['sender_bank']?.toString(); // ✅ Correct ID
              selectedrecieverId =
                  reportData['receiver_bank']?.toString(); // ✅ Correct ID
              Remark.text = reportData['description'] ?? '';
              uname.text = reportData['created_by_name'] ?? '';
              selectedDate =
                  DateTime.tryParse(reportData['created_at']) ?? DateTime.now();
            });
          }
        }

        setState(() {
          allSalesReportList = reciptList;
          salesReportList = allSalesReportList;
        });
        _updateTotals();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to fetch data'),
              duration: Duration(seconds: 2)),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error fetching data'),
            duration: Duration(seconds: 2)),
      );
    }
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<String?> getusername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();
    if (dep == "BDO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                bdo_dashbord()), // Replace AnotherPage with your target page
      );
    } else if (dep == "BDM") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                bdm_dashbord()), // Replace AnotherPage with your target page
      );
    } else if (dep == "warehouse") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                WarehouseDashboard()), // Replace AnotherPage with your target page
      );
    } else if(dep=="CEO" ){
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
else if (dep == "Warehouse Admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                WarehouseAdmin()), // Replace AnotherPage with your target page
      );
    } else {
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
        backgroundColor: Color.fromARGB(242, 255, 255, 255),
        appBar: AppBar(
          title: Text(
            "Update COD Transfer",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back), // Custom back arrow
            onPressed: () async {
              final dep = await getdepFromPrefs();
              if (dep == "BDO") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          bdo_dashbord()), // Replace AnotherPage with your target page
                );
              } else if (dep == "BDM") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          bdm_dashbord()), // Replace AnotherPage with your target page
                );
              } else if (dep == "warehouse") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          WarehouseDashboard()), // Replace AnotherPage with your target page
                );
              } else if (dep == "CEO") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ceo_dashboard()), // Replace AnotherPage with your target page
                );
              } else if (dep == "Warehouse Admin") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          WarehouseAdmin()), // Replace AnotherPage with your target page
                );
              } else {
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
          ],
        ),
        body: SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.only(bottom: 55),
          child: Container(
            child: Column(
              children: [
                SizedBox(
                  height: 15,
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10, top: 10, left: 10),
                  child: Container(
                    width: 600,
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 34, 165, 246),
                      border:
                          Border.all(color: Color.fromARGB(255, 202, 202, 202)),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          "COD Transfer Update",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        SizedBox(
                          height: 13,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 25, left: 15, right: 15),
                  child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                            color: Color.fromARGB(255, 202, 202, 202)),
                      ),
                      width: 700,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 10,
                            ),

                            SizedBox(
                              height: 5,
                            ),
                            Text(
                              "Amount",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Container(
                                child: TextField(
                                  controller: amount,
                                  decoration: InputDecoration(
                                    labelText: 'Amount',
                                    labelStyle: TextStyle(
                                      fontSize:
                                          12.0, // Set your desired font size
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide:
                                          BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 8.0), // Set vertical padding
                                  ),
                                ),
                              ),
                            ),
                            // SizedBox(
                            //   height: 10,
                            // ),
                            // Text(
                            //   "Transaction Id",
                            //   style: TextStyle(
                            //       fontSize: 12, fontWeight: FontWeight.bold),
                            // ),
                            // SizedBox(
                            //   height: 5,
                            // ),
                            // Padding(
                            //   padding: const EdgeInsets.only(right: 10),
                            //   child: Container(
                            //     child: TextField(
                            //       controller: transactionid,
                            //       decoration: InputDecoration(
                            //         labelText: 'Transaction Id',
                            //         labelStyle: TextStyle(
                            //           fontSize:
                            //               12.0, // Set your desired font size
                            //         ),
                            //         border: OutlineInputBorder(
                            //           borderRadius: BorderRadius.circular(10.0),
                            //           borderSide:
                            //               BorderSide(color: Colors.grey),
                            //         ),
                            //         contentPadding: EdgeInsets.symmetric(
                            //             vertical: 8.0), // Set vertical padding
                            //       ),
                            //     ),
                            //   ),
                            // ),
                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              "Sending Bank",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 5),
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: selectedBankId,
                                  hint: Text(
                                    'Select Bank',
                                    style: TextStyle(fontSize: 12.0),
                                  ),
                                  items: bank.map((bankItem) {
                                    return DropdownMenuItem<String>(
                                      value: bankItem['id'].toString(),
                                      child: Text(
                                        '${bankItem['name']}',
                                        style: TextStyle(fontSize: 12.0),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedBankId =
                                          value; // Store the selected bank ID
                                      ;
                                    });
                                  },
                                  underline: SizedBox(),
                                ),
                              ),
                            ),

                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              "Reciever Bank",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 5),
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: selectedrecieverId,
                                  hint: Text(
                                    'Select Bank',
                                    style: TextStyle(fontSize: 12.0),
                                  ),
                                  items: bank.map((bankItem) {
                                    return DropdownMenuItem<String>(
                                      value: bankItem['id'].toString(),
                                      child: Text(
                                        '${bankItem['name']}',
                                        style: TextStyle(fontSize: 12.0),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedrecieverId =
                                          value; // Store the selected bank ID
                                    });
                                  },
                                  underline: SizedBox(),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Remark",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Container(
                                child: TextField(
                                  controller: Remark,
                                  decoration: InputDecoration(
                                    labelText: 'Remark',
                                    labelStyle: TextStyle(
                                      fontSize:
                                          12.0, // Set your desired font size
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide:
                                          BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 8.0), // Set vertical padding
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              "Date",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            // ...existing code...
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: GestureDetector(
                                onTap: () async {
                                  DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (pickedDate != null) {
                                    setState(() {
                                      selectedDate = pickedDate;
                                    });
                                  }
                                },
                                child: AbsorbPointer(
                                  child: TextField(
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      labelText: 'Date',
                                      labelStyle: TextStyle(fontSize: 12.0),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        borderSide:
                                            BorderSide(color: Colors.grey),
                                      ),
                                      contentPadding:
                                          EdgeInsets.symmetric(vertical: 8.0),
                                    ),
                                    controller: TextEditingController(
                                      text: DateFormat('yyyy-MM-dd')
                                          .format(selectedDate),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              "Name",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Container(
                                child: TextField(
                                  controller: TextEditingController(
                                      text: uname
                                          .text), // Display the name extracted from JWT
                                  readOnly: true, // Make the field non-editable
                                  decoration: InputDecoration(
                                    labelText: 'Name',
                                    labelStyle: TextStyle(
                                      fontSize:
                                          12.0, // Set your desired font size
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide:
                                          BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 8.0), // Set vertical padding
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                  ),
                                  SizedBox(
                                    width: 270,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        //AddReceipt3(context);
                                         updatebanktransfer() ;
                                      },
                                      style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                          Color.fromARGB(255, 64, 176, 251),
                                        ),
                                        shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                10), // Set your desired border radius
                                          ),
                                        ),
                                        fixedSize:
                                            MaterialStateProperty.all<Size>(
                                          Size(95,
                                              15), // Set your desired width and heigh
                                        ),
                                      ),
                                      child: Text("Submit",
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                ]),
                            SizedBox(
                              height: 20,
                            )
                          ],
                        ),
                      )),
                ),
              ],
            ),
          ),
        )),
      ),
    );
  }
}
