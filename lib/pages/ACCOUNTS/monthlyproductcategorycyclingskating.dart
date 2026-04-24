import 'dart:convert';
import 'dart:io';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/MARKETING/marketing_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:beposoft/pages/api.dart';
import 'package:share_plus/share_plus.dart';

class CyclingProductwiseCategoryStatewiseReport extends StatefulWidget {
  const CyclingProductwiseCategoryStatewiseReport({super.key});

  @override
  State<CyclingProductwiseCategoryStatewiseReport> createState() =>
      _CyclingProductwiseCategoryStatewiseReportState();
}

class _CyclingProductwiseCategoryStatewiseReportState
    extends State<CyclingProductwiseCategoryStatewiseReport> {
  List<Map<String, dynamic>> staffList = [];
  List<Map<String, dynamic>> reportData = [];
  List<Map<String, dynamic>> categoryList = [];
  bool _isCyclingLoading = false;
  bool _isSkatingLoading = false;

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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateBack();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Categorywise Statewise Monthly Report",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: _navigateBack,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStyledButton(
                icon: Icons.pedal_bike,
                label: "Cycling Categorywise Monthly Excel",
                color: Colors.indigo,
                isLoading: _isCyclingLoading,
                onPressed: () async {
                  setState(() => _isCyclingLoading = true);
                  await generateExcelReportFor("cycling");
                  if (mounted) setState(() => _isCyclingLoading = false);
                },
              ),
              const SizedBox(height: 20),
              _buildStyledButton(
                icon: Icons.ice_skating,
                label: "Skating Categorywise Monthly Excel",
                color: Colors.deepPurple,
                isLoading: _isSkatingLoading,
                onPressed: () async {
                  setState(() => _isSkatingLoading = true);
                  await generateExcelReportFor("skating");
                  if (mounted) setState(() => _isSkatingLoading = false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyledButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
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

          if ((deptName == 'BDM' || deptName == 'BDO') &&
              familyName == familyFilter.toUpperCase()) {
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
    await getStaff(family);
    await getProductCategories();

    final token = await getTokenFromPrefs();
    if (token == null) return;

    final response = await http.get(
      Uri.parse('$api/api/product-wise/report/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) return;

    final parsed = jsonDecode(response.body);
    final allData = List<Map<String, dynamic>>.from(parsed['data']);

    final now = DateTime.now();
    reportData = allData.where((entry) {
      final orderDate = DateTime.tryParse(entry['order_date'] ?? '');
      final familyName = (entry['family_name'] ?? '').toString().toLowerCase();
      return orderDate != null &&
          orderDate.month == now.month &&
          orderDate.year == now.year &&
          familyName == family.toLowerCase();
    }).toList();

    List<String> categoryHeaders =
        categoryList.map((c) => c['name'].toString()).toList();
    categoryHeaders.sort();
    if (categoryHeaders.isEmpty) return;

    var excel = Excel.createExcel();
    Sheet sheet = excel["${family.toUpperCase()} CATEGORY REPORT"];
    List<String> headers = ['BDO', 'STATE', 'TOTAL BILL', ...categoryHeaders];

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

    int rowIndex = 0;
    var titleCell = sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
    titleCell.value =
        '${family.toUpperCase()} CATEGORYWISE STATEWISE MONTHLY REPORT';
    titleCell.cellStyle = titleStyle;
    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        CellIndex.indexByColumnRow(
            columnIndex: headers.length - 1, rowIndex: rowIndex));
    rowIndex += 2;

    for (var staff in staffList) {
      final String bdoName = staff['name'] ?? '';
      final List<dynamic> states = staff['allocated_states_names'] ?? [];

      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
        cell.value = headers[i];
        cell.cellStyle = skyBlueHeaderStyle;
      }
      rowIndex++;

      if (states.isEmpty) {
        final row = rowIndex++;
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = bdoName;
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = '';
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = 0;
        for (int i = 0; i < categoryHeaders.length; i++) {
          final cell = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: i + 3, rowIndex: row));
          cell.value = 0;
          cell.cellStyle = redStyle;
        }
      } else {
        bool isFirstRow = true;
        for (var state in states) {
          final relevantOrders = reportData
              .where((entry) =>
                  (entry['staff_name']?.toLowerCase() ?? '') ==
                      bdoName.toLowerCase() &&
                  (entry['order_state'] ?? '') == state)
              .toList();

          final totalBills = relevantOrders
              .map((o) => o['invoice'] ?? '')
              .where((inv) => inv.toString().trim().isNotEmpty)
              .toSet()
              .length;

          Map<String, int> categoryCount = {
            for (var cat in categoryHeaders) cat: 0
          };

          for (var order in relevantOrders) {
            final catName =
                (order['category_name'] ?? '').toString().trim().toUpperCase();
            for (final cat in categoryCount.keys) {
              if (catName == cat.toUpperCase()) {
                final qty = int.tryParse(order['quantity'].toString()) ?? 0;
                categoryCount[cat] = categoryCount[cat]! + qty;
                break;
              }
            }
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
          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: 2, rowIndex: currentRow))
              .value = totalBills;

          for (int i = 0; i < categoryHeaders.length; i++) {
            int value = categoryCount[categoryHeaders[i]] ?? 0;
            final cell = sheet.cell(CellIndex.indexByColumnRow(
                columnIndex: i + 3, rowIndex: currentRow));
            cell.value = value;
            cell.cellStyle = value == 0 ? redStyle : yellowStyle;
          }
        }
      }
      rowIndex++;
    }

    // ✅ Monthly Summary
    Map<String, int> monthlySummary = {for (var c in categoryHeaders) c: 0};
    for (var order in reportData) {
      final categoryName = (order['category_name'] ?? '').toString();
      final qty = int.tryParse(order['quantity'].toString()) ?? 0;
      if (monthlySummary.containsKey(categoryName)) {
        monthlySummary[categoryName] = monthlySummary[categoryName]! + qty;
      }
    }

    final summaryRow = rowIndex++;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow))
        .value = 'MONTHLY SUMMARY';
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow))
        .cellStyle = summaryStyle;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow))
        .value = 'TOTAL';
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow))
        .cellStyle = summaryStyle;

    for (int i = 0; i < categoryHeaders.length; i++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i + 3, rowIndex: summaryRow));
      cell.value = monthlySummary[categoryHeaders[i]] ?? 0;
      cell.cellStyle = summaryStyle;
    }

    final totalSum = monthlySummary.values.fold(0, (a, b) => a + b);
    final totalCell = sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: summaryRow));
    totalCell.value = totalSum;
    totalCell.cellStyle = summaryStyle;

    // ✅ Grand total bills
    final totalBillsOverall = reportData
        .map((o) => o['invoice'] ?? '')
        .where((inv) => inv.toString().trim().isNotEmpty)
        .toSet()
        .length;

    final totalBillsRow = rowIndex + 2;
    sheet
        .cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalBillsRow))
        .value = 'TOTAL BILLS';
    sheet
        .cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalBillsRow))
        .cellStyle = summaryStyle;
    sheet
        .cell(
            CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: totalBillsRow))
        .value = totalBillsOverall;
    sheet
        .cell(
            CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: totalBillsRow))
        .cellStyle = summaryStyle;

    try {
      final fileBytes = excel.encode();
      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/${family}_Categorywise_Monthly_Report.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(fileBytes!);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '📊 ${family.toUpperCase()} Categorywise Monthly Report',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to generate or share report')),
      );
    }
  }
}
