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
import 'package:beposoft/pages/ACCOUNTS/addrack.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:flutter/material.dart';

import 'package:dropdown_button2/dropdown_button2.dart';

import 'package:beposoft/main.dart';
import 'package:beposoft/pages/ACCOUNTS/add_credit_note.dart';
import 'package:beposoft/pages/ACCOUNTS/customer.dart';
import 'package:beposoft/pages/ACCOUNTS/recipts_list.dart';
import 'package:beposoft/pages/ACCOUNTS/add_new_stock.dart';
import 'package:beposoft/pages/ACCOUNTS/credit_note_list.dart';
import 'package:beposoft/pages/ACCOUNTS/methods.dart';
import 'package:beposoft/pages/ACCOUNTS/new_product.dart';
import 'package:beposoft/pages/ACCOUNTS/order_request.dart';
import 'package:beposoft/pages/ACCOUNTS/purchases_request.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:beposoft/pages/ACCOUNTS/add_new_customer.dart';
import 'package:beposoft/pages/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class update_rack extends StatefulWidget {
  final id;
  const update_rack({super.key, required this.id});

  @override
  State<update_rack> createState() => _update_rackState();
}

class _update_rackState extends State<update_rack> {
  @override
  void initState() {
    super.initState();
    getrack();
  }

  TextEditingController rackname = TextEditingController();
  TextEditingController racknumber = TextEditingController();
  TextEditingController warehouse = TextEditingController();
  List<Map<String, dynamic>> rack = [];
  int? oldRackNumber;

  List<Map<String, dynamic>> Warehouses = [];
  int? selectedwarehouseId; // Variable to store the selected department's ID

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> getrack() async {
    final token = await gettokenFromPrefs();
    try {
      final response =
          await http.get(Uri.parse('$api/api/rack/add/'), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

   
      List<Map<String, dynamic>> racklist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        for (var productData in parsed) {
          String columnNames = (productData['column_names'] as List).join(', ');
          racklist.add({
            'id': productData['id'],
            'warehouse_name': productData['warehouse_name'],
            'rack_name': productData['rack_name'],
            'column_names': columnNames,
            'number_of_columns': productData['number_of_columns'],
          });

          if (widget.id == productData['id']) {
            rackname.text = productData['rack_name'] ?? '';
            racknumber.text =
                productData['number_of_columns']?.toString() ?? '';
            warehouse.text = productData['warehouse_name'];
            oldRackNumber = productData['number_of_columns']; // <-- Save here
          }
        }
      

        setState(() {
          rack = racklist;
        });
      }
    } catch (e) {}
  }

  Future<void> updaterack() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.put(
        Uri.parse('$api/api/rack/add/${widget.id}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          {
            'number_of_columns': racknumber.text,
          },
        ),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rack updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => add_rack()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update rack'),
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

  //searchable dropdown

  String? selectedValue;
  final TextEditingController textEditingController = TextEditingController();

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color.fromARGB(242, 255, 255, 255),
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
              icon: Image.asset('lib/assets/profile.png'),
              onPressed: () {},
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Container(
                width: double.infinity,
                child: Column(
                  children: [
                    SizedBox(height: 15),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                              color: Color.fromARGB(255, 194, 194, 194)),
                        ),
                        width: constraints.maxWidth * 0.9,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: constraints.maxWidth * 0.9,
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 2, 65, 96),
                                  border: Border.all(
                                      color:
                                          Color.fromARGB(255, 202, 202, 202)),
                                ),
                                child: Column(
                                  children: [
                                    SizedBox(height: 10),
                                    Text(
                                      "Update Rack",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 13),
                                  ],
                                ),
                              ),
                              Text(
                                "Rack",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              Container(
                                width: constraints.maxWidth * 0.9,
                                child: TextField(
                                  controller: rackname,
                                  readOnly: true, // ✅ Make field non-editable
                                  decoration: InputDecoration(
                                    hintText: rackname.text.isNotEmpty
                                        ? rackname.text
                                        : 'Enter Rack Name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide:
                                          BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 8.0),
                                  ),
                                ),
                              ),

                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                "Warehouse Name",
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              TextField(
                                controller: warehouse,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Warehouse name',
                                  labelStyle: TextStyle(fontSize: 12.0),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 8.0),
                                ),
                              ),

                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                "Number of Columns",
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 5,
                              ),

                              Container(
                                width: constraints.maxWidth * 0.9,
                                child: TextField(
                                  controller: racknumber,
                                  decoration: InputDecoration(
                                    hintText: racknumber.text.isNotEmpty
                                        ? racknumber.text
                                        : 'Enter Rack number',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide:
                                          BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 8.0),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),

                              SizedBox(height: 15),
                              ElevatedButton(
                                onPressed: () {
                                  // Parse to int and check
                                  int? entered = int.tryParse(racknumber.text);
                                  if (entered == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Please enter a valid number'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    return;
                                  }
                                  if (entered <= (oldRackNumber ?? 0)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Number of columns must be greater than current value (${oldRackNumber ?? 0})'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    return;
                                  }
                                  updaterack();
                                },
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.blue),
                                  shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  fixedSize: MaterialStateProperty.all<Size>(
                                    Size(constraints.maxWidth * 0.4, 50),
                                  ),
                                ),
                                child: Text("Submit",
                                    style: TextStyle(color: Colors.white)),
                              ),

                              // Displaying the list of departments as a table
                              SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    // Padding(
                    //   padding: const EdgeInsets.only(left: 15),
                    //   child: Row(
                    //     mainAxisAlignment: MainAxisAlignment.start,
                    //     children: [
                    //       Text(
                    //         "Available Banks",
                    //         style: TextStyle(
                    //             fontSize: 14, fontWeight: FontWeight.bold),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    // SizedBox(height: 10),
                    // Padding(
                    //   padding: const EdgeInsets.only(right: 15, left: 15),
                    //   child: Table(
                    //     border: TableBorder.all(
                    //         color: const Color.fromARGB(255, 255, 255, 255)),
                    //     columnWidths: {
                    //       0: FixedColumnWidth(40.0),
                    //       1: FlexColumnWidth(),
                    //       2: FixedColumnWidth(50.0),
                    //     },
                    //     children: [
                    //       const TableRow(
                    //         decoration: BoxDecoration(
                    //           color: Colors.blue,
                    //         ),
                    //         children: [
                    //           Padding(
                    //             padding: EdgeInsets.all(8.0),
                    //             child: Text(
                    //               "No.",
                    //               style: TextStyle(
                    //                   fontWeight: FontWeight.bold,
                    //                   color: Colors.white),
                    //             ),
                    //           ),
                    //           Padding(
                    //             padding: EdgeInsets.all(8.0),
                    //             child: Text(
                    //               "Bank Name",
                    //               style: TextStyle(
                    //                   fontWeight: FontWeight.bold,
                    //                   color: Colors.white),
                    //             ),
                    //           ),
                    //           Padding(
                    //             padding: EdgeInsets.all(8.0),
                    //             child: Text(
                    //               "Edit",
                    //               style: TextStyle(
                    //                   fontWeight: FontWeight.bold,
                    //                   color: Colors.white),
                    //             ),
                    //           ),
                    //         ],
                    //       ),
                    //       for (int i = 0; i < banks.length; i++)
                    //         TableRow(
                    //           children: [
                    //             Padding(
                    //               padding: const EdgeInsets.all(8.0),
                    //               child: Text((i + 1).toString()),
                    //             ),
                    //             Padding(
                    //               padding: const EdgeInsets.all(8.0),
                    //               child: Text(banks[i]['name']),
                    //             ),
                    //             Padding(
                    //               padding: const EdgeInsets.all(8.0),
                    //               child: GestureDetector(
                    //                 onTap: () {
                    //                   Navigator.push(
                    //                       context,
                    //                       MaterialPageRoute(
                    //                           builder: (context) => update_bank(
                    //                               id: banks[i]['id'])));
                    //                 },
                    //                 child: Image.asset(
                    //                   "lib/assets/edit.jpg",
                    //                   width: 20,
                    //                   height: 20,
                    //                 ),
                    //               ),
                    //             )
                    //           ],
                    //         ),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              ),
            );
          },
        ));
  }
}
