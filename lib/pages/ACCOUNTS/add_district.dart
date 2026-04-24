import 'dart:convert';

import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/update_district.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddDistrict extends StatefulWidget {
  const AddDistrict({super.key});

  @override
  State<AddDistrict> createState() => _AddDistrictState();
}

class _AddDistrictState extends State<AddDistrict> {
  @override
  void initState() {
    super.initState();
    getStates();
    getDistricts();
  }

  TextEditingController district = TextEditingController();

  int? selectedStateId;

  List<Map<String, dynamic>> states = [];
  List<Map<String, dynamic>> districts = [];

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  // ================= GET STATES ===================
  Future<void> getStates() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/states/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> stateList = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var data = parsed['data'];

        for (var item in data) {
          stateList.add({
            "id": item["id"],
            "name": item["name"],
          });
        }

        setState(() {
          states = stateList;
        });
      }
    } catch (e) {}
  }

  // ================= GET DISTRICTS ===================
  Future<void> getDistricts() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/districts/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> districtList = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var data = parsed['data'];

        for (var item in data) {
          districtList.add({
            "id": item["id"],
            "name": item["name"],
            "state_name": item["state_name"],
            "state_id": item["state_id"],
          });
        }

        setState(() {
          districts = districtList;
        });
      }
    } catch (e) {}
  }

  // ================= ADD DISTRICT ===================
  void addDistrict() async {
    final token = await gettokenFromPrefs();

    if (selectedStateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Please select a state"),
        ),
      );
      return;
    }

    if (district.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Please enter district name"),
        ),
      );
      return;
    }

    try {
      var response = await http.post(
        Uri.parse('$api/api/districts/add/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
        body: {
          "state": selectedStateId.toString(),
          "district": district.text.trim(),
        },
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color.fromARGB(255, 49, 212, 4),
            content: Text("District Added Successfully"),
          ),
        );

        district.clear();
        selectedStateId = null;

        getDistricts();
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Failed to add district"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("An error occurred. Please try again."),
        ),
      );
    }
  }

  // ================= DELETE DISTRICT ===================
  Future<void> deleteDistrict(int id) async {
    final token = await gettokenFromPrefs();

    try {
      final response = await http.delete(
        Uri.parse('$api/api/district/update/$id/'), // ✅ same like state delete
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color.fromARGB(255, 49, 212, 4),
            content: Text("Deleted Successfully"),
          ),
        );

        getDistricts();
      }
    } catch (e) {}
  }

  // ================= LOGOUT ===================
  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('token');

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

    await Future.delayed(Duration(seconds: 2));

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
        title: Text(
          "Add District",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
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
            } else if (dep == "ADMIN") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => admin_dashboard()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => dashboard()),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Container(
              width: double.infinity,
              child: Column(
                children: [
                  SizedBox(height: 15),

                  // =================== FORM CARD ===================
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                            color: Color.fromARGB(255, 202, 202, 202)),
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
                                    color: Color.fromARGB(255, 202, 202, 202)),
                              ),
                              child: Column(
                                children: [
                                  SizedBox(height: 10),
                                  Text(
                                    "New District",
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

                            SizedBox(height: 10),

                            // =================== STATE DROPDOWN ===================
                            Text(
                              "State",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),

                            Container(
                              width: constraints.maxWidth * 0.9,
                              child: DropdownButtonFormField<int>(
                                value: selectedStateId,
                                decoration: InputDecoration(
                                  labelText: "Select State",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                items: states.map((item) {
                                  return DropdownMenuItem<int>(
                                    value: item["id"],
                                    child: Text(item["name"]),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedStateId = value;
                                  });
                                },
                              ),
                            ),

                            SizedBox(height: 10),

                            // =================== DISTRICT FIELD ===================
                            Text(
                              "District",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),

                            Container(
                              width: constraints.maxWidth * 0.9,
                              child: TextField(
                                controller: district,
                                decoration: InputDecoration(
                                  labelText: 'District',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 8.0),
                                ),
                              ),
                            ),

                            SizedBox(height: 10),

                            ElevatedButton(
                              onPressed: () {
                                addDistrict();
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
                                  Size(constraints.maxWidth * 0.4, 50),
                                ),
                              ),
                              child: Text("Submit",
                                  style: TextStyle(color: Colors.white)),
                            ),

                            SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 15),

                  Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Available Districts",
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 10),

                  // =================== TABLE ===================
                  Padding(
                    padding:
                        const EdgeInsets.only(right: 15, left: 15, bottom: 55),
                    child: Container(
                      color: Colors.white,
                      child: Table(
                        border: TableBorder.all(
                            color: Color.fromARGB(255, 214, 213, 213)),
                        columnWidths: {
                          0: FixedColumnWidth(40.0),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(2),
                          3: FixedColumnWidth(50.0),
                        },
                        children: [
                          const TableRow(
                            decoration: BoxDecoration(
                              color: Colors.blue,
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
                                  "State",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  "District",
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
                          for (int i = 0; i < districts.length; i++)
                            TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text((i + 1).toString()),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(districts[i]['state_name'] ?? ""),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(districts[i]['name'] ?? ""),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => UpdateDistrict(
                                              id: districts[i]['id']),
                                        ),
                                      );
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
