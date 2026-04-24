import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:beposoft/pages/api.dart';

import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';

class BdoCallDuration extends StatefulWidget {
  const BdoCallDuration({super.key});

  @override
  State<BdoCallDuration> createState() => _BdoCallDurationState();
}

class _BdoCallDurationState extends State<BdoCallDuration> {
  List<Map<String, dynamic>> stat = [];
  List<Map<String, dynamic>> districts = [];
  List<Map<String, dynamic>> filteredDistricts = [];
  List<Map<String, dynamic>> myOrders = [];
  bool isLoadingTeams = false;
  Map<String, dynamic>? teamData;

  String? selectedCallType;

  final TextEditingController teamController = TextEditingController();
  final TextEditingController teamLeaderController = TextEditingController();
  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController customerPhoneController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  List<Map<String, dynamic>> customer = [];
  List<Map<String, dynamic>> filteredProducts = [];

  List<int> allocatedStateIds = [];

  Map<String, int> stateBillCountMap = {};

  int? selectedStateId;
  int? selectedDistrictId;
  int? selectedTeamId;
  int? selectedInvoiceId;

  final TextEditingController unbilledCustomerctrl = TextEditingController();
  final TextEditingController billedCustomerctrl = TextEditingController();
  final TextEditingController newCustomerctrl = TextEditingController();
  final TextEditingController newConvertionctrl = TextEditingController();

  Duration selectedDuration = Duration.zero;

  Future<void> _selectDuration(BuildContext context) async {
    int tempHours = selectedDuration.inHours;
    int tempMinutes = selectedDuration.inMinutes.remainder(60);
    int tempSeconds = selectedDuration.inSeconds.remainder(60);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.timer_outlined, color: Colors.blue, size: 24),
                  SizedBox(width: 8),
                  Text(
                    "Select Call Duration",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 180,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Hours",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 120,
                                  child: ListWheelScrollView.useDelegate(
                                    itemExtent: 40,
                                    onSelectedItemChanged: (index) {
                                      setStateDialog(() {
                                        tempHours = index;
                                      });
                                    },
                                    childDelegate:
                                        ListWheelChildBuilderDelegate(
                                      childCount: 24,
                                      builder: (context, index) {
                                        return Container(
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: tempHours == index
                                                ? Colors.blue.shade100
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            index.toString().padLeft(2, '0'),
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: tempHours == index
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: tempHours == index
                                                  ? Colors.blue.shade700
                                                  : Colors.black,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            ":",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Minutes",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 120,
                                  child: ListWheelScrollView.useDelegate(
                                    itemExtent: 40,
                                    onSelectedItemChanged: (index) {
                                      setStateDialog(() {
                                        tempMinutes = index;
                                      });
                                    },
                                    childDelegate:
                                        ListWheelChildBuilderDelegate(
                                      childCount: 60,
                                      builder: (context, index) {
                                        return Container(
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: tempMinutes == index
                                                ? Colors.blue.shade100
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            index.toString().padLeft(2, '0'),
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: tempMinutes == index
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: tempMinutes == index
                                                  ? Colors.blue.shade700
                                                  : Colors.black,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            ":",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Seconds",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 120,
                                  child: ListWheelScrollView.useDelegate(
                                    itemExtent: 40,
                                    onSelectedItemChanged: (index) {
                                      setStateDialog(() {
                                        tempSeconds = index;
                                      });
                                    },
                                    childDelegate:
                                        ListWheelChildBuilderDelegate(
                                      childCount: 60,
                                      builder: (context, index) {
                                        return Container(
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: tempSeconds == index
                                                ? Colors.blue.shade100
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            index.toString().padLeft(2, '0'),
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: tempSeconds == index
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: tempSeconds == index
                                                  ? Colors.blue.shade700
                                                  : Colors.black,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${tempHours.toString().padLeft(2, '0')}:${tempMinutes.toString().padLeft(2, '0')}:${tempSeconds.toString().padLeft(2, '0')}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedDuration = Duration(
                        hours: tempHours,
                        minutes: tempMinutes,
                        seconds: tempSeconds,
                      );
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text(
                    "Apply",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> getMyOrders() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/my/orders/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List parsed = jsonDecode(response.body);

        List<Map<String, dynamic>> orderList = [];

        for (var item in parsed) {
          orderList.add({
            "id": item["id"],
            "invoice": item["invoice"],
            "total_amount": item["total_amount"],
            "manage_staff": item["manage_staff"],
            "manage_staff_id": item["manage_staff_id"],
          });
        }

        if (!mounted) return;

        setState(() {
          myOrders = orderList;
        });
      }
    } catch (e) {}
  }

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
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
    getMyOrders();
    getMySalesTeam();
  }

  @override
  void dispose() {
    teamController.dispose();
    teamLeaderController.dispose();
    unbilledCustomerctrl.dispose();
    billedCustomerctrl.dispose();
    newCustomerctrl.dispose();
    newConvertionctrl.dispose();
    customerNameController.dispose();
    customerPhoneController.dispose();
    noteController.dispose();
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
    } catch (e) {}
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
    } catch (e) {}
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

    if (selectedCallType == null) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Please select call type (ACTIVE or PRODUCTIVE)"),
        ),
      );
      return;
    }

    if (selectedCallType == 'PRODUCTIVE' && selectedInvoiceId == null) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Please select invoice"),
        ),
      );
      return;
    }

    if (selectedCallType == 'ACTIVE') {
      if (customerNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("Please enter customer name"),
          ),
        );
        return;
      }
      if (customerPhoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("Please enter phone number"),
          ),
        );
        return;
      }
    }

    if (selectedCallType == 'PRODUCTIVE') {
      if (customerPhoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("Please enter phone number"),
          ),
        );
        return;
      }
    }

    if (selectedDuration.inSeconds == 0) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Please select call duration"),
        ),
      );
      return;
    }

    try {
      String formattedDuration =
          "${selectedDuration.inHours.toString().padLeft(2, '0')}:"
          "${selectedDuration.inMinutes.remainder(60).toString().padLeft(2, '0')}:"
          "${selectedDuration.inSeconds.remainder(60).toString().padLeft(2, '0')}";

      Map<String, dynamic> body = {
        "team": selectedTeamId,
        "state": selectedStateId,
        "district": selectedDistrictId,
        "call_status": selectedCallType?.toLowerCase(),
        "call_duration": formattedDuration,
        "note": noteController.text.trim(),
        "phone": customerPhoneController.text.trim(),
      };

      if (selectedCallType == 'PRODUCTIVE') {
        body["invoice"] = selectedInvoiceId;
      } else if (selectedCallType == 'ACTIVE') {
        body["customer_name"] = customerNameController.text.trim();
      }

      print("Request Body: ${jsonEncode(body)}");

      final response = await http.post(
        Uri.parse('$api/api/sales/team/member/daily/report/add/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("Daily call report submitted successfully"),
          ),
        );

        if (!mounted) return;

        setState(() {
          selectedStateId = null;
          selectedDistrictId = null;
          selectedCallType = null;
          selectedInvoiceId = null;
          selectedDuration = Duration.zero;
          filteredDistricts = [];
          customerNameController.clear();
          customerPhoneController.clear();
          noteController.clear();
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
      print("Error submitting report: $e");
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error: $e"),
        ),
      );
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
            "Add Daily Call Duration Report",
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
                        " DAILY CALL DURATION REPORT",
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
                        // const Text(
                        //   "Team Leader",
                        //   style: TextStyle(
                        //     fontSize: 12,
                        //     fontWeight: FontWeight.bold,
                        //   ),
                        // ),
                        // const SizedBox(height: 5),
                        // TextFormField(
                        //   controller: teamLeaderController,
                        //   readOnly: true,
                        //   decoration: InputDecoration(
                        //     hintText: "Team Leader",
                        //     hintStyle: const TextStyle(color: Colors.grey),
                        //     prefixIcon: const Icon(
                        //       Icons.person,
                        //       size: 18,
                        //       color: Colors.grey,
                        //     ),
                        //     border: OutlineInputBorder(
                        //       borderRadius: BorderRadius.circular(10),
                        //     ),
                        //     contentPadding: const EdgeInsets.symmetric(
                        //       horizontal: 12,
                        //       vertical: 16,
                        //     ),
                        //   ),
                        //   style: const TextStyle(
                        //     fontSize: 15,
                        //     fontWeight: FontWeight.bold,
                        //   ),
                        // ),
                        // const SizedBox(height: 10),
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
                          "Call Type",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedCallType = 'ACTIVE';
                                    selectedInvoiceId = null;
                                    customerNameController.clear();
                                    customerPhoneController.clear();
                                  });
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: selectedCallType == 'ACTIVE'
                                        ? Colors.blue.shade100
                                        : Colors.grey.shade50,
                                    border: Border.all(
                                      color: selectedCallType == 'ACTIVE'
                                          ? Colors.blue
                                          : Colors.grey.shade300,
                                      width:
                                          selectedCallType == 'ACTIVE' ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "ACTIVE",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: selectedCallType == 'ACTIVE'
                                            ? Colors.blue.shade700
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedCallType = 'PRODUCTIVE';
                                    customerNameController.clear();
                                    customerPhoneController.clear();
                                  });
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: selectedCallType == 'PRODUCTIVE'
                                        ? Colors.green.shade100
                                        : Colors.grey.shade50,
                                    border: Border.all(
                                      color: selectedCallType == 'PRODUCTIVE'
                                          ? Colors.green
                                          : Colors.grey.shade300,
                                      width: selectedCallType == 'PRODUCTIVE'
                                          ? 2
                                          : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "PRODUCTIVE",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: selectedCallType == 'PRODUCTIVE'
                                            ? Colors.green.shade700
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (selectedCallType == 'PRODUCTIVE') ...[
                          const Text(
                            "Invoice",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          DropdownButtonFormField<int>(
                            value: selectedInvoiceId,
                            decoration: InputDecoration(
                              labelText: "Select Invoice",
                              labelStyle: const TextStyle(fontSize: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: myOrders.map((item) {
                              return DropdownMenuItem<int>(
                                value: item["id"],
                                child: Row(
                                  children: [
                                    Text(
                                      item["invoice"],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "₹${item["total_amount"]?.toString() ?? "0"}",
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedInvoiceId = value;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Phone Number",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: customerPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: "Enter phone number",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (selectedCallType == 'ACTIVE') ...[
                          const Text(
                            "Customer Name",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: customerNameController,
                            decoration: InputDecoration(
                              hintText: "Enter customer name",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Phone Number",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: customerPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: "Enter phone number",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        const Text(
                          "Call Duration",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        GestureDetector(
                          onTap: () => _selectDuration(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color.fromARGB(255, 202, 202, 202),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.timer,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    selectedDuration.inHours > 0 ||
                                            selectedDuration.inMinutes > 0 ||
                                            selectedDuration.inSeconds > 0
                                        ? '${selectedDuration.inHours}h ${selectedDuration.inMinutes.remainder(60)}m ${selectedDuration.inSeconds.remainder(60)}s'
                                        : 'Select call duration',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: selectedDuration.inHours > 0 ||
                                              selectedDuration.inMinutes > 0 ||
                                              selectedDuration.inSeconds > 0
                                          ? Colors.black
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const SizedBox(height: 10),
                        const Text(
                          "Note (Optional)",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextFormField(
                          controller: noteController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: "Enter any additional notes...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
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