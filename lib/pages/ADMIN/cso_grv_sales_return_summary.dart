import 'dart:convert';
import 'dart:io';

import 'package:beposoft/pages/ACCOUNTS/grv_list.dart';
import 'package:beposoft/pages/api.dart';
import 'package:excel/excel.dart' as ex;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CsoGrvFamilyPaymentSummaryPage extends StatefulWidget {
  final dynamic status;

  const CsoGrvFamilyPaymentSummaryPage({super.key, this.status});

  @override
  State<CsoGrvFamilyPaymentSummaryPage> createState() =>
      _CsoGrvFamilyPaymentSummaryPageState();
}

class _CsoGrvFamilyPaymentSummaryPageState
    extends State<CsoGrvFamilyPaymentSummaryPage> {
  bool isLoading = true;
  String? errorMessage;

  Map<String, dynamic> summaryData = {};

  List<Map<String, dynamic>> todayFamilies = [];
  Map<String, dynamic> todayGrandTotal = {};

  List<Map<String, dynamic>> monthFamilies = [];
  Map<String, dynamic> monthGrandTotal = {};

  String selectedTab = "today";

  DateTimeRange? selectedDateRange;
  String fromDate = "";
  String toDate = "";

@override
void initState() {
  super.initState();

  final now = DateTime.now();

  fromDate = DateFormat('yyyy-MM-dd').format(now);
  toDate = DateFormat('yyyy-MM-dd').format(now);
  selectedDateRange = DateTimeRange(start: now, end: now);

  fetchGrvSummary();
}

  Future<String?> getTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _asDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _formatAmount(dynamic value) {
    final amount = _asDouble(value);
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(amount);
  }

 Future<void> fetchGrvSummary() async {
  if (!mounted) return;

  setState(() {
    isLoading = true;
    errorMessage = null;
  });

  try {
    final token = await getTokenFromPrefs();

    final uri = Uri.parse('$api/api/grv/family/payment/summary/without/bepocart/').replace(
      queryParameters: {
        'start_date': fromDate,
        'end_date': toDate,
      },
    );

    debugPrint("GRV SUMMARY URL: $uri");

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    debugPrint("GRV SUMMARY STATUS: ${response.statusCode}");
    debugPrint("GRV SUMMARY BODY: ${response.body}");

    if (!mounted) return;

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      setState(() {
        summaryData = Map<String, dynamic>.from(decoded);

        todayFamilies = List<Map<String, dynamic>>.from(
          (decoded['families'] ?? []).map(
            (item) => Map<String, dynamic>.from(item),
          ),
        );

        todayGrandTotal = Map<String, dynamic>.from(
          decoded['grand_total'] ?? {},
        );

        monthFamilies = todayFamilies;
        monthGrandTotal = todayGrandTotal;

        selectedTab = "today";
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
        errorMessage = "Failed to load data";
      });
    }
  } catch (e) {
    debugPrint("GRV SUMMARY ERROR: $e");

    if (!mounted) return;

    setState(() {
      isLoading = false;
      errorMessage = "Something went wrong";
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
              primary: Color(0xFF1565C0),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF111827),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      selectedDateRange = picked;
      fromDate = DateFormat('yyyy-MM-dd').format(picked.start);
      toDate = DateFormat('yyyy-MM-dd').format(picked.end);
    });

    await fetchGrvSummary();
  }

  List<Map<String, dynamic>> get activeFamilies {
    return selectedTab == "today" ? todayFamilies : monthFamilies;
  }

  Map<String, dynamic> get activeGrandTotal {
    return selectedTab == "today" ? todayGrandTotal : monthGrandTotal;
  }

ex.CellStyle _excelStyle({
  String backgroundColorHex = '#FFFFFF',
  String fontColorHex = '#111827',
  bool bold = false,
  int? fontSize,
}) {
  final border = ex.Border(borderStyle: ex.BorderStyle.Thin);

  return ex.CellStyle(
    backgroundColorHex: backgroundColorHex,
    fontColorHex: fontColorHex,
    fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
    bold: bold,
    fontSize: fontSize ?? 11,
    horizontalAlign: ex.HorizontalAlign.Center,
    verticalAlign: ex.VerticalAlign.Center,
    leftBorder: border,
    rightBorder: border,
    topBorder: border,
    bottomBorder: border,
  );
}

Future<void> exportToExcel() async {
  try {
    if (activeFamilies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("No data available to export"),
        ),
      );
      return;
    }

    final excel = ex.Excel.createExcel();

    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null) {
      excel.delete(defaultSheet);
    }

    final sheet = excel['SALES RETURN SUMMARY'];

    sheet.setColWidth(0, 22);
    sheet.setColWidth(1, 12);
    sheet.setColWidth(2, 12);
    sheet.setColWidth(3, 16);
    sheet.setColWidth(4, 16);
    sheet.setColWidth(5, 12);
    sheet.setColWidth(6, 15);
    sheet.setColWidth(7, 18);

    final titleStyle = _excelStyle(
      backgroundColorHex: '#1565C0',
      fontColorHex: '#FFFFFF',
      bold: true,
      fontSize: 16,
    );

    final subTitleStyle = _excelStyle(
      backgroundColorHex: '#EAF3FF',
      fontColorHex: '#111827',
      bold: true,
      fontSize: 11,
    );

    final headerStyle = _excelStyle(
      backgroundColorHex: '#1565C0',
      fontColorHex: '#FFFFFF',
      bold: true,
      fontSize: 11,
    );

    final normalStyle = _excelStyle(
      backgroundColorHex: '#FFFFFF',
      fontColorHex: '#111827',
      fontSize: 11,
    );

    final familyStyle = _excelStyle(
      backgroundColorHex: '#FFFFFF',
      fontColorHex: '#111827',
      bold: true,
      fontSize: 11,
    );

    final grandTotalStyle = _excelStyle(
      backgroundColorHex: '#DCEBFF',
      fontColorHex: '#111827',
      bold: true,
      fontSize: 11,
    );

    String excelAmount(dynamic value) {
      final amount = _asDouble(value);
      return amount.toStringAsFixed(2);
    }

    void setCell(
      int col,
      int row,
      String value,
      ex.CellStyle style,
    ) {
      final cell = sheet.cell(
        ex.CellIndex.indexByColumnRow(
          columnIndex: col,
          rowIndex: row,
        ),
      );

      cell.value = value;
      cell.cellStyle = style;
    }

    int row = 0;

    setCell(
      0,
      row,
      'SALES RETURN SUMMARY',
      titleStyle,
    );

    sheet.merge(
      ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      ex.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row),
    );

    row++;

    final periodText = selectedDateRange != null
        ? 'Period: $fromDate to $toDate'
        : 'Date: ${summaryData['date'] ?? ''}';

    setCell(
      0,
      row,
      periodText,
      subTitleStyle,
    );

    for (int col = 1; col <= 7; col++) {
      setCell(col, row, '', subTitleStyle);
    }

    sheet.merge(
      ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      ex.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row),
    );

    row++;

    final headers = <String>[
      'Division',
      'COD SR',
      'Cash SR',
      'COD Amount',
      'Cash Amount',
      'Total SR',
      'Total Invoice',
      'Total Amount',
    ];

    for (int col = 0; col < headers.length; col++) {
      setCell(col, row, headers[col], headerStyle);
    }

    row++;

    for (final item in activeFamilies) {
      final paid = item['paid'] is Map
          ? Map<String, dynamic>.from(item['paid'])
          : <String, dynamic>{};

      final cod = item['COD'] is Map
          ? Map<String, dynamic>.from(item['COD'])
          : <String, dynamic>{};

      final total = item['total'] is Map
          ? Map<String, dynamic>.from(item['total'])
          : <String, dynamic>{};

      final rowValues = <String>[
        item['family_name']?.toString().toUpperCase() ?? '',
        _asInt(cod['grv_count']).toString(),
        _asInt(paid['grv_count']).toString(),
        excelAmount(cod['order_amount']),
        excelAmount(paid['order_amount']),
        _asInt(total['grv_count']).toString(),
        _asInt(total['order_count']).toString(),
        excelAmount(total['order_amount']),
      ];

      for (int col = 0; col < rowValues.length; col++) {
        setCell(
          col,
          row,
          rowValues[col],
          col == 0 ? familyStyle : normalStyle,
        );
      }

      row++;
    }

    final paidTotal = activeGrandTotal['paid'] is Map
        ? Map<String, dynamic>.from(activeGrandTotal['paid'])
        : <String, dynamic>{};

    final codTotal = activeGrandTotal['COD'] is Map
        ? Map<String, dynamic>.from(activeGrandTotal['COD'])
        : <String, dynamic>{};

    final total = activeGrandTotal['total'] is Map
        ? Map<String, dynamic>.from(activeGrandTotal['total'])
        : <String, dynamic>{};

    final grandValues = <String>[
      'GRAND TOTAL',
      _asInt(codTotal['grv_count']).toString(),
      _asInt(paidTotal['grv_count']).toString(),
      excelAmount(codTotal['order_amount']),
      excelAmount(paidTotal['order_amount']),
      _asInt(total['grv_count']).toString(),
      _asInt(total['order_count']).toString(),
      excelAmount(total['order_amount']),
    ];

    for (int col = 0; col < grandValues.length; col++) {
      setCell(
        col,
        row,
        grandValues[col],
        grandTotalStyle,
      );
    }

    final fileBytes = excel.encode();
    if (fileBytes == null || fileBytes.isEmpty) {
      throw Exception('Excel generation failed');
    }

    final directory = await getTemporaryDirectory();

    final fileName =
        'grv_${selectedTab}_summary_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

    final file = File('${directory.path}/$fileName');

    if (await file.exists()) {
      await file.delete();
    }

    await file.writeAsBytes(fileBytes, flush: true);

    await OpenFilex.open(file.path);
  } catch (e) {
    debugPrint('GRV EXCEL EXPORT ERROR: $e');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text('Excel Export Failed: $e'),
      ),
    );
  }
}
  Widget _buildTabButton(String label, String value) {
    final isSelected = selectedTab == value;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            selectedTab = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1565C0) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1565C0)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF1565C0),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final paid = activeGrandTotal['paid'] ?? {};
    final cod = activeGrandTotal['COD'] ?? {};
    final total = activeGrandTotal['total'] ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF56AFFF), Color(0xFF2C74FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C74FF).withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Grand Total",
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _summaryTile("COD SR", "${_asInt(cod['grv_count'])}"),
              const SizedBox(width: 8),
              _summaryTile("Cash SR", "${_asInt(paid['grv_count'])}"),
              const SizedBox(width: 8),
              _summaryTile("Total SR", "${_asInt(total['grv_count'])}"),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _summaryTile("Invoice", "${_asInt(total['order_count'])}"),
              const SizedBox(width: 8),
              _summaryTile("Amount", _formatAmount(total['order_amount'])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.26)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

Widget _buildTable() {
  if (activeFamilies.isEmpty) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          "No GRV summary found",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  return InkWell(
    borderRadius: BorderRadius.circular(18),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GrvList(status: widget.status),
        ),
      );
    },
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(
              const Color(0xFF1565C0),
            ),
            dataRowMinHeight: 48,
            dataRowMaxHeight: 56,
            headingTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            dataTextStyle: const TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            columns: const [
              DataColumn(label: Text("Division")),
              DataColumn(label: Text("COD SR")),
              DataColumn(label: Text("Cash SR")),
              DataColumn(label: Text("COD Amt")),
              DataColumn(label: Text("Cash Amt")),
              DataColumn(label: Text("Total SR")),
              DataColumn(label: Text("Invoice")),
              DataColumn(label: Text("Amount")),
            ],
            rows: [
              ...activeFamilies.map((item) {
                final paid = item['paid'] ?? {};
                final cod = item['COD'] ?? {};
                final total = item['total'] ?? {};

                return DataRow(
                  cells: [
                    DataCell(
                      Text(item['family_name'].toString().toUpperCase()),
                    ),
                    DataCell(Text("${_asInt(cod['grv_count'])}")),
                    DataCell(Text("${_asInt(paid['grv_count'])}")),
                    DataCell(Text(_formatAmount(cod['order_amount']))),
                    DataCell(Text(_formatAmount(paid['order_amount']))),
                    DataCell(Text("${_asInt(total['grv_count'])}")),
                    DataCell(Text("${_asInt(total['order_count'])}")),
                    DataCell(Text(_formatAmount(total['order_amount']))),
                  ],
                );
              }),
              _grandTotalRow(),
            ],
          ),
        ),
      ),
    ),
  );
}

  DataRow _grandTotalRow() {
    final paid = activeGrandTotal['paid'] ?? {};
    final cod = activeGrandTotal['COD'] ?? {};
    final total = activeGrandTotal['total'] ?? {};

    return DataRow(
      color: MaterialStateProperty.all(const Color(0xFFEAF3FF)),
      cells: [
        const DataCell(
          Text(
            "GRAND TOTAL",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        DataCell(Text("${_asInt(cod['grv_count'])}")),
        DataCell(Text("${_asInt(paid['grv_count'])}")),
        DataCell(Text(_formatAmount(cod['order_amount']))),
        DataCell(Text(_formatAmount(paid['order_amount']))),
        DataCell(Text("${_asInt(total['grv_count'])}")),
        DataCell(Text("${_asInt(total['order_count'])}")),
        DataCell(Text(_formatAmount(total['order_amount']))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = summaryData['date']?.toString() ?? '';

    final displayDate = selectedDateRange != null ? "$fromDate to $toDate" : date;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Sales Return Summary",
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Select Date Range",
            icon: const Icon(
              Icons.calendar_month_outlined,
              color: Color(0xFF1565C0),
            ),
            onPressed: pickDateRange,
          ),
          IconButton(
            tooltip: "Export Excel",
            icon: const Icon(
              Icons.file_download_outlined,
              color: Color(0xFF1565C0),
            ),
            onPressed: isLoading ? null : exportToExcel,
          ),
          IconButton(
            tooltip: "Refresh",
            icon: const Icon(
              Icons.refresh,
              color: Color(0xFF1565C0),
            ),
            onPressed: fetchGrvSummary,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchGrvSummary,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (displayDate.isNotEmpty)
                          Text(
                            selectedDateRange != null
                                ? "Period: $displayDate"
                                : "Date: $displayDate",
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: 12),
                        // Row(
                        //   children: [
                        //     _buildTabButton("Today", "today"),
                        //     const SizedBox(width: 10),
                        //     _buildTabButton("Current Month", "month"),
                        //   ],
                        // ),
                        // const SizedBox(height: 16),
                        _buildSummaryCard(),
                        _buildTable(),
                      ],
                    ),
                  ),
      ),
    );
  }
}