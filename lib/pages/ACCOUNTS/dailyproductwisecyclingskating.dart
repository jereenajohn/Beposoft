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
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CyclingskatingDailyProductwiseReport extends StatefulWidget {
  const CyclingskatingDailyProductwiseReport({super.key});

  @override
  State<CyclingskatingDailyProductwiseReport> createState() =>
      _CyclingskatingDailyProductwiseReportState();
}

class _CyclingskatingDailyProductwiseReportState
    extends State<CyclingskatingDailyProductwiseReport> {
  List<Map<String, dynamic>> staffList = [];
  List<Map<String, dynamic>> reportData = [];
  bool _isCyclingLoading = false;
  bool _isSkatingLoading = false;

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();
    if (dep == "BDO") {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => bdo_dashbord()));
    } else if (dep == "BDM") {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => bdm_dashbord()));
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
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => WarehouseAdmin()));
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
          backgroundColor: Colors.indigo,
          elevation: 4,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _navigateBack,
          ),
          title: const Text(
            "Productwise DSR Excel",
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
                _buildReportButton(
                  icon: Icons.pedal_bike,
                  label: "Cycling Productwise Daily Excel",
                  color: Colors.blueAccent,
                  isLoading: _isCyclingLoading,
                  onPressed: () async {
                    setState(() => _isCyclingLoading = true);
                    await generateExcelReportFor("cycling");
                    if (mounted) setState(() => _isCyclingLoading = false);
                  },
                ),
                const SizedBox(height: 20),
                _buildReportButton(
                  icon: Icons.ice_skating,
                  label: "Skating Productwise Daily Excel",
                  color: Colors.teal,
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
      ),
    );
  }

  Widget _buildReportButton({
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

  Future<List<String>> fetchApprovedProductNames() async {
    final token = await getTokenFromPrefs();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$api/api/products/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final products = parsed['data'] as List;
        Set<String> productNames = {};

        for (var product in products) {
          if (product['name'] != null) {
            productNames.add(product['name']);
          }

          final variants = product['variantIDs'] as List<dynamic>? ?? [];
          for (var variant in variants) {
            final variantApproval =
                (variant['approval_status'] ?? '').toString().toLowerCase();
            if (variantApproval == 'approved' && variant['name'] != null) {
              productNames.add(variant['name']);
            }
          }
        }

        return productNames.toList()..sort();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> generateExcelReportFor(String family) async {
    await getStaff(family);

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
    final today = DateTime(now.year, now.month, now.day);

    reportData = allData.where((entry) {
      final orderDateRaw = entry['order_date'];
      final orderDate = DateTime.tryParse(orderDateRaw ?? '');
      final familyName = (entry['family_name'] ?? '').toString().toLowerCase();

      if (orderDate == null) return false;

      final orderDateOnly =
          DateTime(orderDate.year, orderDate.month, orderDate.day);

      return orderDateOnly == today && familyName == family.toLowerCase();
    }).toList();

    List<String> productHeaders = await fetchApprovedProductNames();
    productHeaders.sort();
    if (productHeaders.isEmpty) return;

    var excel = Excel.createExcel();
    Sheet sheet = excel["${family.toUpperCase()} Report"];
    List<String> headers = ['BDO', 'STATE', 'TOTAL BILL', ...productHeaders];

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
    var titleCell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
    titleCell.value = '${family.toUpperCase()} PRODUCTWISE STATEWISE REPORT';
    titleCell.cellStyle = titleStyle;
    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        CellIndex.indexByColumnRow(
            columnIndex: headers.length - 1, rowIndex: rowIndex));
    rowIndex += 2;

    for (var staff in staffList) {
      final String bdoName = staff['name'] ?? '';
      final List<dynamic> states = staff['allocated_states_names'] ?? [];

      // Header row
      for (int i = 0; i < headers.length; i++) {
        final cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
        cell.value = headers[i];
        cell.cellStyle = skyBlueHeaderStyle;
      }
      rowIndex++;

      if (states.isEmpty) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = bdoName;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = '';
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = 0;

        for (int i = 0; i < productHeaders.length; i++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i + 3, rowIndex: rowIndex));
          cell.value = 0;
          cell.cellStyle = redStyle;
        }
        rowIndex++;
      } else {
        bool isFirstRow = true;
        for (var state in states) {
          final relevantOrders = reportData.where((entry) =>
              (entry['staff_name']?.toLowerCase() ?? '') ==
                  bdoName.toLowerCase() &&
              (entry['order_state'] ?? '') == state).toList();

          Map<String, int> productCount = {
            for (var product in productHeaders) product: 0
          };

          for (var order in relevantOrders) {
            final productName = (order['product_name'] ?? '').toString().trim().toLowerCase();
            final orderStaffFamily = (order['staff_family'] ?? '').toString().toLowerCase();

            for (final header in productCount.keys) {
              final normalizedHeader = header.trim().toLowerCase();
              if (orderStaffFamily == family.toLowerCase() && productName == normalizedHeader) {
                final qty = int.tryParse(order['quantity'].toString()) ?? 0;
                productCount[header] = productCount[header]! + qty;
                break;
              }
            }
          }

          final currentRow = rowIndex++;
          if (isFirstRow) {
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = bdoName;
            isFirstRow = false;
          }

          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = state;

          // ✅ TOTAL BILL Column
          final totalBills = relevantOrders
              .map((order) => order['invoice_number'] ?? order['invoice'] ?? '')
              .where((invoice) => invoice.toString().trim().isNotEmpty)
              .toSet()
              .length;

          final totalBillCell =
              sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow));
          totalBillCell.value = totalBills;
          totalBillCell.cellStyle = CellStyle(
            backgroundColorHex: "#E6E6FA",
            fontFamily: getFontFamily(FontFamily.Calibri),
          );

          // Product quantities start from column 3
          for (int i = 0; i < productHeaders.length; i++) {
            int value = productCount[productHeaders[i]] ?? 0;
            final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i + 3, rowIndex: currentRow));
            cell.value = value;
            cell.cellStyle = value == 0 ? redStyle : yellowStyle;
          }
        }
      }
      rowIndex++;
    }

    // ✅ DAILY SUMMARY (unchanged)
    Map<String, int> dailySummary = {for (var product in productHeaders) product: 0};
    final staffNames =
        staffList.map((s) => (s['name'] ?? '').toString().toLowerCase()).toSet();
    for (var order in reportData) {
      final productName = order['product_name'];
      final staffName = (order['staff_name'] ?? '').toString().toLowerCase();
      if (staffNames.contains(staffName) && dailySummary.containsKey(productName)) {
        final qty = int.tryParse(order['quantity'].toString()) ?? 0;
        dailySummary[productName] = dailySummary[productName]! + qty;
      }
    }

    final summaryRow = rowIndex++;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow)).value = 'DAILY SUMMARY';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow)).cellStyle = summaryStyle;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow - 1)).value = 'TOTAL';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow - 1)).cellStyle = summaryStyle;

    for (int i = 0; i < productHeaders.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i + 3, rowIndex: summaryRow));
      cell.value = dailySummary[productHeaders[i]] ?? 0;
      cell.cellStyle = summaryStyle;
    }

    final totalSum = dailySummary.values.fold(0, (a, b) => a + b);
    final totalCell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow));
    totalCell.value = totalSum;
    totalCell.cellStyle = summaryStyle;

    // ✅ TOTAL BILLS AT BOTTOM
    int totalBillsOverall = reportData
        .map((order) => order['invoice_number'] ?? order['invoice'] ?? '')
        .where((invoice) => invoice.toString().trim().isNotEmpty)
        .toSet()
        .length;

    final totalBillsRow = rowIndex + 2;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalBillsRow)).value = 'TOTAL BILLS';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalBillsRow)).cellStyle = summaryStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: totalBillsRow)).value = totalBillsOverall;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: totalBillsRow)).cellStyle = summaryStyle;

    try {
      final fileBytes = excel.encode();
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/${family}_DSR_Report.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(fileBytes!);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '📊 ${family.toUpperCase()} DSR Report',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to generate or share report')),
      );
    }
  }
}
