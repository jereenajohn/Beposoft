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
  List<Map<String, dynamic>> addres = [];

  String? selectstate;
  int? selectedStateId;
  String? selectedCustomerId;

  var allocatedstates;
  var family;
  String? department;

  bool isStateLoading = false;

  final TextEditingController _controller = TextEditingController();

  drower d = drower();

  List<String> categories = ["Joishya", 'Hanvi', 'nimitha', 'Hari'];
  String selectededu = "Hari";

  @override
  void initState() {
    super.initState();

    customer = TextEditingController(text: widget.name);

    getprofiledata();
    getcustomers();
    getaddress();
  }

  @override
  void dispose() {
    customer.dispose();
    name.dispose();
    address.dispose();
    zipcode.dispose();
    city.dispose();
    state.dispose();
    country.dispose();
    phone.dispose();
    altphone.dispose();
    email.dispose();
    _controller.dispose();
    super.dispose();
  }

  void incrementNumber() {
    setState(() {
      number += 0.01;
      _controller.text = number.toStringAsFixed(2);
    });
  }

  void decrementNumber() {
    setState(() {
      if (number >= 0.01) {
        number -= 0.01;
        _controller.text = number.toStringAsFixed(2);
      }
    });
  }

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<void> getprofiledata() async {
    try {
      final token = await gettokenFromPrefs();
      final dep = await getdepFromPrefs();

      if (token == null || token.isEmpty) {
        getstates();
        return;
      }

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
          department = dep;
          allocatedstates = productsData['allocated_states'];
          family = productsData['family'];
        });

        getstates();
      } else {
        setState(() {
          department = dep;
        });

        getstates();
      }
    } catch (error) {
      getstates();
    }
  }

  List<int> _getAllocatedStateIds() {
    List<int> ids = [];

    if (allocatedstates == null) {
      return ids;
    }

    if (allocatedstates is List) {
      for (var item in allocatedstates) {
        if (item == null) continue;

        if (item is int) {
          ids.add(item);
        } else if (item is String) {
          final parsedId = int.tryParse(item);
          if (parsedId != null) {
            ids.add(parsedId);
          }
        } else if (item is Map) {
          if (item['id'] != null) {
            final parsedId = int.tryParse(item['id'].toString());
            if (parsedId != null) {
              ids.add(parsedId);
            }
          }
        }
      }
    }

    return ids;
  }

  Future<void> getstates() async {
    try {
      setState(() {
        isStateLoading = true;
      });

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

        if (department == "BDO") {
          final allocatedStateIds = _getAllocatedStateIds();

          stateslist = stateslist.where((stateData) {
            final stateId = int.tryParse(stateData['id'].toString());
            return stateId != null && allocatedStateIds.contains(stateId);
          }).toList();
        }

        setState(() {
          statess = stateslist;

          if (statess.isNotEmpty) {
            selectstate = statess.first['name'].toString();
            selectedStateId = int.tryParse(statess.first['id'].toString());
          } else {
            selectstate = null;
            selectedStateId = null;
          }

          isStateLoading = false;
        });
      } else {
        setState(() {
          statess = [];
          selectstate = null;
          selectedStateId = null;
          isStateLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        statess = [];
        selectstate = null;
        selectedStateId = null;
        isStateLoading = false;
      });
    }
  }

  Future<void> getcustomers() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/customers/'),
        headers: {
          'Authorization': 'Bearer $token',
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
          setCustomerName();
        });
      }
    } catch (error) {}
  }

  void setCustomerName() {
    final selectedCustomer = customers.firstWhere(
      (customer) => customer['id'] == widget.customerid,
      orElse: () => {},
    );

    if (selectedCustomer.isNotEmpty) {
      customer.text = selectedCustomer['name'].toString();
      selectedCustomerId = selectedCustomer['id'].toString();
    }
  }

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
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Address added Successfully.'),
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => add_address(
              customerid: widget.customerid,
              name: widget.name,
            ),
          ),
        );
      } else {
        String errorMsg = 'Adding address failed.';

        try {
          final Map<String, dynamic> errorBody = jsonDecode(response.body);

          if (errorBody.containsKey('errors')) {
            final errors = errorBody['errors'] as Map<String, dynamic>;
            if (errors.isNotEmpty) {
              final firstError = errors.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                errorMsg = firstError.first.toString();
              } else {
                errorMsg = firstError.toString();
              }
            }
          } else if (errorBody.containsKey('message')) {
            errorMsg = errorBody['message'].toString();
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
          backgroundColor: Colors.red,
          content: Text('Enter valid information'),
        ),
      );
    }
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('token');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ScaffoldMessenger.of(context).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });

    await Future.delayed(const Duration(seconds: 2));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => login()),
    );
  }

  Widget _buildDropdownTile(
    BuildContext context,
    String title,
    List<String> options,
  ) {
    return ExpansionTile(
      title: Text(title),
      children: options.map((option) {
        return ListTile(
          title: Text(option),
          onTap: () {
            Navigator.pop(context);
            d.navigateToSelectedPage(context, option);
          },
        );
      }).toList(),
    );
  }

  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();

    if (dep == "BDO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => bdo_dashbord()),
      );
    } else if (dep == "BDM") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => bdm_dashbord()),
      );
    } else if (dep == "warehouse") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WarehouseDashboard()),
      );
    } else if (dep == "CEO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ceo_dashboard()),
      );
    } else if (dep == "COO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ceo_dashboard()),
      );
    } else if (dep == "Warehouse Admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WarehouseAdmin()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => dashboard()),
      );
    }
  }

  Widget _buildStateDropdown() {
    return Container(
      width: double.infinity,
      height: 49,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InputDecorator(
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 10),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Map<String, dynamic>>(
            value: statess.isNotEmpty && selectedStateId != null
                ? statess.firstWhere(
                    (element) =>
                        int.tryParse(element['id'].toString()) ==
                        selectedStateId,
                    orElse: () => statess[0],
                  )
                : null,
            onChanged: statess.isNotEmpty
                ? (Map<String, dynamic>? newValue) {
                    if (newValue == null) return;

                    setState(() {
                      selectstate = newValue['name'].toString();
                      selectedStateId =
                          int.tryParse(newValue['id'].toString());
                    });
                  }
                : null,
            items: statess.map<DropdownMenuItem<Map<String, dynamic>>>(
              (Map<String, dynamic> stateData) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: stateData,
                  child: Text(
                    stateData['name'].toString(),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ).toList(),
            hint: Text(
              isStateLoading
                  ? 'Loading states...'
                  : department == "BDO"
                      ? 'No allocated states available'
                      : 'No states available',
            ),
            icon: const Icon(Icons.arrow_drop_down),
            isExpanded: true,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(242, 255, 255, 255),
        appBar: AppBar(
          title: const Text(
            "Add Address",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
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
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.only(left: 95),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Add Address",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
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
                            color: const Color.fromARGB(255, 236, 236, 236),
                          ),
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
                                  prefixIcon: const Icon(Icons.local_offer),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide:
                                        const BorderSide(color: Colors.grey),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Shipping Address Name",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: name,
                                decoration: InputDecoration(
                                  labelText: 'name',
                                  prefixIcon: const Icon(Icons.local_offer),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide:
                                        const BorderSide(color: Colors.grey),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
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
                            color: const Color.fromARGB(255, 236, 236, 236),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              const Text(
                                "Address/Building Name/ Building Number ",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 13),
                              TextField(
                                controller: address,
                                decoration: InputDecoration(
                                  labelText: 'Address',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide:
                                        const BorderSide(color: Colors.grey),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Zip code",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: 144,
                                        child: TextField(
                                          controller: zipcode,
                                          decoration: InputDecoration(
                                            labelText: 'Zip code',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              borderSide: const BorderSide(
                                                color: Colors.grey,
                                              ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 13),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "City",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: 144,
                                        child: TextField(
                                          controller: city,
                                          decoration: InputDecoration(
                                            labelText: 'City',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              borderSide: const BorderSide(
                                                color: Colors.grey,
                                              ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "State *:",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildStateDropdown(),
                              const SizedBox(height: 20),
                              const Text(
                                "Country ",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: country,
                                decoration: InputDecoration(
                                  labelText: 'Country',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide:
                                        const BorderSide(color: Colors.grey),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    height: 1,
                                    width: 300,
                                    color: const Color.fromARGB(
                                        255, 215, 201, 201),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Phone Number * : ",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: phone,
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide:
                                        const BorderSide(color: Colors.grey),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Alternate Number * : ",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: altphone,
                                decoration: InputDecoration(
                                  labelText: 'Alt Number',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide:
                                        const BorderSide(color: Colors.grey),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Mail Id : ",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: email,
                                decoration: InputDecoration(
                                  labelText: 'Mail Id',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide:
                                        const BorderSide(color: Colors.grey),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 1,
                        width: 300,
                        color: const Color.fromARGB(255, 215, 201, 201),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Padding(
                    padding: const EdgeInsets.only(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 13),
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: () {
                              if (selectedStateId == null ||
                                  selectstate == null ||
                                  selectstate!.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Please select a state"),
                                  ),
                                );
                                return;
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
                              backgroundColor:
                                  MaterialStateProperty.all<Color>(
                                Colors.blue,
                              ),
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              fixedSize: MaterialStateProperty.all<Size>(
                                const Size(95, 15),
                              ),
                            ),
                            child: const Text(
                              "Submit",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 35),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Customer Addresses',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Customer Name')),
                              DataColumn(label: Text('Address')),
                              DataColumn(label: Text('Edit')),
                            ],
                            rows: addres
                                .map(
                                  (addressData) => DataRow(
                                    cells: [
                                      DataCell(Text(widget.name.toString())),
                                      DataCell(
                                        Text(
                                          addressData['address']?.toString() ??
                                              '',
                                        ),
                                      ),
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    Editaddress(
                                                  addresid: addressData['id'],
                                                  customerid:
                                                      widget.customerid,
                                                  customername: widget.name,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                )
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