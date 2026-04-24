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

class AddDistricts extends StatefulWidget {
  const AddDistricts({super.key});

  @override
  State<AddDistricts> createState() => _AddDistrictsState();
}

class _AddDistrictsState extends State<AddDistricts> {
  final TextEditingController districtController = TextEditingController();

  int? selectedStateId;

  List<Map<String, dynamic>> states = [];
  List<Map<String, dynamic>> districts = [];

  bool isLoading = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    initializePage();
  }

  @override
  void dispose() {
    districtController.dispose();
    super.dispose();
  }

  void logPrint(String label, dynamic value) {
    debugPrint("========== $label ==========");
    debugPrint(value.toString());
    debugPrint("====================================");
  }

  Future<void> initializePage() async {
    setState(() {
      isLoading = true;
    });

    logPrint("INIT", "initializePage started");

    await getStates();
    await getDistricts();

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    logPrint("INIT", "initializePage completed");
  }

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    logPrint("TOKEN FROM PREFS", token);
    return token;
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final dep = prefs.getString('department');
    logPrint("DEPARTMENT FROM PREFS", dep);
    return dep;
  }

  Future<void> getStates() async {
    try {
      final token = await gettokenFromPrefs();

      logPrint("GET STATES URL", '$api/api/states/');

      final response = await http.get(
        Uri.parse('$api/api/states/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      logPrint("GET STATES STATUS", response.statusCode);
      logPrint("GET STATES BODY", response.body);

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final List data = parsed['data'] ?? [];

        final List<Map<String, dynamic>> stateList = [];

        for (final item in data) {
          stateList.add({
            "id": item["id"],
            "name": item["name"]?.toString() ?? "",
            "province": item["province"]?.toString(),
          });
        }

        logPrint("PARSED STATES COUNT", stateList.length);
        logPrint("PARSED STATES LIST", stateList);

        if (!mounted) return;

        setState(() {
          states = stateList;

          if (selectedStateId != null &&
              !states.any((s) => s["id"] == selectedStateId)) {
            selectedStateId = null;
          }
        });
      } else {
        debugPrint("State fetch failed: ${response.statusCode}");
        debugPrint("State fetch body: ${response.body}");
      }
    } catch (e, st) {
      debugPrint("State Fetch Error: $e");
      debugPrint("$st");
    }
  }

  Future<void> getDistricts() async {
    try {
      final token = await gettokenFromPrefs();

      logPrint("GET DISTRICTS URL", '$api/api/districts/add/');

      final response = await http.get(
        Uri.parse('$api/api/districts/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      logPrint("GET DISTRICTS STATUS", response.statusCode);
      logPrint("GET DISTRICTS BODY", response.body);

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final List data = parsed['data'] ?? [];

        final List<Map<String, dynamic>> districtList = [];

        for (final item in data) {
          final row = {
            "id": item["id"],
            "name": item["name"]?.toString() ?? "",
            "state_name": item["state_name"]?.toString() ?? "",
            "state": item["state"],
          };

          districtList.add(row);

          logPrint("PARSED DISTRICT ROW", row);
        }

        logPrint("PARSED DISTRICT COUNT", districtList.length);

        if (!mounted) return;

        setState(() {
          districts = districtList;
        });
      } else {
        debugPrint("District fetch failed: ${response.statusCode}");
        debugPrint("District fetch body: ${response.body}");
      }
    } catch (e, st) {
      debugPrint("District Fetch Error: $e");
      debugPrint("$st");
    }
  }

  Future<void> addDistrict() async {
    final token = await gettokenFromPrefs();

    logPrint("SELECTED STATE ID BEFORE SUBMIT", selectedStateId);
    logPrint("DISTRICT TEXT BEFORE SUBMIT", districtController.text);

    if (selectedStateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Please select a state"),
        ),
      );
      return;
    }

    if (districtController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Please enter district name"),
        ),
      );
      return;
    }

    try {
      setState(() {
        isSubmitting = true;
      });

      final bodyData = {
        "name": districtController.text.trim(),
        "state": selectedStateId,
      };

      logPrint("POST DISTRICT URL", '$api/api/districts/add/');
      logPrint("POST DISTRICT BODY MAP", bodyData);
      logPrint("POST DISTRICT BODY JSON", jsonEncode(bodyData));

      final response = await http.post(
        Uri.parse('$api/api/districts/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(bodyData),
      );

      logPrint("ADD DISTRICT STATUS", response.statusCode);
      logPrint("ADD DISTRICT RESPONSE BODY", response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final parsedResponse = jsonDecode(response.body);
          logPrint("ADD DISTRICT PARSED RESPONSE", parsedResponse);
          logPrint("ADD DISTRICT SAVED DATA", parsedResponse["data"]);
        } catch (e) {
          logPrint("ADD DISTRICT RESPONSE PARSE ERROR", e);
        }

        districtController.clear();

        if (!mounted) return;

        setState(() {
          selectedStateId = null;
        });

        await getDistricts();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color.fromARGB(255, 49, 212, 4),
            content: Text("District Added Successfully"),
          ),
        );
      } else {
        String errorText = "Failed to add district";

        try {
          final parsed = jsonDecode(response.body);
          if (parsed["errors"] != null) {
            errorText = parsed["errors"].toString();
          } else if (parsed["error"] != null) {
            errorText = parsed["error"].toString();
          } else if (parsed["message"] != null) {
            errorText = parsed["message"].toString();
          } else {
            errorText = response.body;
          }
        } catch (_) {
          errorText = response.body;
        }

        logPrint("ADD DISTRICT ERROR TEXT", errorText);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(errorText),
          ),
        );
      }
    } catch (e, st) {
      debugPrint("Add District Error: $e");
      debugPrint("$st");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("An error occurred: $e"),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });
    }
  }

  Future<void> deleteDistrict(int id) async {
    final token = await gettokenFromPrefs();

    try {
      logPrint("DELETE DISTRICT ID", id);
      logPrint("DELETE DISTRICT URL", '$api/api/district/update/$id/');

      final response = await http.delete(
        Uri.parse('$api/api/district/update/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      logPrint("DELETE DISTRICT STATUS", response.statusCode);
      logPrint("DELETE DISTRICT BODY", response.body);

      if (response.statusCode == 200 || response.statusCode == 204) {
        await getDistricts();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color.fromARGB(255, 49, 212, 4),
            content: Text("Deleted Successfully"),
          ),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Delete failed: ${response.body}"),
          ),
        );
      }
    } catch (e, st) {
      debugPrint("Delete Error: $e");
      debugPrint("$st");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Delete error: $e"),
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

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => login()),
    );
  }

  Future<void> handleBackNavigation() async {
    final dep = await getdepFromPrefs();

    if (!mounted) return;

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
  }

  @override
  Widget build(BuildContext context) {
    final int? safeSelectedStateId =
        states.any((item) => item["id"] == selectedStateId)
            ? selectedStateId
            : null;

    return WillPopScope(
      onWillPop: () async {
        await handleBackNavigation();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(242, 255, 255, 255),
        appBar: AppBar(
          title: const Text(
            "Add District",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await handleBackNavigation();
            },
          ),
          actions: [
            IconButton(
              icon: Image.asset('lib/assets/profile.png'),
              onPressed: () {},
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        children: [
                          const SizedBox(height: 15),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(
                                  color:
                                      const Color.fromARGB(255, 202, 202, 202),
                                ),
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
                                          color: const Color.fromARGB(
                                              255, 202, 202, 202),
                                        ),
                                      ),
                                      child: const Column(
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
                                    const SizedBox(height: 10),
                                    const Text(
                                      "State",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: constraints.maxWidth * 0.9,
                                      child: DropdownButtonFormField<int>(
                                        value: safeSelectedStateId,
                                        isExpanded: true,
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
                                            child: Text(
                                              item["name"]?.toString() ?? "",
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: isSubmitting
                                            ? null
                                            : (value) {
                                                logPrint("STATE DROPDOWN CHANGED", value);
                                                setState(() {
                                                  selectedStateId = value;
                                                });
                                              },
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      "District",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: constraints.maxWidth * 0.9,
                                      child: TextField(
                                        controller: districtController,
                                        enabled: !isSubmitting,
                                        onChanged: (value) {
                                          logPrint("DISTRICT TEXT CHANGED", value);
                                        },
                                        decoration: InputDecoration(
                                          labelText: 'District',
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
                                            horizontal: 12.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ElevatedButton(
                                      onPressed: isSubmitting
                                          ? null
                                          : () {
                                              logPrint("SUBMIT BUTTON", "Clicked");
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
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        fixedSize:
                                            MaterialStateProperty.all<Size>(
                                          Size(
                                            constraints.maxWidth * 0.4,
                                            50,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        isSubmitting ? "Submitting..." : "Submit",
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          const Padding(
                            padding: EdgeInsets.only(left: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  "Available Districts",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.only(
                              right: 15,
                              left: 15,
                              bottom: 55,
                            ),
                            child: Container(
                              color: Colors.white,
                              child: districts.isEmpty
                                  ? Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color.fromARGB(
                                              255, 214, 213, 213),
                                        ),
                                      ),
                                      child: const Text(
                                        "No districts available",
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  : Table(
                                      border: TableBorder.all(
                                        color: const Color.fromARGB(
                                            255, 214, 213, 213),
                                      ),
                                      columnWidths: const {
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
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Text(
                                                "State",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Text(
                                                "District",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Text(
                                                "Edit",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        for (int i = 0; i < districts.length; i++)
                                          TableRow(
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text((i + 1).toString()),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                  districts[i]['state_name']
                                                          ?.toString() ??
                                                      "",
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                  districts[i]['name']
                                                          ?.toString() ??
                                                      "",
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: GestureDetector(
                                                  onTap: () async {
                                                    logPrint("EDIT DISTRICT ID", districts[i]['id']);
                                                    await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            UpdateDistrict(
                                                          id: districts[i]['id'],
                                                        ),
                                                      ),
                                                    );
                                                    await getDistricts();
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
      ),
    );
  }
}