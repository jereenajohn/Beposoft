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

class ShippingAddressExcelReport extends StatefulWidget {
  final int warehouseId;
  final String fromDate;
  final String toDate;

  const ShippingAddressExcelReport({
    super.key,
    required this.warehouseId,
    required this.fromDate,
    required this.toDate,
  });

  @override
  State<ShippingAddressExcelReport> createState() =>
      _ShippingAddressExcelReportState();
}

class _ShippingAddressExcelReportState
    extends State<ShippingAddressExcelReport> {
  static const Color primaryBlue = Color(0xFF02347C);
  static const Color lightBg = Color(0xFFF4F7FB);

  bool isLoading = true;
  String? errorMessage;

  String warehouseName = "";
  int count = 0;

  List<Map<String, dynamic>> shippingAddressList = [];

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

    fetchShippingAddressReport();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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

  Future<void> downloadShippingAddressExcelReport() async {
    try {
      if (shippingAddressList.isEmpty) {
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

      ex.Sheet sheet = excel["Shipping Address Report"];

      sheet.setColWidth(0, 28);
      sheet.setColWidth(1, 28);
      sheet.setColWidth(2, 70);
      sheet.setColWidth(3, 22);
      sheet.setColWidth(4, 18);
      sheet.setColWidth(5, 16);

      final ex.Border thinBorder = ex.Border(
        borderStyle: ex.BorderStyle.Thin,
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
        horizontalAlign: ex.HorizontalAlign.Left,
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

      int rowIndex = 0;

      final headers = [
        "NAME",
        "BILL NAME",
        "ADDRESS",
        "STATE",
        "COUNTRY",
        "PIN CODE",
      ];

      for (int i = 0; i < headers.length; i++) {
        setCellValueStyle(i, rowIndex, headers[i], headerStyle);
      }

      rowIndex++;

      for (int i = 0; i < shippingAddressList.length; i++) {
        final item = shippingAddressList[i];

        setCellValueStyle(
          0,
          rowIndex,
          item["name"]?.toString() ?? "-",
          leftStyle,
        );

        setCellValueStyle(
          1,
          rowIndex,
          item["bill_name"]?.toString() ?? "-",
          leftStyle,
        );

        setCellValueStyle(
          2,
          rowIndex,
          item["address"]?.toString() ?? "-",
          leftStyle,
        );

        setCellValueStyle(
          3,
          rowIndex,
          item["state"]?.toString() ?? "-",
          centerStyle,
        );

        setCellValueStyle(
          4,
          rowIndex,
          item["country"]?.toString() ?? "-",
          centerStyle,
        );

        setCellValueStyle(
          5,
          rowIndex,
          item["pin_code"]?.toString() ?? "-",
          centerStyle,
        );

        rowIndex++;
      }

      rowIndex++;

      setCellValueStyle(0, rowIndex, "SUMMARY", headerStyle);
      setCellValueStyle(1, rowIndex, "VALUE", headerStyle);

      rowIndex++;

      final summaryData = [
        ["WAREHOUSE", warehouseName.isEmpty ? "-" : warehouseName],
        ["FROM DATE", selectedFromDate],
        ["TO DATE", selectedToDate],
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
          "${tempDir.path}/Shipping_Address_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx";

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
        text: "Shipping Address Report",
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

  Future<void> fetchShippingAddressReport() async {
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
        "$api/api/shipping/address/excel/export/${widget.warehouseId}/$selectedFromDate/$selectedToDate/",
      ).replace(
        queryParameters: searchText.trim().isEmpty
            ? null
            : {
                "search": searchText.trim(),
              },
      );

      debugPrint("SHIPPING ADDRESS REPORT URL: $uri");

      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      debugPrint("SHIPPING ADDRESS REPORT STATUS: ${response.statusCode}");
      debugPrint("SHIPPING ADDRESS REPORT BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded["status"] == true) {
          final List results = decoded["results"] ?? [];

          setState(() {
            warehouseName = decoded["warehouse_name"]?.toString() ?? "";
            count = _asInt(decoded["count"]);
            shippingAddressList =
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

      fetchShippingAddressReport();
    }
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
              const Icon(
                Icons.location_on_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  warehouseName.isEmpty
                      ? "Shipping Address Report"
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
                onPressed: fetchShippingAddressReport,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                ),
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
                  title: "Total Address",
                  value: count.toString(),
                  icon: Icons.list_alt_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryBox(
                  title: "Warehouse",
                  value: warehouseName.isEmpty ? "-" : warehouseName,
                  icon: Icons.warehouse_rounded,
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
                hintText: "Search....",
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
              onChanged: (_) {
                setState(() {});
              },
              onSubmitted: (value) {
                setState(() {
                  searchText = value.trim();
                });
                fetchShippingAddressReport();
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
                fetchShippingAddressReport();
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
              fetchShippingAddressReport();
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
            flex: 3,
            child: Padding(
              padding: EdgeInsets.all(9),
              child: Text(
                "Name",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.all(9),
              child: Text(
                "Bill Name",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Padding(
              padding: EdgeInsets.all(9),
              child: Text(
                "Address",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.all(9),
              child: Text(
                "State",
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
                "Country",
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
                "Pin Code",
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
    final name = item["name"]?.toString() ?? "-";
    final billName = item["bill_name"]?.toString() ?? "-";
    final address = item["address"]?.toString() ?? "-";
    final state = item["state"]?.toString() ?? "-";
    final country = item["country"]?.toString() ?? "-";
    final pinCode = item["pin_code"]?.toString() ?? "-";

    return Container(
      color: index.isEven ? Colors.white : const Color(0xFFF8FAFC),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Text(
                name,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Text(
                billName,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Text(
                address,
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Text(
                state,
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
                country,
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
                pinCode,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: primaryBlue,
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
    if (shippingAddressList.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Text(
            "No shipping address found",
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
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 980,
            child: Column(
              children: [
                _buildTableHeader(),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: shippingAddressList.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE5E7EB),
                  ),
                  itemBuilder: (context, index) {
                    return _buildTableRow(shippingAddressList[index], index);
                  },
                ),
              ],
            ),
          ),
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
            Icon(
              Icons.error_outline_rounded,
              color: Colors.red.shade400,
              size: 58,
            ),
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
              onPressed: fetchShippingAddressReport,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text(
                "Retry",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
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

  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              "Shipping Address Details",
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
    );
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
          "Shipping Address Report",
          style: TextStyle(
            color: primaryBlue,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Export Excel",
            onPressed: downloadShippingAddressExcelReport,
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
                  onRefresh: fetchShippingAddressReport,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildSummaryCard(),
                        _buildDateFilterBox(),
                        _buildSearchBox(),
                        _buildSectionTitle(),
                        _buildTable(),
                      ],
                    ),
                  ),
                ),
    );
  }
}