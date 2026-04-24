import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:beposoft/pages/api.dart';

class UpdateDsrPage extends StatefulWidget {
  final int dsrId;
  final int? selectedCustomerId;
  final int? selectedInvoiceId;
  final String selectedCallStatus;

  const UpdateDsrPage({
    super.key,
    required this.dsrId,
    required this.selectedCustomerId,
    required this.selectedInvoiceId,
    required this.selectedCallStatus,
  });

  @override
  State<UpdateDsrPage> createState() => _UpdateDsrPageState();
}

class _UpdateDsrPageState extends State<UpdateDsrPage> {
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
    return prefs.getString('token');
  }

  @override
  void initState() {
    super.initState();
    selectedCustomerId = widget.selectedCustomerId;
    selectedInvoiceId = widget.selectedInvoiceId;
    selectedCallStatus = widget.selectedCallStatus;
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await Future.wait([
      getcustomer(),
      getMyOrders(),
    ]);

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

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

  Future<void> updateDsr() async {
    if (selectedCallStatus.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Please select call status"),
        ),
      );
      return;
    }

    if (selectedCallStatus == "productive" && selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Please select customer"),
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

      final body = {
        "customer": selectedCustomerId,
        "call_status": selectedCallStatus,
        "invoice": selectedInvoiceId,
      };

      print("UPDATE BODY: ${jsonEncode(body)}");

      final response = await http.put(
        Uri.parse('$api/api/sales/analysis/edit/${widget.dsrId}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print("UPDATE STATUS: ${response.statusCode}");
      print("UPDATE RESPONSE: ${response.body}");

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
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
                            setState(() {
                              selectedCallStatus = value ?? "active";

                              if (selectedCallStatus != "productive") {
                                selectedCustomerId = null;
                                selectedInvoiceId = null;
                              }
                            });
                          },
                        ),
                        if (showProductiveFields) ...[
                          const SizedBox(height: 18),
                          buildLabel("Customer"),
                          DropdownButtonFormField<int>(
                            value: selectedCustomerId,
                            decoration: buildInputDecoration(
                              labelText: "Select Customer",
                              prefixIcon: Icons.person_outline,
                            ),
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            items: filteredProducts.map((item) {
                              return DropdownMenuItem<int>(
                                value: item["id"],
                                child: Text(
                                  item["name"],
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
                              setState(() {
                                selectedCustomerId = value;
                              });
                            },
                          ),
                          const SizedBox(height: 18),
                          buildLabel("Invoice"),
                          DropdownButtonFormField<int>(
                            value: selectedInvoiceId,
                            decoration: buildInputDecoration(
                              labelText: "Select Invoice",
                              prefixIcon: Icons.receipt_long_outlined,
                            ),
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            items: myOrders.map((item) {
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
                              setState(() {
                                selectedInvoiceId = value;

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
                              disabledBackgroundColor:
                                  const Color(0xff93C5FD),
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