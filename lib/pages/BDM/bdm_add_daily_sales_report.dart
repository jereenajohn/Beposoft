import 'dart:convert';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:beposoft/pages/api.dart';
import 'package:dropdown_search/dropdown_search.dart';

class AddBDMBDOReportPage extends StatefulWidget {
  const AddBDMBDOReportPage({super.key});

  @override
  State<AddBDMBDOReportPage> createState() => _AddBDMBDOReportPageState();
}

class _AddBDMBDOReportPageState extends State<AddBDMBDOReportPage> {
  // ================= LOGGED IN BDM =================
  int? loggedInBDMId;
  String? loggedInBDMName;

  // ================= SELECTED VALUES =================
  int? selectedBDOId;
  int? selectedInvoiceId;
  int? selectedStateId;

  String selectedNewCoach = "no";
  String selectedMicroDealer = "no";

  // ================= LISTS =================
  List<Map<String, dynamic>> bdoList = [];
  List<Map<String, dynamic>> invoiceList = [];
  List<Map<String, dynamic>> stateList = [];

  // ================= TEXTFIELDS =================
  TextEditingController noteController = TextEditingController();
  TextEditingController callDurationController = TextEditingController();
  TextEditingController averageController = TextEditingController();

  // ================= LOADING =================
  bool loading = false;
  bool bdoLoading = true;
  bool invoiceLoading = false;
  bool stateLoading = true;
  bool profileLoading = true;

  // ================= TOKEN =================
  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> initData() async {
    await getProfile();
    await getStates();
    await getBDOUnderLoggedInBDM();
  }

  // ================= GET PROFILE =================
  Future<void> getProfile() async {
    try {
      setState(() {
        profileLoading = true;
      });

      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse("$api/api/profile/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("=========== PROFILE API STATUS CODE ===========");
      print(response.statusCode);

      print("=========== PROFILE API BODY ===========");
      print(response.body);

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        int userId = int.tryParse((parsed["data"]["id"] ?? 0).toString()) ?? 0;
        String userName = (parsed["data"]["name"] ?? "").toString();

        print("=========== LOGGED IN BDM ID ===========");
        print(userId);

        print("=========== LOGGED IN BDM NAME ===========");
        print(userName);

        if (!mounted) return;

        setState(() {
          loggedInBDMId = userId;
          loggedInBDMName = userName;
        });
      }
    } catch (e) {
      print("=========== PROFILE ERROR ===========");
      print(e);
    }

    if (!mounted) return;

    setState(() {
      profileLoading = false;
    });
  }

  // ================= GET STATES =================
  Future<void> getStates() async {
    try {
      setState(() {
        stateLoading = true;
      });

      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse("$api/api/states/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("=========== STATES API STATUS CODE ===========");
      print(response.statusCode);

      print("=========== STATES API BODY ===========");
      print(response.body);

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var data = parsed["data"];

        List<Map<String, dynamic>> states = [];

        for (var st in data) {
          states.add({
            "id": st["id"],
            "name": st["name"],
          });
        }

        states.sort(
            (a, b) => a["name"].toString().compareTo(b["name"].toString()));

        print("=========== FINAL STATES LIST ===========");
        print(states);

        if (!mounted) return;

        setState(() {
          stateList = states;
        });
      }
    } catch (e) {
      print("=========== STATES ERROR ===========");
      print(e);
    }

    if (!mounted) return;

    setState(() {
      stateLoading = false;
    });
  }

  // ================= GET BDO LIST USING supervisor_name =================
  Future<void> getBDOUnderLoggedInBDM() async {
    try {
      setState(() {
        bdoLoading = true;
      });

      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse("$api/api/staffs/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("=========== STAFF API STATUS CODE ===========");
      print(response.statusCode);

      print("=========== STAFF API BODY ===========");
      print(response.body);

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        List staffData = List.from(parsed["data"] ?? []);

        List<Map<String, dynamic>> filteredBDO = [];

        for (var staff in staffData) {
          String department = (staff["department_name"] ?? "").toString();
          String supervisorName = (staff["supervisor_name"] ?? "").toString();

          if (department == "BDO" &&
              supervisorName.trim().toLowerCase() ==
                  loggedInBDMName.toString().trim().toLowerCase()) {
            filteredBDO.add({
              "id": staff["id"],
              "name": staff["name"],
              "email": staff["email"],
              "phone": staff["phone"],
            });
          }
        }

        filteredBDO.sort(
            (a, b) => a["name"].toString().compareTo(b["name"].toString()));

        print("=========== FINAL BDO LIST ===========");
        print(filteredBDO);

        if (!mounted) return;

        setState(() {
          bdoList = filteredBDO;
        });
      }
    } catch (e) {
      print("=========== STAFF ERROR ===========");
      print(e);
    }

    if (!mounted) return;

    setState(() {
      bdoLoading = false;
    });
  }

  // ================= FETCH INVOICES BASED ON SELECTED BDO =================
  Future<void> getInvoicesByBDO(int bdoId) async {
    try {
      setState(() {
        invoiceLoading = true;
        invoiceList = [];
        selectedInvoiceId = null;
      });

      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse("$api/api/all/orders/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("=========== ALL ORDERS STATUS CODE ===========");
      print(response.statusCode);

      print("=========== ALL ORDERS BODY ===========");
      print(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> ordersData = jsonDecode(response.body);

        List<Map<String, dynamic>> filteredInvoices = [];

        for (var ord in ordersData) {
          int manageStaffId =
              int.tryParse((ord["manage_staff_id"] ?? 0).toString()) ?? 0;

          if (manageStaffId == bdoId) {
            filteredInvoices.add({
              "id": ord["id"],
              "invoice_no": ord["invoice"] ?? "Order#${ord["id"]}",
              "customer_name": ord["customer_name"] ?? "",
              "customer_id": ord["customer_id"] ?? 0,
              "manage_staff": ord["manage_staff"] ?? "",
              "manage_staff_id": ord["manage_staff_id"] ?? 0,
            });
          }
        }

        filteredInvoices.sort((a, b) =>
            a["invoice_no"].toString().compareTo(b["invoice_no"].toString()));

        print("=========== FINAL FILTERED INVOICES ===========");
        print(filteredInvoices);

        if (!mounted) return;

        setState(() {
          invoiceList = filteredInvoices;
        });
      }
    } catch (e) {
      print("=========== INVOICE FETCH ERROR ===========");
      print(e);
    }

    if (!mounted) return;

    setState(() {
      invoiceLoading = false;
    });
  }

  // ================= POST FUNCTION =================
  Future<void> submitBDMBDOReport() async {
    if (selectedBDOId == null ||
        selectedInvoiceId == null ||
        selectedStateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Please select BDO, Invoice and State"),
        ),
      );
      return;
    }

    try {
      setState(() {
        loading = true;
      });

      final token = await gettokenFromPrefs();

      Map<String, dynamic> bodyData = {
        "bdo": selectedBDOId,
        "invoice": selectedInvoiceId,
        "state": selectedStateId,
        "new_coach": selectedNewCoach,
        "micro_dealer": selectedMicroDealer,
        "note": noteController.text.trim(),
        "call_duration": callDurationController.text.trim(),
        "average": averageController.text.trim(),
      };

      print("=========== POST BODY DATA ===========");
      print(jsonEncode(bodyData));

      var response = await http.post(
        Uri.parse("$api/api/monthly/sales/report/bdm/bdo/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(bodyData),
      );

      print("=========== POST STATUS CODE ===========");
      print(response.statusCode);

      print("=========== POST RESPONSE BODY ===========");
      print(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("Report Added Successfully"),
          ),
        );

        setState(() {
          selectedBDOId = null;
          selectedInvoiceId = null;
          selectedStateId = null;

          selectedNewCoach = "no";
          selectedMicroDealer = "no";

          invoiceList = [];

          noteController.clear();
          callDurationController.clear();
          averageController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Failed: ${response.body}"),
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

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(242, 255, 255, 255),
      appBar: AppBar(
        title: const Text(
          "Add BDM BDO Report",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => bdm_dashbord()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 15),

            // ================= BLUE HEADER =================
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
                      "BDM - BDO REPORT ENTRY",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Monthly Sales Report",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 13),
                  ],
                ),
              ),
            ),

            // ================= FORM CARD =================
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 15, right: 15),
              child: Container(
                width: 700,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                      color: const Color.fromARGB(255, 202, 202, 202)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ================= BDO DROPDOWN =================
                      AbsorbPointer(
                        absorbing: bdoLoading,
                        child: Opacity(
                          opacity: bdoLoading ? 0.5 : 1,
                          child: DropdownSearch<Map<String, dynamic>>(
                            items: bdoList,
                            itemAsString: (item) => item?["name"] ?? "",
                            selectedItem: selectedBDOId == null
                                ? null
                                : bdoList.firstWhere(
                                    (e) => e["id"] == selectedBDOId,
                                    orElse: () => {},
                                  ),
                            popupProps: const PopupProps.menu(
                              showSearchBox: true,
                              searchFieldProps: TextFieldProps(
                                decoration: InputDecoration(
                                  hintText: "Search BDO...",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            dropdownDecoratorProps: DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                labelText: bdoLoading
                                    ? "Loading BDO..."
                                    : "Select BDO",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            onChanged: (value) async {
                              setState(() {
                                selectedBDOId = value?["id"];
                              });

                              if (selectedBDOId != null) {
                                await getInvoicesByBDO(selectedBDOId!);
                              }
                            },
                            clearButtonProps:
                                const ClearButtonProps(isVisible: true),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ================= INVOICE DROPDOWN =================
                      AbsorbPointer(
                        absorbing: invoiceLoading,
                        child: Opacity(
                          opacity: invoiceLoading ? 0.5 : 1,
                          child: DropdownSearch<Map<String, dynamic>>(
                            items: invoiceList,
                            itemAsString: (item) =>
                                "${item?["invoice_no"] ?? ""}  (${item?["customer_name"] ?? ""})",
                            selectedItem: selectedInvoiceId == null
                                ? null
                                : invoiceList.firstWhere(
                                    (e) => e["id"] == selectedInvoiceId,
                                    orElse: () => {},
                                  ),
                            popupProps: const PopupProps.menu(
                              showSearchBox: true,
                              searchFieldProps: TextFieldProps(
                                decoration: InputDecoration(
                                  hintText: "Search Invoice...",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            dropdownDecoratorProps: DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                labelText: invoiceLoading
                                    ? "Loading Invoice..."
                                    : "Select Invoice",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                selectedInvoiceId = value?["id"];
                              });
                            },
                            clearButtonProps:
                                const ClearButtonProps(isVisible: true),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ================= STATE DROPDOWN =================
                      AbsorbPointer(
                        absorbing: stateLoading,
                        child: Opacity(
                          opacity: stateLoading ? 0.5 : 1,
                          child: DropdownSearch<Map<String, dynamic>>(
                            items: stateList,
                            itemAsString: (item) => item?["name"] ?? "",
                            selectedItem: selectedStateId == null
                                ? null
                                : stateList.firstWhere(
                                    (e) => e["id"] == selectedStateId,
                                    orElse: () => {},
                                  ),
                            popupProps: const PopupProps.menu(
                              showSearchBox: true,
                              searchFieldProps: TextFieldProps(
                                decoration: InputDecoration(
                                  hintText: "Search State...",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            dropdownDecoratorProps: DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                labelText: stateLoading
                                    ? "Loading State..."
                                    : "Select State",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                selectedStateId = value?["id"];
                              });
                            },
                            clearButtonProps:
                                const ClearButtonProps(isVisible: true),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ================= NEW COACH =================
                      DropdownButtonFormField<String>(
                        value: selectedNewCoach,
                        decoration: InputDecoration(
                          labelText: "New Coach",
                          labelStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: "yes", child: Text("YES")),
                          DropdownMenuItem(value: "no", child: Text("NO")),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedNewCoach = value ?? "no";
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      // ================= MICRO DEALER =================
                      DropdownButtonFormField<String>(
                        value: selectedMicroDealer,
                        decoration: InputDecoration(
                          labelText: "Micro Dealer",
                          labelStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: "yes", child: Text("YES")),
                          DropdownMenuItem(value: "no", child: Text("NO")),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedMicroDealer = value ?? "no";
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      // ================= CALL DURATION =================
                      TextFormField(
                        controller: callDurationController,
                        decoration: InputDecoration(
                          labelText: "Call Duration",
                          labelStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ================= AVERAGE =================
                      TextFormField(
                        controller: averageController,
                        decoration: InputDecoration(
                          labelText: "Average",
                          labelStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ================= NOTE =================
                      TextFormField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: "Note",
                          labelStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ================= SUBMIT BUTTON =================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 250,
                            child: ElevatedButton(
                              onPressed: loading ? null : submitBDMBDOReport,
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
                              ),
                              child: loading
                                  ? const Text(
                                      "Submitting...",
                                      style: TextStyle(color: Colors.white),
                                    )
                                  : const Text(
                                      "Submit Report",
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

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
