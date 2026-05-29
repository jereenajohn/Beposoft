import 'dart:convert';
import 'dart:io';

import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:excel/excel.dart' as ex;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductStockReportPage extends StatefulWidget {
  final int warehouseId;
  final String fromDate;
  final String toDate;

  const ProductStockReportPage({
    super.key,
    required this.warehouseId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  State<ProductStockReportPage> createState() => _ProductStockReportPageState();
}

class _ProductStockReportPageState extends State<ProductStockReportPage> {
  static const Color primaryBlue = Color(0xFF02347C);
  static const Color lightBg = Color(0xFFF4F7FB);

  bool isLoading = true;
  String? errorMessage;

  String warehouseName = "";
  int count = 0;

  Map<String, dynamic> summary = {};
  List<Map<String, dynamic>> stockList = [];

  final TextEditingController searchController = TextEditingController();
  String searchText = "";

  late String selectedFromDate;
  late String selectedToDate;
  DateTimeRange? selectedDateRange;

  @override
  void initState() {
    super.initState();

    selectedFromDate = widget.fromDate;
    selectedToDate = widget.toDate;

    selectedDateRange = DateTimeRange(
      start: DateTime.parse(widget.fromDate),
      end: DateTime.parse(widget.toDate),
    );

    fetchProductStockReport();
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

   Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();
   if(dep=="BDO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => bdo_dashbord()), // Replace AnotherPage with your target page
            );

}
else if(dep=="BDM" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => bdm_dashbord()), // Replace AnotherPage with your target page
            );
}
else if(dep=="warehouse" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => WarehouseDashboard()), // Replace AnotherPage with your target page
            );
}
else if(dep=="CEO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ceo_dashboard()), // Replace AnotherPage with your target page
            );
}
else if(dep=="COO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ceo_dashboard()), // Replace AnotherPage with your target page
            );
}


else if(dep=="Warehouse Admin" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => WarehouseAdmin()), // Replace AnotherPage with your target page
            );
}else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => dashboard()),
      );
    }
  }

  Future<void> downloadProductStockExcelReport() async {
    try {
      if (stockList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("No data available to export"),
          ),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text("Generating Excel file..."),
                ],
              ),
            ),
          ),
        ),
      );

      var excel = ex.Excel.createExcel();

      final defaultSheet = excel.getDefaultSheet();
      if (defaultSheet != null) {
        excel.delete(defaultSheet);
      }

      ex.Sheet sheet = excel["Product Stock Report"];

      sheet.setColWidth(0, 45);
      sheet.setColWidth(1, 18);
      sheet.setColWidth(2, 16);

      final ex.Border thinBorder = ex.Border(
        borderStyle: ex.BorderStyle.Thin,
      );

      final ex.CellStyle titleStyle = ex.CellStyle(
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        fontSize: 16,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle infoStyle = ex.CellStyle(
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        fontSize: 11,
        horizontalAlign: ex.HorizontalAlign.Left,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle headerStyle = ex.CellStyle(
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        fontSize: 11,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        textWrapping: ex.TextWrapping.WrapText,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle leftStyle = ex.CellStyle(
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        fontSize: 10,
        horizontalAlign: ex.HorizontalAlign.Left,
        verticalAlign: ex.VerticalAlign.Center,
        textWrapping: ex.TextWrapping.WrapText,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle centerStyle = ex.CellStyle(
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        fontSize: 10,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        textWrapping: ex.TextWrapping.WrapText,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle summaryLabelStyle = ex.CellStyle(
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        fontSize: 11,
        horizontalAlign: ex.HorizontalAlign.Left,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle summaryValueStyle = ex.CellStyle(
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        fontSize: 11,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      void setCellValueStyle(
        int col,
        int row,
        String value,
        ex.CellStyle style,
      ) {
        final cell = sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
        );
        cell.value = value;
        cell.cellStyle = style;
      }

      void fillRangeStyle(
        int startCol,
        int endCol,
        int row,
        ex.CellStyle style, {
        String? firstValue,
      }) {
        for (int c = startCol; c <= endCol; c++) {
          final cell = sheet.cell(
            ex.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row),
          );
          cell.value = (c == startCol && firstValue != null) ? firstValue : "";
          cell.cellStyle = style;
        }
      }

      int rowIndex = 0;

      final headers = [
        "PRODUCT NAME",
        "UNIT",
        "STOCK",
      ];

      for (int i = 0; i < headers.length; i++) {
        setCellValueStyle(i, rowIndex, headers[i], headerStyle);
      }

      rowIndex++;

      for (int i = 0; i < stockList.length; i++) {
        final item = stockList[i];

        setCellValueStyle(
          0,
          rowIndex,
          item["product_name"]?.toString() ?? "-",
          leftStyle,
        );

        setCellValueStyle(
          1,
          rowIndex,
          item["units"]?.toString() ?? "-",
          centerStyle,
        );

        setCellValueStyle(
          2,
          rowIndex,
          _formatNumber(item["stock"]),
          centerStyle,
        );

        rowIndex++;
      }

      rowIndex++;

      setCellValueStyle(0, rowIndex, "SUMMARY", headerStyle);
      setCellValueStyle(1, rowIndex, "VALUE", headerStyle);

      rowIndex++;

      final summaryData = [
        ["TOTAL PRODUCTS", _formatNumber(summary["total_products"])],
        ["TOTAL STOCK", _formatNumber(summary["total_stock"])],
        ["SINGLE STOCK", _formatNumber(summary["single_stock"])],
        ["VARIANT STOCK", _formatNumber(summary["variant_stock"])],
        ["TOTAL RECORDS", count.toString()],
      ];

      for (final item in summaryData) {
        setCellValueStyle(0, rowIndex, item[0], summaryLabelStyle);
        setCellValueStyle(1, rowIndex, item[1], summaryValueStyle);
        rowIndex++;
      }

      final fileBytes = excel.encode();

      final tempDir = await getTemporaryDirectory();

      final filePath =
          "${tempDir.path}/Product_Stock_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx";

      final file = File(filePath);
      await file.writeAsBytes(fileBytes!, flush: true);

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Excel exported successfully"),
        ),
      );

      await Share.shareXFiles(
        [XFile(file.path)],
        text: "Product Stock Report",
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Excel Export Failed: $e"),
        ),
      );
    }
  }

  Future<void> fetchProductStockReport() async {
    final token = await getTokenFromPrefs();

    if (token == null || token.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = "Token not found";
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final uri = Uri.parse(
        "$api/api/product/stock/excel/export/${widget.warehouseId}/$selectedFromDate/$selectedToDate/",
      ).replace(
        queryParameters: searchText.trim().isEmpty
            ? null
            : {
                "search": searchText.trim(),
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

        if (decoded["status"] == true) {
          final List results = decoded["results"] ?? [];

          setState(() {
            warehouseName = decoded["warehouse_name"]?.toString() ?? "";
            count = _asInt(decoded["count"]);
            summary = Map<String, dynamic>.from(decoded["summary"] ?? {});
            stockList =
                results.map((e) => Map<String, dynamic>.from(e)).toList();
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage =
                decoded["message"]?.toString() ?? "Failed to fetch data";
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "Failed to fetch data. Status: ${response.statusCode}";
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
    final number = _asInt(value);
    return number.toString();
  }

  Widget _buildSummaryBox({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> pickDateRange() async {
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(now.year + 1),
      initialDateRange: selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDateRange = DateTimeRange(
          start: DateTime(
            picked.start.year,
            picked.start.month,
            picked.start.day,
          ),
          end: DateTime(
            picked.end.year,
            picked.end.month,
            picked.end.day,
          ),
        );

        selectedFromDate = DateFormat('yyyy-MM-dd').format(picked.start);
        selectedToDate = DateFormat('yyyy-MM-dd').format(picked.end);
      });

      fetchProductStockReport();
    }
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF02347C),
            Color(0xFF82E49D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  warehouseName.isEmpty
                      ? "Product Stock Report"
                      : warehouseName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: fetchProductStockReport,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "$selectedFromDate to $selectedToDate",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryBox(
                  title: "Products",
                  value: _formatNumber(summary["total_products"]),
                  icon: Icons.category_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryBox(
                  title: "Total Stock",
                  value: _formatNumber(summary["total_stock"]),
                  icon: Icons.warehouse_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSummaryBox(
                  title: "Single Stock",
                  value: _formatNumber(summary["single_stock"]),
                  icon: Icons.widgets_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryBox(
                  title: "Variant Stock",
                  value: _formatNumber(summary["variant_stock"]),
                  icon: Icons.account_tree_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterBox() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            color: primaryBlue,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "$selectedFromDate to $selectedToDate",
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ElevatedButton.icon(
            onPressed: pickDateRange,
            icon: const Icon(
              Icons.date_range_rounded,
              color: Colors.white,
              size: 16,
            ),
            label: const Text(
              "Filter",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: primaryBlue,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: "Search product name...",
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              onSubmitted: (value) {
                setState(() {
                  searchText = value.trim();
                });
                fetchProductStockReport();
              },
            ),
          ),
          if (searchController.text.trim().isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: Color(0xFF6B7280),
                size: 20,
              ),
              onPressed: () {
                searchController.clear();
                setState(() {
                  searchText = "";
                });
                fetchProductStockReport();
              },
            ),
          IconButton(
            icon: const Icon(
              Icons.tune_rounded,
              color: primaryBlue,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                searchText = searchController.text.trim();
              });
              fetchProductStockReport();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: primaryBlue,
      child: Row(
        children: const [
          Expanded(
            flex: 5,
            child: Padding(
              padding: EdgeInsets.all(9),
              child: Text(
                "Product Name",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(9),
              child: Text(
                "Unit",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(9),
              child: Text(
                "Stock",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> item, int index) {
    final productName = item["product_name"]?.toString() ?? "-";
    final unit = item["units"]?.toString() ?? "-";
    final stock = _formatNumber(item["stock"]);

    return Container(
      color: index.isEven ? Colors.white : const Color(0xFFF8FAFC),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Text(
                productName,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Text(
                unit,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Text(
                stock,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _asInt(item["stock"]) <= 0
                      ? Colors.red.shade700
                      : Colors.green.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    if (stockList.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Text(
            "No stock data found",
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            _buildTableHeader(),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stockList.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE5E7EB),
              ),
              itemBuilder: (context, index) {
                return _buildTableRow(stockList[index], index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(color: primaryBlue),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                color: Colors.red.shade400, size: 58),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? "Something went wrong",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: fetchProductStockReport,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text(
                "Retry",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: primaryBlue,
            size: 20,
          ),
          onPressed: () => _navigateBack(),
        ),
        title: const Text(
          "Product Stock Report",
          style: TextStyle(
            color: primaryBlue,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Export Excel",
            onPressed: downloadProductStockExcelReport,
            icon: const Icon(
              Icons.file_download_rounded,
              color: primaryBlue,
            ),
          ),
        ],
      ),
      body: isLoading
          ? _buildLoadingView()
          : errorMessage != null
              ? _buildErrorView()
              : RefreshIndicator(
                  color: primaryBlue,
                  onRefresh: fetchProductStockReport,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildSummaryCard(),
                        _buildDateFilterBox(),
                        _buildSearchBox(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  "Product Stock Details",
                                  style: TextStyle(
                                    color: Color(0xFF111827),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryBlue.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "$count Items",
                                  style: const TextStyle(
                                    color: primaryBlue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildTable(),
                      ],
                    ),
                  ),
                ),
    );
  }
}
