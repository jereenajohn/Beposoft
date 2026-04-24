import 'dart:convert';

import 'package:beposoft/pages/ACCOUNTS/order.review.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryProductDetailsPage extends StatefulWidget {
  final dynamic categoryId;
  final String categoryName;
  final String startDate;
  final String endDate;

  const CategoryProductDetailsPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<CategoryProductDetailsPage> createState() =>
      _CategoryProductDetailsPageState();
}

class _CategoryProductDetailsPageState
    extends State<CategoryProductDetailsPage> {
  List<Map<String, dynamic>> productList = [];
  bool isLoading = true;

  final Map<dynamic, bool> expandedInvoices = {};
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  void initState() {
    super.initState();
    selectedStartDate = DateTime.tryParse(widget.startDate) ?? DateTime.now();
    selectedEndDate = DateTime.tryParse(widget.endDate) ?? DateTime.now();
    fetchCategoryProducts();
  }

  Future<void> fetchCategoryProducts() async {
    final token = await getTokenFromPrefs();
    if (token == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final uri = Uri.parse('$api/api/counts/product/category/wise/').replace(
        queryParameters: {
          'category_id': widget.categoryId?.toString() ?? "",
          'start_date': DateFormat('yyyy-MM-dd').format(selectedStartDate!),
          'end_date': DateFormat('yyyy-MM-dd').format(selectedEndDate!),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List data = decoded['data'] ?? [];

        setState(() {
          productList = List<Map<String, dynamic>>.from(
            data.map((item) => Map<String, dynamic>.from(item)),
          );
          isLoading = false;
        });
      } else {
        setState(() {
          productList = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        productList = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${widget.categoryName} Product List",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "${DateFormat('yyyy-MM-dd').format(selectedStartDate!)} to ${DateFormat('yyyy-MM-dd').format(selectedEndDate!)}",
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final pickedRange = await showDateRangePicker(
                context: context,
                initialDateRange: DateTimeRange(
                  start: selectedStartDate ?? DateTime.now(),
                  end: selectedEndDate ?? DateTime.now(),
                ),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                saveText: "Save",
              );

              if (pickedRange == null) return;

              setState(() {
                selectedStartDate = pickedRange.start;
                selectedEndDate = pickedRange.end;
              });

              fetchCategoryProducts();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : productList.isEmpty
              ? const Center(
                  child: Text(
                    "No product data available",
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    const SizedBox(height: 12),
                    ...productList.map((item) {
                      // final invoices = List<String>.from(
                      //   ((item['invoices'] as List?) ?? [])
                      //       .map((e) => e.toString()),
                      // );
                      final invoices = List<Map<String, dynamic>>.from(
                        ((item['invoices'] as List?) ?? []).map(
                          (e) => Map<String, dynamic>.from(e),
                        ),
                      );

                      final productId = item['product_id'] ?? item.hashCode;
                      final isExpanded = expandedInvoices[productId] ?? false;
                      final visibleInvoices =
                          isExpanded ? invoices : invoices.take(1).toList();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // const SizedBox(height: 6),
                            // Align(
                            //   alignment: Alignment.centerRight,
                            //   child: Padding(
                            //     padding:
                            //         const EdgeInsets.symmetric(horizontal: 12),
                            //     child: Text(
                            //       "${DateFormat('yyyy-MM-dd').format(selectedStartDate!)} to ${DateFormat('yyyy-MM-dd').format(selectedEndDate!)}",
                            //       style: const TextStyle(
                            //         fontSize: 13,
                            //         fontWeight: FontWeight.w600,
                            //         color: Colors.black54,
                            //       ),
                            //     ),
                            //   ),
                            // ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(18),
                                  topRight: Radius.circular(18),
                                ),
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF1F4E8C),
                                    Color(0xFF4CD17B)
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                              child: Text(
                                (item['product_name'] ?? '')
                                    .toString()
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Table(
                              border: TableBorder.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                              columnWidths: const {
                                0: FlexColumnWidth(2.5),
                                1: FlexColumnWidth(2.0),
                              },
                              children: [
                                _tableRow(
                                  "Total Quantity",
                                  "${item['total_quantity'] ?? 0}",
                                ),
                                // _tableRow(
                                //   "Order Item Count",
                                //   "${item['order_item_count'] ?? 0}",
                                // ),
                                _tableRow(
                                  "Category",
                                  "${item['category_name'] ?? ''}",
                                ),
                                TableRow(
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Text(
                                        "Invoices",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Wrap(
                                            alignment: WrapAlignment.center,
                                            spacing: 8,
                                            runSpacing: 8,
                                            children:
                                                visibleInvoices.map((invoice) {
                                              final orderId =
                                                  invoice['order__id'];
                                              final invoiceNo =
                                                  invoice['order__invoice']
                                                          ?.toString() ??
                                                      '';

                                              return InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                                onTap: () {
                                                  if (orderId != null) {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            OrderReview(
                                                                id: orderId, customer: null,),
                                                      ),
                                                    );
                                                  }
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 12,
                                                    vertical: 7,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFF4F8FF),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            18),
                                                    border: Border.all(
                                                      color: const Color(
                                                          0xFFB8C7E6),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    invoiceNo,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Color(0xFF2E4A7D),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                          if (invoices.length > 1) ...[
                                            const SizedBox(height: 8),
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  expandedInvoices[productId] =
                                                      !isExpanded;
                                                });
                                              },
                                              child: Text(
                                                isExpanded
                                                    ? "See Less"
                                                    : "See More",
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF1F4E8C),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
    );
  }

  TableRow _tableRow(String field, String value, {bool isGreen = false}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            field,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isGreen ? Colors.green : Colors.black87,
              fontWeight: isGreen ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
