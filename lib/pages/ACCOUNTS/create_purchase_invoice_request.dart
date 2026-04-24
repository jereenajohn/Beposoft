import 'dart:convert';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class CreatePurchaseInvoiceRequest extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount;

  const CreatePurchaseInvoiceRequest({
    super.key,
    required this.cartItems,
    required this.totalAmount,
  });

  @override
  State<CreatePurchaseInvoiceRequest> createState() =>
      _CreatePurchaseInvoiceRequestState();
}

class _CreatePurchaseInvoiceRequestState
    extends State<CreatePurchaseInvoiceRequest> {
  List<Map<String, dynamic>> supplierList = [];
  List<Map<String, dynamic>> company = [];
  bool showAllProducts = false;

  bool loadingSupplier = false;
  bool loadingCompany = false;
  bool submitting = false;

  String? selectedSupplierId;
  String? selectedCompanyId;

  DateTime? selectedInvoiceDate;
  TextEditingController noteController = TextEditingController();

  List<Map<String, dynamic>> currency = [];
  String? selectedCurrencyId;
  String selectedCurrencySymbol = "₹"; // default INR
  TextEditingController currencyRateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getSuppliers();
    getcompany();
    getcurrency();
  }

  Future<String?> gettoken() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString('token');
  }

  Future<void> getcurrency() async {
    final token = await gettoken();

    try {
      final response =
          await http.get(Uri.parse('$api/api/currency/add/'), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      List<Map<String, dynamic>> currencylist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var data = parsed['data'];

        for (var item in data) {
          currencylist.add({
            'id': item['id'].toString(),
            'name': item['currency'], // e.g. ₹ or $
            'country': item['country_name'],
            'symbol': item['currency'], // ✅ USE SAME FIELD
          });
        }

        setState(() {
          currency = currencylist;

          // ✅ Default INR (₹)
          final inr = currencylist.firstWhere(
            (e) => e['symbol'] == "₹",
            orElse: () => currencylist.first,
          );

          selectedCurrencyId = inr['id'];
          selectedCurrencySymbol = inr['symbol'];
        });
      }
    } catch (e) {}
  }

  // ===================== GET COMPANY =====================
  Future<void> getcompany() async {
    setState(() {
      loadingCompany = true;
    });

    try {
      final token = await gettoken();

      var response = await http.get(
        Uri.parse('$api/api/company/data/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> companylist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          companylist.add({
            'id': productData['id'].toString(),
            'name': productData['name'],
          });
        }

        setState(() {
          company = companylist;
        });
      }
    } catch (error) {}

    setState(() {
      loadingCompany = false;
    });
  }

  // ===================== GET SUPPLIERS =====================
  Future<void> getSuppliers() async {
    setState(() {
      loadingSupplier = true;
    });

    try {
      final token = await gettoken();

      final response = await http.get(
        Uri.parse("$api/api/product/sellers/details/add/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List data = parsed["data"] ?? [];

        List<Map<String, dynamic>> temp = [];

        for (var item in data) {
          temp.add({
            "id": item["id"].toString(),
            "name": item["name"] ?? "",
            "company_name": item["company_name"] ?? "",
            "gstin": item["gstin"] ?? "",
            "phone": item["phone"] ?? "",
          });
        }

        setState(() {
          supplierList = temp;
        });
      }
    } catch (e) {}

    setState(() {
      loadingSupplier = false;
    });
  }

  // ===================== DATE PICKER =====================
  Future<void> pickInvoiceDate() async {
    DateTime now = DateTime.now();

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedInvoiceDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedInvoiceDate = picked;
      });
    }
  }

  String formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  void showCustomPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // ===================== SUBMIT REQUEST =====================
  Future<void> submitInvoiceRequest() async {
    if (selectedSupplierId == null) {
      showCustomPopup("Error", "Please select Supplier");
      return;
    }

    if (selectedCompanyId == null) {
      showCustomPopup("Error", "Please select Company");
      return;
    }

    if (selectedInvoiceDate == null) {
      showCustomPopup("Error", "Please select Invoice Date");
      return;
    }

    setState(() {
      submitting = true;
    });

    try {
      final token = await gettoken();

      final response = await http.post(
        Uri.parse("$api/api/product/seller/invoice/create/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "seller_id": selectedSupplierId,
          "company": selectedCompanyId,
          "invoice_date": formatDate(selectedInvoiceDate!),
          "note": noteController.text,
          "currency": selectedCurrencyId,
          "currency_rate": currencyRateController.text,
        }),
      );

      print(formatDate(selectedInvoiceDate!));
      print("Create Invoice Status: ${response.statusCode}");
      print("Create Invoice Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        showCustomPopup("Success", "Invoice Request Created Successfully!");
      } else {
        showCustomPopup("Error", "Failed to Create Invoice Request");
      }
    } catch (e) {
      showCustomPopup("Error", "Something went wrong!");
    }

    setState(() {
      submitting = false;
    });
  }

  // ===================== UI HELPERS (DESIGN MATCH) =====================
  Widget buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget buildDropdownBox({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: child,
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget buildTextFieldBox({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: child,
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: child,
    );
  }

  // ===================== FIXED BOTTOM BAR =====================
  Widget bottomFixedBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.25),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ TOTAL AMOUNT FIXED
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "Total Amount",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  "$selectedCurrencySymbol${widget.totalAmount.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ✅ SUBMIT BUTTON FIXED
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: submitting ? null : submitInvoiceRequest,
              child: submitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Submit Request",
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
    );
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        title: const Text(
          "PURCHASE REQUEST",
          style: TextStyle(
            fontSize: 16,
            letterSpacing: 3,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            children: [
              // ================= MAIN FORM CARD =================
              buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildDropdownBox(
                      label: "Currency",
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                        value: selectedCurrencyId,
                        hint: const Text("Select Currency"),
                        items: currency.map((c) {
                          return DropdownMenuItem<String>(
                            value: c["id"],
                            child: Text("${c["symbol"]} - ${c["country"]}"),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCurrencyId = value;

                            final selected =
                                currency.firstWhere((e) => e["id"] == value);

                            selectedCurrencySymbol = selected["symbol"];
                          });
                        },
                      ),
                    ),

                    buildTextFieldBox(
                      label: "Currency Rate",
                      child: TextField(
                        controller: currencyRateController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter currency rate",
                        ),
                      ),
                    ),
                    // SUPPLIER DROPDOWN
                    buildDropdownBox(
                      label: "Supplier",
                      child: loadingSupplier
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : DropdownButtonFormField<String>(
                              isExpanded: true,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                              value: selectedSupplierId,
                              hint: const Text("Select Supplier"),
                              items: supplierList.map((sup) {
                                return DropdownMenuItem<String>(
                                  value: sup["id"],
                                  child: Text(
                                    "${sup["name"]} (${sup["company_name"]})",
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedSupplierId = value;
                                });
                              },
                            ),
                    ),

                    // COMPANY DROPDOWN
                    buildDropdownBox(
                      label: "Company",
                      child: loadingCompany
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : DropdownButtonFormField<String>(
                              isExpanded: true,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                              value: selectedCompanyId,
                              hint: const Text("Select a company"),
                              items: company.map((c) {
                                return DropdownMenuItem<String>(
                                  value: c["id"],
                                  child: Text(
                                    c["name"],
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedCompanyId = value;
                                });
                              },
                            ),
                    ),

                    // INVOICE DATE PICKER
                    buildTextFieldBox(
                      label: "Invoice Date",
                      child: GestureDetector(
                        onTap: pickInvoiceDate,
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  selectedInvoiceDate == null
                                      ? "Select Date"
                                      : formatDate(selectedInvoiceDate!),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: selectedInvoiceDate == null
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            const Icon(Icons.calendar_month,
                                color: Colors.black54),
                          ],
                        ),
                      ),
                    ),

                    // NOTE FIELD
                    buildTextFieldBox(
                      label: "Note",
                      child: TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter note here...",
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // ================= CART PRODUCTS SECTION =================
              buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Cart Products",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...((showAllProducts
                            ? widget.cartItems
                            : widget.cartItems.take(3).toList())
                        .map((item) {
                      String name = item["product_name"] ?? "";
                      String image = item["product_image"] ?? "";

                      int qty = int.tryParse(item["quantity"].toString()) ?? 0;
                      double price =
                          double.tryParse(item["price"].toString()) ?? 0;
                      double discount =
                          double.tryParse(item["discount"].toString()) ?? 0;

                      double total = (price * qty) - discount;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: image.isNotEmpty
                                  ? Image.network(
                                      "$api$image",
                                      width: 55,
                                      height: 55,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error,
                                              stackTrace) =>
                                          const Icon(Icons.image_not_supported,
                                              size: 40),
                                    )
                                  : Container(
                                      width: 55,
                                      height: 55,
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.image, size: 35),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Qty: $qty",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "$selectedCurrencySymbol${total.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList()),
                    if (widget.cartItems.length > 3)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            showAllProducts = !showAllProducts;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            showAllProducts ? "See Less ▲" : "See More ▼",
                            style: const TextStyle(
                              color: Colors.blue,
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
      ),
      bottomNavigationBar: bottomFixedBar(),
    );
  }
}
