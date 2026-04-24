import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/MARKETING/marketing_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CyclingskatingCategoryDailyProductwiseReport extends StatefulWidget {
  const CyclingskatingCategoryDailyProductwiseReport({super.key});

  @override
  State<CyclingskatingCategoryDailyProductwiseReport> createState() =>
      _CyclingskatingCategoryDailyProductwiseReportState();
}

class _CyclingskatingCategoryDailyProductwiseReportState
    extends State<CyclingskatingCategoryDailyProductwiseReport> {
  List<Map<String, dynamic>> staffList = [];
  List<Map<String, dynamic>> reportData = [];
  List<Map<String, dynamic>> categoryList = [];
  bool _isCyclingLoading = false;
  bool _isSkatingLoading = false;
  bool _isBepocartLoading = false;

  List<Map<String, dynamic>> fam = [];

  DateTime? _startDate;
  DateTime? _endDate;

  String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Select Date";
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();
    if (dep == "BDO") {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => bdo_dashbord()));
    } else if (dep == "BDM") {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => bdm_dashbord()));
    } else if (dep == "CEO" || dep == "COO") {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => ceo_dashboard()));
    } else if (dep == "CSO") {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => cso_dashboard()));
    } else if (dep == "Marketing") {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => marketing_dashboard()));
    } else if (dep == "warehouse") {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => WarehouseDashboard()));
    } else if (dep == "Warehouse Admin") {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => WarehouseAdmin()));
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => dashboard()));
    }
  }

  String? _extractInvoice(Map<String, dynamic> order) {
    final v = order['invoice'] ??
        order['order_invoice'] ??
        (order['order'] is Map ? order['order']['invoice'] : null);
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateBack();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          elevation: 4,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _navigateBack,
          ),
          title: const Text(
            "Family Wise Excel Report",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Select Date Range",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 20),

                // 🗓️ Date pickers
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.date_range,
                          color: Colors.blueAccent),
                      label: Text(
                        _formatDate(_startDate),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black87),
                      ),
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2022),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _startDate = picked;
                            if (_endDate != null &&
                                _endDate!.isBefore(_startDate!)) {
                              _endDate = null;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    const Text("to"),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      icon: const Icon(Icons.date_range, color: Colors.teal),
                      label: Text(
                        _formatDate(_endDate),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black87),
                      ),
                      onPressed: _startDate == null
                          ? null
                          : () async {
                              // 🔒 Ensure the initial date does not exceed today
                              DateTime safeInitialDate;
                              if (_endDate != null) {
                                safeInitialDate = _endDate!;
                              } else {
                                final nextDay =
                                    _startDate!.add(const Duration(days: 1));
                                safeInitialDate =
                                    nextDay.isAfter(DateTime.now())
                                        ? DateTime.now()
                                        : nextDay;
                              }

                              // 🔒 Ensure the lastDate is always ≥ safeInitialDate
                              DateTime safeLastDate = DateTime.now();
                              if (safeLastDate.isBefore(safeInitialDate)) {
                                safeLastDate = safeInitialDate;
                              }

                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: safeInitialDate,
                                firstDate: _startDate!,
                                lastDate: safeLastDate,
                              );

                              if (picked != null) {
                                setState(() {
                                  _endDate = picked;
                                });
                              }
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                _buildReportButton(
                  icon: Icons.pedal_bike,
                  label: "Cycling Excel Report",
                  color: Colors.blueAccent,
                  isLoading: _isCyclingLoading,
                  onPressed: (_startDate == null || _endDate == null)
                      ? null
                      : () async {
                          setState(() => _isCyclingLoading = true);
                          await generateExcelReportFor("cycling");
                          if (mounted)
                            setState(() => _isCyclingLoading = false);
                        },
                ),
                const SizedBox(height: 20),

                _buildReportButton(
                  icon: Icons.ice_skating,
                  label: "Skating Excel Report",
                  color: Colors.teal,
                  isLoading: _isSkatingLoading,
                  onPressed: (_startDate == null || _endDate == null)
                      ? null
                      : () async {
                          setState(() => _isSkatingLoading = true);
                          await generateExcelReportFor("skating");
                          if (mounted)
                            setState(() => _isSkatingLoading = false);
                        },
                ),
                const SizedBox(height: 20),

// _buildReportButton(
//   icon: Icons.shopping_cart,
//   label: "Bepocart Excel Report",
//   color: Colors.deepPurple,
//   isLoading: _isBepocartLoading,
//   onPressed: (_startDate == null || _endDate == null)
//       ? null
//       : () async {
//           setState(() => _isBepocartLoading = true);
//           await generateExcelReportFor("bepocart");
//           if (mounted) setState(() => _isBepocartLoading = false);
//         },
// ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportButton({
    required IconData icon,
    required String label,
    required Color color,
    required Future<void> Function()? onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: color,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(fontSize: 14)),
                ],
              ),
      ),
    );
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> getStaff(String familyFilter) async {
    try {
      final token = await getTokenFromPrefs();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$api/api/staffs/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final staffData = parsed['data'] as List;

        List<Map<String, dynamic>> staffListData = [];

        for (var staff in staffData) {
          final deptName =
              (staff['department_name'] ?? '').toString().toUpperCase();
          final familyName =
              (staff['family_name'] ?? '').toString().toUpperCase();

          // 🟢 Case 1: For Cycling / Skating -> only BDM / BDO of that family
          if ((deptName == 'BDM' || deptName == 'BDO') &&
              familyName == familyFilter.toUpperCase()) {
            staffListData.add({
              'name': staff['name'],
              'allocated_states_names': staff['allocated_states_names'] ?? [],
            });
          }

          // 🟢 Case 2: For Bepocart -> only Marketing department (all families)
          else if (familyFilter.toLowerCase() == 'bepocart' &&
              deptName == 'MARKETING') {
            staffListData.add({
              'name': staff['name'],
              'allocated_states_names': staff['allocated_states_names'] ?? [],
            });
          }
        }

        if (!mounted) return;
        setState(() {
          staffList = staffListData;
        });
      }
    } catch (e) {}
  }

  Future<void> getProductCategories() async {
    try {
      final token = await getTokenFromPrefs();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$api/api/product/category/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        List<Map<String, dynamic>> tempList = [];

        for (var item in parsed) {
          tempList.add({
            'id': item['id'],
            'name': item['category_name'],
          });
        }

        setState(() {
          categoryList = tempList;
        });
      }
    } catch (error) {}
  }

  Future<void> generateExcelReportFor(String family) async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please select start and end dates')),
      );
      return;
    }

    await getStaff(family);
    await getProductCategories();

    final token = await getTokenFromPrefs();
    if (token == null) return;

    final startDateStr =
        "${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}";
    final endDateStr =
        "${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}";
    final reportPeriodText = "Report Period: $startDateStr → $endDateStr";

    final url = Uri.parse(
        '$api/api/product-wise/filter/report/?start_date=$startDateStr&end_date=$endDateStr&family=$family');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) return;

    final parsed = jsonDecode(response.body);
    final allData = List<Map<String, dynamic>>.from(parsed['data']);

    // ✅ Filter by family
    List<Map<String, dynamic>> filteredData = allData
        .where((entry) =>
            (entry['staff_family']?.toString().toLowerCase() ?? '') ==
            family.toLowerCase())
        .toList();

    reportData = filteredData;
    final Set<String> globalInvoices = <String>{};

    List<String> categoryHeaders =
        categoryList.map((c) => c['name'].toString()).toList();
    categoryHeaders.sort();

    if (!categoryHeaders.contains("UNKNOWN PRODUCTS")) {
      categoryHeaders.add("UNKNOWN PRODUCTS");
    }

    var excel = Excel.createExcel();
    Sheet sheet = excel["${family.toUpperCase()} CATEGORY REPORT"];
    List<String> headers = ['BDO', 'STATE', 'TOTAL BILL', ...categoryHeaders];

    // === Styles ===
    final yellowStyle = CellStyle(
        backgroundColorHex: "#FFFF00",
        fontFamily: getFontFamily(FontFamily.Calibri));
    final redStyle = CellStyle(
        backgroundColorHex: "#FF0000",
        fontFamily: getFontFamily(FontFamily.Calibri));
    final skyBlueHeaderStyle = CellStyle(
        backgroundColorHex: "#87CEEB",
        fontFamily: getFontFamily(FontFamily.Calibri),
        bold: true);
    final summaryStyle = CellStyle(
        backgroundColorHex: "#FFFF00",
        fontFamily: getFontFamily(FontFamily.Calibri),
        fontSize: 14,
        bold: true);
    final titleStyle = CellStyle(
        backgroundColorHex: "#FF0000",
        fontFamily: getFontFamily(FontFamily.Calibri),
        fontSize: 16,
        bold: true,
        horizontalAlign: HorizontalAlign.Center);
    final totalBillColStyle = CellStyle(
      backgroundColorHex: "#90EE90",
      fontFamily: getFontFamily(FontFamily.Calibri),
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    int rowIndex = 0;
    var titleCell = sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
    titleCell.value = family.toLowerCase() == 'bepocart'
        ? 'BEPOCART CATEGORYWISE STATEWISE REPORT (MARKETING STAFF)'
        : '${family.toUpperCase()} CATEGORYWISE STATEWISE REPORT';
    titleCell.cellStyle = titleStyle;
    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        CellIndex.indexByColumnRow(
            columnIndex: headers.length - 1, rowIndex: rowIndex));
    rowIndex++;

    // 📅 Report period
    var dateRangeCell = sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
    dateRangeCell.value = reportPeriodText;
    dateRangeCell.cellStyle = CellStyle(
      backgroundColorHex: "#D3D3D3",
      fontFamily: getFontFamily(FontFamily.Calibri),
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );
    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        CellIndex.indexByColumnRow(
            columnIndex: headers.length - 1, rowIndex: rowIndex));
    rowIndex += 2;

    // 🧮 accumulate exact written totals
    final Map<String, int> accumulatedTotals = {
      for (var cat in categoryHeaders) cat: 0
    };

    // === STAFF LOOP ===
    for (var staff in staffList) {
      final String bdoName = staff['name'] ?? '';
      final List<String> allocatedStates =
          List<String>.from(staff['allocated_states_names'] ?? []);

      final List<String> orderStates = reportData
          .where((entry) =>
              (entry['staff_name']?.toLowerCase() ?? '') ==
              bdoName.toLowerCase())
          .map<String>((entry) => (entry['order_state'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();

      final Set<String> allStates = {...allocatedStates, ...orderStates};

      // Header row
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
        cell.value = headers[i];
        cell.cellStyle = (i == 2) ? totalBillColStyle : skyBlueHeaderStyle;
      }
      rowIndex++;

      bool isFirstRow = true;
      for (var state in allStates) {
        final relevantOrders = reportData
            .where((entry) =>
                (entry['staff_name']?.toLowerCase() ?? '') ==
                    bdoName.toLowerCase() &&
                (entry['order_state'] ?? '') == state)
            .toList();

        Map<String, int> categoryCount = {
          for (var cat in categoryHeaders) cat: 0
        };
        final Set<String> processedItems = <String>{};
        final Set<String> stateInvoices = <String>{};

        for (final order in relevantOrders) {
          final categoryName =
              (order['category_name'] ?? '').toString().trim().toUpperCase();
          final qty = int.tryParse(order['quantity'].toString()) ?? 0;

          final key = '${order['order_id']}_${order['product_id'] ?? ''}';
          if (processedItems.contains(key)) continue;
          processedItems.add(key);

          final inv = _extractInvoice(order);
          if (inv != null) {
            stateInvoices.add(inv);
            globalInvoices.add(inv);
          }

          if (categoryName.isNotEmpty &&
              categoryCount.containsKey(categoryName)) {
            categoryCount[categoryName] = categoryCount[categoryName]! + qty;
          } else {
            categoryCount["UNKNOWN PRODUCTS"] =
                (categoryCount["UNKNOWN PRODUCTS"] ?? 0) + qty;
          }
        }

        // ✅ Accumulate what’s actually written
        for (final cat in categoryHeaders) {
          accumulatedTotals[cat] =
              (accumulatedTotals[cat] ?? 0) + (categoryCount[cat] ?? 0);
        }

        final currentRow = rowIndex++;
        if (isFirstRow) {
          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: 0, rowIndex: currentRow))
              .value = bdoName;
          isFirstRow = false;
        }

        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: 1, rowIndex: currentRow))
            .value = state;
        final int totalBills = stateInvoices.length;
        final totalBillCell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow));
        totalBillCell.value = totalBills;

        totalBillCell.cellStyle = CellStyle(
          backgroundColorHex: colorToHex(
            totalBills > 0
                ? const Color.fromARGB(255, 80, 255, 86)
                : const Color.fromARGB(255, 255, 17, 0),
          ),
          fontFamily: getFontFamily(FontFamily.Calibri),
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
        );

        for (int i = 0; i < categoryHeaders.length; i++) {
          int value = categoryCount[categoryHeaders[i]] ?? 0;
          final cell = sheet.cell(CellIndex.indexByColumnRow(
              columnIndex: i + 3, rowIndex: currentRow));
          cell.value = value;
          cell.cellStyle = value == 0 ? redStyle : yellowStyle;
        }
      }

      // 🟢 After finishing all states for this staff → show STAFF TOTAL
      int staffTotalBills = 0;

// Collect all invoices belonging to this staff
      final staffInvoices = reportData
          .where((entry) =>
              (entry['staff_name']?.toLowerCase() ?? '') ==
              bdoName.toLowerCase())
          .map((entry) => _extractInvoice(entry))
          .where((inv) => inv != null)
          .toSet();
      staffTotalBills = staffInvoices.length;

// ✅ Row for this staff's total bills
      final staffTotalRow = rowIndex++;
      sheet
          .cell(CellIndex.indexByColumnRow(
              columnIndex: 0, rowIndex: staffTotalRow))
          .value = '';
      sheet
          .cell(CellIndex.indexByColumnRow(
              columnIndex: 1, rowIndex: staffTotalRow))
          .cellStyle = CellStyle(
        backgroundColorHex: "#FFA500", // 🟠 Orange highlight
        bold: true,
        fontFamily: getFontFamily(FontFamily.Calibri),
      );

// Merge across columns for visibility
      sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: staffTotalRow),
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: staffTotalRow));

// Write total count in TOTAL BILL column
      final staffTotalCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: staffTotalRow));
      staffTotalCell.value = staffTotalBills;
      staffTotalCell.cellStyle = CellStyle(
        backgroundColorHex: "#FFA500",
        bold: true,
        fontFamily: getFontFamily(FontFamily.Calibri),
        horizontalAlign: HorizontalAlign.Center,
      );

// Add a gap before next staff’s section
      rowIndex += 1;
    }

    // ✅ Use accumulatedTotals instead of recomputation
    final Map<String, int> dailySummary = accumulatedTotals;

    final summaryRow = rowIndex++;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow))
        .value = "PRODUCTS SOLD";
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow))
        .cellStyle = summaryStyle;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow))
        .value = 'SUMMARY';
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow))
        .cellStyle = summaryStyle;

    for (int i = 0; i < categoryHeaders.length; i++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i + 3, rowIndex: summaryRow));
      cell.value = dailySummary[categoryHeaders[i]] ?? 0;
      cell.cellStyle = summaryStyle;
    }

    final totalSum = dailySummary.values.fold(0, (a, b) => a + b);
    final totalCell = sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: summaryRow));
    totalCell.value = totalSum;
    totalCell.cellStyle = totalBillColStyle;

    final int totalDailyBills = globalInvoices.length;

    final totalBillsRow = summaryRow + 1;
    sheet
        .cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalBillsRow))
        .value = 'TOTAL BILLS';
    sheet
        .cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalBillsRow))
        .cellStyle = summaryStyle;
    final totalBillsCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: totalBillsRow));
    totalBillsCell.value = totalDailyBills;
    totalBillsCell.cellStyle = totalBillColStyle;

    try {
      final fileBytes = excel.encode();
      if (fileBytes == null) return;

      final dir = await getApplicationDocumentsDirectory();

      final filePath =
          '${dir.path}/${family}_Categorywise_Report_${startDateStr}_to_${endDateStr}.xlsx';

      final file = File(filePath);
      await file.writeAsBytes(fileBytes, flush: true);

      await Future.delayed(const Duration(milliseconds: 300));

      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType:
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
          )
        ],
        text:
            '📊 ${family.toUpperCase()} Categorywise Report ($startDateStr → $endDateStr)',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('❌ Failed to generate or share report')));
    }
  }
}
