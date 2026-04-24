import 'dart:convert';
import 'dart:io';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

import 'package:beposoft/pages/api.dart';
import 'package:share_plus/share_plus.dart';

class DivisionProductwiseStatewiseReport extends StatefulWidget {
  const DivisionProductwiseStatewiseReport({super.key});

  @override
  State<DivisionProductwiseStatewiseReport> createState() =>
      _DivisionProductwiseStatewiseReportState();
}

class _DivisionProductwiseStatewiseReportState
    extends State<DivisionProductwiseStatewiseReport> {
  List<Map<String, dynamic>> staffList = [];
  List<Map<String, dynamic>> reportData = [];

  @override
  void initState() {
    super.initState();
    getStaff();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "All Division Product Sale Report",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => cso_dashboard()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStyledButton(
              icon: Icons.cloud_download,
              label: "All Division Productwise Monthly Excel",
              color: Colors.teal,
              onPressed: () async {
                await generateExcelReportFor();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 20),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: Colors.black45,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

 Future<void> getStaff() async {
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
            (staff['department_name'] ?? '').toString().trim().toUpperCase();

        if ([
          'BDM',
          'BDO',
          'MARKETING',
          'ADMIN',
          'ACCOUNTS / ACCOUNTING'
        ].contains(deptName)) {
          staffListData.add({
            'name': staff['name'],
            'allocated_states_names': staff['allocated_states_names'] ?? [],
            'department': deptName,
            'family': staff['family_name'] ?? '',
          });
        }
      }

      if (!mounted) return;
      setState(() {
        staffList = staffListData;
      });
    } else {
    }
  } catch (e) {
  }
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

Future<void> generateExcelReportFor() async {
  await getStaff();

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
    return orderDate != null &&
        orderDate.month == now.month &&
        orderDate.year == now.year;
  }).toList();

  List<String> productHeaders = await fetchApprovedProductNames();
  productHeaders.sort();
  if (productHeaders.isEmpty) return;

  var excel = Excel.createExcel();
  Sheet sheet = excel["Division Report"];
  List<String> headers = ['BDO', 'STATE', ...productHeaders];

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
  var titleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
  titleCell.value = ' PRODUCTWISE STATEWISE REPORT';
  titleCell.cellStyle = titleStyle;
  sheet.merge(
    CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
    CellIndex.indexByColumnRow(columnIndex: headers.length - 1, rowIndex: rowIndex),
  );
  rowIndex += 2;

  for (var staff in staffList) {
    final String bdoName = staff['name'] ?? '';
    final List<dynamic> states = staff['allocated_states_names'] ?? [];

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
      cell.value = headers[i];
      cell.cellStyle = skyBlueHeaderStyle;
    }
    rowIndex++;

    if (states.isEmpty) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = bdoName;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = '';

      for (int i = 0; i < productHeaders.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i + 2, rowIndex: rowIndex));
        cell.value = 0;
        cell.cellStyle = redStyle;
      }
      rowIndex++;
    } else {
      bool isFirstRow = true;
      for (var state in states) {
        final relevantOrders = reportData.where((entry) =>
          (entry['staff_name']?.toLowerCase() ?? '') == bdoName.toLowerCase() &&
          (entry['order_state'] ?? '') == state).toList();

        Map<String, int> productCount = {
          for (var product in productHeaders) product: 0
        };

        for (var order in relevantOrders) {
          final productName = (order['product_name'] ?? '').toString().trim().toLowerCase();

          for (final header in productCount.keys) {
            final normalizedHeader = header.trim().toLowerCase();
            if (productName == normalizedHeader) {
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

        for (int i = 0; i < productHeaders.length; i++) {
          int value = productCount[productHeaders[i]] ?? 0;
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i + 2, rowIndex: currentRow));
          cell.value = value;
          cell.cellStyle = value == 0 ? redStyle : yellowStyle;
        }
      }
    }
    rowIndex++;
  }

  Map<String, int> monthlySummary = {
    for (var product in productHeaders) product: 0
  };

  final staffNames = staffList.map((s) => (s['name'] ?? '').toString().toLowerCase()).toSet();
  for (var order in reportData) {
    final productName = order['product_name'];
    final staffName = (order['staff_name'] ?? '').toString().toLowerCase();
    if (staffNames.contains(staffName) && monthlySummary.containsKey(productName)) {
      final qty = int.tryParse(order['quantity'].toString()) ?? 0;
      monthlySummary[productName] = monthlySummary[productName]! + qty;
    }
  }

  final summaryRow = rowIndex++;
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow)).value = 'MONTHLY SUMMARY';
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow)).cellStyle = summaryStyle;
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow - 1)).value = 'TOTAL';
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow - 1)).cellStyle = summaryStyle;

  for (int i = 0; i < productHeaders.length; i++) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i + 2, rowIndex: summaryRow));
    cell.value = monthlySummary[productHeaders[i]] ?? 0;
    cell.cellStyle = summaryStyle;
  }

  final totalSum = monthlySummary.values.fold(0, (a, b) => a + b);
  final totalCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow));
  totalCell.value = totalSum;
  totalCell.cellStyle = summaryStyle;

  try {
    final fileBytes = excel.encode();
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/Division_Report.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(fileBytes!);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: '📊 Productwise Statewise Report',
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('❌ Failed to generate or share report')),
    );
  }
}

}
