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

class BdoAddDsrReport extends StatefulWidget {
  const BdoAddDsrReport({super.key});

  @override
  State<BdoAddDsrReport> createState() => _BdoAddDsrReportState();
}

class _BdoAddDsrReportState extends State<BdoAddDsrReport> {
  // ================= LISTS =================
  List<Map<String, dynamic>> stat = [];
  List<Map<String, dynamic>> districts = [];
  List<Map<String, dynamic>> filteredDistricts = [];

  List<Map<String, dynamic>> invoices = [];
  List<Map<String, dynamic>> myOrders = [];

  List<Map<String, dynamic>> customer = [];
  List<Map<String, dynamic>> filteredProducts = [];

  List<int> allocatedStateIds = [];

  Map<String, int> stateBillCountMap = {};

  // ================= SELECTED VALUES =================
  int? selectedStateId;
  int? selectedDistrictId;
  int? selectedCustomerId;
  int? selectedInvoiceId;

  String selectedCallStatus = 'active';

  final List<Map<String, String>> callStatusOptions = const [
    {"value": "active", "label": "Active"},
    {"value": "productive", "label": "Productive"},
  ];

  // ================= CONTROLLERS =================
  final TextEditingController customerNameController = TextEditingController();

  final TextEditingController phoneController = TextEditingController();

  final TextEditingController noteController = TextEditingController();
  final TextEditingController invoiceAmountController = TextEditingController();

  Duration selectedDuration = Duration.zero;

  // ================= TOKEN =================
  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  // ================= BACK NAVIGATION =================
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
    loadAllocatedStatesAndStates();
    getDistricts();
    getInvoices();
    getMyOrders();
    getcustomer();
  }

  @override
  void dispose() {
    customerNameController.dispose();
    phoneController.dispose();
    noteController.dispose();
    invoiceAmountController.dispose();
    super.dispose();
  }

  // ================= LOAD PROFILE ALLOCATED STATES + STATES ===================
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

  // ================= GET CUSTOMERS ===================
  Future<void> getcustomer() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/staff/customers/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];
        List<Map<String, dynamic>> managerlist = [];

        for (var productData in productsData) {
          managerlist.add({
            'id': productData['id'],
            'name': productData['name'],
            'created_at': productData['created_at']
          });
        }

        if (!mounted) return;
        setState(() {
          customer = managerlist;
          filteredProducts = List.from(customer);
        });
      }
    } catch (error) {}
  }

  // ================= GET MY ORDERS ===================
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

      print("My Orders Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final List parsed = jsonDecode(response.body);

        List<Map<String, dynamic>> orderList = [];

        for (var item in parsed) {
          orderList.add({
            "id": item["id"],
            "invoice": item["invoice"]?.toString() ?? "",
            "total_amount": item["total_amount"] ?? 0,
            "manage_staff": item["manage_staff"]?.toString() ?? "",
            "manage_staff_id": item["manage_staff_id"],
            "customer_id": item["customer_id"],
            "customer_name": item["customer"]?.toString() ?? "",
          });
        }

        if (!mounted) return;
        setState(() {
          myOrders = orderList;
        });
      }
    } catch (e) {}
  }

  // ================= GET SALES ANALYSIS TABLE ===================
  Future<void> getInvoices() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/sales/analysis/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final List data = parsed["data"];

        List<Map<String, dynamic>> invoiceList = [];

        for (var item in data) {
          invoiceList.add({
            "id": item["id"],
            "invoice_no": item["invoice_no"] ?? "",
            "state_name": item["state_name"] ?? "",
            "district_name": item["district_name"] ?? "",
            "user_name": item["user_name"] ?? "",
            "customer_name": item["customer_name"] ?? "",
            "call_duration": item["call_duration"] ?? "",
            "call_status": item["call_status"] ?? "",
            "note": item["note"] ?? "",
          });
        }

        Map<String, int> tempMap = {};

        for (var inv in invoiceList) {
          String state = inv["state_name"].toString();
          if (tempMap.containsKey(state)) {
            tempMap[state] = tempMap[state]! + 1;
          } else {
            tempMap[state] = 1;
          }
        }

        if (!mounted) return;
        setState(() {
          invoices = invoiceList;
          stateBillCountMap = tempMap;
        });
      }
    } catch (e) {}
  }

  // ================= FILTER DISTRICTS BY STATE ===================
  void filterDistrictByState(int stateId) {
    List<Map<String, dynamic>> filtered =
        districts.where((d) => d["state_id"] == stateId).toList();

    setState(() {
      filteredDistricts = filtered;
      selectedDistrictId = null;
    });
  }

  // ================= FORMAT DURATION ===================
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  // ================= DURATION PICKER ===================
  Future<void> pickDuration() async {
    int tempHour = selectedDuration.inHours;
    int tempMinute = selectedDuration.inMinutes.remainder(60);
    int tempSecond = selectedDuration.inSeconds.remainder(60);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Call Duration"),
          content: SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text("HH"),
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 40,
                          perspective: 0.005,
                          diameterRatio: 1.2,
                          controller: FixedExtentScrollController(
                              initialItem: tempHour),
                          onSelectedItemChanged: (value) {
                            tempHour = value;
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 24,
                            builder: (context, index) {
                              return Center(
                                child: Text(index.toString().padLeft(2, '0')),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text("MM"),
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 40,
                          perspective: 0.005,
                          diameterRatio: 1.2,
                          controller: FixedExtentScrollController(
                            initialItem: tempMinute,
                          ),
                          onSelectedItemChanged: (value) {
                            tempMinute = value;
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 60,
                            builder: (context, index) {
                              return Center(
                                child: Text(index.toString().padLeft(2, '0')),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text("SS"),
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 40,
                          perspective: 0.005,
                          diameterRatio: 1.2,
                          controller: FixedExtentScrollController(
                            initialItem: tempSecond,
                          ),
                          onSelectedItemChanged: (value) {
                            tempSecond = value;
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 60,
                            builder: (context, index) {
                              return Center(
                                child: Text(index.toString().padLeft(2, '0')),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedDuration = Duration(
                    hours: tempHour,
                    minutes: tempMinute,
                    seconds: tempSecond,
                  );
                });
                Navigator.pop(context);
              },
              child: const Text("Done"),
            ),
          ],
        );
      },
    );
  }

  // ================= UPDATE INVOICE AMOUNT ===================
  void updateSelectedInvoiceAmount(int? invoiceId) {
    if (invoiceId == null) {
      invoiceAmountController.clear();
      return;
    }

    final selectedOrder = myOrders.firstWhere(
      (item) => item["id"] == invoiceId,
      orElse: () => {},
    );

    final amount = selectedOrder["total_amount"];
    invoiceAmountController.text = amount != null ? amount.toString() : "";
  }

  // ================= POST SALES ANALYSIS ===================
  Future<void> postDailySalesReport(BuildContext scaffoldContext) async {
    final token = await gettokenFromPrefs();

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

    if (selectedCallStatus == "active" &&
        customerNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Please enter customer name"),
        ),
      );
      return;
    }

    if ((selectedCallStatus == "active" ||
            selectedCallStatus == "productive") &&
        phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Please enter phone number"),
        ),
      );
      return;
    }

    if (selectedCallStatus == "productive" && selectedCustomerId == null) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Please select customer"),
        ),
      );
      return;
    }

    if (selectedCallStatus == "productive" && selectedInvoiceId == null) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Please select invoice"),
        ),
      );
      return;
    }

    if (selectedDuration == Duration.zero) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Please choose call duration"),
        ),
      );
      return;
    }

    try {
      Map<String, dynamic> body = {
        "state": selectedStateId,
        "district": selectedDistrictId,
        "call_status": selectedCallStatus,
        "call_duration": formatDuration(selectedDuration),
        "note": noteController.text.trim(),
        "phone": phoneController.text.trim(),
      };

      if (selectedCallStatus == "active") {
        body["customer_name"] = customerNameController.text.trim();
        body["phone"] = phoneController.text.trim();
      }

      if (selectedCallStatus == "productive") {
        final selectedCustomer = customer.firstWhere(
          (item) => item["id"] == selectedCustomerId,
          orElse: () => {},
        );

        body["customer"] = selectedCustomerId;
        body["customer_name"] = selectedCustomer["name"] ?? "";
        body["invoice"] = selectedInvoiceId;
        body["phone"] = phoneController.text.trim();
      }

      final response = await http.post(
        Uri.parse('$api/api/sales/analysis/add/'),
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

        await getInvoices();

        if (!mounted) return;
        setState(() {
          selectedStateId = null;
          selectedDistrictId = null;
          selectedCustomerId = null;
          selectedInvoiceId = null;
          selectedCallStatus = "active";

          selectedDuration = Duration.zero;
          filteredDistricts = [];
          customerNameController.clear();
          noteController.clear();
          invoiceAmountController.clear();
          phoneController.clear();
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

  // ================= DELETE ===================
  Future<void> deleteSubmittedInvoice(int id) async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.delete(
        Uri.parse('$api/api/sales/analysis/update/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("Invoice deleted successfully"),
          ),
        );

        await getInvoices();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Delete failed: ${response.body}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
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
                        " DAILY SALES REPORT",
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
                          "Call Status",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<String>(
                          value: selectedCallStatus,
                          decoration: InputDecoration(
                            labelText: "Select Call Status",
                            labelStyle: const TextStyle(fontSize: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: callStatusOptions.map((item) {
                            return DropdownMenuItem<String>(
                              value: item["value"],
                              child: Text(item["label"]!),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCallStatus = value ?? "active";
                              selectedCustomerId = null;
                              selectedInvoiceId = null;
                              customerNameController.clear();
                              invoiceAmountController.clear();
                              phoneController.clear();
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        if (selectedCallStatus == "active") ...[
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
                        ],
                        if (selectedCallStatus == "active") ...[
                          const Text(
                            "Phone",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: phoneController,
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
                        if (selectedCallStatus == "productive") ...[
                          const Text(
                            "Customer",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          DropdownButtonFormField<int>(
                            value: selectedCustomerId,
                            decoration: InputDecoration(
                              labelText: "Select Customer",
                              labelStyle: const TextStyle(fontSize: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: filteredProducts.map((item) {
                              return DropdownMenuItem<int>(
                                value: item["id"],
                                child: Text(
                                  item["name"],
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedCustomerId = value;
                                selectedInvoiceId = null;
                                invoiceAmountController.clear();
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Phone",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: "Enter phone number",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
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
                                child: Text(
                                  "${item["invoice"]} - ${item["customer_name"]}",
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedInvoiceId = value;
                                updateSelectedInvoiceAmount(value);

                                final selectedOrder = myOrders.firstWhere(
                                  (item) => item["id"] == value,
                                  orElse: () => {},
                                );

                                if (selectedOrder.isNotEmpty) {
                                  selectedCustomerId =
                                      selectedOrder["customer_id"];
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Invoice Amount",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: invoiceAmountController,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: "Invoice amount",
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
                          onTap: pickDuration,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 15,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              selectedDuration == Duration.zero
                                  ? "Choose duration (hh:mm:ss)"
                                  : formatDuration(selectedDuration),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Note",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextFormField(
                          controller: noteController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: "Enter note",
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
