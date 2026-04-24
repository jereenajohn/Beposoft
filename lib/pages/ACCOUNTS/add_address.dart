import 'dart:convert';

import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/customer.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/update_customer_address.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beposoft/pages/api.dart';

class add_address extends StatefulWidget {
  const add_address({super.key, required this.customerid, required this.name});

  final int customerid;
  final name;
  @override
  State<add_address> createState() => _add_addressState();
}

class _add_addressState extends State<add_address> {
  double number = 0.00;
  late TextEditingController customer;
  TextEditingController name = TextEditingController();
  TextEditingController address = TextEditingController();

  TextEditingController zipcode = TextEditingController();
  TextEditingController city = TextEditingController();
  TextEditingController state = TextEditingController();

  TextEditingController country = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController altphone = TextEditingController();

  TextEditingController email = TextEditingController();
  List<Map<String, dynamic>> statess = [];
  List<Map<String, dynamic>> customers = [];

  String? selectstate;
  int? selectedStateId;
  String? selectedCustomerId;

  final TextEditingController _controller = TextEditingController();
  void incrementNumber() {
    setState(() {
      number +=
          0.01; // Increment by 0.01 (you can adjust the increment value as needed)
      _controller.text = number.toStringAsFixed(2);
    });
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

  void decrementNumber() {
    setState(() {
      if (number >= 0.01) {
        number -=
            0.01; // Decrement by 0.01 (you can adjust the decrement value as needed)
        _controller.text = number.toStringAsFixed(2);
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

  List<String> categories = ["Joishya", 'Hanvi', 'nimitha', 'Hari'];
  String selectededu = "Hari";
  // List<String> state = ["Kerala", 'Tamilnadu', 'Karnataka', 'Gujarat'];
  // String selectstate = "Kerala";

  @override
  void initState() {
    getstates();
    getcustomers();
    getaddress();
    customer = TextEditingController(text: widget.name);
    super.initState();
  }

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  List<Map<String, dynamic>> addres = [];

  Future<void> getaddress() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/add/customer/address/${widget.customerid}/'),
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
          // String imageUrl = "${productData['image']}";
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

  Future<void> getcustomers() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/customers/'),
        headers: {
          'Authorization': '$token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> customerlist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          customerlist.add({
            'id': productData['id'],
            'name': productData['name'],
          });
        }

        setState(() {
          customers = customerlist;

          // After fetching customers, set the customer name and ID
          setCustomerName();
        });
      }
    } catch (error) {}
  }

  void setCustomerName() {
    // Find the customer with the matching ID
    final selectedCustomer = customers.firstWhere(
      (customer) => customer['id'] == widget.customerid,
      orElse: () => {},
    );

    // If a matching customer is found, set the name in the text field and save the customer ID
    if (selectedCustomer.isNotEmpty) {
      customer.text = selectedCustomer['name'];
      selectedCustomerId =
          selectedCustomer['id'].toString(); // Store the customer ID
    }
  }

  Future<void> getstates() async {
    try {
      final token = await gettokenFromPrefs();

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
        setState(() {
          statess = stateslist;
        });
      }
    } catch (error) {}
  }

  void addaddress(
    String name,
    String address,
    String email,
    String phone,
    String altphone,
    String zipcode,
    String city,
    String state,
    String country,
    BuildContext scaffoldContext,
  ) async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.post(
        Uri.parse('$api/api/add/customer/address/${widget.customerid}/'),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "customer": widget.customerid,
          "name": name,
          "address": address,
          "zipcode": zipcode,
          "city": city,
          "state": selectedStateId,
          "country": country,
          "phone": phone,
          "alt_phone": altphone,
          "email": email,
        }),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Address added Successfully.'),
          ),
        );
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => add_address(
                    customerid: widget.customerid, name: widget.name)));
      } else {
        String errorMsg = 'Adding address failed.';
        try {
          final Map<String, dynamic> errorBody = jsonDecode(response.body);
          if (errorBody.containsKey('errors')) {
            final errors = errorBody['errors'] as Map<String, dynamic>;
            if (errors.isNotEmpty) {
              // Get the first error message
              final firstError = errors.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                errorMsg = firstError.first.toString();
              }
            }
          }
        } catch (e) {
          // Ignore JSON parse errors, fallback to default message
        }
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(errorMsg),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          content: Text('Enter valid information'),
        ),
      );
    }
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
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
        // Trigger the navigation logic when the back swipe occurs
        _navigateBack();
        return false; // Prevent the default back navigation behavior
      },
      child: Scaffold(
        backgroundColor: Color.fromARGB(242, 255, 255, 255),
        appBar: AppBar(
          title: Text(
            "Add Address",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back), // Custom back arrow
            onPressed: () async {
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
                    padding: const EdgeInsets.only(left: 95),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Add Address",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15),
                  SizedBox(
                    height: 230,
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
                              TextField(
                                controller: customer,
                                decoration: InputDecoration(
                                  labelText: 'Customer Name',
                                  prefixIcon: Icon(Icons.local_offer),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 8.0),
                                ),
                              ),
                              SizedBox(height: 10),
                              Text("Shipping Address Name",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 10),
                              TextField(
                                controller: name,
                                decoration: InputDecoration(
                                  labelText: 'name',
                                  prefixIcon: Icon(Icons.local_offer),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 8.0),
                                ),
                              ),
                              SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  SizedBox(
                    height: 750,
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
                              SizedBox(height: 20),
                              Text("Country ",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 10),
                              TextField(
                                controller: country,
                                decoration: InputDecoration(
                                  labelText: 'Country',
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
                              SizedBox(height: 10),
                              Text("Phone Number * : ",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 10),
                              TextField(
                                controller: phone,
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

                               Text("Alternate Number * : ",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 10),
                              TextField(
                                controller: altphone,
                                decoration: InputDecoration(
                                  labelText: 'Alt Number',
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
                        SizedBox(width: 13),
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: () {
                              if (selectstate == null || selectstate!.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text("Please select a state")),
                                );
                                return; // don't proceed
                              }

                              addaddress(
                                name.text,
                                address.text,
                                email.text,
                                phone.text,
                                altphone.text,
                                zipcode.text,
                                city.text,
                                state.text,
                                country.text,
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
                            child: Text("Submit",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 35),

                  // Display addresses in table format
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer Addresses',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Customer Name')),
                              DataColumn(label: Text('Address')),
                              DataColumn(label: Text('Edit')),
                            ],
                            rows: addres
                                .map((address) => DataRow(cells: [
                                      DataCell(Text(widget.name)),
                                      DataCell(Text(address['address'])),
                                      DataCell(
                                        IconButton(
                                          icon: Icon(Icons.edit),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    Editaddress(
                                                        addresid: address['id'],
                                                        customerid:
                                                            widget.customerid,
                                                        customername:
                                                            widget.name),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ]))
                                .toList(),
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
    );
  }
}
