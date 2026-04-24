import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:beposoft/pages/api.dart';

class AddDailySalesReport extends StatefulWidget {
  const AddDailySalesReport({super.key});

  @override
  State<AddDailySalesReport> createState() => _AddDailySalesReportState();
}

class _AddDailySalesReportState extends State<AddDailySalesReport> {
  // ================= LISTS =================
  List<Map<String, dynamic>> stat = [];
  List<Map<String, dynamic>> districts = [];
  List<Map<String, dynamic>> filteredDistricts = [];
// popup invoice list (my orders)
  List<Map<String, dynamic>> myOrders = [];

// submitted report list (daily sales report)
  List<Map<String, dynamic>> invoices = [];

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

  @override
  void initState() {
    super.initState();
    getstate();
    getDistricts();
    getInvoices();
    getDailySalesReports();
    getMyOrders();
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

      // print("========== MY ORDERS STATUS: ${response.statusCode}");
      // print("========== MY ORDERS BODY: ${response.body}");

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

        // print("========== MY ORDERS LIST: $invoices");
      } else {
        // print("========== FAILED TO FETCH MY ORDERS");
      }
    } catch (e) {
      // print("========== MY ORDERS ERROR: $e");
    }
  }

  // ================= GET STATES ===================
  Future<void> getstate() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/states/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // print("========== STATES STATUS: ${response.statusCode}");
      // print("========== STATES BODY: ${response.body}");

      List<Map<String, dynamic>> statelist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var data = parsed['data'];

        for (var item in data) {
          statelist.add({
            'id': item['id'],
            'name': item['name'],
          });
        }

        setState(() {
          stat = statelist;
        });

        // print("========== STATES LIST: $stat");
      }
    } catch (error) {
      // print("STATE ERROR: $error");
    }
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

      // print("========== DISTRICTS STATUS: ${response.statusCode}");
      // print("========== DISTRICTS BODY: ${response.body}");

      List<Map<String, dynamic>> districtList = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var data = parsed['data'];

        for (var item in data) {
          districtList.add({
            "id": item["id"],
            "name": item["name"],
            "state_name": item["state_name"],

            // IMPORTANT FIX: convert to int
            "state_id": item["state"],
          });
        }
        if (!mounted) return;
        setState(() {
          districts = districtList;
        });

        // print("========== DISTRICT LIST: $districts");
      }
    } catch (e) {
      // print("DISTRICT ERROR: $e");
    }
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

      // print("========== INVOICE STATUS: ${response.statusCode}");
      // print("========== INVOICE BODY: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final List data = parsed["data"];

        List<Map<String, dynamic>> invoiceList = [];

        for (var item in data) {
          invoiceList.add({
            "id": item["id"],
            "invoice_no": item["invoice_no"],
            "state_name": item["state_name"],
            "district_name": item["district_name"],
            "user_name": item["user_name"],
          });
        }

        if (!mounted) return;

        setState(() {
          invoices = invoiceList;
        });

        // print("========== DAILY REPORT INVOICE LIST: $invoices");
      }
    } catch (e) {
      // print("INVOICE ERROR: $e");
    }
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Invoices"),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: double.maxFinite,
                height: 350,
               child: ListView.builder(
  itemCount: myOrders.length,
  itemBuilder: (context, index) {
    final invoiceItem = myOrders[index];

    bool isSelected =
        localSelected.any((e) => e["id"] == invoiceItem["id"]);

    return CheckboxListTile(
      title: Text(invoiceItem["invoice"]),
      subtitle: Text(invoiceItem["manage_staff"] ?? ""),
      value: isSelected,
      onChanged: (val) {
        if (val == true) {
          localSelected.add(invoiceItem);
        } else {
          localSelected.removeWhere((e) => e["id"] == invoiceItem["id"]);
        }
        setStateDialog(() {});
      },
    );
  },
),

              );
            },
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  tempSelectedInvoices = localSelected;
                });

                // print(
                //     "========== FINAL TEMP INVOICES AFTER DONE: $tempSelectedInvoices");

                Navigator.pop(context);
              },
              child: const Text("Done"),
            ),
          ],
        );
      },
    );
  }

  // ================= POST DAILY SALES REPORT ===================
  Future<void> postDailySalesReport(BuildContext scaffoldContext) async {
    final token = await gettokenFromPrefs();

    // print("========== SUBMIT CLICKED");
    // print("========== STATE ID: $selectedStateId");
    // print("========== DISTRICT ID: $selectedDistrictId");
    // print("========== TEMP INVOICES: $tempSelectedInvoices");

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

      // loop selected invoices and post one by one
      for (var invoiceItem in tempSelectedInvoices) {
        int invoiceId = invoiceItem["id"];

        // print("========== POSTING INVOICE ID: $invoiceId");

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

        // print("========== POST STATUS: ${response.statusCode}");
        // print("========== POST BODY: ${response.body}");

        if (response.statusCode == 201 || response.statusCode == 200) {
          successCount++;
        } else {
          failCount++;
        }
      }
      await getInvoices();


      // after all invoices posted
      if (successCount > 0) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
                "$successCount invoices submitted successfully. Failed: $failCount"),
          ),
        );

        if (!mounted) return;

        setState(() {
          // reset form only
          selectedStateId = null;
          selectedDistrictId = null;
          tempSelectedInvoices = [];
          filteredDistricts = [];
        });

        // print("========== SUBMITTED INVOICES TABLE: $submittedInvoices");
      } else {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("All invoices failed. Failed: $failCount"),
          ),
        );
      }
    } catch (e) {
      // print("========== POST ERROR: $e");

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

      // print("========== DAILY SALES REPORT STATUS: ${response.statusCode}");
      // print("========== DAILY SALES REPORT BODY: ${response.body}");

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

        // print("========== DAILY SALES REPORT LIST: $submittedInvoices");
      } else {
        // print("========== FAILED TO FETCH REPORTS");
      }
    } catch (e) {
      // print("========== DAILY SALES REPORT ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(242, 255, 255, 255),
      appBar: AppBar(
        title: const Text(
          "Add Daily Sales Report",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

            // ================= TABLE ONLY AFTER SUBMIT =================
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: const [
                  Text(
                    "Submitted Invoices",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

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
                              child: Text(
                                invoices[i]['state_name'].toString(),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                invoices[i]['district_name']
                                    .toString(),
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
    );
  }
}
