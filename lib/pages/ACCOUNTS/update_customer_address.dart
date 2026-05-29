import 'dart:convert';

import 'package:beposoft/pages/ACCOUNTS/add_credit_note.dart';
import 'package:beposoft/pages/ACCOUNTS/customer.dart';
import 'package:beposoft/pages/ACCOUNTS/recipts_list.dart';
import 'package:beposoft/pages/BDO/bdo_customer_list.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Editaddress extends StatefulWidget {
  final int addresid;
  final int customerid;
  final String customername;

  const Editaddress({
    super.key,
    required this.addresid,
    required this.customerid,
    required this.customername,
  });

  @override
  State<Editaddress> createState() => _EditaddressState();
}

class _EditaddressState extends State<Editaddress> {
  late TextEditingController customerNameController;

  TextEditingController name = TextEditingController();
  TextEditingController address = TextEditingController();
  TextEditingController zipcode = TextEditingController();
  TextEditingController city = TextEditingController();
  TextEditingController state = TextEditingController();
  TextEditingController country = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController altphone = TextEditingController();
  TextEditingController email = TextEditingController();

  String? selectedState;
  String? selectedStateName;

  List<Map<String, dynamic>> stat = [];

  var allocatedstates;
  var family;
  String? department;

  bool isStateLoading = false;
  bool isPageLoading = true;

  @override
  void initState() {
    super.initState();

    customerNameController = TextEditingController(text: widget.customername);

    loadInitialData();
  }

  @override
  void dispose() {
    customerNameController.dispose();
    name.dispose();
    address.dispose();
    zipcode.dispose();
    city.dispose();
    state.dispose();
    country.dispose();
    phone.dispose();
    altphone.dispose();
    email.dispose();
    super.dispose();
  }

  Future<void> loadInitialData() async {
    setState(() {
      isPageLoading = true;
    });

    await getprofiledata();
    await getaddress();

    setState(() {
      isPageLoading = false;
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

      setState(() {
        department = dep;
      });

      if (token == null || token.isEmpty) {
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
          allocatedstates = productsData['allocated_states'];
          family = productsData['family'];
        });
      }
    } catch (error) {}
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

  Widget buildDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedState,
      isExpanded: true,
      onChanged: stat.isNotEmpty
          ? (String? newValue) {
              setState(() {
                selectedState = newValue;

                final matchedState = stat.firstWhere(
                  (element) => element['id'].toString() == newValue,
                  orElse: () => {},
                );

                if (matchedState.isNotEmpty) {
                  selectedStateName = matchedState['name'].toString();
                } else {
                  selectedStateName = null;
                }
              });
            }
          : null,
      items: stat.map((stateData) {
        return DropdownMenuItem<String>(
          value: stateData['id'].toString(),
          child: Text(
            stateData['name'].toString(),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 10,
        ),
        labelText: isStateLoading
            ? 'Loading states...'
            : department == "BDO"
                ? 'Select Allocated State'
                : 'Select State',
      ),
      hint: Text(
        isStateLoading
            ? 'Loading states...'
            : department == "BDO"
                ? 'No allocated states available'
                : 'No states available',
      ),
    );
  }

  Future<void> getstate(int? stateId) async {
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

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        List<Map<String, dynamic>> statelist = [];

        for (var productData in productsData) {
          statelist.add({
            'id': productData['id'],
            'name': productData['name'],
          });
        }

        if (department == "BDO") {
          final allocatedStateIds = _getAllocatedStateIds();

          statelist = statelist.where((stateData) {
            final parsedStateId = int.tryParse(stateData['id'].toString());
            return parsedStateId != null &&
                allocatedStateIds.contains(parsedStateId);
          }).toList();
        }

        String? newSelectedState;
        String? newSelectedStateName;

        if (stateId != null) {
          final matchedState = statelist.firstWhere(
            (element) => int.tryParse(element['id'].toString()) == stateId,
            orElse: () => {},
          );

          if (matchedState.isNotEmpty) {
            newSelectedState = matchedState['id'].toString();
            newSelectedStateName = matchedState['name'].toString();
          }
        }

        if (newSelectedState == null && statelist.isNotEmpty) {
          newSelectedState = statelist.first['id'].toString();
          newSelectedStateName = statelist.first['name'].toString();
        }

        setState(() {
          stat = statelist;
          selectedState = newSelectedState;
          selectedStateName = newSelectedStateName;
          isStateLoading = false;
        });
      } else {
        setState(() {
          stat = [];
          selectedState = null;
          selectedStateName = null;
          isStateLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        stat = [];
        selectedState = null;
        selectedStateName = null;
        isStateLoading = false;
      });
    }
  }

  Future<void> getaddress() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/address/get/${widget.addresid}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        int? stateId;

        if (productsData['state'] != null) {
          stateId = int.tryParse(productsData['state'].toString());
        }

        setState(() {
          name.text = productsData['name'] ?? '';
          email.text = productsData['email'] ?? '';
          zipcode.text = productsData['zipcode'] ?? '';
          address.text = productsData['address'] ?? '';
          city.text = productsData['city'] ?? '';
          country.text = productsData['country'] ?? '';
          phone.text = productsData['phone'] ?? '';
          altphone.text = productsData['alt_phone'] ?? '';
          state.text = productsData['state']?.toString() ?? '';
        });

        await getstate(stateId);
      }
    } catch (error) {}
  }

  Future<void> updateaddress() async {
    try {
      if (selectedState == null || selectedState!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a state'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final token = await gettokenFromPrefs();

      var response = await http.put(
        Uri.parse('$api/api/update/cutomer/address/${widget.addresid}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          {
            'name': name.text,
            'email': email.text,
            'zipcode': zipcode.text,
            'address': address.text,
            'city': city.text,
            'country': country.text,
            'phone': phone.text,
            'alt_phone': altphone.text,
            'state': selectedState,
          },
        ),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('address updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => bdo_customer_list()),
        );
      } else {
        String errorMsg = 'Failed to update address';

        try {
          final decoded = jsonDecode(response.body);

          if (decoded is Map && decoded.containsKey('message')) {
            errorMsg = decoded['message'].toString();
          } else if (decoded is Map && decoded.containsKey('errors')) {
            final errors = decoded['errors'];
            if (errors is Map && errors.isNotEmpty) {
              final firstError = errors.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                errorMsg = firstError.first.toString();
              } else {
                errorMsg = firstError.toString();
              }
            }
          }
        } catch (e) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating address'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(242, 255, 255, 255),
      appBar: AppBar(
        title: const Text(
          "Add Address",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => customer_list()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Image.asset('lib/assets/profile.png'),
            onPressed: () {},
          ),
        ],
      ),
      body: isPageLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
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
                              "Update Address",
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
                                    controller: customerNameController,
                                    decoration: InputDecoration(
                                      labelText: 'Customer Name',
                                      prefixIcon:
                                          const Icon(Icons.local_offer),
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
                                      prefixIcon:
                                          const Icon(Icons.local_offer),
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
                                                      BorderRadius.circular(
                                                          10.0),
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
                                                      BorderRadius.circular(
                                                          10.0),
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
                                  buildDropdown(),
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
                                  const SizedBox(height: 30),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        height: 1,
                                        width: 300,
                                        color: const Color.fromARGB(
                                          255,
                                          215,
                                          201,
                                          201,
                                        ),
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
                                  updateaddress();
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
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}