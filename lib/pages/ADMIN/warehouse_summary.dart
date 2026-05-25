import 'dart:convert';
import 'package:beposoft/pages/ACCOUNTS/product_list.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WarehouseSummaryScreen extends StatefulWidget {
  const WarehouseSummaryScreen({super.key});

  @override
  State<WarehouseSummaryScreen> createState() => _WarehouseSummaryScreenState();
}

class _WarehouseSummaryScreenState extends State<WarehouseSummaryScreen> {
  static const Color primaryBlue = Color(0xFF0F3D75);
  static const Color darkText = Color(0xFF111827);

  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic> summaryData = {};
  String warehouseName = "";

  @override
  void initState() {
    super.initState();
    fetchWarehouseSummary();
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getWarehouseFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? warehouseId = prefs.getInt('warehouse');
    return warehouseId?.toString();
  }

  Future<void> fetchWarehouseSummary() async {
    final String? token = await getTokenFromPrefs();
    final String? warehouseId = await getWarehouseFromPrefs();

    if (warehouseId == null || warehouseId.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = "Warehouse not found";
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("$api/api/warehouse/products/gets/$warehouseId/"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final results = parsed['results'];

        if (results is Map && results['summary'] is Map) {
          setState(() {
            summaryData = Map<String, dynamic>.from(results['summary']);
            warehouseName =
                results['warehouse_name']?.toString() ?? "Warehouse";
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage = "No summary data available";
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "Failed to load warehouse summary";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error: $e";
      });
    }
  }

  String _formatNumber(dynamic value) {
    if (value == null) return "0";
    final double number = value is num
        ? value.toDouble()
        : double.tryParse(value.toString()) ?? 0;
    if (number == number.toInt()) {
      return number.toInt().toString();
    }
    return number.toStringAsFixed(2);
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return "₹0";
    final double amount = value is num
        ? value.toDouble()
        : double.tryParse(value.toString()) ?? 0;
    return "₹${amount.toStringAsFixed(2)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF02347C), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          warehouseName.isNotEmpty ? warehouseName : "Warehouse Summary",
          style: const TextStyle(
            color: Color(0xFF02347C),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF02347C)),
            onPressed: () {
              setState(() {
                isLoading = true;
                errorMessage = null;
              });
              fetchWarehouseSummary();
            },
          ),
        ],
      ),
      body: isLoading
          ? _buildLoadingView()
          : errorMessage != null
              ? _buildErrorView()
              : _buildSummaryContent(),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF02347C)),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 60),
          const SizedBox(height: 16),
          Text(
            errorMessage!,
            style: const TextStyle(fontSize: 16, color: darkText),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                isLoading = true;
                errorMessage = null;
              });
              fetchWarehouseSummary();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF02347C),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Retry", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryContent() {
    final damagedSummary = summaryData['damaged_stock_summary'] as Map? ?? {};
    final partiallyDamagedSummary =
        summaryData['partially_damaged_stock_summary'] as Map? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Main Warehouse Summary Card with Gradient
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF02347C), Color(0xFF82E49D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade100,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Header Row
                Row(
                  children: [
                    const Icon(Icons.warehouse, color: Colors.white, size: 15),
                    const SizedBox(width: 8),
                    Text(
                      warehouseName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Row(
                  children: [
                    const Icon(Icons.summarize, color: Colors.white, size: 15),
                    const SizedBox(width: 8),
                    const Text(
                      "Warehouse Stock Summary",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white60),
                const SizedBox(height: 6),

                /// Main Summary Table
                Table(
                  border: TableBorder.all(color: Colors.white, width: 1),
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1),
                  },
                  children: [
                    /// Table Header
                    const TableRow(
                      decoration: const BoxDecoration(color: Colors.black26),
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(6),
                          child: Text("Metric",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(6),
                          child: Text("Total",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(6),
                          child: Text("Single",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(6),
                          child: Text("Variant",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                      ],
                    ),

                    /// Total Products Row
                    _buildTableRow(
                      label: "Total Products",
                      total: _formatNumber(summaryData['total_products']),
                      single:
                          _formatNumber(summaryData['single_product_count']),
                      variant:
                          _formatNumber(summaryData['variant_product_count']),
                    ),

                    /// Total Stock Row
                    _buildTableRow(
                      label: "Total Stock",
                      total: _formatNumber(summaryData['total_stock']),
                      single: _formatNumber(summaryData['single_stock']),
                      variant: _formatNumber(summaryData['variant_stock']),
                    ),

                    /// Locked Stock Row
                    _buildTableRow(
                      label: "Locked Stock",
                      total: _formatNumber(summaryData['total_locked_stock']),
                      single: _formatNumber(summaryData['single_locked_stock']),
                      variant:
                          _formatNumber(summaryData['variant_locked_stock']),
                    ),

                    /// Retail Amount Row
                    _buildTableRow(
                      label: "Retail Amount",
                      total:
                          _formatCurrency(summaryData['total_retail_amount']),
                      single:
                          _formatCurrency(summaryData['single_retail_amount']),
                      variant:
                          _formatCurrency(summaryData['variant_retail_amount']),
                    ),

                    /// Selling Amount Row
                    _buildTableRow(
                      label: "Selling Amount",
                      total:
                          _formatCurrency(summaryData['total_selling_amount']),
                      single:
                          _formatCurrency(summaryData['single_selling_amount']),
                      variant: _formatCurrency(
                          summaryData['variant_selling_amount']),
                    ),

                    /// Landing Cost Row
                    _buildTableRow(
                      label: "Landing Cost",
                      total: _formatCurrency(
                          summaryData['total_landing_cost_amount']),
                      single: _formatCurrency(
                          summaryData['single_landing_cost_amount']),
                      variant: _formatCurrency(
                          summaryData['variant_landing_cost_amount']),
                    ),

                    /// Exclude Price Row
                    _buildTableRow(
                      label: "Exclude Price",
                      total: _formatCurrency(
                          summaryData['total_exclude_price_amount']),
                      single: _formatCurrency(
                          summaryData['single_exclude_price_amount']),
                      variant: _formatCurrency(
                          summaryData['variant_exclude_price_amount']),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// Damaged Stock Card
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF02347C), Color(0xFF82E49D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.shade100,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    const Icon(Icons.warning_rounded,
                        color: Colors.white, size: 15),
                    const SizedBox(width: 8),
                    const Text(
                      "Damaged Stock Summary",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white60),
                const SizedBox(height: 6),
                Table(
                  border: TableBorder.all(color: Colors.white, width: 1),
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1),
                  },
                  children: [
                    const TableRow(
                      decoration: const BoxDecoration(color: Colors.black26),
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(6),
                          child: Text("Metric",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(6),
                          child: Text("Total",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(6),
                          child: Text("Single",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(6),
                          child: Text("Variant",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                      ],
                    ),
                    _buildTableRow(
                      label: "Damaged Stock",
                      total: _formatNumber(summaryData['damaged_stock_summary']
                              ?['total_damaged_stock'] ??
                          0),
                      single: _formatNumber(summaryData['damaged_stock_summary']
                              ?['single_damaged_stock'] ??
                          0),
                      variant: _formatNumber(
                          summaryData['damaged_stock_summary']
                                  ?['variant_damaged_stock'] ??
                              0),
                    ),
                    _buildTableRow(
                      label: "Damaged Retail",
                      total: _formatCurrency(
                          summaryData['damaged_stock_summary']
                                  ?['total_damaged_retail_amount'] ??
                              0),
                      single: "",
                      variant: "",
                    ),
                    _buildTableRow(
                      label: "Damaged Selling",
                      total: _formatCurrency(
                          summaryData['damaged_stock_summary']
                                  ?['total_damaged_selling_amount'] ??
                              0),
                      single: "",
                      variant: "",
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// Partially Damaged Stock Card
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF02347C), Color(0xFF82E49D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.shade100,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    const Icon(Icons.report_problem_rounded,
                        color: Colors.white, size: 15),
                    const SizedBox(width: 8),
                    const Text(
                      "Partially Damaged Stock Summary",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white60),
                const SizedBox(height: 6),
                Table(
                  border: TableBorder.all(color: Colors.white, width: 1),
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1),
                  },
                  children: [
                    const TableRow(
                      decoration: const BoxDecoration(color: Colors.black26),
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(6),
                          child: Text("Metric",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(6),
                          child: Text("Total",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(6),
                          child: Text("Single",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(6),
                          child: Text("Variant",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                      ],
                    ),
                    _buildTableRow(
                      label: "Partial Stock",
                      total: _formatNumber(
                          summaryData['partially_damaged_stock_summary']
                                  ?['total_partially_damaged_stock'] ??
                              0),
                      single: _formatNumber(
                          summaryData['partially_damaged_stock_summary']
                                  ?['single_partially_damaged_stock'] ??
                              0),
                      variant: _formatNumber(
                          summaryData['partially_damaged_stock_summary']
                                  ?['variant_partially_damaged_stock'] ??
                              0),
                    ),
                    _buildTableRow(
                      label: "Partial Retail",
                      total: _formatCurrency(
                          summaryData['partially_damaged_stock_summary']
                                  ?['total_partially_damaged_retail_amount'] ??
                              0),
                      single: "",
                      variant: "",
                    ),
                    _buildTableRow(
                      label: "Partial Selling",
                      total: _formatCurrency(
                          summaryData['partially_damaged_stock_summary']
                                  ?['total_partially_damaged_selling_amount'] ??
                              0),
                      single: "",
                      variant: "",
                    ),
                    _buildTableRow(
                      label: "Partial Landing",
                      total: _formatCurrency(summaryData[
                                  'partially_damaged_stock_summary']?[
                              'total_partially_damaged_landing_cost_amount'] ??
                          0),
                      single: "",
                      variant: "",
                    ),
                    _buildTableRow(
                      label: "Partial Exclude",
                      total: _formatCurrency(summaryData[
                                  'partially_damaged_stock_summary']?[
                              'total_partially_damaged_exclude_price_amount'] ??
                          0),
                      single: "",
                      variant: "",
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// View Products Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Product_List()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF02347C),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "View All Products",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow({
    required String label,
    required String total,
    required String single,
    required String variant,
  }) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            total,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            single.isEmpty || single == "0" || single == "₹0" ? "-" : single,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            variant.isEmpty || variant == "0" || variant == "₹0"
                ? "-"
                : variant,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
