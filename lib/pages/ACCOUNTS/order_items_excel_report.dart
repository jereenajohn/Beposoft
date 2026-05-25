import 'dart:convert';
import 'dart:io';

import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:excel/excel.dart' as ex;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderItemsExcelReport extends StatefulWidget {
  final int warehouseId;

  const OrderItemsExcelReport({
    super.key,
    this.warehouseId = 1,
  });

  @override
  State<OrderItemsExcelReport> createState() => _OrderItemsExcelReportState();
}

class _OrderItemsExcelReportState extends State<OrderItemsExcelReport> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  bool _hasError = false;
  bool _isExporting = false;

  String _errorMessage = '';
  String _warehouseName = '';
  String _message = '';

  int _count = 0;

  late DateTime _fromDate;
  late DateTime _toDate;

  List<Map<String, dynamic>> _orderItems = [];
  List<Map<String, dynamic>> _companies = [];
  String _selectedCompanyId = '';
  bool _isCompanyLoading = false;
  final ScrollController _horizontalTableController = ScrollController();

  /*
    Change this baseUrl if your project already has api variable.
    Example:
    final String baseUrl = api;
  */
  final String baseUrl = 'https://bepocart.in';

  @override
  void initState() {
    super.initState();

    final DateTime now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = now;

    fetchCompanies();
    fetchOrderItemsExcelReport();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalTableController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatDisplayDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return '';
    }

    try {
      final DateTime date = DateTime.parse(value.toString());

      const List<String> months = [
        'JAN',
        'FEB',
        'MAR',
        'APR',
        'MAY',
        'JUN',
        'JUL',
        'AUG',
        'SEP',
        'OCT',
        'NOV',
        'DEC',
      ];

      final String day = date.day.toString().padLeft(2, '0');
      final String month = months[date.month - 1];
      final String year = date.year.toString().substring(2);

      return '$day-$month-$year';
    } catch (e) {
      return value.toString();
    }
  }

  String _formatAmount(dynamic value) {
    final double amount = double.tryParse(value.toString()) ?? 0.0;
    return amount.toStringAsFixed(2);
  }

  String _formatQuantity(dynamic value) {
    final double qty = double.tryParse(value.toString()) ?? 0.0;
    if (qty == qty.roundToDouble()) {
      return qty.toInt().toString();
    }
    return qty.toStringAsFixed(2);
  }

  List<double> _getAvailableTaxPercentages() {
    final Set<double> taxPercentages = {};

    for (final Map<String, dynamic> item in _orderItems) {
      final double taxPercentage =
          double.tryParse(item['tax_percentage']?.toString() ?? '0') ?? 0.0;

      if (taxPercentage > 0) {
        taxPercentages.add(taxPercentage);
      }
    }

    final List<double> sortedTaxPercentages = taxPercentages.toList();
    sortedTaxPercentages.sort();

    return sortedTaxPercentages;
  }

  String _formatTaxColumnTitle(double taxPercentage) {
    if (taxPercentage == taxPercentage.roundToDouble()) {
      return 'Tax ${taxPercentage.toInt()}%';
    }

    return 'Tax ${taxPercentage.toStringAsFixed(2)}%';
  }

  String _getTaxValueForPercentage(
    Map<String, dynamic> item,
    double columnTaxPercentage,
  ) {
    final double itemTaxPercentage =
        double.tryParse(item['tax_percentage']?.toString() ?? '0') ?? 0.0;

    if (itemTaxPercentage == columnTaxPercentage) {
      return _formatAmount(item['tax']);
    }

    return '';
  }

  Future<void> fetchCompanies() async {
    setState(() {
      _isCompanyLoading = true;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      final Uri url = Uri.parse('$baseUrl/api/company/data/');

      debugPrint('COMPANY LIST URL: $url');

      final http.Response response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      debugPrint('COMPANY LIST STATUS: ${response.statusCode}');
      debugPrint('COMPANY LIST BODY: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(response.body);

        final List<dynamic> data = decodedData is Map<String, dynamic>
            ? decodedData['data'] ?? []
            : decodedData is List
                ? decodedData
                : [];

        final List<Map<String, dynamic>> companyList = data
            .map((item) => Map<String, dynamic>.from(item as Map))
            .map((item) {
          return {
            'id': item['id'],
            'name': item['name']?.toString() ?? '',
          };
        }).where((item) {
          return item['id'] != null && item['name'].toString().isNotEmpty;
        }).toList();

        setState(() {
          _companies = companyList;
          _isCompanyLoading = false;
        });
      } else {
        setState(() {
          _companies = [];
          _isCompanyLoading = false;
        });
      }
    } catch (e) {
      debugPrint('COMPANY LIST ERROR: $e');

      setState(() {
        _companies = [];
        _isCompanyLoading = false;
      });
    }
  }

  Future<void> fetchOrderItemsExcelReport() async {
    if (_fromDate.isAfter(_toDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('From date cannot be greater than To date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      final String fromDate = _formatDate(_fromDate);
      final String toDate = _formatDate(_toDate);
      final String search = _searchController.text.trim();

      final Uri url = Uri.parse(
        '$baseUrl/api/order/items/excel/export/${widget.warehouseId}/$fromDate/$toDate/',
      ).replace(
        queryParameters: {
          if (search.isNotEmpty) 'search': search,
          if (_selectedCompanyId.isNotEmpty) 'company_id': _selectedCompanyId,
        },
      );

      debugPrint('ORDER ITEMS EXCEL REPORT URL: $url');

      final http.Response response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      debugPrint('ORDER ITEMS EXCEL REPORT STATUS: ${response.statusCode}');
      debugPrint('ORDER ITEMS EXCEL REPORT BODY: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == true) {
        final List<dynamic> results = responseData['results'] ?? [];

        setState(() {
          _message = responseData['message']?.toString() ?? '';
          _warehouseName = responseData['warehouse_name']?.toString() ?? '';
          _count =
              int.tryParse(responseData['count'].toString()) ?? results.length;
          _orderItems = results
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
          _isLoading = false;
          _hasError = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = responseData['message']?.toString() ??
              'Failed to fetch order items report';
          _orderItems = [];
        });
      }
    } catch (e) {
      debugPrint('ORDER ITEMS EXCEL REPORT ERROR: $e');

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
        _orderItems = [];
      });
    }
  }

  Future<void> _exportTableDataToExcel() async {
    if (_orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No table data available to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      var excel = ex.Excel.createExcel();

      final defaultSheet = excel.getDefaultSheet();
      if (defaultSheet != null) {
        excel.delete(defaultSheet);
      }

      ex.Sheet sheet = excel["Order Items Report"];

      final List<double> taxPercentages = _getAvailableTaxPercentages();

      sheet.setColWidth(0, 14); // DATE
      sheet.setColWidth(1, 18); // STATE
      sheet.setColWidth(2, 18); // Voucher Number
      sheet.setColWidth(3, 28); // party name
      sheet.setColWidth(4, 38); // item name
      sheet.setColWidth(5, 10); // item qty
      sheet.setColWidth(6, 12); // item rate
      sheet.setColWidth(7, 12); // per
      sheet.setColWidth(8, 18); // item basic amt

      for (int i = 0; i < taxPercentages.length; i++) {
        sheet.setColWidth(9 + i, 14);
      }

      sheet.setColWidth(9 + taxPercentages.length, 16);

      final List<String> headers = [
        'DATE',
        'state',
        'Voucher Number',
        'party name',
        'item name',
        'item qty',
        'item rate',
        'per',
        'item basic amt',
        ...taxPercentages.map((tax) => _formatTaxColumnTitle(tax)),
        'total amount',
      ];

      for (int col = 0; col < headers.length; col++) {
        final cell = sheet.cell(
          ex.CellIndex.indexByColumnRow(
            columnIndex: col,
            rowIndex: 0,
          ),
        );
        cell.value = headers[col];
      }

      for (int rowIndex = 0; rowIndex < _orderItems.length; rowIndex++) {
        final Map<String, dynamic> item = _orderItems[rowIndex];

        final List<String> rowData = [
          _formatDisplayDate(item['date']),
          item['state']?.toString() ?? '',
          item['voucher_no']?.toString() ?? '',
          item['party_name']?.toString() ?? '',
          item['item_name']?.toString() ?? '',
          _formatQuantity(item['item_quantity']),
          _formatAmount(item['item_rate']),
          item['unit']?.toString() ?? '',
          _formatAmount(item['item_basic_amount']),
          ...taxPercentages.map(
            (taxPercentage) => _getTaxValueForPercentage(item, taxPercentage),
          ),
          _formatAmount(item['total_amount']),
        ];

        for (int col = 0; col < rowData.length; col++) {
          final cell = sheet.cell(
            ex.CellIndex.indexByColumnRow(
              columnIndex: col,
              rowIndex: rowIndex + 1,
            ),
          );
          cell.value = rowData[col];
        }
      }

      final fileBytes = excel.encode();

      if (fileBytes == null) {
        throw Exception('Failed to generate Excel file');
      }

      final Directory tempDir = await getTemporaryDirectory();

      final String filePath =
          "${tempDir.path}/Order_Items_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx";

      final File file = File(filePath);
      await file.writeAsBytes(fileBytes, flush: true);

      if (!mounted) return;

      setState(() {
        _isExporting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Excel exported successfully'),
          backgroundColor: Colors.green,
        ),
      );

      await OpenFilex.open(file.path);
    } catch (e) {
      debugPrint('ORDER ITEMS EXCEL EXPORT ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isExporting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectFromDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _fromDate = pickedDate;
      });

      fetchOrderItemsExcelReport();
    }
  }

  Future<void> _selectToDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _toDate = pickedDate;
      });

      fetchOrderItemsExcelReport();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    fetchOrderItemsExcelReport();
  }

  void _clearFilters() {
    final DateTime now = DateTime.now();

    setState(() {
      _searchController.clear();
      _selectedCompanyId = '';
      _fromDate = DateTime(now.year, now.month, 1);
      _toDate = now;
    });

    fetchOrderItemsExcelReport();
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        children: [
          _summaryItem(
            title: 'Warehouse',
            value: _warehouseName.isEmpty
                ? 'Warehouse ${widget.warehouseId}'
                : _warehouseName,
          ),
          _summaryItem(
            title: 'From Date',
            value: _formatDisplayDate(_formatDate(_fromDate)),
          ),
          _summaryItem(
            title: 'To Date',
            value: _formatDisplayDate(_formatDate(_toDate)),
          ),
          _summaryItem(
            title: 'Total Items',
            value: _count.toString(),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required String title,
    required String value,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => fetchOrderItemsExcelReport(),
            decoration: InputDecoration(
              hintText: 'Search voucher no, party name, item name',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.close),
                    ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.blue.shade700,
                  width: 1.4,
                ),
              ),
            ),
            onChanged: (_) {
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          _companyDropdown(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _dateButton(
                  label: 'From',
                  value: _formatDisplayDate(_formatDate(_fromDate)),
                  onTap: _selectFromDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dateButton(
                  label: 'To',
                  value: _formatDisplayDate(_formatDate(_toDate)),
                  onTap: _selectToDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : fetchOrderItemsExcelReport,
                  icon: const Icon(Icons.filter_alt),
                  label: const Text('Filter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _clearFilters,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                    side: BorderSide(color: Colors.blue.shade700),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Widget _dateButton({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month,
              size: 18,
              color: Colors.blue.shade700,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _companyDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCompanyId.isEmpty ? null : _selectedCompanyId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Company',
        prefixIcon: const Icon(Icons.business),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.blue.shade700,
            width: 1.4,
          ),
        ),
      ),
      hint: Text(
        _isCompanyLoading ? 'Loading companies...' : 'All Companies',
      ),
      items: [
        const DropdownMenuItem<String>(
          value: '',
          child: Text('All Companies'),
        ),
        ..._companies.map((company) {
          return DropdownMenuItem<String>(
            value: company['id'].toString(),
            child: Text(
              company['name']?.toString() ?? '',
              overflow: TextOverflow.ellipsis,
            ),
          );
        }),
      ],
      onChanged: _isCompanyLoading
          ? null
          : (String? value) {
              setState(() {
                _selectedCompanyId = value ?? '';
              });

              fetchOrderItemsExcelReport();
            },
    );
  }

  Widget _buildTableSection() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasError) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 46,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage.isEmpty ? 'Something went wrong' : _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: fetchOrderItemsExcelReport,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_orderItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text(
            'No order items found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }
    final List<double> taxPercentages = _getAvailableTaxPercentages();
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Scrollbar(
          controller: _horizontalTableController,
          thumbVisibility: true,
          notificationPredicate: (notification) => notification.depth == 0,
          child: SingleChildScrollView(
            controller: _horizontalTableController,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: 1240 + (taxPercentages.length * 110),
              ),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  Colors.blue.shade700,
                ),
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
                dataTextStyle: const TextStyle(
                  color: Colors.black87,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
                columnSpacing: 20,
                horizontalMargin: 14,
                headingRowHeight: 44,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 66,
                columns: [
                  const DataColumn(label: Text('Date')),
                  const DataColumn(label: Text('State')),
                  const DataColumn(label: Text('Voucher No')),
                  const DataColumn(label: Text('Party Name')),
                  const DataColumn(label: Text('Item Name')),
                  const DataColumn(label: Text('Qty')),
                  const DataColumn(label: Text('Rate')),
                  const DataColumn(label: Text('Unit')),
                  const DataColumn(label: Text('Basic Amount')),
                  ...taxPercentages.map(
                    (taxPercentage) => DataColumn(
                      label: Text(_formatTaxColumnTitle(taxPercentage)),
                    ),
                  ),
                  const DataColumn(label: Text('Total')),
                ],
                rows: List.generate(_orderItems.length, (index) {
                  final Map<String, dynamic> item = _orderItems[index];

                  return DataRow(
                    color: WidgetStateProperty.resolveWith<Color?>(
                      (states) {
                        if (index.isEven) {
                          return Colors.grey.shade50;
                        }
                        return Colors.white;
                      },
                    ),
                    cells: [
                      DataCell(Text(_formatDisplayDate(item['date']))),
                      DataCell(
                        SizedBox(
                          width: 120,
                          child: Text(
                            item['state']?.toString() ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text(item['voucher_no']?.toString() ?? '')),
                      DataCell(
                        SizedBox(
                          width: 180,
                          child: Text(
                            item['party_name']?.toString() ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 280,
                          child: Text(
                            item['item_name']?.toString() ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text(_formatQuantity(item['item_quantity']))),
                      DataCell(Text(_formatAmount(item['item_rate']))),
                      DataCell(Text(item['unit']?.toString() ?? '')),
                      DataCell(Text(_formatAmount(item['item_basic_amount']))),
                      ...taxPercentages.map(
                        (taxPercentage) => DataCell(
                          Text(_getTaxValueForPercentage(item, taxPercentage)),
                        ),
                      ),
                      DataCell(
                        Text(
                          _formatAmount(item['total_amount']),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBar() {
    if (_message.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Text(
        _message,
        style: TextStyle(
          color: Colors.green.shade800,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildExportLoader() {
    if (!_isExporting) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Exporting Excel file...',
            style: TextStyle(
              color: Colors.blue.shade800,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();
    if (dep == "BDO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                bdo_dashbord()), // Replace AnotherPage with your target page
      );
    } else if (dep == "BDM") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                bdm_dashbord()), // Replace AnotherPage with your target page
      );
    } else if (dep == "warehouse") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                WarehouseDashboard()), // Replace AnotherPage with your target page
      );
    } else if (dep == "CEO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ceo_dashboard()), // Replace AnotherPage with your target page
      );
    } else if (dep == "COO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ceo_dashboard()), // Replace AnotherPage with your target page
      );
    } else if (dep == "Warehouse Admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                WarehouseAdmin()), // Replace AnotherPage with your target page
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => dashboard()),
      );
    }
  }

  Future<void> _handleRefresh() async {
    await fetchOrderItemsExcelReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Order Items Excel Report',
          style: TextStyle(fontSize: 18),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => _navigateBack(),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading || _isExporting || _orderItems.isEmpty
                ? null
                : _exportTableDataToExcel,
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export Excel',
          ),
          IconButton(
            onPressed:
                _isLoading || _isExporting ? null : fetchOrderItemsExcelReport,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildSummaryCard(),
                _buildFilterSection(),
                _buildMessageBar(),
                _buildExportLoader(),
                _buildTableSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
