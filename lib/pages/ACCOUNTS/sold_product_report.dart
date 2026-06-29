import 'dart:convert';
import 'dart:io';

import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:excel/excel.dart' as excel;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Sold_pro_report extends StatefulWidget {
  const Sold_pro_report({super.key});

  @override
  State<Sold_pro_report> createState() => _Sold_pro_reportState();
}

class _Sold_pro_reportState extends State<Sold_pro_report> {
  List<Map<String, dynamic>> groupedData = [];
  List<Map<String, dynamic>> filteredProducts = [];
  List<Map<String, dynamic>> sta = [];
  List<Map<String, dynamic>> states = [];

  final TextEditingController searchController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  String? selectedstaff;
  String? selectedState;

  int currentPage = 1;
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMoreData = true;

  final drower d = drower();

  static const Color primaryColor = Color.fromARGB(255, 12, 80, 163);
  static const Color bgColor = Color(0xffF5F7FB);
  static const Color textColor = Color.fromARGB(255, 32, 43, 61);

  @override
  void initState() {
    super.initState();

    getSoldReport(isRefresh: true);
    getstaff();
    getStates();

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 220 &&
          !isLoadingMore &&
          hasMoreData &&
          !isLoading) {
        getSoldReport();
      }
    });
  }

  Future<String?> getTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  String _selectedStaffName() {
    if (selectedstaff == null || selectedstaff!.isEmpty) return 'All Staff';
    final item = sta.where((e) => e['id'].toString() == selectedstaff).toList();
    return item.isEmpty ? 'Selected Staff' : item.first['name'].toString();
  }

  String _selectedStateName() {
    if (selectedState == null || selectedState!.isEmpty) return 'All States';
    final item =
        states.where((e) => e['id'].toString() == selectedState).toList();
    return item.isEmpty ? 'Selected State' : item.first['name'].toString();
  }

  int get _totalSold {
    int total = 0;
    for (final item in filteredProducts) {
      total += _toInt(item['total_sold']);
    }
    return total;
  }

  double get _totalAmount {
    double total = 0;
    for (final item in filteredProducts) {
      total += _toDouble(item['total_amount']);
    }
    return total;
  }

  String get _dateRangeLabel {
    final start = startDateController.text.trim();
    final end = endDateController.text.trim();

    if (start.isEmpty && end.isEmpty) return 'All Dates';
    if (start.isNotEmpty && end.isNotEmpty) return '$start to $end';
    if (start.isNotEmpty) return 'From $start';
    return 'Until $end';
  }

  Future<void> getstaff() async {
    try {
      final token = await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/staffs/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final productsData = parsed['data'] ?? [];

        final stafflist = productsData.map<Map<String, dynamic>>((item) {
          return {
            'id': item['id'],
            'name': item['name'],
          };
        }).toList();

        setState(() {
          sta = stafflist;
        });
      }
    } catch (error) {
      debugPrint('Staff fetch error: $error');
    }
  }

  Future<void> getStates() async {
    try {
      final token = await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/states/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        setState(() {
          states = List<Map<String, dynamic>>.from(parsed['data'] ?? []);
        });
      }
    } catch (error) {
      debugPrint('State fetch error: $error');
    }
  }

  Future<void> getSoldReport({bool isRefresh = false}) async {
    if (isLoading || isLoadingMore) return;

    try {
      final token = await getTokenFromPrefs();

      if (isRefresh) {
        currentPage = 1;
        hasMoreData = true;
        groupedData.clear();
        filteredProducts.clear();
        isLoading = true;
      } else {
        isLoadingMore = true;
      }

      setState(() {});

      final uri = Uri.parse('$api/api/sold/products/').replace(
        queryParameters: {
          'page': currentPage.toString(),
          if (searchController.text.trim().isNotEmpty)
            'search': searchController.text.trim(),
          if (selectedstaff != null && selectedstaff!.isNotEmpty)
            'staff_id': selectedstaff!,
          if (startDateController.text.trim().isNotEmpty)
            'start_date': startDateController.text.trim(),
          if (endDateController.text.trim().isNotEmpty)
            'end_date': endDateController.text.trim(),
          if (selectedState != null && selectedState!.isNotEmpty)
            'state_id': selectedState!,
        },
      );

      debugPrint('SOLD PRODUCT URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('SOLD PRODUCT STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final List<dynamic> soldProducts = parsed['results']?['data'] ?? [];

        final orderList = soldProducts.map<Map<String, dynamic>>((item) {
          return {
            'date': item['date'] ?? '',
            'product': item['product'] ?? '',
            'order': item['order'] ?? '',
            'manage_staff': item['manage_staff'] ?? '',
            'family': item['family'] ?? '',
            'customer': item['customer'] ?? '',
            'state': item['state'] ?? '',
            'status': item['status'] ?? '',
            'total_sold': item['total_sold'] ?? 0,
            'total_amount': item['total_amount'] ?? 0,
            'stock': item['stock'] ?? 0,
          };
        }).toList();

        setState(() {
          groupedData.addAll(orderList);
          filteredProducts = List<Map<String, dynamic>>.from(groupedData);
          hasMoreData = parsed['next'] != null;
          if (hasMoreData) currentPage++;
        });
      } else {
        debugPrint('Sold report error: ${response.statusCode}');
        debugPrint(response.body);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch sold report (${response.statusCode})'),
          ),
        );
      }
    } catch (error) {
      debugPrint('Sold report exception: $error');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching sold product report')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
      }
    }
  }

  Future<void> exportSoldProductsToExcel() async {
    if (filteredProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }

    final workbook = excel.Excel.createExcel();
    final sheet = workbook['Sold Product Report'];

    final titleStyle = excel.CellStyle(
      bold: true,
      fontColorHex: '#FFFFFF',
      backgroundColorHex: '#0F172A',
      horizontalAlign: excel.HorizontalAlign.Center,
      verticalAlign: excel.VerticalAlign.Center,
    );

    final infoLabelStyle = excel.CellStyle(
      bold: true,
      fontColorHex: '#334155',
      backgroundColorHex: '#EAF2FF',
    );

    final infoValueStyle = excel.CellStyle(
      fontColorHex: '#0F172A',
      backgroundColorHex: '#F8FAFC',
    );

    final headerStyle = excel.CellStyle(
      bold: true,
      fontColorHex: '#FFFFFF',
      backgroundColorHex: '#2563EB',
      horizontalAlign: excel.HorizontalAlign.Center,
      verticalAlign: excel.VerticalAlign.Center,
    );

    final normalStyle = excel.CellStyle(
      fontColorHex: '#0F172A',
      backgroundColorHex: '#FFFFFF',
      horizontalAlign: excel.HorizontalAlign.Center,
      verticalAlign: excel.VerticalAlign.Center,
    );

    final alternateStyle = excel.CellStyle(
      fontColorHex: '#0F172A',
      backgroundColorHex: '#F8FAFC',
      horizontalAlign: excel.HorizontalAlign.Center,
      verticalAlign: excel.VerticalAlign.Center,
    );

    final amountStyle = excel.CellStyle(
      fontColorHex: '#0F172A',
      backgroundColorHex: '#FFFFFF',
      horizontalAlign: excel.HorizontalAlign.Center,
      verticalAlign: excel.VerticalAlign.Center,
    );

    void setCell(int col, int row, dynamic value, {excel.CellStyle? style}) {
      final cell = sheet.cell(
        excel.CellIndex.indexByColumnRow(
          columnIndex: col,
          rowIndex: row,
        ),
      );

      cell.value = value?.toString() ?? '';

      if (style != null) {
        cell.cellStyle = style;
      }
    }

    double totalAmount = 0;
    int totalSold = 0;

    for (final item in filteredProducts) {
      totalAmount += _toDouble(item['total_amount']);
      totalSold += _toInt(item['total_sold']);
    }

    sheet.merge(
      excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      excel.CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: 0),
    );

    setCell(0, 0, 'SOLD PRODUCT REPORT', style: titleStyle);

    setCell(0, 2, 'Generated At', style: infoLabelStyle);
    setCell(
      1,
      2,
      DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
      style: infoValueStyle,
    );
    setCell(2, 2, 'Total Rows', style: infoLabelStyle);
    setCell(3, 2, filteredProducts.length, style: infoValueStyle);
    setCell(4, 2, 'Total Sold', style: infoLabelStyle);
    setCell(5, 2, totalSold, style: infoValueStyle);
    setCell(6, 2, 'Total Amount', style: infoLabelStyle);
    setCell(7, 2, totalAmount.toStringAsFixed(2), style: infoValueStyle);

    setCell(0, 3, 'Search', style: infoLabelStyle);
    setCell(
      1,
      3,
      searchController.text.trim().isEmpty
          ? 'All'
          : searchController.text.trim(),
      style: infoValueStyle,
    );
    setCell(2, 3, 'Staff', style: infoLabelStyle);
    setCell(3, 3, _selectedStaffName(), style: infoValueStyle);
    setCell(4, 3, 'State', style: infoLabelStyle);
    setCell(5, 3, _selectedStateName(), style: infoValueStyle);
    setCell(6, 3, 'Date Range', style: infoLabelStyle);
    setCell(7, 3, _dateRangeLabel, style: infoValueStyle);

    final headers = [
      'Sl No',
      'Date',
      'Order',
      'Product',
      'Staff',
      'Family',
      'Customer',
      'State',
      'Status',
      'Total Sold',
      'Amount',
      'Stock',
    ];

    for (int i = 0; i < headers.length; i++) {
      setCell(i, 5, headers[i], style: headerStyle);
    }

    for (int i = 0; i < filteredProducts.length; i++) {
      final item = filteredProducts[i];
      final row = i + 6;
      final rowStyle = i.isOdd ? alternateStyle : normalStyle;

      setCell(0, row, i + 1, style: rowStyle);
      setCell(1, row, item['date'], style: rowStyle);
      setCell(2, row, item['order'], style: rowStyle);
      setCell(3, row, item['product'], style: rowStyle);
      setCell(4, row, item['manage_staff'], style: rowStyle);
      setCell(5, row, item['family'], style: rowStyle);
      setCell(6, row, item['customer'], style: rowStyle);
      setCell(7, row, item['state'], style: rowStyle);
      setCell(8, row, item['status'], style: rowStyle);
      setCell(9, row, item['total_sold'], style: rowStyle);
      setCell(10, row, item['total_amount'], style: amountStyle);
      setCell(11, row, item['stock'], style: rowStyle);
    }

    final totalRow = filteredProducts.length + 7;

    setCell(0, totalRow, 'TOTAL', style: titleStyle);
    for (int col = 1; col <= 8; col++) {
      setCell(col, totalRow, '', style: titleStyle);
    }
    setCell(9, totalRow, totalSold, style: titleStyle);
    setCell(10, totalRow, totalAmount.toStringAsFixed(2), style: titleStyle);
    setCell(11, totalRow, '', style: titleStyle);

    sheet.setColWidth(0, 8);
    sheet.setColWidth(1, 14);
    sheet.setColWidth(2, 15);
    sheet.setColWidth(3, 42);
    sheet.setColWidth(4, 24);
    sheet.setColWidth(5, 16);
    sheet.setColWidth(6, 28);
    sheet.setColWidth(7, 24);
    sheet.setColWidth(8, 18);
    sheet.setColWidth(9, 16);
    sheet.setColWidth(10, 14);
    sheet.setColWidth(11, 12);

    final bytes = workbook.encode();

    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate Excel')),
      );
      return;
    }

    final dir = await getApplicationDocumentsDirectory();

    final file = File(
      '${dir.path}/Sold_Product_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx',
    );

    await file.writeAsBytes(bytes);
    final result = await OpenFilex.open(file.path);

    debugPrint("Excel Open Result: ${result.type}");
    debugPrint("Message: ${result.message}");
  }

  Future<void> _refreshData() async {
    await getSoldReport(isRefresh: true);
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final now = DateTime.now();

    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: startDateController.text.isNotEmpty &&
              endDateController.text.isNotEmpty
          ? DateTimeRange(
              start: DateTime.parse(startDateController.text),
              end: DateTime.parse(endDateController.text),
            )
          : DateTimeRange(start: now, end: now),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      setState(() {
        startDateController.text =
            DateFormat('yyyy-MM-dd').format(pickedRange.start);
        endDateController.text =
            DateFormat('yyyy-MM-dd').format(pickedRange.end);
      });

      getSoldReport(isRefresh: true);
    }
  }

  void _clearFilters() {
    setState(() {
      searchController.clear();
      startDateController.clear();
      endDateController.clear();
      selectedstaff = null;
      selectedState = null;
    });

    getSoldReport(isRefresh: true);
  }

  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();

    if (dep == "BDO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => bdo_dashbord()),
      );
    } else if (dep == "BDM") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => bdm_dashbord()),
      );
    } else if (dep == "warehouse") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WarehouseDashboard()),
      );
    } else if (dep == "CEO" || dep == "COO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ceo_dashboard()),
      );
    } else if (dep == "CSO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => cso_dashboard()),
      );
    } else if (dep == "Warehouse Admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WarehouseAdmin()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => dashboard()),
      );
    }
  }

  Widget _buildHeaderSummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 12, 80, 163),
            Color.fromARGB(255, 35, 129, 232),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _summaryMetric(
            title: 'Rows',
            value: filteredProducts.length.toString(),
            icon: Icons.list_alt_rounded,
          ),
          const SizedBox(width: 10),
          _summaryMetric(
            title: 'Sold',
            value: _totalSold.toString(),
            icon: Icons.shopping_bag_outlined,
          ),
          const SizedBox(width: 10),
          _summaryMetric(
            title: 'Amount',
            value: '₹${_totalAmount.toStringAsFixed(0)}',
            icon: Icons.currency_rupee,
          ),
        ],
      ),
    );
  }

  Widget _summaryMetric({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 8),
            Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.78),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: "Search product, order, customer...",
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: primaryColor),
          suffixIcon: searchController.text.trim().isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    setState(() {
                      searchController.clear();
                    });
                    getSoldReport(isRefresh: true);
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onChanged: (_) {
          Future.delayed(const Duration(milliseconds: 450), () {
            if (mounted) {
              getSoldReport(isRefresh: true);
            }
          });
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _dropdownContainer(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedstaff,
                      isExpanded: true,
                      hint: const Text(
                        "Staff",
                        style: TextStyle(fontSize: 13),
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: primaryColor,
                      ),
                      items: sta.map<DropdownMenuItem<String>>((staff) {
                        return DropdownMenuItem<String>(
                          value: staff['id'].toString(),
                          child: Text(
                            staff['name'].toString(),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedstaff = newValue;
                        });
                        getSoldReport(isRefresh: true);
                      },
                    ),
                  ),
                  icon: Icons.person_outline,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dropdownContainer(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedState,
                      isExpanded: true,
                      hint: const Text(
                        "State",
                        style: TextStyle(fontSize: 13),
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: primaryColor,
                      ),
                      items: states.map<DropdownMenuItem<String>>((state) {
                        return DropdownMenuItem<String>(
                          value: state['id'].toString(),
                          child: Text(
                            state['name'].toString(),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedState = value;
                        });
                        getSoldReport(isRefresh: true);
                      },
                    ),
                  ),
                  icon: Icons.location_on_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _dateChip(),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: _clearFilters,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.refresh_rounded, color: Colors.red, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Reset',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdownContainer({
    required Widget child,
    required IconData icon,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryColor),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _dateChip() {
    return InkWell(
      onTap: () => _selectDateRange(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: primaryColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _dateRangeLabel,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const Icon(Icons.edit_calendar, color: primaryColor, size: 17),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> order) {
    final date = order['date']?.toString() ?? '';
    final product = order['product']?.toString() ?? '';
    final stock = _toInt(order['stock']);
    final totalSold = _toInt(order['total_sold']);
    final amount = _toDouble(order['total_amount']);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 7, 14, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    product,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _stockBadge(stock),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _miniTile(
                        label: 'Sold',
                        value: totalSold.toString(),
                        icon: Icons.shopping_cart_outlined,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _miniTile(
                        label: 'Amount',
                        value: '₹${amount.toStringAsFixed(2)}',
                        icon: Icons.currency_rupee,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _infoRow(Icons.receipt_long_outlined, 'Order', order['order']),
                _infoRow(Icons.person_outline, 'Staff', order['manage_staff']),
                _infoRow(Icons.groups_2_outlined, 'Family', order['family']),
                _infoRow(Icons.account_circle_outlined, 'Customer',
                    order['customer']),
                _infoRow(Icons.location_on_outlined, 'State', order['state']),
                _infoRow(Icons.verified_outlined, 'Status', order['status']),
                _infoRow(Icons.calendar_today_outlined, 'Date', date),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockBadge(int stock) {
    final bool lowStock = stock <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: lowStock ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: lowStock ? Colors.red.shade100 : Colors.orange.shade100,
        ),
      ),
      child: Text(
        'Stock $stock',
        style: TextStyle(
          color: lowStock ? Colors.red : Colors.orange.shade800,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _miniTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, dynamic value) {
    final text = value?.toString() ?? '';

    if (text.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade500, size: 17),
          const SizedBox(width: 8),
          SizedBox(
            width: 74,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.16),
        Icon(Icons.search_off_rounded, color: Colors.grey.shade400, size: 64),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'No sold products found',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Center(
          child: Text(
            'Try changing filters or date range',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    if (isLoading && filteredProducts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (filteredProducts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 18),
      itemCount: filteredProducts.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filteredProducts.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(color: primaryColor),
            ),
          );
        }

        return _buildProductCard(filteredProducts[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: const Text(
            "Sold Product Report",
            style: TextStyle(
              fontSize: 15,
              color: textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: textColor),
            onPressed: _navigateBack,
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh, color: textColor),
              onPressed: () => getSoldReport(isRefresh: true),
            ),
            IconButton(
              tooltip: 'Export Excel',
              icon: const Icon(Icons.file_download_outlined, color: primaryColor),
              onPressed: exportSoldProductsToExcel,
            ),
          ],
        ),
        body: Column(
          children: [
            // _buildHeaderSummary(),
            _buildSearchBox(),
            _buildFilters(),
            Expanded(
              child: RefreshIndicator(
                color: primaryColor,
                onRefresh: _refreshData,
                child: _buildList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    searchController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    super.dispose();
  }
}