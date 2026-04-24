import 'dart:convert';

import 'package:beposoft/Sales%20Directors/SD_dashboard.dart';
import 'package:beposoft/functions.dart';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/MARKETING/marketing_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class add_new_customer extends StatefulWidget {
  const add_new_customer({super.key});

  @override
  State<add_new_customer> createState() => _add_new_customerState();
}

class _add_new_customerState extends State<add_new_customer> {
  List<Map<String, dynamic>> manager = [];
  List<Map<String, dynamic>> statess = [];

  String? selectedManagerName;
  int? selectedManagerId;
  String? selectstate;
  int? selectedId; // variable to store selected id
  int? selectedStateId;
  final _formKey = GlobalKey<FormState>();

  List<String> categories = ["customer", "warehouse"];
  String selectedCategory = "customer"; // Default value
  List<String> gst = ["NO GST", "Yes"];
  String selectedgst = ""; // Default value

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

  @override
  void initState() {
    super.initState();
    _initData();
  }

  var tok;
  var id;
  Functions functions = Functions();
  Future<void> _initData() async {
    tok = await functions.gettokenFromPrefs();
    id = await functions.getidFromPrefs();
    selectedManagerId = id;

    getmanagers();
    getprofiledata();
    getcustomertype();
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
          'before_data': {"Action": "${name.text} Customer added "},
          'after_data': {"Data": "$responseData"},
          'order': "",
        }),
      );

      // print("====================${response.body}");

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

  List<Map<String, dynamic>> type = [];

  Future<void> getcustomertype() async {
    try {
      final response =
          await http.get(Uri.parse('$api/api/customer-types/'), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $tok',
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

  var allocatedstates;
  var family;

  Future<void> getprofiledata() async {
    try {
      var response = await http.get(
        Uri.parse("$api/api/profile/"),
        headers: {
          'Authorization': 'Bearer $tok',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        setState(() {
          allocatedstates = productsData['allocated_states'];
          family = productsData['family'];
        });
        getstates();
      }
    } catch (error) {}
  }

  bool isOnlyLetters(String value) {
    return RegExp(r'^[A-Za-z]+$').hasMatch(value);
  }

  bool isValidGST(String value) {
    final gst = value.trim().toUpperCase();

    final RegExp gstRegex =
        RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');

    return gstRegex.hasMatch(gst);
  }

  var responseData;
  void addcustomer(
      String gstno,
      String name,
      String selectedManagerId,
      String selectedStateId,
      String phone,
      String altphone,
      String email,
      String address,
      String zipcode,
      String city,
      String states,
      String comment,
      BuildContext scaffoldContext) async {
    // ================= GST VALIDATION START =================
    final String gst = gstno.trim().toUpperCase();

    bool isOnlyLetters(String value) {
      return RegExp(r'^[A-Z]+$').hasMatch(value);
    }

    bool isValidGST(String value) {
      final RegExp gstRegex =
          RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
      return gstRegex.hasMatch(value);
    }

    if (gst.isNotEmpty) {
      // ❌ GST contains only letters
      if (isOnlyLetters(gst)) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('GST number cannot contain only letters'),
          ),
        );
        return;
      }

      // ❌ Invalid GST format
      if (!isValidGST(gst)) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Enter a valid GST number'),
          ),
        );
        return;
      }
    }
    // ================= GST VALIDATION END =================

    try {
      var response = await http.post(
        Uri.parse('$api/api/add/customer/'),
        headers: {
          'Authorization': 'Bearer $tok',
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "gst": gst,
          "name": name,
          "manager": selectedManagerId,
          "state": selectedStateId,
          "phone": phone,
          "alt_phone": altphone,
          "email": email,
          "address": address,
          "zip_code": zipcode,
          "city": city,
          "comment": comment,
          "customer_status": selectedCategory,
          'customer_type': selectedId,
          "gst_confirm": selectedgst,
        }),
      );

      if (response.statusCode == 201) {
        responseData = jsonDecode(response.body);
        AddStatusTime(scaffoldContext);

        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Customer Added Successfully.'),
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => add_new_customer()),
        );
      } else {
        String errorMsg = 'Customer already exists.';
        try {
          final Map<String, dynamic> errorBody = jsonDecode(response.body);
          if (errorBody.containsKey('errors')) {
            final errors = errorBody['errors'] as Map<String, dynamic>;
            if (errors.isNotEmpty) {
              final firstError = errors.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                errorMsg = firstError.first.toString();
              }
            }
          }
        } catch (e) {}

        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(errorMsg),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          content: Text('An error occurred.'),
        ),
      );
    }
  }

  Future<String?> gettokenFromPrefs() async {
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

  Future<void> getmanagers() async {
    try {
      var dep = await getdepFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/staffs/'),
        headers: {
          'Authorization': 'Bearer $tok',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> managerlist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          if (dep == "BDM") {
            if (productData['family'] == family) {
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

        setState(() {
          manager = managerlist;
        });
      }
    } catch (error) {}
  }

  Future<void> getstates() async {
    try {
      var dep = await getdepFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/states/'),
        headers: {
          'Authorization': 'Bearer $tok',
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

  String selectededu = "Hari";
  List<String> state = [
    "Kerala",
    'Tamilnadu',
    'Karnataka',
    'Gujarat',
  ];
  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  // String selectstate = "Kerala";
  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();
    if (dep == "BDO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                bdo_dashbord()), // Replace AnotherPage with your target page
      );
    } else if (dep == "SD") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                SdDashboard()), // Replace AnotherPage with your target page
      );
    } else if (dep == "BDM") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                bdm_dashbord()), // Replace AnotherPage with your target page
      );
    } else if (dep == "CEO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ceo_dashboard()), // Replace AnotherPage with your target page
      );
    } else if (dep == "COO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ceo_dashboard()), // Replace AnotherPage with your target page
      );
    } else if (dep == "CSO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                cso_dashboard()), // Replace AnotherPage with your target page
      );
    } else if (dep == "Marketing") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                marketing_dashboard()), // Replace AnotherPage with your target page
      );
    } else if (dep == "warehouse") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                WarehouseDashboard()), // Replace AnotherPage with your target page
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
        MaterialPageRoute(builder: (context) => dashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Trigger the navigation logic when the back swipe occurs
        _navigateBack();
        return false; // Prevent the default back navigation behavior
      },
      child: Scaffold(
        backgroundColor: Color.fromARGB(242, 255, 255, 255),
        appBar: AppBar(
          title: Text(
            "Add Customer",
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
              } else if (dep == "SD") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SdDashboard()), // Replace AnotherPage with your target page
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
              } else if (dep == "Warehouse Admin") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          WarehouseAdmin()), // Replace AnotherPage with your target page
                );
              } else if (dep == "CEO") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ceo_dashboard()), // Replace AnotherPage with your target page
                );
              } else if (dep == "COO") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ceo_dashboard()), // Replace AnotherPage with your target page
                );
              } else if (dep == "CSO") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          cso_dashboard()), // Replace AnotherPage with your target page
                );
              } else if (dep == "Marketing") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          marketing_dashboard()), // Replace AnotherPage with your target page
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
            padding:
                const EdgeInsets.only(top: 30, left: 12, right: 12, bottom: 50),
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
                          "Add New Customer ",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15),
                  SizedBox(
                    height: 555, // Increased height to accommodate new dropdown
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
                              // New Dropdown added here
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
                                  items: categories
                                      .map<DropdownMenuItem<String>>(
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
                                  value:
                                      selectedgst.isEmpty ? null : selectedgst,
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

                              if (selectedgst == "Yes") SizedBox(height: 15),

                              if (selectedgst == "Yes")
                                Text(
                                  "GSTIN Number",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                              if (selectedgst == "Yes") SizedBox(height: 10),
                              if (selectedgst == "Yes")
                                TextField(
                                  controller: gstno,
                                  decoration: InputDecoration(
                                    labelText: 'AAA00',
                                    prefixIcon: Icon(Icons.numbers),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide:
                                          BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 8.0),
                                  ),
                                ),

                              SizedBox(height: 10),

                              Text(
                                "Name of Customer",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 10),
                              TextField(
                                controller: name,
                                decoration: InputDecoration(
                                  labelText: 'Name of customer',
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
                                    border: Border.all(
                                        color: Colors.grey, width: 1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButton<int>(
                                    hint: Text("Select Type"),
                                    value: selectedId,
                                    isExpanded:
                                        true, // makes dropdown take full width
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
                              Text(
                                "Technical Manager",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
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
                                    SizedBox(width: 20),
                                    Flexible(
                                      child: InputDecorator(
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 1),
                                        ),
                                        child: DropdownButton<
                                            Map<String, dynamic>>(
                                          value: manager.isNotEmpty
                                              ? manager.firstWhere(
                                                  (element) =>
                                                      element['id'] ==
                                                      selectedManagerId,
                                                  orElse: () => manager[0],
                                                )
                                              : null,
                                          underline: Container(),
                                          onChanged: manager.isNotEmpty
                                              ? (Map<String, dynamic>?
                                                  newValue) {
                                                  setState(() {
                                                    selectedManagerName =
                                                        newValue!['name'];
                                                    selectedManagerId =
                                                        newValue['id'];
                                                  });
                                                }
                                              : null,
                                          items: manager.isNotEmpty
                                              ? manager.map<
                                                  DropdownMenuItem<
                                                      Map<String, dynamic>>>(
                                                  (Map<String, dynamic>
                                                      manager) {
                                                    return DropdownMenuItem<
                                                        Map<String, dynamic>>(
                                                      value: manager,
                                                      child:
                                                          Text(manager['name']),
                                                    );
                                                  },
                                                ).toList()
                                              : [
                                                  DropdownMenuItem(
                                                    child: Text(
                                                        'No managers available'),
                                                    value: null,
                                                  ),
                                                ],
                                          icon: Container(
                                            alignment: Alignment.centerRight,
                                            child: Icon(Icons.arrow_drop_down),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 5),
                  // SizedBox(
                  //   height: 200,
                  //   width: 340,
                  //   child: Card(
                  //     elevation: 3,
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(10.0),
                  //     ),
                  //     child: Container(
                  //       decoration: BoxDecoration(
                  //         color: Colors.white,
                  //         borderRadius: BorderRadius.circular(10.0),
                  //         border: Border.all(
                  //             color: Color.fromARGB(255, 236, 236, 236)),
                  //       ),
                  //       child: Padding(
                  //         padding: const EdgeInsets.all(10.0),
                  //         child: Column(
                  //           crossAxisAlignment: CrossAxisAlignment.start,
                  //           children: [
                  //             Text("Administrative information ",
                  //                 style: TextStyle(
                  //                     fontSize: 15, fontWeight: FontWeight.bold)),
                  //             SizedBox(height: 20),
                  //             TextField(
                  //               decoration: InputDecoration(
                  //                 labelText: 'Naf code',
                  //                 border: OutlineInputBorder(
                  //                   borderRadius: BorderRadius.circular(10.0),
                  //                   borderSide: BorderSide(color: Colors.grey),
                  //                 ),
                  //                 contentPadding:
                  //                     EdgeInsets.symmetric(vertical: 8.0),
                  //               ),
                  //             ),
                  //             SizedBox(height: 10),
                  //             TextField(
                  //               decoration: InputDecoration(
                  //                 labelText: 'VAT number',
                  //                 border: OutlineInputBorder(
                  //                   borderRadius: BorderRadius.circular(10.0),
                  //                   borderSide: BorderSide(color: Colors.grey),
                  //                 ),
                  //                 contentPadding:
                  //                     EdgeInsets.symmetric(vertical: 8.0),
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 10),
                              TextField(
                                controller: email,
                                decoration: InputDecoration(
                                  labelText: 'Mail Id',
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 13),
                              TextField(
                                controller: address,
                                decoration: InputDecoration(
                                  labelText: 'Address',
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              borderSide: BorderSide(
                                                  color: Colors.grey),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              borderSide: BorderSide(
                                                  color: Colors.grey),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 10),
                              Container(
                                width:
                                    double.infinity, // Use full width available
                                height: 49,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal:
                                            10), // Adjust padding as needed
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<Map<String, dynamic>>(
                                      value: statess.isNotEmpty
                                          ? statess.firstWhere(
                                              (element) =>
                                                  element['name'] ==
                                                  selectstate,
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
                                      isExpanded:
                                          true, // Ensure dropdown takes full width
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 20),
                              TextField(
                                controller: comment,
                                decoration: InputDecoration(
                                  labelText: 'Enter',
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
                    padding: const EdgeInsets.only(left: 120),
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // Your onPressed logic goes here
                          },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                              Color.fromARGB(255, 164, 164, 164),
                            ),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            fixedSize: MaterialStateProperty.all<Size>(
                              Size(85, 15),
                            ),
                          ),
                          child: Text("Close",
                              style: TextStyle(color: Colors.white)),
                        ),
                        SizedBox(width: 13),
                        ElevatedButton(
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

                            if (selectedgst == "Yes" && gstno.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text("Please enter GSTIN number"),
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
                                      "Phone number must be exactly 10 digits."),
                                ),
                              );
                              return;
                            }

                            if (selectstate == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Please select a state"),
                                ),
                              );
                              return;
                            }

                            if (selectedManagerId != null &&
                                selectedStateId != null) {
                              addcustomer(
                                gstno.text,
                                name.text,
                                selectedManagerId!.toString(),
                                selectedStateId!.toString(),
                                phone.text,
                                altphone.text,
                                email.text,
                                address.text,
                                zipcode.text,
                                city.text,
                                states.text,
                                comment.text,
                                context,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text(
                                      'Please select both manager and state.'),
                                ),
                              );
                            }
                          },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                              Color.fromARGB(255, 244, 66, 66),
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
                          child: Text("Submit",
                              style: TextStyle(color: Colors.white)),
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
      ),
    );
  }
}
