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

  @override
  void initState() {
    super.initState();
    getaddress();
    //  getstate(); 
    customerNameController = TextEditingController(text: widget.customername);

    ;
    ;
    ;
  }

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
  
Widget buildDropdown() {
  return DropdownButtonFormField<String>(
    value: selectedState,
    onChanged: (String? newValue) {
      setState(() {
        selectedState = newValue;
        ;
      });
    },
    items: stat.map((state) {
      return DropdownMenuItem<String>(
        value: state['id'].toString(),
        child: Text(state['name']),
      );
    }).toList(),
    decoration: InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Colors.grey),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 8.0),
      labelText: 'Select State',
    ),
  );
}

List<Map<String, dynamic>> stat = [];

Future<void> getstate(int stateId) async {
  try {
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

      setState(() {
        stat = statelist;

        // Find the state name corresponding to the ID
        var matchedState = stat.firstWhere(
          (element) => element['id'] == stateId,
          orElse: () => {'name': null},
        );

        if (matchedState['name'] != null) {
          selectedState = stateId.toString();
          selectedStateName = matchedState['name'];
        }
      });
    } else {
      ;
    }
  } catch (error) {
    ;
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
      ;

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

        // Fetch states and set the default selection
        int stateId = productsData['state'];
        getstate(stateId);
      });
    } else {
      ;
    }
  } catch (error) {
    ;
  }
}


  Future<void> updateaddress() async {
    try {
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
          SnackBar(
            content: Text('address updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      
      Navigator.push(context, MaterialPageRoute(builder: (context) => bdo_customer_list()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update address'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating address'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(242, 255, 255, 255),
      appBar: AppBar(
        title: Text(
          "Add Address",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Custom back arrow
          onPressed: () async {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => customer_list()));
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
                        "Update Address",
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
                              controller: customerNameController,
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
                                    fontSize: 15, fontWeight: FontWeight.bold)),
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
                                    fontSize: 15, fontWeight: FontWeight.bold)),
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
    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
SizedBox(height: 10),
buildDropdown(),

                            // Container(
                            //   width:
                            //       double.infinity, // Use full width available
                            //   height: 49,
                            //   decoration: BoxDecoration(
                            //     border: Border.all(color: Colors.grey),
                            //     borderRadius: BorderRadius.circular(10),
                            //   ),
                            //   child: InputDecorator(
                            //     decoration: InputDecoration(
                            //       border: InputBorder.none,
                            //       contentPadding: EdgeInsets.symmetric(
                            //           horizontal:
                            //               10), // Adjust padding as needed
                            //     ),
                            //     child: DropdownButtonHideUnderline(
                            //       child: DropdownButton<Map<String, dynamic>>(
                            //         value: statess.isNotEmpty
                            //             ? statess.firstWhere(
                            //                 (element) =>
                            //                     element['name'] == selectstate,
                            //                 orElse: () => statess[0],
                            //               )
                            //             : null,
                            //         onChanged: statess.isNotEmpty
                            //             ? (Map<String, dynamic>? newValue) {
                            //                 setState(() {
                            //                   selectstate = newValue!['name'];
                            //                   selectedStateId = newValue[
                            //                       'id']; // Store the selected state's ID

                            //                 });
                            //               }
                            //             : null,
                            //         items: statess.isNotEmpty
                            //             ? statess.map<
                            //                 DropdownMenuItem<
                            //                     Map<String, dynamic>>>(
                            //                 (Map<String, dynamic> state) {
                            //                   return DropdownMenuItem<
                            //                       Map<String, dynamic>>(
                            //                     value: state,
                            //                     child: Text(state['name']),
                            //                   );
                            //                 },
                            //               ).toList()
                            //             : [
                            //                 DropdownMenuItem(
                            //                   child:
                            //                       Text('No states available'),
                            //                   value: null,
                            //                 ),
                            //               ],
                            //         icon: Icon(Icons.arrow_drop_down),
                            //         isExpanded:
                            //             true, // Ensure dropdown takes full width
                            //       ),
                            //     ),
                            //   ),
                            // ),
                            SizedBox(height: 20),
                            Text("Country ",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
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
                                    fontSize: 15, fontWeight: FontWeight.bold)),
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
                                    fontSize: 15, fontWeight: FontWeight.bold)),
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
                                    fontSize: 15, fontWeight: FontWeight.bold)),
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
                            updateaddress();
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
              ],
            ),
          ),
        ),
      ),
    );
  }

 
}
