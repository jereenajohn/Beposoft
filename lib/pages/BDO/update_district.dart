import 'dart:convert';

import 'package:beposoft/pages/ACCOUNTS/add_district.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UpdateDistrict extends StatefulWidget {
  final int id;

  const UpdateDistrict({super.key, required this.id});

  @override
  State<UpdateDistrict> createState() => _UpdateDistrictState();
}

class _UpdateDistrictState extends State<UpdateDistrict> {
  TextEditingController districtController = TextEditingController();

  List<Map<String, dynamic>> states = [];
  int? selectedStateId;

  bool loading = true;

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    await getStates();
    await getDistrictDetails();
  }

  // ===================== GET STATES =====================
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

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var data = parsed['data'];

        List<Map<String, dynamic>> stateList = [];

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

  Future<void> getDistrictDetails() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/districts/update/${widget.id}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // print("District Details Status: ${response.statusCode}");
      // print("District Details Body: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        var districtData = parsed["data"]; // ✅ NOT data[0]

        setState(() {
          districtController.text = districtData["name"] ?? "";
          selectedStateId = districtData["state"];
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  // ===================== UPDATE DISTRICT =====================
  void updateDistrict() async {
    final token = await gettokenFromPrefs();

    try {
      var response = await http.put(
        Uri.parse('$api/api/districts/update/${widget.id}/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
        body: {
          "name": districtController.text.trim(),
          "state": selectedStateId.toString(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color.fromARGB(255, 49, 212, 4),
            content: Text("District Updated Successfully"),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AddDistrict()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Failed to update district"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Something went wrong"),
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
          "Update District",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : LayoutBuilder(
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
                                      color:
                                          const Color.fromARGB(255, 2, 65, 96),
                                      border: Border.all(
                                          color: Color.fromARGB(
                                              255, 202, 202, 202)),
                                    ),
                                    child: Column(
                                      children: [
                                        SizedBox(height: 10),
                                        Text(
                                          "Edit District",
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

                                  SizedBox(height: 15),

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
                                          borderRadius:
                                              BorderRadius.circular(10),
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

                                  SizedBox(height: 15),

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
                                      controller: districtController,
                                      decoration: InputDecoration(
                                        labelText: 'District',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          borderSide:
                                              BorderSide(color: Colors.grey),
                                        ),
                                        contentPadding:
                                            EdgeInsets.symmetric(vertical: 8.0),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 15),

                                  ElevatedButton(
                                    onPressed: () {
                                      updateDistrict();
                                    },
                                    style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all<Color>(
                                        Colors.blue,
                                      ),
                                      shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      fixedSize:
                                          MaterialStateProperty.all<Size>(
                                        Size(constraints.maxWidth * 0.5, 50),
                                      ),
                                    ),
                                    child: Text("Update",
                                        style: TextStyle(color: Colors.white)),
                                  ),

                                  SizedBox(height: 10),
                                ],
                              ),
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
