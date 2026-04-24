import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:beposoft/pages/api.dart';

import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';

class BdoDsrAdding extends StatefulWidget {
  const BdoDsrAdding({super.key});

  @override
  State<BdoDsrAdding> createState() => _BdoDsrAddingState();
}

class _BdoDsrAddingState extends State<BdoDsrAdding> {
  List<Map<String, dynamic>> stat = [];
  List<Map<String, dynamic>> districts = [];
  List<Map<String, dynamic>> filteredDistricts = [];
  List<Map<String, dynamic>> myOrders = [];
  bool isLoadingTeams = false;

  Map<String, dynamic>? teamData;

  List<Map<String, dynamic>> customer = [];
  List<Map<String, dynamic>> filteredProducts = [];

  List<int> allocatedStateIds = [];

  Map<String, int> stateBillCountMap = {};

  int? selectedStateId;
  int? selectedDistrictId;
  int? selectedTeamId;

  final TextEditingController teamController = TextEditingController();
  final TextEditingController teamLeaderController = TextEditingController();
  final TextEditingController unbilledCustomerctrl = TextEditingController();
  final TextEditingController billedCustomerctrl = TextEditingController();
  final TextEditingController newCustomerctrl = TextEditingController();
  final TextEditingController newConvertionctrl = TextEditingController();

  Duration selectedDuration = Duration.zero;

  bool _isAdjustingBilled = false;
  bool _isAdjustingConversion = false;
  bool _isValidationDialogOpen = false;

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  int _parseInt(String value) {
    return int.tryParse(value.trim()) ?? 0;
  }

  void _setControllerValue(TextEditingController controller, String value) {
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> _showValidationPopup(String message) async {
    if (!mounted || _isValidationDialogOpen) return;

    _isValidationDialogOpen = true;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
              ),
              SizedBox(width: 8),
              Text(
                "Invalid Value",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );

    _isValidationDialogOpen = false;
  }

  void _validateBilledAgainstUnbilled({bool showSnack = false}) {
    if (_isAdjustingBilled) return;

    final int unbilled = _parseInt(unbilledCustomerctrl.text);
    final int billed = _parseInt(billedCustomerctrl.text);

    if (billed > unbilled) {
      _isAdjustingBilled = true;
      _setControllerValue(billedCustomerctrl, unbilled.toString());
      _isAdjustingBilled = false;

      if (showSnack && mounted) {
        _showValidationPopup(
          "Billed customer cannot be greater than unbilled customer",
        );
      }
    }
  }

  void _validateConversionAgainstNewCustomer({bool showSnack = false}) {
    if (_isAdjustingConversion) return;

    final int newCustomer = _parseInt(newCustomerctrl.text);
    final int newConversion = _parseInt(newConvertionctrl.text);

    if (newConversion > newCustomer) {
      _isAdjustingConversion = true;
      _setControllerValue(newConvertionctrl, newCustomer.toString());
      _isAdjustingConversion = false;

      if (showSnack && mounted) {
        _showValidationPopup(
          "New conversion cannot be greater than new customer",
        );
      }
    }
  }

  Future<void> _navigateBack() async {
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
    } else if (dep == "warehouse") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WarehouseDashboard()),
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

  @override
  void initState() {
    super.initState();
    teamController.text = "Loading...";
    teamLeaderController.text = "Loading...";
    loadAllocatedStatesAndStates();
    getDistricts();
    getMySalesTeam();

    unbilledCustomerctrl.addListener(() {
      _validateBilledAgainstUnbilled();
    });

    newCustomerctrl.addListener(() {
      _validateConversionAgainstNewCustomer();
    });
  }

  @override
  void dispose() {
    teamController.dispose();
    teamLeaderController.dispose();
    unbilledCustomerctrl.dispose();
    billedCustomerctrl.dispose();
    newCustomerctrl.dispose();
    newConvertionctrl.dispose();
    super.dispose();
  }

  Future<void> loadAllocatedStatesAndStates() async {
    try {
      final token = await gettokenFromPrefs();

      var profileResponse = await http.get(
        Uri.parse('$api/api/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (profileResponse.statusCode == 200) {
        final profileParsed = jsonDecode(profileResponse.body);
        List allocated = profileParsed["data"]["allocated_states"] ?? [];
        allocatedStateIds = List<int>.from(allocated);
      } else {
        return;
      }

      var stateResponse = await http.get(
        Uri.parse('$api/api/states/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (stateResponse.statusCode == 200) {
        final stateParsed = jsonDecode(stateResponse.body);
        List data = stateParsed["data"];

        List<Map<String, dynamic>> statelist = [];

        for (var item in data) {
          int stateId = item["id"];
          if (allocatedStateIds.contains(stateId)) {
            statelist.add({
              "id": stateId,
              "name": item["name"],
            });
          }
        }

        if (!mounted) return;
        setState(() {
          stat = statelist;
        });
      }
    } catch (e) {
      debugPrint("loadAllocatedStatesAndStates error: $e");
    }
  }

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
            "state_id": item["state"],
          });
        }

        if (!mounted) return;
        setState(() {
          districts = districtList;
        });
      }
    } catch (e) {
      debugPrint("getDistricts error: $e");
    }
  }

  void filterDistrictByState(int stateId) {
    List<Map<String, dynamic>> filtered =
        districts.where((d) => d["state_id"] == stateId).toList();

    setState(() {
      filteredDistricts = filtered;
      selectedDistrictId = null;
    });
  }

  Future<void> postDailySalesReport(BuildContext scaffoldContext) async {
    final token = await gettokenFromPrefs();

    if (selectedTeamId == null) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("No team assigned"),
        ),
      );
      return;
    }

    if (selectedStateId == null) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Please select state"),
        ),
      );
      return;
    }

    if (selectedDistrictId == null) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Please select district"),
        ),
      );
      return;
    }

    final int unbilled = _parseInt(unbilledCustomerctrl.text);
    final int billed = _parseInt(billedCustomerctrl.text);
    final int newCustomer = _parseInt(newCustomerctrl.text);
    final int newConversion = _parseInt(newConvertionctrl.text);

    if (billed > unbilled) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Billed customer cannot be greater than unbilled customer",
          ),
        ),
      );
      return;
    }

    if (newConversion > newCustomer) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "New conversion cannot be greater than new customer",
          ),
        ),
      );
      return;
    }

    try {
      Map<String, dynamic> body = {
        'team': selectedTeamId,
        "state": selectedStateId,
        "district": selectedDistrictId,
        "unbilled": unbilledCustomerctrl.text.trim(),
        "billed": billedCustomerctrl.text.trim(),
        "new_customers": newCustomerctrl.text.trim(),
        "new_conversions": newConvertionctrl.text.trim(),
      };

      final response = await http.post(
        Uri.parse('$api/api/sales/team/daily/report/add/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      print("Request Body: ${jsonEncode(body)}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("DSR submitted successfully"),
          ),
        );

        if (!mounted) return;
        setState(() {
          selectedStateId = null;
          selectedDistrictId = null;
          filteredDistricts = [];
          unbilledCustomerctrl.clear();
          billedCustomerctrl.clear();
          newCustomerctrl.clear();
          newConvertionctrl.clear();
        });
      } else {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Submit failed: ${response.body}"),
          ),
        );
      }
    } catch (e) {
      print("Error submitting DSR: $e");
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error: $e"),
        ),
      );
    }
  }

  Future<void> getMySalesTeam() async {
    try {
      if (mounted) {
        setState(() {
          isLoadingTeams = true;
        });
      }

      teamController.text = "Loading...";
      teamLeaderController.text = "Loading...";

      final token = await gettokenFromPrefs();
      if (token == null) {
        throw Exception("Token not found");
      }

      final response = await http.get(
        Uri.parse('$api/api/my/sales/team/memberships/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("MY SALES TEAM RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final data = parsed["data"];

        if (data != null && data is List && data.isNotEmpty) {
          final firstTeam = data[0];

          if (!mounted) return;
          setState(() {
            teamData = {
              "id": firstTeam["team_id"],
              "name": firstTeam["team_name"]?.toString() ?? "",
              "joined_at": firstTeam["joined_at"]?.toString() ?? "",
            };
            selectedTeamId = firstTeam["team_id"];
          });

          teamController.text = firstTeam["team_name"]?.toString() ?? "";
          teamLeaderController.text = "N/A";
        } else {
          if (!mounted) return;
          setState(() {
            teamData = null;
            selectedTeamId = null;
          });
          teamController.text = "No team assigned";
          teamLeaderController.text = "No team leader";
        }
      } else {
        if (!mounted) return;
        setState(() {
          teamData = null;
          selectedTeamId = null;
        });
        teamController.text = "No team assigned";
        teamLeaderController.text = "No team leader";
      }
    } catch (e) {
      debugPrint("Get my sales team error: $e");
      if (!mounted) return;
      setState(() {
        teamData = null;
        selectedTeamId = null;
      });
      teamController.text = "No team assigned";
      teamLeaderController.text = "No team leader";
    } finally {
      if (mounted) {
        setState(() {
          isLoadingTeams = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _navigateBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(242, 255, 255, 255),
        appBar: AppBar(
          title: const Text(
            "Add Daily Sales Report",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _navigateBack();
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
          child: Column(
            children: [
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.only(right: 10, top: 10, left: 10),
                child: Container(
                  width: 600,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 34, 165, 246),
                    border: Border.all(
                      color: const Color.fromARGB(255, 202, 202, 202),
                    ),
                  ),
                  child: const Column(
                    children: [
                      SizedBox(height: 10),
                      Text(
                        " DAILY SALES REPORTT",
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
              ),
              Padding(
                padding: const EdgeInsets.only(top: 25, left: 15, right: 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: const Color.fromARGB(255, 202, 202, 202),
                    ),
                  ),
                  width: 700,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 10,
                      right: 10,
                      top: 10,
                      bottom: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Team",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextFormField(
                          controller: teamController,
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: "Team",
                            hintStyle: const TextStyle(color: Colors.grey),
                            prefixIcon: const Icon(
                              Icons.groups,
                              size: 18,
                              color: Colors.grey,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "State",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<int>(
                          value: selectedStateId,
                          decoration: InputDecoration(
                            labelText: "Select State",
                            labelStyle: const TextStyle(fontSize: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: stat.map((item) {
                            return DropdownMenuItem<int>(
                              value: item["id"],
                              child: Text(item["name"]),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedStateId = value;
                            });

                            if (value != null) {
                              filterDistrictByState(value);
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "District",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<int>(
                          value: selectedDistrictId,
                          decoration: InputDecoration(
                            labelText: "Select District",
                            labelStyle: const TextStyle(fontSize: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: filteredDistricts.map((item) {
                            return DropdownMenuItem<int>(
                              value: item["id"],
                              child: Text(item["name"]),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedDistrictId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Unbilled Customer",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextFormField(
                          controller: unbilledCustomerctrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            hintText: "Enter unbilled customer",
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Billed Customer",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextFormField(
                          controller: billedCustomerctrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) {
                            _validateBilledAgainstUnbilled(showSnack: true);
                          },
                          decoration: InputDecoration(
                            hintText: "Enter Billed customer",
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "New Customer",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextFormField(
                          controller: newCustomerctrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            hintText: "Enter New customer",
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "New Convertion",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextFormField(
                          controller: newConvertionctrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) {
                            _validateConversionAgainstNewCustomer(
                              showSnack: true,
                            );
                          },
                          decoration: InputDecoration(
                            hintText: "Enter New Convertion",
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 270,
                              child: ElevatedButton(
                                onPressed: () {
                                  postDailySalesReport(context);
                                },
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                    const Color.fromARGB(255, 64, 176, 251),
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
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}