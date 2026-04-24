import 'dart:convert';

import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/update_warehouse.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:beposoft/pages/api.dart';

class add_warehouse extends StatefulWidget {
  const add_warehouse({super.key});

  @override
  State<add_warehouse> createState() => _add_warehouseState();
}

class _add_warehouseState extends State<add_warehouse> {
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

  TextEditingController name = TextEditingController();
  TextEditingController location = TextEditingController();
  TextEditingController address = TextEditingController();

  List<Map<String, dynamic>> Warehouses = [];

  Future<String?> gettoken() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString('token');
  }

  @override
  void initState() {
    super.initState();
    getwarehouse();
    getcountry();
  }

    List<Map<String, dynamic>> country = [];
int? selectedCountryId;
String? selectedCountryName;
 Future<void> getcountry() async {
    final token = await gettoken();
    try {
      final response =
          await http.get(Uri.parse('$api/api/country/codes/'), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      List<Map<String, dynamic>> countrylist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          // String imageUrl = "${productData['image']}";
          countrylist.add({
            'id': productData['id'],
            'country_code': productData['country_code'],
          });
        }
        setState(() {
          country = countrylist;
        });
      }
    } catch (e) {}
  }
  Future<void> Addwarehouse(
    BuildContext scaffoldContext,
  ) async {
    final token = await gettoken();
    try {
      final response = await http.post(Uri.parse('$api/api/warehouse/add/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'name': name.text,
            'location': location.text,
            'address': address.text,
            'country_code': selectedCountryId,
          }));
      
      

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Warehouse added Successfully.'),
          ),
        );
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => add_warehouse()));
      } else {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Adding Warehouse failed.'),
          ),
        );
      }
    } catch (e) {
      
    }
  }

  Future<void> getwarehouse() async {
    final token = await gettoken();
    try {
      final response =
          await http.get(Uri.parse('$api/api/warehouse/add/'), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      List<Map<String, dynamic>> warehouselist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        
        for (var productData in parsed) {
          warehouselist.add({
            'id': productData['id'],
            'name': productData['name'],
            'location': productData['location'],
            'address': productData['address'] ?? '',
          });
        }
        setState(() {
          Warehouses = warehouselist;
          
        });
      }
    } catch (e) {
      
    }
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

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(242, 255, 255, 255),
      appBar: AppBar(
        title: Text(
          "Add Warehouse",
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
            }  else if (dep == "BDM") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        bdm_dashbord()), // Replace AnotherPage with your target page
              );
            }

else if(dep=="CEO" ){
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
 else {
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
                  border: Border.all(color: Color.fromARGB(255, 202, 202, 202)),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      " Warehouse Details ",
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
                    border:
                        Border.all(color: Color.fromARGB(255, 202, 202, 202)),
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
                        Text(
                          "Warehouse Name",
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
                              controller: name,
                              decoration: InputDecoration(
                                labelText: 'Warehouse Name',

                                labelStyle: TextStyle(
                                  fontSize: 12.0, // Set your desired font size
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: Colors.grey),
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
                          "Location",
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
                              controller: location,
                              decoration: InputDecoration(
                                labelText: 'Location',
                                labelStyle: TextStyle(
                                  fontSize: 12.0, // Set your desired font size
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: Colors.grey),
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
                          "Address",
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
                              controller: address,
                              decoration: InputDecoration(
                                labelText: 'Address',
                                labelStyle: TextStyle(
                                  fontSize: 12.0, // Set your desired font size
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: Colors.grey),
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

                          Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(10.0),
    border: Border.all(color: Colors.grey),
  ),
  padding: EdgeInsets.symmetric(horizontal: 12),
  child: DropdownButton<int>(
    isExpanded: true,
    value: selectedCountryId,
    hint: Text('Select Country Code'),
    underline: SizedBox(), // Removes default underline
    onChanged: (int? newValue) {
      setState(() {
        selectedCountryId = newValue;
        selectedCountryName = country.firstWhere((c) => c['id'] == newValue)['country_code'];
      });
    },
    items: country.map<DropdownMenuItem<int>>((countryItem) {
      return DropdownMenuItem<int>(
        value: countryItem['id'],
        child: Text(countryItem['country_code']),
      );
    }).toList(),
  ),
),

                                  SizedBox(height: 5),
                        SizedBox(
                          height: 15,
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
                                    Addwarehouse(context);
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
                                    fixedSize: MaterialStateProperty.all<Size>(
                                      Size(95,
                                          15), // Set your desired width and heigh
                                    ),
                                  ),
                                  child: Text("Submit",
                                      style: TextStyle(color: Colors.white)),
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
            SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Available Warehouse",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 15, left: 15,bottom:55),
              child: Container(
                color: Colors.white,
                child: Table(
                  border: TableBorder.all(
                      color: Color.fromARGB(255, 214, 213, 213)),
                  columnWidths: {
                    0: FixedColumnWidth(
                        30.0), // Fixed width for the first column (No.)
                    1: FlexColumnWidth(
                        3), // Increased Flex width for the second column (Warehouse Name)
                    2: FixedColumnWidth(
                        50.0), // Fixed width for the third column (Location)
                  },
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 64, 176, 251),
                      ),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "No.",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Warehouse Name",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Location",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Address",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Edit",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    for (int i = 0; i < Warehouses.length; i++)
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text((i + 1).toString()),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(Warehouses[i]['name']),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(Warehouses[i]['location']),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(Warehouses[i]['address']),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => update_warehouse(
                                            id: Warehouses[i]['id'])));
                              },
                              child: Image.asset(
                                "lib/assets/edit.jpg",
                                width: 20,
                                height: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 20,
            )
          ],
        ),
      )),
    );
  }
}
