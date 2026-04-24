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
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

class view_customer extends StatefulWidget {
  const view_customer({super.key, required this.customerid});
  final int customerid;

  @override
  State<view_customer> createState() => _view_customerState();
}

class _view_customerState extends State<view_customer> {
  List<Map<String, dynamic>> manager = [];
  List<Map<String, dynamic>> statess = [];
  List<Map<String, dynamic>> customer = [];

  List<String> categories = ["customer", "warehouse"];
  String selectedCategory = "customer"; // Default value

  String? selectedManagerName;
  int? selectedManagerId;
  String? selectstate;
  int? selectedStateId;
  int? selectedId; // variable to store selected id
  TextEditingController gstno = TextEditingController();
  TextEditingController name = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController altphone = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController address = TextEditingController();
  TextEditingController zipcode = TextEditingController();
  TextEditingController city = TextEditingController();
  TextEditingController states = TextEditingController();
  TextEditingController comment = TextEditingController();
  List<String> gst = ["NO GST", "Yes"];
  String selectedgst = ""; // Default value
  @override
  void initState() {
    super.initState();
    // getcustomertype();
    // getcustomers();
    // getmanagers();
    // getstates();

    getprofiledata();
    initCustomerData();
  }

  Future<void> initCustomerData() async {
    await getprofiledata(); // Load profile first (for family, dep, etc.)
    await getcustomertype(); // Load customer types
    await getcustomers(); // ✅ Fetch existing customer first to get managerfetchid
    await getmanagers(); // ✅ Then load managers (now managerfetchid is available)
    await getstates(); // Finally load states
  }

  void initdata() async {
    await getmanagers();
    await getstates();
  }

  List<Map<String, dynamic>> type = [];

  Future<void> getcustomertype() async {
    final token = await gettokenFromPrefs();
    try {
      final response =
          await http.get(Uri.parse('$api/api/customer-types/'), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      List<Map<String, dynamic>> banklist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        for (var productData in parsed) {
          banklist.add({
            'id': productData['id'],
            'name': productData['type_name'],
          });
        }
        setState(() {
          type = banklist;
        });
      }
    } catch (e) {}
  }

  Future<void> storeUserData(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> AddStatusTime(BuildContext scaffoldContext) async {
    final token = await gettokenFromPrefs();
    try {
      final response = await http.post(
        Uri.parse('$api/api/datalog/create/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'before_data': {"Action": "${name.text} Customer updated "},
          'after_data': {"Data": "$responseData"},
          'order': "",
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('time added Successfully.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Adding time failed.'),
          ),
        );
      }
    } catch (e) {}
  }

  var responseData;
  void updateCustomer(
    String gst,
    String name,
    int manager,
    String phone,
    String altPhone,
    String email,
    String address,
    String zipcode,
    String city,
    int state,
    String comment,
    BuildContext context,
  ) async {
    final token = await gettokenFromPrefs();

    // ✅ Check before sending API request
    if (manager == 0 || state == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "⚠️ Please select Technical Manager and State once more to confirm.",
            style: TextStyle(color: Colors.white),
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return; // ⛔ Stop execution here
    }

    try {
      var response = await http.put(
        Uri.parse("$api/api/customer/update/${widget.customerid}/"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "gst": gst,
          "name": name,
          "manager": manager,
          "phone": phone,
          "alt_phone": altPhone,
          "email": email,
          "address": address,
          "zip_code": zipcode,
          "city": city,
          "state": state,
          "gst_confirm": selectedgst,
          "comment": comment,
        }),
      );

      if (response.statusCode == 200) {
        responseData = jsonDecode(response.body);
        AddStatusTime(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color.fromARGB(255, 49, 212, 4),
            content: Text('✅ Customer updated successfully'),
          ),
        );
      } else {
        // show API error message in snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('❌ Failed to update: ${response.body}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('⚠️ An error occurred. Please try again.'),
        ),
      );
    }
  }

  var managerfetchid;
  var statefetchid;
  String? managerfetchname;

  Future<void> getcustomers() async {
    try {
      final token = await gettokenFromPrefs();
      var response = await http.get(
        Uri.parse('$api/api/customer/update/${widget.customerid}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        gstno.text = productsData['gst'] ?? '';
        name.text = productsData['name'] ?? '';
        phone.text = productsData['phone'] ?? '';
        altphone.text = productsData['alt_phone'] ?? '';
        email.text = productsData['email'] ?? '';
        address.text = productsData['address'] ?? '';
        zipcode.text = productsData['zip_code']?.toString() ?? '';
        city.text = productsData['city'] ?? '';
        comment.text = productsData['comment'] ?? '';
        selectedgst = (productsData['gst'] != null &&
                productsData['gst'].toString().trim().isNotEmpty)
            ? "Yes"
            : "";

        // 🔹 Manager and state
        managerfetchname = productsData['manager']; // string
        statefetchid = productsData['state'] is int
            ? productsData['state']
            : int.tryParse(productsData['state'].toString());

        setState(() {
          selectedStateId = statefetchid;
        });
      }
    } catch (error) {}
  }

  // Future<String?> gettokenFromPrefs() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   return prefs.getString('token');
  // }
  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  var family;
  var staffid;
  var allocatedstates;

  Future<void> getprofiledata() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse("$api/api/profile/"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        setState(() {
          allocatedstates = productsData['allocated_states'];

          family = productsData['family'];
          staffid = productsData['id'];
        });
        getstates();
      }
    } catch (error) {}
  }

  Future<void> getmanagers() async {
    try {
      final token = await gettokenFromPrefs();
      var dep = await getdepFromPrefs();
      var response = await http.get(
        Uri.parse('$api/api/staffs/'),
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
          if (dep == "BDM") {
            if (productData['family'] == family) {
              managerlist.add({
                'id': productData['id'],
                'name': productData['name'],
              });
            }
          } else if (dep == 'BDO') {
            if (staffid == productData['id']) {
              managerlist.add({
                'id': productData['id'],
                'name': productData['name'],
              });
            }
          } else {
            managerlist.add({
              'id': productData['id'],
              'name': productData['name'],
            });
          }
        }

        // 🔹 Match by name, since API returns manager name string
        int? matchedId;
        if (managerfetchname != null) {
          for (var m in managerlist) {
            if (m['name'].toString().trim().toLowerCase() ==
                managerfetchname!.trim().toLowerCase()) {
              matchedId = m['id'];
              break;
            }
          }
        }

        setState(() {
          manager = managerlist;
          if (matchedId != null) {
            selectedManagerId = matchedId;
          }
        });
      }
    } catch (error) {}
  }

  Future<void> getstates() async {
    try {
      final token = await gettokenFromPrefs();
      var dep = await getdepFromPrefs();
      var response = await http.get(
        Uri.parse('$api/api/states/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> stateslist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          stateslist.add({
            'id': productData['id'],
            'name': productData['name'],
          });
        }

        // Filter to keep only allocated states
        if (dep == "BDO" || dep == "BDM") {
          if (allocatedstates.isNotEmpty) {
            List<Map<String, dynamic>> filteredStates = stateslist
                .where((state) => allocatedstates.contains(state['id']))
                .toList();
            setState(() {
              statess = filteredStates;
            });
          } else {
            statess = [];
          }
        } else {
          setState(() {
            statess = stateslist;
          });
        }
      }
    } catch (error) {}
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

  // String selectstate = "Kerala";
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 30, left: 12, right: 12),
          child: Container(
            width: double.infinity,
            color: Colors.white,
            child: Column(
              children: [
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(left: 75),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "Update Customer",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 15),
                SizedBox(
                  height: 570,
                  width: 340,
                  child: Card(
                    elevation: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                            color: Color.fromARGB(255, 236, 236, 236)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(13.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Select Type",
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButton<String>(
                                value: categories.contains(selectedCategory)
                                    ? selectedCategory
                                    : null, // Ensure valid selection
                                isExpanded: true,
                                underline: SizedBox(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedCategory = newValue!;
                                  });
                                },
                                items: categories.map<DropdownMenuItem<String>>(
                                    (String category) {
                                  return DropdownMenuItem<String>(
                                    value: category,
                                    child: Text(category),
                                  );
                                }).toList(),
                                icon: Icon(Icons.arrow_drop_down),
                              ),
                            ),
                            SizedBox(height: 15),
                            // Text(
                            //   "GSTIN Number",
                            //   style: TextStyle(
                            //       fontSize: 15, fontWeight: FontWeight.bold),
                            // ),
                            // SizedBox(height: 10),
                            // TextField(
                            //   controller: gstno,
                            //   decoration: InputDecoration(
                            //     labelText: 'AAA00',
                            //     prefixIcon: Icon(Icons.numbers),
                            //     border: OutlineInputBorder(
                            //       borderRadius: BorderRadius.circular(10.0),
                            //       borderSide: BorderSide(color: Colors.grey),
                            //     ),
                            //     contentPadding:
                            //         EdgeInsets.symmetric(vertical: 8.0),
                            //   ),
                            // ),
                            // SizedBox(height: 10),

                            Text(
                              "GST",
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButton<String>(
                                value: selectedgst.isEmpty ? null : selectedgst,
                                hint: Text("Select GST Option"),
                                isExpanded: true,
                                underline: SizedBox(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedgst = newValue ?? "";
                                  });
                                },
                                items: [
                                  DropdownMenuItem(
                                      value: "NO GST", child: Text("NO GST")),
                                  DropdownMenuItem(
                                      value: "Yes", child: Text("Yes")),
                                ],
                                icon: Icon(Icons.arrow_drop_down),
                              ),
                            ),

                            if (selectedgst == "Yes") ...[
                              SizedBox(height: 10),
                              Text("GSTIN Number",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 10),
                              TextField(
                                controller: gstno,
                                decoration: InputDecoration(
                                  labelText: 'Enter GSTIN',
                                  prefixIcon: Icon(Icons.numbers),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 8.0),
                                ),
                              ),
                            ],

                            SizedBox(height: 10),
                            Text("Name of customer ",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                            SizedBox(height: 10),
                            TextField(
                              controller: name,
                              decoration: InputDecoration(
                                labelText: 'Name of customer',
                                hintText: name.text.isNotEmpty
                                    ? name.text
                                    : 'Enter your name',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 8.0),
                              ),
                            ),
                            SizedBox(height: 10),

                            DropdownButtonHideUnderline(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 3),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey, width: 1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButton<int>(
                                  hint: Text("Select Type"),
                                  value: type.any(
                                          (item) => item["id"] == selectedId)
                                      ? selectedId
                                      : null,
                                  isExpanded: true,
                                  onChanged: (int? newValue) {
                                    setState(() {
                                      selectedId = newValue;
                                    });
                                  },
                                  items: type.map((item) {
                                    return DropdownMenuItem<int>(
                                      value: item["id"],
                                      child: Text(item["name"]),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),

                            SizedBox(height: 10),
                            Text("Technical manager",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                            SizedBox(height: 10),
                            Container(
                              width: 310,
                              height: 49,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 20),
                                  Flexible(
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        hintText: '',
                                        contentPadding:
                                            EdgeInsets.symmetric(horizontal: 1),
                                      ),
                                      child:
                                          DropdownButton<Map<String, dynamic>>(
                                        isExpanded: true,
                                        underline: const SizedBox(),
                                        icon: const Icon(Icons.arrow_drop_down),

                                        // ✅ Fix: Ensure correct manager is preselected
                                        value: manager.isNotEmpty
                                            ? manager.firstWhere(
                                                (m) =>
                                                    m['id'] ==
                                                    selectedManagerId,
                                                orElse: () => manager.first,
                                              )
                                            : null,

                                        onChanged:
                                            (Map<String, dynamic>? newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              selectedManagerId =
                                                  newValue['id'];
                                              selectedManagerName =
                                                  newValue['name'];
                                            });
                                          }
                                        },

                                        items: manager.isNotEmpty
                                            ? manager.map<
                                                DropdownMenuItem<
                                                    Map<String, dynamic>>>(
                                                (Map<String, dynamic> mgr) {
                                                  return DropdownMenuItem<
                                                      Map<String, dynamic>>(
                                                    value: mgr,
                                                    child: Text(
                                                      mgr['name'],
                                                      style: const TextStyle(
                                                          fontSize: 14),
                                                    ),
                                                  );
                                                },
                                              ).toList()
                                            : [
                                                const DropdownMenuItem(
                                                  value: null,
                                                  child: Text(
                                                      'No managers available'),
                                                ),
                                              ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 5),

                SizedBox(height: 15),
                // Continue adding form elements here
                SizedBox(height: 15),
                SizedBox(
                  height: 690,
                  width: 340,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                            color: Color.fromARGB(255, 236, 236, 236)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Client information ",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                            SizedBox(height: 20),
                            // Text("Discount : ",
                            //     style: TextStyle(
                            //         fontSize: 15, fontWeight: FontWeight.bold)),
                            // SizedBox(height: 10),
                            // TextField(
                            //   decoration: InputDecoration(
                            //     labelText: 'Discount ',
                            //     border: OutlineInputBorder(
                            //       borderRadius: BorderRadius.circular(10.0),
                            //       borderSide: BorderSide(color: Colors.grey),
                            //     ),
                            //     contentPadding:
                            //         EdgeInsets.symmetric(vertical: 8.0),
                            //   ),
                            // ),
                            // SizedBox(height: 10),
                            Text("Phone Number * : ",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                            SizedBox(height: 10),
                            TextField(
                              controller: phone,
                              keyboardType: TextInputType
                                  .phone, // 👈 Number/Phone keyboard
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 8.0),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Alternate Number : ",
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            TextField(
                              controller: altphone,
                              keyboardType: TextInputType
                                  .phone, // 👈 Number/Phone keyboard
                              decoration: InputDecoration(
                                labelText: 'Alternate Number',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 8.0),
                              ),
                            ),

                            SizedBox(height: 10),
                            Text("Mail Id : ",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                            SizedBox(height: 10),
                            TextField(
                              controller: email,
                              decoration: InputDecoration(
                                labelText: 'Mail Id',
                                hintText: email.text.isNotEmpty
                                    ? email.text
                                    : 'Enter your email Id',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 8.0),
                              ),
                            ),
                            SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  height: 1,
                                  width: 300,
                                  color: Color.fromARGB(255, 215, 201, 201),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            Text("Address/Building Name/ Building Number ",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                            SizedBox(height: 13),
                            TextField(
                              controller: address,
                              decoration: InputDecoration(
                                labelText: 'Address',
                                hintText: address.text.isNotEmpty
                                    ? address.text
                                    : 'Enter your Address',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 8.0),
                              ),
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Zip code",
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(height: 10),
                                    Container(
                                      width: 144,
                                      child: TextField(
                                        controller: zipcode,
                                        decoration: InputDecoration(
                                          labelText: 'Zip code',
                                          hintText: zipcode.text.isNotEmpty
                                              ? zipcode.text
                                              : 'Enter your zipcode',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                            borderSide:
                                                BorderSide(color: Colors.grey),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical: 8.0),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width: 13,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("City",
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(height: 10),
                                    Container(
                                      width: 144,
                                      child: TextField(
                                        controller: city,
                                        decoration: InputDecoration(
                                          labelText: 'City',
                                          hintText: city.text.isNotEmpty
                                              ? city.text
                                              : 'Enter your city',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                            borderSide:
                                                BorderSide(color: Colors.grey),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical: 8.0),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                            SizedBox(height: 10),
                            Text("State *:",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                            SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              height: 49,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 10),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<Map<String, dynamic>>(
                                    value: statess.isNotEmpty
                                        ? statess.firstWhere(
                                            (s) => s['id'] == selectedStateId,
                                            orElse: () => statess[0],
                                          )
                                        : null,
                                    onChanged: statess.isNotEmpty
                                        ? (Map<String, dynamic>? newValue) {
                                            setState(() {
                                              selectstate = newValue!['name'];
                                              selectedStateId = newValue[
                                                  'id']; // Store the selected state's ID
                                            });
                                          }
                                        : null,
                                    items: statess.isNotEmpty
                                        ? statess.map<
                                            DropdownMenuItem<
                                                Map<String, dynamic>>>(
                                            (Map<String, dynamic> state) {
                                              return DropdownMenuItem<
                                                  Map<String, dynamic>>(
                                                value: state,
                                                child: Text(state['name']),
                                              );
                                            },
                                          ).toList()
                                        : [
                                            DropdownMenuItem(
                                              child:
                                                  Text('No states available'),
                                              value: null,
                                            ),
                                          ],
                                    icon: Icon(Icons.arrow_drop_down),
                                    isExpanded: true,
                                  ),
                                ),
                              ),
                            ),

                            // SizedBox(height: 20),
                            // Text("Country ",
                            //     style: TextStyle(
                            //         fontSize: 15, fontWeight: FontWeight.bold)),
                            // SizedBox(height: 10),
                            // TextField(
                            //   decoration: InputDecoration(
                            //     labelText: 'Country',
                            //     border: OutlineInputBorder(
                            //       borderRadius: BorderRadius.circular(10.0),
                            //       borderSide: BorderSide(color: Colors.grey),
                            //     ),
                            //     contentPadding:
                            //         EdgeInsets.symmetric(vertical: 8.0),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 15),
                SizedBox(
                  height: 150,
                  width: 340,
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                            color: Color.fromARGB(255, 236, 236, 236)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Comment ",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                            SizedBox(height: 20),
                            TextField(
                              controller: comment,
                              decoration: InputDecoration(
                                labelText: 'Enter comment',
                                hintText: comment.text.isNotEmpty
                                    ? comment.text
                                    : 'Enter your comment',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 8.0),
                              ),
                              maxLines: null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 1,
                      width: 300,
                      color: Color.fromARGB(255, 215, 201, 201),
                    ),
                  ],
                ),
                SizedBox(height: 13),
                Padding(
                  padding: const EdgeInsets.only(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        child: ElevatedButton(
                          onPressed: () {
                            if (selectedgst.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text("Please select GST option"),
                                ),
                              );
                              return;
                            }

                            if (selectedgst == "Yes" &&
                                gstno.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text("GSTIN number required"),
                                ),
                              );
                              return;
                            }

                            final String phoneNumber = phone.text.trim();
                            if (phoneNumber.length != 10 ||
                                !RegExp(r'^\d{10}$').hasMatch(phoneNumber)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text(
                                      'Phone number must be exactly 10 digits.'),
                                ),
                              );
                              return;
                            }

                            updateCustomer(
                              gstno.text,
                              name.text,
                              selectedManagerId ?? managerfetchid ?? 0,
                              phone.text,
                              altphone.text,
                              email.text,
                              address.text,
                              zipcode.text,
                              city.text,
                              selectedStateId ?? statefetchid ?? 0,
                              comment.text,
                              context,
                            );
                          },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                              Colors.blue,
                            ),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            fixedSize: MaterialStateProperty.all<Size>(
                              Size(95, 15),
                            ),
                          ),
                          child: Text("Update",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 35),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
