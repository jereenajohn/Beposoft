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

class BdoAddDailySalesReport extends StatefulWidget {
  const BdoAddDailySalesReport({super.key});

  @override
  State<BdoAddDailySalesReport> createState() => _BdoAddDailySalesReportState();
}

class _BdoAddDailySalesReportState extends State<BdoAddDailySalesReport> {
  // ================= LISTS =================
  List<Map<String, dynamic>> stat = [];
  List<Map<String, dynamic>> districts = [];
  List<Map<String, dynamic>> filteredDistricts = [];

  // State wise total bills map
  Map<String, int> stateBillCountMap = {};

  // popup invoice list (my orders)
  List<Map<String, dynamic>> myOrders = [];

  // submitted report list (daily sales report)
  List<Map<String, dynamic>> invoices = [];

  // allocated states from profile
  List<int> allocatedStateIds = [];

  // ================= SELECTED VALUES =================
  int? selectedStateId;
  int? selectedDistrictId;

  // TEMP invoices (selected in popup)
  List<Map<String, dynamic>> tempSelectedInvoices = [];

  // FINAL invoices (after submit only show)
  List<Map<String, dynamic>> submittedInvoices = [];

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
    getDailySalesReports();
    getMyOrders();
  }

  // ================= LOAD PROFILE ALLOCATED STATES + STATES ===================
  Future<void> loadAllocatedStatesAndStates() async {
    try {
      final token = await gettokenFromPrefs();

      // =================== 1) FETCH PROFILE ===================
      var profileResponse = await http.get(
        Uri.parse('$api/api/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (profileResponse.statusCode == 200) {
        final profileParsed = jsonDecode(profileResponse.body);

        // allocated_states from profile
        List allocated = profileParsed["data"]["allocated_states"] ?? [];

        allocatedStateIds = List<int>.from(allocated);
      } else {
        return;
      }

      // =================== 2) FETCH ALL STATES ===================
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

          // only include allocated states
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

      if (response.statusCode == 200) {
        final List parsed = jsonDecode(response.body);

        List<Map<String, dynamic>> orderList = [];

        for (var item in parsed) {
          orderList.add({
            "id": item["id"],
            "invoice": item["invoice"],
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

  // ================= GET INVOICES ===================
  Future<void> getInvoices() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/daily/sales/report/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final List data = parsed["data"];

        List<Map<String, dynamic>> invoiceList = [];

        // ===== FIRST ADD ALL INVOICES =====
        for (var item in data) {
          invoiceList.add({
            "id": item["id"],
            "invoice_no": item["invoice_no"],
            "state_name": item["state_name"],
            "district_name": item["district_name"],
            "user_name": item["user_name"],
          });
        }

        // ===== NOW CALCULATE STATE BILL COUNT =====
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

  // ================= MULTI SELECT INVOICE POPUP ===================
  void openInvoiceMultiSelect() {
    List<Map<String, dynamic>> localSelected =
        List<Map<String, dynamic>>.from(tempSelectedInvoices);

    List<Map<String, dynamic>> filteredOrders =
        List<Map<String, dynamic>>.from(myOrders);

    TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            void filterInvoices(String query) {
              if (query.isEmpty) {
                filteredOrders = List<Map<String, dynamic>>.from(myOrders);
              } else {
                filteredOrders = myOrders.where((item) {
                  String invoice =
                      (item["invoice"] ?? "").toString().toLowerCase();
                  String staff =
                      (item["manage_staff"] ?? "").toString().toLowerCase();

                  return invoice.contains(query.toLowerCase()) ||
                      staff.contains(query.toLowerCase());
                }).toList();
              }
              setStateDialog(() {});
            }

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                width: double.maxFinite,
                height: 520,
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    // ================= HEADER =================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Select Invoices",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        )
                      ],
                    ),

                    const SizedBox(height: 8),

                    // ================= SELECTED COUNT =================
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Selected: ${localSelected.length}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ================= SEARCH FIELD =================
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "Search Invoice / Staff...",
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  searchController.clear();
                                  filterInvoices("");
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(255, 64, 176, 251),
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (val) {
                        filterInvoices(val);
                      },
                    ),

                    const SizedBox(height: 12),

                    // ================= INVOICE LIST =================
                    Expanded(
                      child: filteredOrders.isEmpty
                          ? const Center(
                              child: Text(
                                "No invoices found",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredOrders.length,
                              itemBuilder: (context, index) {
                                final invoiceItem = filteredOrders[index];

                                bool isSelected = localSelected
                                    .any((e) => e["id"] == invoiceItem["id"]);

                                return Card(
                                  elevation: 2,
                                  color: Colors.white,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: CheckboxListTile(
                                    activeColor:
                                        const Color.fromARGB(255, 64, 176, 251),
                                    title: Text(
                                      invoiceItem["invoice"] ?? "",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      invoiceItem["manage_staff"] ?? "",
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    value: isSelected,
                                    onChanged: (val) {
                                      if (val == true) {
                                        localSelected.add(invoiceItem);
                                      } else {
                                        localSelected.removeWhere((e) =>
                                            e["id"] == invoiceItem["id"]);
                                      }

                                      setStateDialog(() {});
                                    },
                                  ),
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: 12),

                    // ================= BUTTONS =================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            localSelected.clear();
                            setStateDialog(() {});
                          },
                          icon: const Icon(Icons.clear, color: Colors.white),
                          label: const Text(
                            "Clear",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              tempSelectedInvoices = localSelected;
                            });

                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text(
                            "Done",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 64, 176, 251),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================= POST DAILY SALES REPORT ===================
  Future<void> postDailySalesReport(BuildContext scaffoldContext) async {
    final token = await gettokenFromPrefs();

    if (selectedStateId == null ||
        selectedDistrictId == null ||
        tempSelectedInvoices.isEmpty) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Please select State, District and Invoice"),
        ),
      );
      return;
    }

    try {
      int successCount = 0;
      int failCount = 0;
      int alreadyAddedCount = 0;

      for (var invoiceItem in tempSelectedInvoices) {
        int invoiceId = invoiceItem["id"];
        String invoiceNumber = invoiceItem["invoice"].toString();

        // ================= CHECK IF INVOICE ALREADY ADDED =================
        bool alreadyExists = invoices
            .any((inv) => inv["invoice_no"].toString() == invoiceNumber);

        if (alreadyExists) {
          alreadyAddedCount++;

          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
            SnackBar(
              backgroundColor: Colors.orange,
              content: Text("Invoice $invoiceNumber already added!"),
            ),
          );

          continue; // skip this invoice
        }

        final response = await http.post(
          Uri.parse('$api/api/daily/sales/report/add/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            "state": selectedStateId,
            "district": selectedDistrictId,
            "invoice": invoiceId,
          }),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          successCount++;
        } else {
          failCount++;
        }
      }

      await getInvoices();

      if (successCount > 0) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              "$successCount invoices submitted successfully. Already Added: $alreadyAddedCount, Failed: $failCount",
            ),
          ),
        );

        if (!mounted) return;

        setState(() {
          selectedStateId = null;
          selectedDistrictId = null;
          tempSelectedInvoices = [];
          filteredDistricts = [];
        });
      } else {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              "No new invoice submitted. Already Added: $alreadyAddedCount, Failed: $failCount",
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error: $e"),
        ),
      );
    }
  }

  Future<void> getDailySalesReports() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/daily/sales/report/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List<Map<String, dynamic>> reportList = [];

        for (var item in parsed["data"]) {
          reportList.add({
            "id": item["id"],
            "user_name": item["user_name"],
            "state_name": item["state_name"],
            "district_name": item["district_name"],
            "invoice_no": item["invoice_no"],
            "count": item["count"],
            "created_at": item["created_at"],
            "updated_at": item["updated_at"],
            "user": item["user"],
            "state": item["state"],
            "district": item["district"],
            "invoice": item["invoice"],
          });
        }

        if (!mounted) return;

        setState(() {
          submittedInvoices = reportList;
        });
      }
    } catch (e) {}
  }

  Future<void> deleteSubmittedInvoice(int id) async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.delete(
        Uri.parse('$api/api/daily/sales/report/update/$id/'),
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

        await getInvoices(); // refresh table
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

              // ================= HEADER =================
              Padding(
                padding: const EdgeInsets.only(right: 10, top: 10, left: 10),
                child: Container(
                  width: 600,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 34, 165, 246),
                    border: Border.all(
                        color: const Color.fromARGB(255, 202, 202, 202)),
                  ),
                  child: const Column(
                    children: [
                      SizedBox(height: 10),
                      Text(
                        " DAILY SALES REPORT ",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      SizedBox(height: 13),
                    ],
                  ),
                ),
              ),

              // ================= FORM CARD =================
              Padding(
                padding: const EdgeInsets.only(top: 25, left: 15, right: 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                        color: const Color.fromARGB(255, 202, 202, 202)),
                  ),
                  width: 700,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        // ================= STATE =================
                        const Text(
                          "State",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: DropdownButtonFormField<int>(
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
                        ),

                        const SizedBox(height: 10),

                        // ================= DISTRICT =================
                        const Text(
                          "District",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: DropdownButtonFormField<int>(
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
                        ),

                        const SizedBox(height: 10),

                        // ================= INVOICE MULTI SELECT =================
                        const Text(
                          "Invoices",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: openInvoiceMultiSelect,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 15),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      tempSelectedInvoices.isEmpty
                                          ? "Select Invoices"
                                          : tempSelectedInvoices
                                              .map((e) => e["invoice"])
                                              .join(", "),
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        // ================= SUBMIT BUTTON =================
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
                                child: const Text("Submit",
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ================= TABLE =================
              Padding(
                padding: const EdgeInsets.only(right: 15, left: 15, bottom: 55),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    color: Colors.white,
                    child: Table(
                      border: TableBorder.all(
                          color: const Color.fromARGB(255, 214, 213, 213)),
                      defaultColumnWidth: const FixedColumnWidth(180),
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
                                "Invoice No",
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
                                "User",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                "Action",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        for (int i = 0; i < invoices.length; i++)
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text((i + 1).toString()),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  invoices[i]['invoice_no'].toString(),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      invoices[i]['state_name'].toString(),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      "Total Bills: ${stateBillCountMap[invoices[i]['state_name'].toString()] ?? 0}",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  invoices[i]['district_name'].toString(),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  invoices[i]['user_name'].toString(),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () {
                                    int id = invoices[i]["id"];
                                    deleteSubmittedInvoice(id);
                                  },
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
