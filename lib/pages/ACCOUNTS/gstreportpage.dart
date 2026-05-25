import 'dart:convert';
import 'dart:io';

import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GSTReportPage extends StatefulWidget {
  const GSTReportPage({super.key});

  @override
  State<GSTReportPage> createState() => _GSTReportPageState();
}

class _GSTReportPageState extends State<GSTReportPage> {
  final String baseUrl = 'https://bepocart.in/api/gst/orders/';

  final int pageSize = 100;

  int currentPage = 1;
  int totalCount = 0;
  bool loading = false;
  bool exporting = false;

  DateTime? startDate;
  DateTime? endDate;

  List<Map<String, dynamic>> gstData = [];

  final Map<String, String> stateCodes = const {
    "Jammu & Kashmir": "01",
    "Himachal Pradesh": "02",
    "Punjab": "03",
    "Chandigarh": "04",
    "Uttarakhand": "05",
    "Haryana": "06",
    "Delhi": "07",
    "Rajasthan": "08",
    "Uttar Pradesh": "09",
    "Bihar": "10",
    "Sikkim": "11",
    "Arunachal Pradesh": "12",
    "Nagaland": "13",
    "Manipur": "14",
    "Mizoram": "15",
    "Tripura": "16",
    "Meghalaya": "17",
    "Assam": "18",
    "West Bengal": "19",
    "Jharkhand": "20",
    "Odisha": "21",
    "Chhattisgarh": "22",
    "Madhya Pradesh": "23",
    "Gujarat": "24",
    "Daman & Diu": "25",
    "Dadra & Nagar Haveli": "26",
    "Maharashtra": "27",
    "Karnataka": "29",
    "Goa": "30",
    "Lakshadweep": "31",
    "Kerala": "32",
    "Tamil Nadu": "33",
    "Puducherry": "34",
    "Andaman & Nicobar Islands": "35",
    "Telangana": "36",
    "Andhra Pradesh": "37",
    "Ladakh": "38",
  };

  @override
  void initState() {
    super.initState();
    fetchGSTPage(page: 1);
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
else if(dep=="ADMIN"){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => admin_dashboard()), // Replace AnotherPage with your target page
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


  String _apiDate(DateTime? value) {
    if (value == null) return '';
    return DateFormat('yyyy-MM-dd').format(value);
  }

  String _invoiceDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return '';

    try {
      final date = DateTime.parse(value.toString());
      return DateFormat('dd-MMM-yy').format(date);
    } catch (_) {
      return '';
    }
  }

  String _placeOfSupply(dynamic address) {
    final state = address?.toString() ?? '';
    if (state.isEmpty) return '';

    final code = stateCodes[state];
    return code != null ? '$code-$state' : state;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  int get totalPages {
    if (totalCount <= 0) return 1;
    return (totalCount / pageSize).ceil();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Map<String, String> _headers(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Uri _buildUri({
    required int page,
    DateTime? sDate,
    DateTime? eDate,
  }) {
    final params = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    final start = _apiDate(sDate);
    final end = _apiDate(eDate);

    if (start.isNotEmpty) {
      params['start_date'] = start;
    }

    if (end.isNotEmpty) {
      params['end_date'] = end;
    }

    return Uri.parse(baseUrl).replace(queryParameters: params);
  }

  Future<void> fetchGSTPage({
    required int page,
    DateTime? sDate,
    DateTime? eDate,
  }) async {
    if (loading) return;

    setState(() {
      loading = true;
    });

    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        _showMessage('Token missing. Please login again.', isError: true);

        if (mounted) {
          setState(() {
            gstData = [];
            totalCount = 0;
          });
        }

        return;
      }

      final uri = _buildUri(
        page: page,
        sDate: sDate ?? startDate,
        eDate: eDate ?? endDate,
      );

      final response = await http.get(uri, headers: _headers(token));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final results = decoded['results'];

        if (results is List) {
          if (!mounted) return;

          setState(() {
            gstData = results
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();

            totalCount = int.tryParse(decoded['count']?.toString() ?? '0') ?? 0;
            currentPage =
                int.tryParse(decoded['page']?.toString() ?? '$page') ?? page;
          });
        } else {
          if (!mounted) return;

          setState(() {
            gstData = [];
            totalCount = 0;
            currentPage = page;
          });
        }
      } else {
        _showMessage('Error fetching GST data', isError: true);
      }
    } catch (_) {
      _showMessage('Error fetching GST data', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _tableRows() {
    final rows = <Map<String, dynamic>>[];

    for (int index = 0; index < gstData.length; index++) {
      final row = gstData[index];
      final items = row['items'];

      final Map<String, List<Map<String, dynamic>>> grouped = {};

      if (items is List) {
        for (final item in items) {
          if (item is Map) {
            final mappedItem = Map<String, dynamic>.from(item);
            final tax = mappedItem['tax']?.toString() ?? '';

            grouped.putIfAbsent(tax, () => []);
            grouped[tax]!.add(mappedItem);
          }
        }
      }

      grouped.forEach((taxRate, itemList) {
        rows.add({
          'key': '${row['id']}-$taxRate-${rows.length}',
          'index': index + 1,
          'gst': row['gst']?.toString() ?? '',
          'receiver': row['customerName']?.toString() ?? '',
          'invoice': row['invoice']?.toString() ?? '',
          'date': _invoiceDate(row['order_date']),
          'placeOfSupply': _placeOfSupply(row['address']),
          'taxRate': '$taxRate%',
        });
      });
    }

    return rows;
  }

  Future<List<Map<String, dynamic>>> _fetchAllPagesForExport(
    String token,
  ) async {
    final allResults = <Map<String, dynamic>>[];

    final firstUri = _buildUri(
      page: 1,
      sDate: startDate,
      eDate: endDate,
    );

    final firstResponse = await http.get(firstUri, headers: _headers(token));

    if (firstResponse.statusCode != 200) {
      throw Exception('Export failed');
    }

    final firstDecoded = jsonDecode(firstResponse.body);
    final total = int.tryParse(firstDecoded['count']?.toString() ?? '0') ?? 0;

    if (total <= 0) {
      return [];
    }

    final firstResults = firstDecoded['results'];

    if (firstResults is List) {
      allResults.addAll(
        firstResults.whereType<Map>().map(
              (e) => Map<String, dynamic>.from(e),
            ),
      );
    }

    final pages = (total / pageSize).ceil();

    for (int p = 2; p <= pages; p++) {
      final uri = _buildUri(
        page: p,
        sDate: startDate,
        eDate: endDate,
      );

      final response = await http.get(uri, headers: _headers(token));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final results = decoded['results'];

        if (results is List) {
          allResults.addAll(
            results.whereType<Map>().map(
                  (e) => Map<String, dynamic>.from(e),
                ),
          );
        }
      }
    }

    return allResults;
  }

  List<String> get _b2bB2cHeaders => const [
        '#',
        'GSTIN/UIN Number',
        'Receiver Name',
        'Invoice Number',
        'Invoice Date',
        'Invoice Value',
        'Place of Supply',
        'Reverse Charge',
        'Applicable % of Tax',
        'Invoice Type',
        'E-Commerce GSTIN',
        'Rate',
        'Taxable Value',
        'Cess Amount',
      ];

  List<String> get _hsnHeaders => const [
        'Description',
        'HSN',
        'measurement',
        'TotalQuantity',
        'TaxRate',
        'TotalTaxableValue',
        'IGST',
        'CentralTax',
        'StateTax',
        'Cess',
        'TOTAL',
      ];

  void _appendHeader(Sheet sheet, List<String> headers) {
    sheet.appendRow(headers);

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );

      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
    }
  }

  void _appendMapRow(
    Sheet sheet,
    List<String> headers,
    Map<String, dynamic> row,
  ) {
    sheet.appendRow(
      headers.map((header) {
        final value = row[header];

        if (value is int) {
          return value;
        }

        if (value is double) {
          return value;
        }

        if (value is num) {
          return value.toDouble();
        }

        return value?.toString() ?? '';
      }).toList(),
    );
  }

  Future<void> exportCombinedExcel() async {
    if (exporting) return;

    setState(() {
      exporting = true;
    });

    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        _showMessage('Token missing. Please login again.', isError: true);
        return;
      }

      final allResults = await _fetchAllPagesForExport(token);

      if (allResults.isEmpty) {
        _showMessage('No data to export');
        return;
      }

      final b2bRows = <Map<String, dynamic>>[];
      final b2cRows = <Map<String, dynamic>>[];

      for (int index = 0; index < allResults.length; index++) {
        final row = allResults[index];

        final gstConfirm =
            (row['gst_confirm'] ?? '').toString().trim().toUpperCase();

        final items = row['items'];
        final Map<String, List<Map<String, dynamic>>> groupedByTax = {};

        if (items is List) {
          for (final item in items) {
            if (item is Map) {
              final mappedItem = Map<String, dynamic>.from(item);
              final tax = mappedItem['tax']?.toString() ?? '';

              groupedByTax.putIfAbsent(tax, () => []);
              groupedByTax[tax]!.add(mappedItem);
            }
          }
        }

        groupedByTax.forEach((taxRate, itemList) {
          final baseRow = <String, dynamic>{
            '#': index + 1,
            'GSTIN/UIN Number': row['gst']?.toString() ?? '',
            'Receiver Name': row['customerName']?.toString() ?? '',
            'Invoice Number': row['invoice']?.toString() ?? '',
            'Invoice Date': _invoiceDate(row['order_date']),
            'Invoice Value': '',
            'Place of Supply': _placeOfSupply(row['address']),
            'Reverse Charge': 'N',
            'Applicable % of Tax': '',
            'E-Commerce GSTIN': '',
            'Rate': '$taxRate%',
            'Taxable Value': '',
            'Cess Amount': '',
          };

          if (gstConfirm == 'YES') {
            b2bRows.add({
              ...baseRow,
              'Invoice Type': 'Regular B2B',
            });
          } else if (gstConfirm == 'NO GST') {
            b2cRows.add({
              ...baseRow,
              'Invoice Type': 'Regular B2C',
            });
          } else {
            b2cRows.add({
              ...baseRow,
              'Invoice Type':
                  row['gst'] != null && row['gst'].toString().isNotEmpty
                      ? 'Regular B2B'
                      : 'Regular B2C',
            });
          }
        });
      }

      final Map<String, Map<String, dynamic>> summaryMap = {};

      for (final row in allResults) {
        final items = row['items'];

        if (items is! List) continue;

        for (final item in items) {
          if (item is! Map) continue;

          final mappedItem = Map<String, dynamic>.from(item);
          final key = '${mappedItem['name']}-${mappedItem['product']}';

          summaryMap.putIfAbsent(key, () {
            return {
              'Description': mappedItem['name']?.toString() ?? '',
              'HSN': mappedItem['hsn']?.toString() ?? '',
              'measurement': mappedItem['unit']?.toString() ?? 'PCS',
              'TotalQuantity': 0.0,
              'TaxRate': mappedItem['tax'] ?? '',
              'TotalTaxableValue': 0.0,
              'IGST': 0.0,
              'CentralTax': 0.0,
              'StateTax': 0.0,
              'Cess': 0.0,
              'TOTAL': 0.0,
            };
          });

          final taxable = _toDouble(mappedItem['exclude_price']);
          final qty = _toDouble(mappedItem['quantity']);
          final rate = _toDouble(mappedItem['tax']);
          final taxAmount = (taxable * rate) / 100;

          summaryMap[key]!['TotalQuantity'] =
              _toDouble(summaryMap[key]!['TotalQuantity']) + qty;

          summaryMap[key]!['TotalTaxableValue'] =
              _toDouble(summaryMap[key]!['TotalTaxableValue']) + taxable;

          if (row['gst'] != null && row['gst'].toString().isNotEmpty) {
            summaryMap[key]!['IGST'] =
                _toDouble(summaryMap[key]!['IGST']) + taxAmount;
          } else {
            summaryMap[key]!['CentralTax'] =
                _toDouble(summaryMap[key]!['CentralTax']) + (taxAmount / 2);

            summaryMap[key]!['StateTax'] =
                _toDouble(summaryMap[key]!['StateTax']) + (taxAmount / 2);
          }

          summaryMap[key]!['TOTAL'] =
              _toDouble(summaryMap[key]!['TotalTaxableValue']) +
                  _toDouble(summaryMap[key]!['IGST']) +
                  _toDouble(summaryMap[key]!['CentralTax']) +
                  _toDouble(summaryMap[key]!['StateTax']);
        }
      }

      final excel = Excel.createExcel();

      final defaultSheet = excel.getDefaultSheet();

      if (defaultSheet != null) {
        excel.delete(defaultSheet);
      }

      final b2bSheet = excel['B2B (GST YES)'];
      final b2cSheet = excel['B2C (NO GST)'];
      final hsnSheet = excel['HSN Summary'];

      _appendHeader(b2bSheet, _b2bB2cHeaders);
      _appendHeader(b2cSheet, _b2bB2cHeaders);
      _appendHeader(hsnSheet, _hsnHeaders);

      for (final row in b2bRows) {
        _appendMapRow(b2bSheet, _b2bB2cHeaders, row);
      }

      for (final row in b2cRows) {
        _appendMapRow(b2cSheet, _b2bB2cHeaders, row);
      }

      for (final row in summaryMap.values) {
        _appendMapRow(hsnSheet, _hsnHeaders, row);
      }

      final bytes = excel.encode();

      if (bytes == null) {
        _showMessage('Export failed', isError: true);
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/GST_Report_B2B_B2C_With_HSN.xlsx';

      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      _showMessage('GST Excel exported successfully');
      await OpenFilex.open(filePath);
    } catch (_) {
      _showMessage('Export failed', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          exporting = false;
        });
      }
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        startDate = picked;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        endDate = picked;
      });
    }
  }

  void _applyFilter() {
    if (startDate != null && endDate != null && endDate!.isBefore(startDate!)) {
      _showMessage('End date cannot be before start date', isError: true);
      return;
    }

    fetchGSTPage(
      page: 1,
      sDate: startDate,
      eDate: endDate,
    );
  }

  void _clearFilter() {
    setState(() {
      startDate = null;
      endDate = null;
    });

    fetchGSTPage(page: 1, sDate: null, eDate: null);
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        content: Text(message),
      ),
    );
  }

  Widget _dateBox({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 19,
              color: Colors.blue.shade700,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value == null ? label : DateFormat('yyyy-MM-dd').format(value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: value == null ? Colors.grey.shade600 : Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    bool busy = false,
  }) {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: busy ? null : onTap,
        icon: busy
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, size: 18),
        label: Text(
          busy ? 'Please wait...' : label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          disabledBackgroundColor: color.withOpacity(0.55),
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade800,
            Colors.blue.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade800.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GST Report',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'B2B, B2C and HSN summary report',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Total: $totalCount',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _dateBox(
                  label: 'Start Date',
                  value: startDate,
                  onTap: _pickStartDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dateBox(
                  label: 'End Date',
                  value: endDate,
                  onTap: _pickEndDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  label: 'Filter',
                  icon: Icons.filter_alt_outlined,
                  color: Colors.blue.shade700,
                  onTap: _applyFilter,
                  busy: loading,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: loading ? null : _clearFilter,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text(
                      'Clear',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blueGrey.shade800,
                      side: BorderSide(color: Colors.blueGrey.shade200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableCell(
    String value, {
    bool bold = false,
    double width = 150,
    Alignment alignment = Alignment.centerLeft,
  }) {
    return Container(
      width: width,
      constraints: const BoxConstraints(
        minHeight: 46,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      alignment: alignment,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          color: bold ? Colors.blueGrey.shade900 : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: Colors.blue.shade50,
      child: Row(
        children: [
          _tableCell('#', bold: true, width: 60, alignment: Alignment.center),
          _tableCell('GSTIN/UIN Number', bold: true, width: 170),
          _tableCell('Receiver Name', bold: true, width: 190),
          _tableCell('Invoice Number', bold: true, width: 160),
          _tableCell('Invoice Date', bold: true, width: 130),
          _tableCell('Invoice Value', bold: true, width: 130),
          _tableCell('Place of Supply', bold: true, width: 190),
          _tableCell('Reverse Charge', bold: true, width: 140),
          _tableCell('Applicable % of Tax', bold: true, width: 170),
          _tableCell('Invoice Type', bold: true, width: 160),
          _tableCell('E-Commerce GSTIN', bold: true, width: 170),
          _tableCell('Rate', bold: true, width: 100),
          _tableCell('Taxable Value', bold: true, width: 140),
          _tableCell('Cess Amount', bold: true, width: 130),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> row) {
    return Row(
      children: [
        _tableCell(
          row['index']?.toString() ?? '',
          width: 60,
          alignment: Alignment.center,
        ),
        _tableCell(row['gst']?.toString() ?? '', width: 170),
        _tableCell(row['receiver']?.toString() ?? '', width: 190),
        _tableCell(row['invoice']?.toString() ?? '', width: 160),
        _tableCell(row['date']?.toString() ?? '', width: 130),
        _tableCell('', width: 130),
        _tableCell(row['placeOfSupply']?.toString() ?? '', width: 190),
        _tableCell('N', width: 140),
        _tableCell('', width: 170),
        _tableCell('Regular B2B', width: 160),
        _tableCell('', width: 170),
        _tableCell(row['taxRate']?.toString() ?? '', width: 100),
        _tableCell('', width: 140),
        _tableCell('', width: 130),
      ],
    );
  }

  Widget _buildTable() {
    final rows = _tableRows();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 2060,
          child: Column(
            children: [
              _buildTableHeader(),
              if (loading)
                Container(
                  height: 180,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                )
              else if (rows.isEmpty)
                Container(
                  height: 180,
                  alignment: Alignment.center,
                  child: const Text(
                    'No records found',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.black54,
                    ),
                  ),
                )
              else
                Column(
                  children: List.generate(rows.length, (index) {
                    return Container(
                      color: index.isEven ? Colors.white : Colors.grey.shade50,
                      child: _buildTableRow(rows[index]),
                    );
                  }),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    final firstItem = totalCount == 0 ? 0 : ((currentPage - 1) * pageSize) + 1;

    final lastItem =
        currentPage * pageSize > totalCount ? totalCount : currentPage * pageSize;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $firstItem to $lastItem of $totalCount entries',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: currentPage > 1 && !loading
                ? () => fetchGSTPage(page: currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$currentPage / $totalPages',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: currentPage < totalPages && !loading
                ? () => fetchGSTPage(page: currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshPage() async {
    await fetchGSTPage(page: currentPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6f8),
      appBar: AppBar(
  leading: IconButton(
    tooltip: 'Back',
    icon: const Icon(Icons.arrow_back),
    onPressed: _navigateBack,
  ),
  title: const Text(
    'GST Report',
    style: TextStyle(fontWeight: FontWeight.w800),
  ),
  backgroundColor: Colors.white,
  foregroundColor: Colors.black87,
  elevation: 0,
  actions: [
    IconButton(
      tooltip: 'Export GST + HSN Excel',
      onPressed: exporting || totalCount <= 0 ? null : exportCombinedExcel,
      icon: exporting
          ? const SizedBox(
              height: 19,
              width: 19,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.file_download_outlined,
              color: totalCount <= 0 ? Colors.grey : Colors.green,
            ),
    ),
    IconButton(
      tooltip: 'Refresh',
      onPressed: loading ? null : _refreshPage,
      icon: const Icon(Icons.refresh),
    ),
  ],
),
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildFilters(),
            const SizedBox(height: 16),
            _buildTable(),
            _buildPagination(),
          ],
        ),
      ),
    );
  }
}