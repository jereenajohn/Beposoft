import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CeoDailyProductsoldReport extends StatefulWidget {
  const CeoDailyProductsoldReport({super.key});

  @override
  State<CeoDailyProductsoldReport> createState() =>
      _CeoDailyProductsoldReportState();
}

class _CeoDailyProductsoldReportState extends State<CeoDailyProductsoldReport> {
  List<Map<String, dynamic>> product = [];
  List<Map<String, dynamic>> filteredProduct = []; // <- filtered list

  DateTime? startDate;
  DateTime? endDate;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    startDate = DateTime.now();
    endDate = DateTime.now();
    _fetchReport();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString('token');
  }

  Future<void> _fetchReport() async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('$api/api/product/date/wise/report/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );


      if (response.statusCode != 200) return;

      final parsed = jsonDecode(response.body);
      final List<Map<String, dynamic>> banklist = [];

      final s = DateFormat('yyyy-MM-dd').format(startDate!);
      final e = DateFormat('yyyy-MM-dd').format(endDate!);

      for (var p in parsed) {
        final date = p['order_date'];
        if (date.compareTo(s) >= 0 && date.compareTo(e) <= 0) {
          banklist.add({
            'id': p['id'],
            'quantity': p['quantity'],
            'order_date': p['order_date'],
            'product_name': p['product_name'],
            'total_amount': p['total_amount'],
            'product_stock': p['product_stock'],
          });
        }
      }

      setState(() {
        product = banklist;
        _applyFilter(); // refresh filter after fetch
      });
    } catch (err) {
    }
  }

  void _onSearchChanged() => _applyFilter();

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredProduct = List.from(product);
      } else {
        filteredProduct = product
            .where((p) => (p['product_name'] ?? '')
                .toString()
                .toLowerCase()
                .contains(query))
            .toList();
      }
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: startDate!, end: endDate!),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      _fetchReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Totals
    int totalQuantity = 0;
    int totalStockLeft = 0;
    double totalAmountPaid = 0;
    for (var p in filteredProduct) {
      totalQuantity += int.tryParse(p['quantity'].toString()) ?? 0;
      totalStockLeft += int.tryParse(p['product_stock'].toString()) ?? 0;
      totalAmountPaid += (p['total_amount'] ?? 0).toDouble();
    }

    // Heading date/range
    final df = DateFormat('dd-MM-yyyy');
    String headingDate = '';
    if (startDate != null && endDate != null) {
      headingDate = df.format(startDate!) == df.format(endDate!)
          ? df.format(startDate!)
          : '${df.format(startDate!)} → ${df.format(endDate!)}';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Daily Product Sale Report",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ),
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // -------- Search Bar ----------
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search product name',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // -------- Product List + Summary ----------
          Expanded(
            child: filteredProduct.isEmpty
                ? const Center(child: Text('No products found'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredProduct.length,
                    itemBuilder: (context, index) {
                      final p = filteredProduct[index];
                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['product_name'] ?? '',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Table(
                                border: TableBorder.all(
                                    color: Colors.grey.shade300, width: 1),
                                columnWidths: const {
                                  0: FlexColumnWidth(2),
                                  1: FlexColumnWidth(3),
                                },
                                children: [
                                  _tableRow('Order Date', p['order_date']),
                                  // Quantity → green label and value
                                  _tableRow(
                                    'Quantity Sold',
                                    p['quantity'].toString(),
                                    labelColor: Colors.green,
                                    valueColor: Colors.green,
                                    labelWeight: FontWeight.bold,
                                    valueWeight: FontWeight.bold,
                                  ),
                                  _tableRow('Stock Left',
                                      p['product_stock'].toString()),
                                  // Total Amount → green label and value
                                  _tableRow(
                                    'Total Amount',
                                    '₹${p['total_amount']}',
                                    labelColor: Colors.green,
                                    valueColor: Colors.green,
                                    labelWeight: FontWeight.bold,
                                    valueWeight: FontWeight.bold,
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // ===== Summary Card =====
          Card(
            color: const Color.fromARGB(255, 12, 80, 163),
            margin: const EdgeInsets.symmetric(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Summary ($headingDate)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.date_range, color: Colors.white),
                        onPressed: _pickDateRange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Table(
                    border: TableBorder.all(color: Colors.white, width: 1),
                    columnWidths: const {
                      0: FlexColumnWidth(),
                      1: FlexColumnWidth(),
                    },
                    children: [
                      _summaryRow('Total Quantity Sold', '$totalQuantity'),
                      // _summaryRow('Total Stock Left', '$totalStockLeft'),
                      _summaryRow(
                        'Total Amount',
                        '₹${totalAmountPaid.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                  SizedBox(height: 35),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Helpers ----
  TableRow _tableRow(
    String label,
    String value, {
    Color? labelColor,
    FontWeight? labelWeight,
    Color? valueColor,
    FontWeight? valueWeight,
  }) {
    return TableRow(
      children: [
        _cell(label, labelColor ?? Colors.black54,
            labelWeight ?? FontWeight.w600),
        _cell(value, valueColor ?? Colors.black87,
            valueWeight ?? FontWeight.w500),
      ],
    );
  }

  TableRow _summaryRow(String label, String value,
      {Color? valueColor, FontWeight? valueWeight}) {
    return TableRow(children: [
      _cell(label, Colors.white, FontWeight.w600),
      _cell(value, valueColor ?? Colors.white, valueWeight ?? FontWeight.w500),
    ]);
  }

  Widget _cell(String text, Color color, FontWeight weight) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(text, style: TextStyle(color: color, fontWeight: weight)),
    );
  }
}
