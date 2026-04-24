import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:beposoft/pages/api.dart';

class UpdateDsrPagee extends StatefulWidget {
  final int dsrId;
  final int? selectedCustomerId;
  final int? selectedInvoiceId;
  final String selectedCallStatus;

  const UpdateDsrPagee({
    super.key,
    required this.dsrId,
    required this.selectedCustomerId,
    required this.selectedInvoiceId,
    required this.selectedCallStatus,
  });

  @override
  State<UpdateDsrPagee> createState() => _UpdateDsrPageeState();
}

class _UpdateDsrPageeState extends State<UpdateDsrPagee> {
  bool isLoading = true;
  bool isSubmitting = false;

  List<Map<String, dynamic>> customer = [];
  List<Map<String, dynamic>> filteredProducts = [];
  List<Map<String, dynamic>> myOrders = [];

  int? selectedCustomerId;
  int? selectedInvoiceId;
  String selectedCallStatus = "active";

  final List<Map<String, String>> callStatusOptions = const [
    {"value": "active", "label": "Active"},
    {"value": "productive", "label": "Productive"},
  ];

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    debugPrint("TOKEN FROM PREFS: $token");
    return token;
  }

  @override
  void initState() {
    super.initState();

    debugPrint("========================================");
    debugPrint("UPDATE DSR PAGE OPENED");
    debugPrint("WIDGET DSR ID: ${widget.dsrId}");
    debugPrint("WIDGET CUSTOMER ID: ${widget.selectedCustomerId}");
    debugPrint("WIDGET INVOICE ID: ${widget.selectedInvoiceId}");
    debugPrint("WIDGET CALL STATUS: ${widget.selectedCallStatus}");
    debugPrint("========================================");

    selectedCustomerId = widget.selectedCustomerId;
    selectedInvoiceId = widget.selectedInvoiceId;
    selectedCallStatus = widget.selectedCallStatus.trim().isEmpty
        ? "active"
        : widget.selectedCallStatus.toLowerCase().trim();

    debugPrint("INITIAL SELECTED CUSTOMER ID: $selectedCustomerId");
    debugPrint("INITIAL SELECTED INVOICE ID: $selectedInvoiceId");
    debugPrint("INITIAL SELECTED CALL STATUS: $selectedCallStatus");

    loadInitialData();
  }

  Future<void> loadInitialData() async {
    debugPrint("LOAD INITIAL DATA STARTED");

    await Future.wait([
      getcustomer(),
      getMyOrders(),
    ]);

    if (!mounted) return;

    final availableInvoiceIds = myOrders.map((e) => e["id"]).toSet();
    if (selectedInvoiceId != null &&
        !availableInvoiceIds.contains(selectedInvoiceId)) {
      debugPrint(
        "INITIAL SELECTED INVOICE ID NOT FOUND IN ORDER LIST, RESETTING: $selectedInvoiceId",
      );
      selectedInvoiceId = null;
    }

    final availableCustomerIds = customer.map((e) => e["id"]).toSet();
    if (selectedCustomerId != null &&
        !availableCustomerIds.contains(selectedCustomerId)) {
      debugPrint(
        "INITIAL SELECTED CUSTOMER ID NOT FOUND IN CUSTOMER LIST, RESETTING: $selectedCustomerId",
      );
      selectedCustomerId = null;
    }

    setState(() {
      isLoading = false;
    });

    debugPrint("LOAD INITIAL DATA COMPLETED");
    debugPrint("CUSTOMER COUNT: ${customer.length}");
    debugPrint("ORDER COUNT: ${myOrders.length}");
  }

  Future<void> getcustomer() async {
    try {
      final token = await gettokenFromPrefs();
      final url = Uri.parse('$api/api/staff/customers/');

      debugPrint("GET CUSTOMER URL: $url");

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("GET CUSTOMER STATUS: ${response.statusCode}");
      debugPrint("GET CUSTOMER RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final productsData = parsed['data'] ?? [];
        final List<Map<String, dynamic>> managerlist = [];

        for (final productData in productsData) {
          managerlist.add({
            'id': productData['id'],
            'name': productData['name']?.toString() ?? "",
            'created_at': productData['created_at'],
          });
        }

        if (!mounted) return;

        setState(() {
          customer = managerlist;
          filteredProducts = List<Map<String, dynamic>>.from(customer);
        });

        debugPrint("CUSTOMERS LOADED: ${customer.length}");
        for (final item in customer) {
          debugPrint("CUSTOMER ITEM: ${jsonEncode(item)}");
        }
      }
    } catch (error) {
      debugPrint("CUSTOMER ERROR: $error");
    }
  }

  Future<void> getMyOrders() async {
    try {
      final token = await gettokenFromPrefs();
      final url = Uri.parse('$api/api/my/orders/');

      debugPrint("GET MY ORDERS URL: $url");

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("GET MY ORDERS STATUS: ${response.statusCode}");
      debugPrint("GET MY ORDERS RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final List parsed = jsonDecode(response.body);

        final List<Map<String, dynamic>> orderList = [];

        for (final item in parsed) {
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

        debugPrint("MY ORDERS LOADED: ${myOrders.length}");
        for (final order in myOrders) {
          debugPrint("ORDER ITEM: ${jsonEncode(order)}");
        }
      }
    } catch (e) {
      debugPrint("MY ORDERS ERROR: $e");
    }
  }

  Future<void> updateDsr() async {
    debugPrint("========================================");
    debugPrint("UPDATE DSR FUNCTION CALLED");
    debugPrint("CURRENT DSR ID: ${widget.dsrId}");
    debugPrint("CURRENT SELECTED CALL STATUS: $selectedCallStatus");
    debugPrint("CURRENT SELECTED CUSTOMER ID: $selectedCustomerId");
    debugPrint("CURRENT SELECTED INVOICE ID: $selectedInvoiceId");
    debugPrint("========================================");

    if (selectedCallStatus.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Please select call status"),
        ),
      );
      return;
    }

    if (selectedCallStatus == "productive" && selectedInvoiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Please select invoice"),
        ),
      );
      return;
    }

    try {
      setState(() {
        isSubmitting = true;
      });

      final token = await gettokenFromPrefs();

      final url = Uri.parse(
        '$api/api/sales/team/member/daily/report/edit/${widget.dsrId}/',
      );

      final body = {
        "call_status": selectedCallStatus,
        "invoice": selectedInvoiceId,
      };

      debugPrint("UPDATE URL: $url");
      debugPrint("UPDATE BODY: ${jsonEncode(body)}");

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint("UPDATE STATUS: ${response.statusCode}");
      debugPrint("UPDATE RESPONSE: ${response.body}");

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("DSR updated successfully"),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Update failed: ${response.body}"),
          ),
        );
      }
    } catch (e) {
      debugPrint("UPDATE ERROR: $e");

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error: $e"),
        ),
      );
    }
  }

  Widget buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xff1F2937),
        ),
      ),
    );
  }

  InputDecoration buildInputDecoration({
    required String labelText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(
        fontSize: 13,
        color: Color(0xff6B7280),
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 20, color: const Color(0xff2563EB))
          : null,
      filled: true,
      fillColor: const Color(0xffF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xffDCE3EC),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xff2563EB),
          width: 1.4,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Widget buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: const Color(0xffE8EEF5),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showProductiveFields = selectedCallStatus == "productive";

    final List<Map<String, dynamic>> filteredInvoices = myOrders.where((item) {
      if (selectedCustomerId == null) return true;
      return item["customer_id"] == selectedCustomerId;
    }).toList();

    final bool selectedInvoiceStillExists = selectedInvoiceId == null
        ? true
        : filteredInvoices.any((item) => item["id"] == selectedInvoiceId);

    return Scaffold(
      backgroundColor: const Color(0xffEEF4FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xff111827)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Update DSR",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xff111827),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  buildSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Color(0xffDBEAFE),
                              child: Icon(
                                Icons.edit_document,
                                color: Color(0xff2563EB),
                                size: 22,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Edit DSR Details",
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff111827),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "First choose call status. Customer and invoice will appear only for productive calls.",
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.4,
                                      color: Color(0xff6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        buildLabel("Call Status"),
                        DropdownButtonFormField<String>(
                          value: selectedCallStatus,
                          decoration: buildInputDecoration(
                            labelText: "Select Call Status",
                            prefixIcon: Icons.call,
                          ),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          items: callStatusOptions.map((item) {
                            return DropdownMenuItem<String>(
                              value: item["value"],
                              child: Text(
                                item["label"]!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xff111827),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            debugPrint("CALL STATUS CHANGED TO: $value");

                            setState(() {
                              selectedCallStatus = value ?? "active";

                              if (selectedCallStatus != "productive") {
                                selectedCustomerId = null;
                                selectedInvoiceId = null;
                              }
                            });

                            debugPrint(
                              "AFTER CHANGE CALL STATUS: $selectedCallStatus",
                            );
                            debugPrint(
                              "AFTER CHANGE CUSTOMER ID: $selectedCustomerId",
                            );
                            debugPrint(
                              "AFTER CHANGE INVOICE ID: $selectedInvoiceId",
                            );
                          },
                        ),
                        if (showProductiveFields) ...[
                          const SizedBox(height: 18),
                          // buildLabel("Customer"),
                          // DropdownButtonFormField<int>(
                          //   value: selectedCustomerId != null &&
                          //           filteredProducts.any(
                          //             (item) =>
                          //                 item["id"] == selectedCustomerId,
                          //           )
                          //       ? selectedCustomerId
                          //       : null,
                          //   decoration: buildInputDecoration(
                          //     labelText: "Select Customer",
                          //     prefixIcon: Icons.person_outline,
                          //   ),
                          //   dropdownColor: Colors.white,
                          //   borderRadius: BorderRadius.circular(14),
                          //   items: filteredProducts.map((item) {
                          //     return DropdownMenuItem<int>(
                          //       value: item["id"],
                          //       child: Text(
                          //         item["name"] ?? "",
                          //         overflow: TextOverflow.ellipsis,
                          //         style: const TextStyle(
                          //           fontSize: 14,
                          //           color: Color(0xff111827),
                          //           fontWeight: FontWeight.w500,
                          //         ),
                          //       ),
                          //     );
                          //   }).toList(),
                          //   onChanged: (value) {
                          //     debugPrint("CUSTOMER CHANGED TO: $value");

                          //     setState(() {
                          //       selectedCustomerId = value;
                          //       selectedInvoiceId = null;
                          //     });

                          //     debugPrint(
                          //       "AFTER CUSTOMER CHANGE CUSTOMER ID: $selectedCustomerId",
                          //     );
                          //     debugPrint(
                          //       "AFTER CUSTOMER CHANGE INVOICE ID: $selectedInvoiceId",
                          //     );
                          //   },
                          // ),
                          buildLabel("Invoice"),
                          DropdownButtonFormField<int>(
                            value:
                                selectedInvoiceStillExists ? selectedInvoiceId : null,
                            decoration: buildInputDecoration(
                              labelText: "Select Invoice",
                              prefixIcon: Icons.receipt_long_outlined,
                            ),
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            items: filteredInvoices.map((item) {
                              return DropdownMenuItem<int>(
                                value: item["id"],
                                child: Text(
                                  "${item["invoice"]} - ${item["customer_name"]}",
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xff111827),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              debugPrint("INVOICE CHANGED TO: $value");

                              setState(() {
                                selectedInvoiceId = value;

                                final selectedOrder = myOrders.firstWhere(
                                  (item) => item["id"] == value,
                                  orElse: () => <String, dynamic>{},
                                );

                                debugPrint(
                                  "SELECTED ORDER DATA: ${jsonEncode(selectedOrder)}",
                                );

                                if (selectedOrder.isNotEmpty) {
                                  selectedCustomerId = selectedOrder["customer_id"];
                                }
                              });

                              debugPrint(
                                "AFTER INVOICE CHANGE CUSTOMER ID: $selectedCustomerId",
                              );
                              debugPrint(
                                "AFTER INVOICE CHANGE INVOICE ID: $selectedInvoiceId",
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isSubmitting ? null : updateDsr,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: const Color(0xff2563EB),
                              disabledBackgroundColor: const Color(0xff93C5FD),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    "Update DSR",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}