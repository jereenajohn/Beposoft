import 'dart:convert';
import 'package:beposoft/pages/ACCOUNTS/seller_invoice_details_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beposoft/pages/api.dart';

class SellerInvoiceListPage extends StatefulWidget {
  const SellerInvoiceListPage({super.key});

  @override
  State<SellerInvoiceListPage> createState() => _SellerInvoiceListPageState();
}

class _SellerInvoiceListPageState extends State<SellerInvoiceListPage> {
  bool loading = false;

  List<Map<String, dynamic>> invoices = [];
  List<Map<String, dynamic>> filteredInvoices = [];
  DateTimeRange? selectedRange;

  TextEditingController searchController = TextEditingController();

  String selectedFilter = "All";

  Future<String?> gettoken() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString('token');
  }

  @override
  void initState() {
    super.initState();
    fetchInvoices();

    searchController.addListener(() {
      applyFilter();
    });
  }

  // ================= DATE RANGE =================
  Future<void> pickDateRange() async {
    DateTime now = DateTime.now();

    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: selectedRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: DateTime(now.year, now.month + 1, 0),
          ),
    );

    if (picked != null) {
      setState(() {
        selectedRange = picked;
      });

      filterByDateRange();
    }
  }

  void filterByDateRange() {
    if (selectedRange == null) {
      filteredInvoices = invoices;
      setState(() {});
      return;
    }

    DateTime start = selectedRange!.start;
    DateTime end = selectedRange!.end;

    List<Map<String, dynamic>> temp = invoices.where((inv) {
      try {
        DateTime invoiceDate = DateTime.parse(inv["invoice_date"]);

        return invoiceDate.isAfter(start.subtract(const Duration(days: 1))) &&
            invoiceDate.isBefore(end.add(const Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).toList();

    setState(() {
      filteredInvoices = temp;
    });
  }

  void clearDateFilter() {
    setState(() {
      selectedRange = null;
      filteredInvoices = invoices;
    });
  }

  // ================= FETCH =================
  Future<void> fetchInvoices() async {
    setState(() => loading = true);

    try {
      final token = await gettoken();

      final response = await http.get(
        Uri.parse("$api/api/product/seller/invoices/"),
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
            "invoice_no": item["invoice_no"] ?? "",
            "seller_name": item["seller_name"] ?? "",
            "invoice_date": item["invoice_date"] ?? "",
            "total_amount": item["total_amount"] ?? "0.00",
            "note": item["note"] ?? "",
            "items": item["items"] ?? [],
            "currency": item["currency_name"] ?? "₹",
            "currency_rate": item["currency_rate"] ?? "1",
          });
        }

        setState(() {
          invoices = temp;
          filteredInvoices = temp;
        });
      }
    } catch (e) {}

    setState(() => loading = false);
  }

  // ================= FILTER =================
  void applyFilter() {
    String searchText = searchController.text.toLowerCase();

    List<Map<String, dynamic>> temp = invoices.where((inv) {
      String invoiceNo = (inv["invoice_no"] ?? "").toString().toLowerCase();
      String sellerName = (inv["seller_name"] ?? "").toString().toLowerCase();

      return invoiceNo.contains(searchText) || sellerName.contains(searchText);
    }).toList();

    setState(() {
      filteredInvoices = temp;
    });
  }

  // ================= FORMAT DATE =================
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

      return "$day ${months[d.month - 1]} ${d.year.toString().substring(2)}";
    } catch (e) {
      return date;
    }
  }

  // ================= CARD =================
  Widget invoiceCard(Map<String, dynamic> invoice) {
    String currency = invoice["currency"] ?? "₹";
    double amount = double.tryParse(invoice["total_amount"].toString()) ?? 0;
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SellerInvoiceDetailsPage(
              invoiceId: invoice["id"],
            ),
          ),
        );

        if (result == true) {
          fetchInvoices();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      "#${invoice["invoice_no"]}",
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    formatDateShort(invoice["invoice_date"]),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Seller: ${invoice["seller_name"]}",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(
                          child: Text("Billing Amount:",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      Text(
                        "$currency${amount.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTopFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: searchController,
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search),
          hintText: "Search...",
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Purchase invoice List",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          IconButton(
            onPressed: pickDateRange,
            icon: const Icon(Icons.calendar_month),
          ),
          if (selectedRange != null)
            IconButton(
              onPressed: clearDateFilter,
              icon: const Icon(Icons.close, color: Colors.red),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            buildTopFilters(),
            const SizedBox(height: 15),
            Expanded(
              child: RefreshIndicator(
                onRefresh: fetchInvoices,
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredInvoices.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 200),
                              Center(child: Text("No Invoices Found")),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: filteredInvoices.length,
                            itemBuilder: (context, index) {
                              return invoiceCard(filteredInvoices[index]);
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
