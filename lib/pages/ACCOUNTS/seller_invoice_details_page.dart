import 'dart:convert';
import 'package:beposoft/pages/ACCOUNTS/add_more_product_purchase_list.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beposoft/pages/api.dart';
import 'package:url_launcher/url_launcher.dart';

class SellerInvoiceDetailsPage extends StatefulWidget {
  final int invoiceId;

  const SellerInvoiceDetailsPage({
    super.key,
    required this.invoiceId,
  });

  @override
  State<SellerInvoiceDetailsPage> createState() =>
      _SellerInvoiceDetailsPageState();
}

class _SellerInvoiceDetailsPageState extends State<SellerInvoiceDetailsPage> {
  bool loading = false;
  bool showAllItems = false;

  Map<String, dynamic>? invoiceData;
  List<Map<String, dynamic>> items = [];
  TextEditingController noteController = TextEditingController();
  TextEditingController companyController = TextEditingController();
  TextEditingController invoiceDateController = TextEditingController();

  bool loadingSupplier = false;
  List<Map<String, dynamic>> supplierList = [];
  int? selectedCompanyId;
  int? selectedSellerId;

  List<Map<String, dynamic>> sellerList = [];

  Future<String?> gettoken() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString('token');
  }

  @override
  void initState() {
    super.initState();
    fetchInvoiceDetails();

    getcompany();
    getSellers();
  }

  List<Map<String, dynamic>> company = [];

  Future<void> getcompany() async {
    try {
      final token = await gettoken();

      var response = await http.get(
        Uri.parse('$api/api/company/data/'),
        headers: {
          'Authorization': ' Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> companylist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          companylist.add({
            'id': productData['id'],
            'name': productData['name'],
          });
        }
        setState(() {
          company = companylist;
        });
      }
    } catch (error) {}
  }

  // ===================== GET SUPPLIERS =====================
  Future<void> getSellers() async {
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
            "id": item["id"],
            "name": item["name"] ?? "",
            "company_name": item["company_name"] ?? "",
            "gstin": item["gstin"] ?? "",
            "phone": item["phone"] ?? "",
            "email": item["email"] ?? "",
            "address": item["address"] ?? "",
          });
        }

        setState(() {
          sellerList = temp;
        });
      }
    } catch (e) {
      // print("Seller fetch error: $e");
    }
  }

  // ===================== FETCH INVOICE DETAILS =====================
  Future<void> fetchInvoiceDetails() async {
    setState(() {
      loading = true;
    });

    try {
      final token = await gettoken();

      final response = await http.get(
        Uri.parse("$api/api/product/seller/invoice/${widget.invoiceId}/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

     

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final data = parsed["data"] ?? {};

        List tempItems = data["items"] ?? [];

        List<Map<String, dynamic>> itemList = [];

        for (var i in tempItems) {
          itemList.add({
            "id": i["id"],
            "product_id": i["product_id"],
            "product_name": i["product_name"] ?? "",
            "quantity": i["quantity"] ?? 0,
            "price": i["price"] ?? 0.0,
            "discount": i["discount"] ?? 0.0,
            "tax": i["tax"] ?? 0.0,
            "total": i["total"] ?? 0.0,
            "image": i["image"] ?? "",
          });
        }

        setState(() {
          invoiceData = data;
          items = itemList;
          showAllItems = false;
        });
      }
    } catch (e) {
      // print("Error: $e");
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> updateInvoiceItem({
    required int itemId,
    required String qty,
    required String price,
    required String discount,
    required String tax,
  }) async {
    try {
      final token = await gettoken();

      final response = await http.put(
        Uri.parse("$api/api/product/seller/invoice/${widget.invoiceId}/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "items": [
            {
              "id": itemId,
              "quantity": int.tryParse(qty) ?? 0,
              "price": double.tryParse(price) ?? 0,
              "discount": double.tryParse(discount) ?? 0,
              "tax": double.tryParse(tax) ?? 0,
            }
          ]
        }),
      );

      // print("Update Item Status: ${response.statusCode}");
      // print("Update Item Body: ${response.body}");

      if (response.statusCode == 200) {
        Navigator.pop(context);
        await fetchInvoiceDetails();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Item Updated Successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update item: ${response.body}")),
        );
      }
    } catch (e) {
      // print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong")),
      );
    }
  }

  Future<void> openPrintInvoice() async {
    final url = "$api/api/product/seller/invoice/print/${widget.invoiceId}/";

    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open invoice print URL")),
      );
    }
  }

  Future<void> updateInvoiceDetails() async {
    try {
      final token = await gettoken();

      final response = await http.put(
        Uri.parse("$api/api/product/seller/invoice/${widget.invoiceId}/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "seller_id": selectedSellerId,
          "company_id": selectedCompanyId,
          "note": noteController.text,
          "invoice_date": invoiceDateController.text,
        }),
      );

      // print("Update Invoice Status: ${response.statusCode}");
      // print("Update Invoice Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context);
        fetchInvoiceDetails();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invoice Updated Successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update invoice")),
        );
      }
    } catch (e) {
      // print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong")),
      );
    }
  }

  Future<void> addInvoiceItem(Map<String, dynamic> item) async {
    try {
      final token = await gettoken();

      final response = await http.post(
        Uri.parse("$api/api/product/seller/invoice/item/add/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "invoice_id": widget.invoiceId,
          "product_id": item["product_id"],
          "quantity": item["quantity"],
          "price": item["price"],
          "discount": item["discount"] ?? 0,
          "tax": item["tax"] ?? 0,
        }),
      );

      // print("ADD ITEM STATUS: ${response.statusCode}");
      // print("ADD ITEM BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product added successfully")),
        );

        await fetchInvoiceDetails(); // ✅ refresh from backend
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error adding product")),
      );
    }
  }

  // ===================== FORMAT DATE =====================
  String formatDateShort(String date) {
    try {
      DateTime d = DateTime.parse(date);
      String day = d.day.toString().padLeft(2, "0");

      List months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec"
      ];

      String month = months[d.month - 1];
      String year = d.year.toString().substring(2);

      return "$day $month $year";
    } catch (e) {
      return date;
    }
  }

  Future<void> deleteInvoiceItem(int itemId, int index) async {
    try {
      final token = await gettoken();

      final response = await http.delete(
        Uri.parse("$api/api/product/seller/invoice/item/delete/$itemId/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      // print("Delete Item Status: ${response.statusCode}");
      // print("Delete Item Body: ${response.body}");
      if (response.statusCode == 200 || response.statusCode == 204) {
        // ✅ Remove from UI
        setState(() {
          items.removeAt(index);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Item removed")),
        );

        // OPTIONAL: refresh totals
        await fetchInvoiceDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Delete failed: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong")),
      );
    }
  }

  void openEditItemForm(Map<String, dynamic> item) {
    TextEditingController qtyController =
        TextEditingController(text: item["quantity"].toString());
    TextEditingController priceController =
        TextEditingController(text: item["price"].toString());
    TextEditingController discountController =
        TextEditingController(text: item["discount"].toString());
    TextEditingController taxController =
        TextEditingController(text: item["tax"].toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Edit Item: ${item["product_name"]}",
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Quantity",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Price",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: discountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Discount",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: taxController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Tax (%)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    updateInvoiceItem(
                      itemId: item["id"],
                      qty: qtyController.text,
                      price: priceController.text,
                      discount: discountController.text,
                      tax: taxController.text,
                    );
                  },
                  child: const Text(
                    "Update Item",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===================== ITEM CARD =====================
  Widget itemCard(Map<String, dynamic> item, int index) {
    String name = item["product_name"] ?? "";
    String image = item["image"] ?? "";

    int qty = int.tryParse(item["quantity"].toString()) ?? 0;
    double price = double.tryParse(item["price"].toString()) ?? 0;
    double discount = double.tryParse(item["discount"].toString()) ?? 0;
    double tax = double.tryParse(item["tax"].toString()) ?? 0;
    double total = double.tryParse(item["total"].toString()) ?? 0;
    String currencySymbol = invoiceData?["currency_name"] ?? "₹";

    return GestureDetector(
      onTap: () {
        openEditItemForm(item);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.25),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: image.isNotEmpty
                  ? Image.network(
                      image,
                      width: 65,
                      height: 65,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 65,
                        height: 65,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image_not_supported),
                      ),
                    )
                  : Container(
                      width: 65,
                      height: 65,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text("Qty: $qty", style: const TextStyle(fontSize: 12)),
                  Text("Price: $currencySymbol$price"),
                  Text("Discount: $currencySymbol$discount"),
                  Text("Tax: $tax%", style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              children: [
                Text(
                 "$currencySymbol${total.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final confirm = await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Delete Item"),
                        content: const Text(
                            "Are you sure you want to remove this product?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Delete"),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      if (item["id"] != null) {
                        deleteInvoiceItem(item["id"], index);
                      } else {
                        setState(() {
                          items.removeAt(index);
                        });
                      }
                    }
                  },
                  child: const Icon(
                    Icons.delete,
                    color: Colors.red,
                    size: 18,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  int getTotalProductsQty() {
    int totalQty = 0;

    for (var item in items) {
      int qty = int.tryParse(item["quantity"].toString()) ?? 0;
      totalQty += qty;
    }

    return totalQty;
  }

  // ===================== BOTTOM TOTAL BAR =====================
  Widget bottomTotalBar() {
    if (invoiceData == null) return const SizedBox();

    double totalAmount =
        double.tryParse(invoiceData!["total_amount"].toString()) ?? 0;
String currencySymbol = invoiceData?["currency_name"] ?? "₹";
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
      child: Row(
        children: [
          const Expanded(
            child: Text(
              "Total Amount",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            "$currencySymbol${totalAmount.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  void openEditInvoiceForm() {
    if (invoiceData == null) return;

    noteController.text = invoiceData!["note"] ?? "";
    invoiceDateController.text = invoiceData!["invoice_date"] ?? "";

    selectedCompanyId = company.firstWhere(
      (c) => c["name"] == invoiceData!["company_name"],
      orElse: () => {"id": null},
    )["id"];

    selectedSellerId = sellerList.firstWhere(
      (s) => s["name"] == invoiceData!["seller_name"],
      orElse: () => {"id": null},
    )["id"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Edit Invoice",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),

              // ✅ SELLER DROPDOWN
              DropdownButtonFormField<int>(
                isExpanded: true,
                value: selectedSellerId,
                decoration: const InputDecoration(
                  labelText: "Select Seller",
                  border: OutlineInputBorder(),
                ),
                items: sellerList.map((s) {
                  return DropdownMenuItem<int>(
                    value: s["id"],
                    child: Text(
                      s["name"],
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSellerId = value;

                    var sel = sellerList.firstWhere((x) => x["id"] == value);

                    invoiceData!["seller_name"] = sel["name"];
                    invoiceData!["company_name"] = sel["company_name"];
                    invoiceData!["gstin"] = sel["gstin"];
                    invoiceData!["phone"] = sel["phone"];
                    invoiceData!["email"] = sel["email"];
                    invoiceData!["address"] = sel["address"];
                  });
                },
              ),

              const SizedBox(height: 12),

              // ✅ COMPANY DROPDOWN
              DropdownButtonFormField<int>(
                isExpanded: true,
                value: selectedCompanyId,
                decoration: const InputDecoration(
                  labelText: "Select Company",
                  border: OutlineInputBorder(),
                ),
                items: company.map((c) {
                  return DropdownMenuItem<int>(
                    value: c["id"],
                    child: Text(
                      c["name"],
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCompanyId = value;
                  });
                },
              ),

              const SizedBox(height: 12),

              // ✅ INVOICE DATE
              TextField(
                controller: invoiceDateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Invoice Date",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_month),
                ),
                onTap: () async {
                  DateTime now = DateTime.now();
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );

                  if (picked != null) {
                    invoiceDateController.text =
                        "${picked.year}-${picked.month.toString().padLeft(2, "0")}-${picked.day.toString().padLeft(2, "0")}";
                  }
                },
              ),

              const SizedBox(height: 12),

              // ✅ NOTE
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Note",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    updateInvoiceDetails();
                  },
                  child: const Text(
                    "Update Invoice",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void openAddProductModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Add Product",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // TODO: Open product selection modal / API call
                },
                child: const Text("Select Product"),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    String invoiceNo = invoiceData?["invoice_no"] ?? "";
    String invoiceDate = invoiceData?["invoice_date"] ?? "";
    String currencySymbol = invoiceData?["currency_name"] ?? "₹";

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Invoice Details",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        actions: [
          IconButton(
            onPressed: openPrintInvoice,
            icon: const Icon(Icons.download, color: Colors.black54),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : invoiceData == null
              ? const Center(
                  child: Text(
                    "No Details Found",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(14),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 90),
                    child: Column(
                      children: [
                        // ================= HEADER CARD =================
                        // ================= HEADER CARD WITH SELLER DETAILS =================
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // BLUE HEADER
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1E88E5),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(14),
                                    topRight: Radius.circular(14),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "#$invoiceNo",
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      formatDateShort(invoiceDate),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: openEditInvoiceForm,
                                      icon: const Icon(Icons.edit,
                                          color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),

                              // WHITE BODY WITH SELLER DETAILS
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "Seller: ${invoiceData!["seller_name"] ?? ""}",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "Company: ${invoiceData!["company_name"] ?? ""}",
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black87),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "GSTIN: ${invoiceData!["gstin"] ?? ""}",
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black87),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "Phone: ${invoiceData!["phone"] ?? ""}",
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black87),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "Email: ${invoiceData!["email"] ?? ""}",
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black87),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "Address: ${invoiceData!["address"] ?? ""}",
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black87),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "Note: ${invoiceData!["note"] ?? ""}",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ================= SELLER INFO =================

                        const SizedBox(height: 14),

                        // ================= ITEMS HEADER =================
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Items (${items.length})",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                // 🔥 THIS IS THE IMPORTANT PART (YOU WERE ASKING "WHERE")
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AddMoreProductPurchaseList(),
                                  ),
                                );

                                if (result != null) {
                                  await addInvoiceItem(result);
                                }
                              },
                              icon: const Icon(Icons.add,
                                  size: 16, color: Colors.white),
                              label: const Text(
                                "Add Product",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const SizedBox(height: 10),
                        const SizedBox(height: 10),

                        ...((showAllItems ? items : items.take(2).toList())
                            .asMap()
                            .entries
                            .map((entry) {
                              int index = entry.key;
                              var item = entry.value;
                              return itemCard(item, index);
                            })
                            .toList()
                            .toList()),

// ✅ SEE MORE / SEE LESS BUTTON
                        if (items.length > 2)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                showAllItems = !showAllItems;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                showAllItems ? "See Less ▲" : "See More ▼",
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 14),

// ✅ TOTAL PRODUCTS CARD
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.25),
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  "Total Product Quantity",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Text(
                                "${getTotalProductsQty()}",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: bottomTotalBar(),
    );
  }
}
