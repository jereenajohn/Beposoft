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
import 'package:excel/excel.dart' as excel;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderComparisonReportPage extends StatefulWidget {
  const OrderComparisonReportPage({
    super.key,
    required this.baseUrl,
  });

  final String baseUrl;

  @override
  State<OrderComparisonReportPage> createState() =>
      _OrderComparisonReportPageState();
}

class _OrderComparisonReportPageState extends State<OrderComparisonReportPage> {
  bool loading = false;
  bool initialLoading = true;
  String token = '';

  Map<String, dynamic>? report;

  List<dynamic> familyData = [];
  List<dynamic> staffs = [];
  List<dynamic> customerOptions = [];
  List<dynamic> stateList = [];
  List<dynamic> companies = [];
  List<dynamic> parcelServices = [];

  final Map<String, String> filters = {
    'range1_start': '',
    'range1_end': '',
    'range2_start': '',
    'range2_end': '',
    'report_type': '',
    'search': '',
    'status': '',
    'payment_status': '',
    'cod_status': '',
    'family': '',
    'manage_staff': '',
    'customer': '',
    'state': '',
    'company': '',
    'warehouse': '',
    'parcel_service': '',
    'shipping_mode': '',
    'min_amount': '',
    'max_amount': '',
  };

  final List<Map<String, String>> reportTypeOptions = const [
    {'value': 'status_wise', 'label': 'Status Wise'},
    {'value': 'payment_wise', 'label': 'Payment Wise'},
    {'value': 'cod_status_wise', 'label': 'COD Status Wise'},
    {'value': 'family_wise', 'label': 'Family Wise'},
    {'value': 'staff_wise', 'label': 'Staff Wise'},
    {'value': 'state_wise', 'label': 'State Wise'},
    {'value': 'parcel_service_wise', 'label': 'Parcel Service Wise'},
  ];

  List<String> get selectedReportTypes {
    return (filters['report_type'] ?? '')
        .split(',')
        .where((e) => e.trim().isNotEmpty)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        showMsg('Token not found');
        return;
      }

      await Future.wait([
        fetchFamilyData(),
        fetchStaffs(),
        fetchCustomers(),
        fetchStates(),
        fetchCompanies(),
        fetchParcelServices(),
      ]);
    } finally {
      if (mounted) {
        setState(() => initialLoading = false);
      }
    }
  }

  Map<String, String> get headers => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Uri buildUri(String endpoint, [Map<String, String>? params]) {
    final base =
        widget.baseUrl.endsWith('/') ? widget.baseUrl : '${widget.baseUrl}/';

    final cleanParams = <String, String>{};

    if (params != null) {
      params.forEach((key, value) {
        if (value.trim().isNotEmpty) {
          cleanParams[key] = value;
        }
      });
    }

    return Uri.parse('$base$endpoint').replace(
      queryParameters: cleanParams.isEmpty ? null : cleanParams,
    );
  }

  Future<void> fetchFamilyData() async {
    try {
      final res = await http.get(buildUri('api/familys/'), headers: headers);
      final body = jsonDecode(res.body);

      if (!mounted) return;
      setState(() => familyData = body['data'] ?? []);
    } catch (e) {
      showMsg('Error fetching family data');
    }
  }

  Future<void> fetchStaffs([String search = '']) async {
    try {
      final res = await http.get(
        buildUri('api/get/staffs/', {
          'page': '1',
          'page_size': '1000',
          'search': search,
        }),
        headers: headers,
      );

      final body = jsonDecode(res.body);

      if (!mounted) return;
      setState(() {
        staffs = body['results']?['data'] ?? body['data'] ?? [];
      });
    } catch (e) {
      showMsg('Error fetching staffs');
    }
  }

  Future<void> fetchCustomers([String search = '']) async {
    try {
      final res = await http.get(
        buildUri('api/customers/', {'search': search}),
        headers: headers,
      );

      final body = jsonDecode(res.body);

      if (!mounted) return;
      setState(() => customerOptions = body['results'] ?? []);
    } catch (e) {
      if (!mounted) return;
      setState(() => customerOptions = []);
      showMsg('Failed to load customer options');
    }
  }

  Future<void> fetchStates() async {
    try {
      final res = await http.get(buildUri('api/states/'), headers: headers);
      final body = jsonDecode(res.body);

      if (!mounted) return;
      setState(() => stateList = body['data'] ?? []);
    } catch (e) {
      showMsg('Failed to load states');
    }
  }

  Future<void> fetchCompanies() async {
    try {
      final res =
          await http.get(buildUri('api/company/data/'), headers: headers);
      final body = jsonDecode(res.body);

      if (!mounted) return;
      setState(() => companies = body['data'] ?? []);
    } catch (e) {
      showMsg('Company fetch error');
    }
  }

  Future<void> fetchParcelServices() async {
    try {
      final res =
          await http.get(buildUri('api/parcal/service/'), headers: headers);
      final body = jsonDecode(res.body);

      if (!mounted) return;
      setState(() => parcelServices = body['data'] ?? []);
    } catch (e) {
      showMsg('Error fetching parcel services');
    }
  }

  Future<void> fetchReport() async {
    if ((filters['range1_start'] ?? '').isEmpty ||
        (filters['range1_end'] ?? '').isEmpty ||
        (filters['range2_start'] ?? '').isEmpty ||
        (filters['range2_end'] ?? '').isEmpty) {
      showMsg('Please select all date ranges');
      return;
    }

    if ((filters['report_type'] ?? '').isEmpty) {
      showMsg('Please select at least one report type');
      return;
    }

    try {
      setState(() => loading = true);

      final uri = buildUri(
        'api/orders/comparison/report/',
        Map<String, String>.from(filters),
      );

      debugPrint('ORDER COMPARISON URL: $uri');

      final res = await http.get(uri, headers: headers);
      debugPrint('ORDER COMPARISON STATUS: ${res.statusCode}');
      debugPrint('ORDER COMPARISON BODY: ${res.body}');

      final body = jsonDecode(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        setState(() => report = Map<String, dynamic>.from(body));
        showMsg('Comparison report loaded');
      } else {
        showMsg(
          body['message']?.toString() ??
              body['detail']?.toString() ??
              body['errors']?.toString() ??
              'Failed to fetch comparison report',
        );
      }
    } catch (e) {
      showMsg('Failed to fetch comparison report: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void handleChange(String key, dynamic value) {
    setState(() {
      filters[key] = value?.toString() ?? '';

      if (key == 'report_type') {
        report = null;
      }
    });
  }

  void clearFilters() {
    setState(() {
      for (final key in filters.keys) {
        filters[key] = '';
      }
      report = null;
    });
  }

  String formatAmount(dynamic amount) {
    final value = double.tryParse(amount?.toString() ?? '0') ?? 0;

    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(value);
  }

  String formatCompactAmount(dynamic amount) {
    final value = double.tryParse(amount?.toString() ?? '0') ?? 0;

    if (value.abs() >= 10000000) {
      return '₹${(value / 10000000).toStringAsFixed(2)} Cr';
    }

    if (value.abs() >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(2)} L';
    }

    if (value.abs() >= 1000) {
      return '₹${(value / 1000).toStringAsFixed(2)} K';
    }

    return '₹${value.toStringAsFixed(2)}';
  }

  String formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return '-';

    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(value.toString()));
    } catch (_) {
      return value.toString();
    }
  }

  String formatPercentage(dynamic value) {
    final number = double.tryParse(value?.toString() ?? '0') ?? 0;
    return '${number.toStringAsFixed(2)}%';
  }

  Color positiveNegativeColor(dynamic value) {
    final number = double.tryParse(value?.toString() ?? '0') ?? 0;

    if (number > 0) return const Color(0xFF16A34A);
    if (number < 0) return const Color(0xFFDC2626);

    return const Color(0xFF334155);
  }

  String signedNumber(dynamic value) {
    final number = num.tryParse(value?.toString() ?? '0') ?? 0;
    return '${number > 0 ? '+' : ''}$number';
  }

  String signedPercentage(dynamic value) {
    final number = num.tryParse(value?.toString() ?? '0') ?? 0;
    return '${number > 0 ? '+' : ''}${formatPercentage(number)}';
  }

  String signedAmount(dynamic value) {
    final number = num.tryParse(value?.toString() ?? '0') ?? 0;
    return '${number > 0 ? '+' : ''}${formatAmount(number)}';
  }

  String getReportTitleByType(String type) {
    return reportTypeOptions.firstWhere(
      (item) => item['value'] == type,
      orElse: () => {'label': 'Comparison'},
    )['label']!;
  }

  String getReportTitle() {
    if (selectedReportTypes.isEmpty) return 'Comparison';
    return selectedReportTypes.map(getReportTitleByType).join(', ');
  }

  Map<String, dynamic> getSelectedRowsByType(String type) {
    if (report == null || type.isEmpty) {
      return {
        'rows': [],
        'total': null,
      };
    }

    final backendTable = report?['comparison_tables']?[type];

    return {
      'rows': backendTable?['rows'] ?? [],
      'total': backendTable?['total'],
    };
  }

  Future<void> exportToExcel() async {
    if (report == null || selectedReportTypes.isEmpty) {
      showMsg('No report data to export');
      return;
    }

    final workbook = excel.Excel.createExcel();
    final sheet = workbook['Comparison Report'];
    int row = 0;

    final titleStyle = excel.CellStyle(
      bold: true,
      fontColorHex: '#FFFFFF',
      backgroundColorHex: '#1D4ED8',
      horizontalAlign: excel.HorizontalAlign.Center,
      verticalAlign: excel.VerticalAlign.Center,
    );

    final sectionStyle = excel.CellStyle(
      bold: true,
      fontColorHex: '#FFFFFF',
      backgroundColorHex: '#0F172A',
      horizontalAlign: excel.HorizontalAlign.Left,
      verticalAlign: excel.VerticalAlign.Center,
    );

    final headerStyle = excel.CellStyle(
      bold: true,
      fontColorHex: '#FFFFFF',
      backgroundColorHex: '#2563EB',
      horizontalAlign: excel.HorizontalAlign.Center,
      verticalAlign: excel.VerticalAlign.Center,
    );

    final labelStyle = excel.CellStyle(
      bold: true,
      fontColorHex: '#334155',
      backgroundColorHex: '#EAF2FF',
      horizontalAlign: excel.HorizontalAlign.Left,
      verticalAlign: excel.VerticalAlign.Center,
    );

    final valueStyle = excel.CellStyle(
      fontColorHex: '#0F172A',
      backgroundColorHex: '#F8FAFC',
      horizontalAlign: excel.HorizontalAlign.Left,
      verticalAlign: excel.VerticalAlign.Center,
    );

    final alternateRowStyle = excel.CellStyle(
      fontColorHex: '#0F172A',
      backgroundColorHex: '#F8FAFC',
      horizontalAlign: excel.HorizontalAlign.Left,
      verticalAlign: excel.VerticalAlign.Center,
    );

    final normalRowStyle = excel.CellStyle(
      fontColorHex: '#0F172A',
      backgroundColorHex: '#FFFFFF',
      horizontalAlign: excel.HorizontalAlign.Left,
      verticalAlign: excel.VerticalAlign.Center,
    );

    final totalStyle = excel.CellStyle(
      bold: true,
      fontColorHex: '#FFFFFF',
      backgroundColorHex: '#0F172A',
      horizontalAlign: excel.HorizontalAlign.Left,
      verticalAlign: excel.VerticalAlign.Center,
    );

    final positiveStyle = excel.CellStyle(
      bold: true,
      fontColorHex: '#15803D',
      backgroundColorHex: '#ECFDF5',
      horizontalAlign: excel.HorizontalAlign.Left,
      verticalAlign: excel.VerticalAlign.Center,
    );

    final negativeStyle = excel.CellStyle(
      bold: true,
      fontColorHex: '#DC2626',
      backgroundColorHex: '#FEF2F2',
      horizontalAlign: excel.HorizontalAlign.Left,
      verticalAlign: excel.VerticalAlign.Center,
    );

    final neutralStyle = excel.CellStyle(
      bold: true,
      fontColorHex: '#334155',
      backgroundColorHex: '#F1F5F9',
      horizontalAlign: excel.HorizontalAlign.Left,
      verticalAlign: excel.VerticalAlign.Center,
    );

    excel.CellStyle differenceStyle(dynamic value) {
      final number = double.tryParse(value?.toString() ?? '0') ?? 0;
      if (number > 0) return positiveStyle;
      if (number < 0) return negativeStyle;
      return neutralStyle;
    }

    void setCell(
      int columnIndex,
      int rowIndex,
      dynamic value, {
      excel.CellStyle? style,
    }) {
      final cell = sheet.cell(
        excel.CellIndex.indexByColumnRow(
          columnIndex: columnIndex,
          rowIndex: rowIndex,
        ),
      );

      cell.value = value?.toString() ?? '';

      if (style != null) {
        cell.cellStyle = style;
      }
    }

    void addStyledRow(
      List<dynamic> values, {
      excel.CellStyle? style,
      Map<int, excel.CellStyle>? columnStyles,
      int minColumns = 0,
    }) {
      final columnCount = values.length > minColumns ? values.length : minColumns;

      for (int i = 0; i < columnCount; i++) {
        setCell(
          i,
          row,
          i < values.length ? values[i] : '',
          style: columnStyles?[i] ?? style,
        );
      }

      row++;
    }

    void addBlankRow() {
      row++;
    }

    void addTitleRow(String title) {
      addStyledRow(
        [title],
        style: titleStyle,
        minColumns: 9,
      );
    }

    void addSectionRow(String title) {
      addStyledRow(
        [title],
        style: sectionStyle,
        minColumns: 9,
      );
    }

    void addKeyValueRow(
      String label,
      dynamic value, {
      String? label2,
      dynamic value2,
    }) {
      addStyledRow(
        [
          label,
          value ?? '',
          label2 ?? '',
          value2 ?? '',
        ],
        columnStyles: {
          0: labelStyle,
          1: valueStyle,
          2: label2 == null ? valueStyle : labelStyle,
          3: valueStyle,
        },
        minColumns: 4,
      );
    }

    void addTableHeader(List<dynamic> values) {
      addStyledRow(values, style: headerStyle, minColumns: values.length);
    }

    void addDataRow(
      List<dynamic> values, {
      bool isAlternate = false,
      bool isTotal = false,
      Map<int, excel.CellStyle>? columnStyles,
    }) {
      addStyledRow(
        values,
        style: isTotal
            ? totalStyle
            : isAlternate
                ? alternateRowStyle
                : normalRowStyle,
        columnStyles: columnStyles,
        minColumns: values.length,
      );
    }

    final comparison = report?['comparison'] ?? {};
    final range1 = report?['range1'] ?? {};
    final range2 = report?['range2'] ?? {};

    addTitleRow('ORDER COMPARISON REPORT');
    addStyledRow(
      [
        'Generated At',
        DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
        'Report Types',
        getReportTitle(),
      ],
      columnStyles: {
        0: labelStyle,
        1: valueStyle,
        2: labelStyle,
        3: valueStyle,
      },
      minColumns: 9,
    );
    addBlankRow();

    addSectionRow('SELECTED FILTERS');
    addKeyValueRow(
      'Range 1 Start',
      formatDate(filters['range1_start']),
      label2: 'Range 1 End',
      value2: formatDate(filters['range1_end']),
    );
    addKeyValueRow(
      'Range 2 Start',
      formatDate(filters['range2_start']),
      label2: 'Range 2 End',
      value2: formatDate(filters['range2_end']),
    );
    addKeyValueRow('Report Type', getReportTitle());
    addKeyValueRow('Search', filters['search']?.isEmpty == true ? 'All' : filters['search']);
    addKeyValueRow(
      'Status',
      filters['status']?.isEmpty == true ? 'All' : filters['status'],
      label2: 'Payment Status',
      value2: filters['payment_status']?.isEmpty == true
          ? 'All'
          : filters['payment_status'],
    );
    addKeyValueRow(
      'COD Status',
      filters['cod_status']?.isEmpty == true ? 'All' : filters['cod_status'],
      label2: 'Shipping Mode',
      value2: filters['shipping_mode']?.isEmpty == true
          ? 'All'
          : filters['shipping_mode'],
    );
    addKeyValueRow(
      'Minimum Amount',
      filters['min_amount']?.isEmpty == true ? 'All' : filters['min_amount'],
      label2: 'Maximum Amount',
      value2: filters['max_amount']?.isEmpty == true ? 'All' : filters['max_amount'],
    );
    addKeyValueRow(
      'Warehouse',
      filters['warehouse']?.isEmpty == true ? 'All' : filters['warehouse'],
    );
    addBlankRow();

    addSectionRow('RANGE SUMMARY');
    addTableHeader(['Range', 'Date Range', 'Total Orders', 'Total Amount']);
    addDataRow([
      'Range 1 Base',
      '${formatDate(filters['range1_start'])} - ${formatDate(filters['range1_end'])}',
      range1['order_count'] ?? 0,
      formatAmount(range1['total_amount']),
    ]);
    addDataRow([
      'Range 2 Compare',
      '${formatDate(filters['range2_start'])} - ${formatDate(filters['range2_end'])}',
      range2['order_count'] ?? 0,
      formatAmount(range2['total_amount']),
    ], isAlternate: true);
    addDataRow(
      [
        'Difference',
        'Range 2 - Range 1',
        signedNumber(comparison['order_count_difference']),
        signedAmount(comparison['amount_difference']),
      ],
      columnStyles: {
        0: neutralStyle,
        1: neutralStyle,
        2: differenceStyle(comparison['order_count_difference']),
        3: differenceStyle(comparison['amount_difference']),
      },
    );
    addBlankRow();

    addSectionRow('COMPARISON RESULT');
    addTableHeader(['Metric', 'Value']);
    addDataRow(
      [
        'Order Difference',
        signedNumber(comparison['order_count_difference']),
      ],
      columnStyles: {
        1: differenceStyle(comparison['order_count_difference']),
      },
    );
    addDataRow(
      [
        'Order Growth',
        signedPercentage(comparison['order_count_percentage']),
      ],
      isAlternate: true,
      columnStyles: {
        1: differenceStyle(comparison['order_count_percentage']),
      },
    );
    addDataRow(
      [
        'Amount Difference',
        signedAmount(comparison['amount_difference']),
      ],
      columnStyles: {
        1: differenceStyle(comparison['amount_difference']),
      },
    );
    addDataRow(
      [
        'Amount Growth',
        signedPercentage(comparison['amount_percentage']),
      ],
      isAlternate: true,
      columnStyles: {
        1: differenceStyle(comparison['amount_percentage']),
      },
    );
    addDataRow(
      ['Result', comparison['result'] ?? '-'],
      columnStyles: {
        1: (comparison['result']?.toString().toLowerCase() == 'increase')
            ? positiveStyle
            : (comparison['result']?.toString().toLowerCase() == 'decrease')
                ? negativeStyle
                : neutralStyle,
      },
    );
    addBlankRow();

    for (final type in selectedReportTypes) {
      final table = getSelectedRowsByType(type);
      final rows = List<dynamic>.from(table['rows'] ?? []);
      final total = table['total'];

      addSectionRow('${getReportTitleByType(type).toUpperCase()} COMPARISON');
      addTableHeader([
        'Name',
        'Range 1 Orders',
        'Range 1 Amount',
        'Range 2 Orders',
        'Range 2 Amount',
        'Order Difference',
        'Amount Difference',
        'Order %',
        'Amount %',
      ]);

      for (int i = 0; i < rows.length; i++) {
        final item = rows[i];

        addDataRow(
          [
            item['name'] ?? 'N/A',
            item['range1_orders'] ?? 0,
            formatAmount(item['range1_amount']),
            item['range2_orders'] ?? 0,
            formatAmount(item['range2_amount']),
            signedNumber(item['order_difference']),
            signedAmount(item['amount_difference']),
            signedPercentage(item['order_percentage']),
            signedPercentage(item['amount_percentage']),
          ],
          isAlternate: i.isOdd,
          columnStyles: {
            5: differenceStyle(item['order_difference']),
            6: differenceStyle(item['amount_difference']),
            7: differenceStyle(item['order_percentage']),
            8: differenceStyle(item['amount_percentage']),
          },
        );
      }

      if (total != null) {
        addDataRow(
          [
            total['name'] ?? 'TOTAL',
            total['range1_orders'] ?? 0,
            formatAmount(total['range1_amount']),
            total['range2_orders'] ?? 0,
            formatAmount(total['range2_amount']),
            signedNumber(total['order_difference']),
            signedAmount(total['amount_difference']),
            signedPercentage(total['order_percentage']),
            signedPercentage(total['amount_percentage']),
          ],
          isTotal: true,
        );
      }

      addBlankRow();
    }

    final bytes = workbook.encode();

    if (bytes == null) {
      showMsg('Failed to generate Excel');
      return;
    }

    final dir = await getApplicationDocumentsDirectory();

    final file = File(
      '${dir.path}/Order_Comparison_Report_${filters['range1_start']}_to_${filters['range2_end']}.xlsx',
    );

    await file.writeAsBytes(bytes);
    await OpenFilex.open(file.path);
  }

  void showMsg(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> pickDate(String key) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      handleChange(key, DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  Future<void> openReportTypeSelector() async {
    final selected = selectedReportTypes.toSet();

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Select Report Types',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setSheetState(() => selected.clear());
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.separated(
                        itemCount: reportTypeOptions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final item = reportTypeOptions[index];
                          final value = item['value']!;

                          return CheckboxListTile(
                            value: selected.contains(value),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            activeColor: const Color(0xFF2563EB),
                            title: Text(
                              item['label']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onChanged: (checked) {
                              setSheetState(() {
                                if (checked == true) {
                                  selected.add(value);
                                } else {
                                  selected.remove(value);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          handleChange('report_type', selected.join(','));
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.done_rounded),
                        label: const Text('Apply Report Type'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> openSearchDialog({
    required String title,
    required List<dynamic> items,
    required String filterKey,
    required String Function(dynamic item) labelBuilder,
    Future<void> Function(String search)? onSearch,
  }) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) {
        List<dynamic> localItems = List.from(items);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              content: SizedBox(
                width: 460,
                height: 480,
                child: Column(
                  children: [
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'Search',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      onChanged: (value) async {
                        if (onSearch != null) {
                          await onSearch(value);

                          setDialogState(() {
                            if (filterKey == 'manage_staff') {
                              localItems = List.from(staffs);
                            } else if (filterKey == 'customer') {
                              localItems = List.from(customerOptions);
                            }
                          });
                        } else {
                          setDialogState(() {
                            localItems = items.where((item) {
                              return labelBuilder(item)
                                  .toLowerCase()
                                  .contains(value.toLowerCase());
                            }).toList();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: localItems.isEmpty
                          ? const Center(
                              child: Text(
                                'No matching data found',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: localItems.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, index) {
                                final item = localItems[index];

                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    labelBuilder(item),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  trailing:
                                      const Icon(Icons.chevron_right_rounded),
                                  onTap: () {
                                    handleChange(filterKey, item['id']);
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          handleChange(filterKey, '');
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.clear_rounded),
                        label: const Text('Clear Selection'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String selectedLabel(
    List<dynamic> list,
    String key,
    String Function(dynamic) label,
  ) {
    final selectedId = filters[key] ?? '';

    if (selectedId.isEmpty) return 'All';

    final selectedItems = list
        .where((item) => item['id'].toString() == selectedId.toString())
        .toList();

    if (selectedItems.isEmpty) return 'Selected';

    return label(selectedItems.first);
  }

  double fieldWidthFromConstraints(BoxConstraints constraints) {
    const gap = 12.0;

    if (constraints.maxWidth >= 850) {
      return (constraints.maxWidth - (gap * 3)) / 4;
    }

    if (constraints.maxWidth >= 560) {
      return (constraints.maxWidth - (gap * 2)) / 3;
    }

    return (constraints.maxWidth - gap) / 2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
    appBar: AppBar(
  leading: IconButton(
    tooltip: 'Back',
    onPressed: _navigateBack,
    icon: const Icon(Icons.arrow_back_ios_new_rounded),
  ),
  title: const Text(
    'Order Comparison Report',
    style: TextStyle(fontWeight: FontWeight.w900),
  ),
  backgroundColor: Colors.white,
  foregroundColor: const Color(0xFF0F172A),
  elevation: 0,
  actions: [
    if (report != null)
      IconButton(
        tooltip: 'Export Excel',
        onPressed: exportToExcel,
        icon: const Icon(Icons.file_download_outlined),
      ),
    IconButton(
      tooltip: 'Clear filters',
      onPressed: clearFilters,
      icon: const Icon(Icons.refresh_rounded),
    ),
  ],
),
      body: Stack(
        children: [
          if (initialLoading)
            const Center(child: CircularProgressIndicator())
          else
            SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildHeaderCard(),
                  const SizedBox(height: 14),
                  buildFilterCard(),
                  if (report != null) ...[
                    const SizedBox(height: 16),
                    buildComparisonResultCard(),
                    const SizedBox(height: 16),
                    buildRangeSummaryCard(),
                    const SizedBox(height: 16),
                    ...selectedReportTypes.map(
                      (type) => buildCompareTable(
                        '${getReportTitleByType(type)} Comparison',
                        type,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    buildEmptyState(),
                  ],
                ],
              ),
            ),
          if (loading) buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1D4ED8),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withOpacity(0.25),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 14,
        children: [
          const SizedBox(
            width: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Comparison Report',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Compare two date ranges by staff, family, payment, COD, state, parcel service, and status.',
                  style: TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              headerPill(
                Icons.calendar_month_rounded,
                filters['range1_start']!.isEmpty
                    ? 'Range 1 pending'
                    : '${filters['range1_start']} to ${filters['range1_end']}',
              ),
              headerPill(
                Icons.compare_arrows_rounded,
                selectedReportTypes.isEmpty ? 'Type pending' : getReportTitle(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildFilterCard() {
    return buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle(
            title: 'Filters',
            subtitle:
                'Select required date ranges and report type. Other filters are optional.',
            icon: Icons.tune_rounded,
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final fieldWidth = fieldWidthFromConstraints(constraints);

              return Wrap(
                spacing: 12,
                runSpacing: 14,
                children: [
                  dateField('Range 1 Start', 'range1_start', fieldWidth),
                  dateField('Range 1 End', 'range1_end', fieldWidth),
                  dateField('Range 2 Start', 'range2_start', fieldWidth),
                  dateField('Range 2 End', 'range2_end', fieldWidth),
                  selectBox(
                    'Report Type',
                    selectedReportTypes.isEmpty
                        ? 'Select report types'
                        : getReportTitle(),
                    openReportTypeSelector,
                    fieldWidth,
                  ),
                  textField(
                    'Search',
                    'search',
                    'Invoice or customer',
                    fieldWidth,
                  ),
                  dropdownField(
                    'Status',
                    'status',
                    const [
                      'Invoice Created',
                      'Invoice Approved',
                      'Waiting For Confirmation',
                      'To Print',
                      'Packing under progress',
                      'Packed',
                      'Ready to ship',
                      'Shipped',
                      'Invoice Rejected',
                    ],
                    fieldWidth,
                  ),
                  dropdownField(
                    'Payment Status',
                    'payment_status',
                    const [
                      'paid',
                      'COD',
                      'credit',
                    ],
                    fieldWidth,
                    labels: const {
                      'paid': 'Paid',
                      'COD': 'COD',
                      'credit': 'Credit',
                    },
                  ),
                  dropdownField(
                    'COD Status',
                    'cod_status',
                    const [
                      'FULL_COD',
                      'PARTIAL_COD',
                    ],
                    fieldWidth,
                    labels: const {
                      'FULL_COD': 'Full COD',
                      'PARTIAL_COD': 'Partial COD',
                    },
                  ),
                  dropdownDynamic(
                    'Division',
                    'family',
                    familyData,
                    (item) =>
                        item['name'] ??
                        item['family_name'] ??
                        'Family ${item['id']}',
                    fieldWidth,
                  ),
                  dropdownDynamic(
                    'Company',
                    'company',
                    companies,
                    (item) =>
                        item['name'] ??
                        item['company_name'] ??
                        'Company ${item['id']}',
                    fieldWidth,
                  ),
                  selectBox(
                    'Staff',
                    selectedLabel(
                      staffs,
                      'manage_staff',
                      (item) =>
                          item['name'] ??
                          item['family_name'] ??
                          item['username'] ??
                          'Staff ${item['id']}',
                    ),
                    () => openSearchDialog(
                      title: 'Search Staff',
                      items: staffs,
                      filterKey: 'manage_staff',
                      labelBuilder: (item) =>
                          item['name'] ??
                          item['family_name'] ??
                          item['username'] ??
                          'Staff ${item['id']}',
                      onSearch: fetchStaffs,
                    ),
                    fieldWidth,
                  ),
                  selectBox(
                    'Customer',
                    selectedLabel(
                      customerOptions,
                      'customer',
                      (item) =>
                          item['name'] ??
                          item['customer_name'] ??
                          item['phone'] ??
                          'Customer ${item['id']}',
                    ),
                    () => openSearchDialog(
                      title: 'Search Customer',
                      items: customerOptions,
                      filterKey: 'customer',
                      labelBuilder: (item) =>
                          item['name'] ??
                          item['customer_name'] ??
                          item['phone'] ??
                          'Customer ${item['id']}',
                      onSearch: fetchCustomers,
                    ),
                    fieldWidth,
                  ),
                  selectBox(
                    'State',
                    selectedLabel(
                      stateList,
                      'state',
                      (item) =>
                          item['name'] ??
                          item['state_name'] ??
                          'State ${item['id']}',
                    ),
                    () => openSearchDialog(
                      title: 'Search State',
                      items: stateList,
                      filterKey: 'state',
                      labelBuilder: (item) =>
                          item['name'] ??
                          item['state_name'] ??
                          'State ${item['id']}',
                    ),
                    fieldWidth,
                  ),
                  selectBox(
                    'Parcel Service',
                    selectedLabel(
                      parcelServices,
                      'parcel_service',
                      (item) =>
                          item['name'] ??
                          item['parcel_service_name'] ??
                          item['service_name'] ??
                          'Parcel Service ${item['id']}',
                    ),
                    () => openSearchDialog(
                      title: 'Search Parcel Service',
                      items: parcelServices,
                      filterKey: 'parcel_service',
                      labelBuilder: (item) =>
                          item['name'] ??
                          item['parcel_service_name'] ??
                          item['service_name'] ??
                          'Parcel Service ${item['id']}',
                    ),
                    fieldWidth,
                  ),
                  textField(
                    'Min Amount',
                    'min_amount',
                    'Minimum amount',
                    fieldWidth,
                  ),
                  textField(
                    'Max Amount',
                    'max_amount',
                    'Maximum amount',
                    fieldWidth,
                  ),
                  textField(
                    'Shipping Mode',
                    'shipping_mode',
                    'Shipping mode',
                    fieldWidth,
                  ),
                  textField(
                    'Warehouse',
                    'warehouse',
                    'Warehouse',
                    fieldWidth,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: actionButton(
                  loading ? 'Comparing...' : 'Compare',
                  Icons.analytics_rounded,
                  const Color(0xFF2563EB),
                  loading ? null : fetchReport,
                  width: double.infinity,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: actionButton(
                  'Clear',
                  Icons.clear_rounded,
                  const Color(0xFF64748B),
                  clearFilters,
                  width: double.infinity,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildComparisonResultCard() {
    final comparison = report?['comparison'] ?? {};
    final result = comparison['result']?.toString() ?? '';
    final isIncrease = result.toLowerCase() == 'increase';

    return buildCard(
      leftBorderColor:
          isIncrease ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle(
            title: 'Comparison Result',
            subtitle:
                '${getReportTitle()} comparison between selected date ranges.',
            icon: Icons.insights_rounded,
            trailing: statusBadge(result),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              metricCard(
                title: 'Order Difference',
                value: signedNumber(comparison['order_count_difference']),
                icon: Icons.shopping_bag_outlined,
                valueColor:
                    positiveNegativeColor(comparison['order_count_difference']),
              ),
              metricCard(
                title: 'Order Growth',
                value: signedPercentage(comparison['order_count_percentage']),
                icon: Icons.trending_up_rounded,
                valueColor: positiveNegativeColor(
                  comparison['order_count_percentage'],
                ),
              ),
              metricCard(
                title: 'Amount Difference',
                value: signedAmount(comparison['amount_difference']),
                icon: Icons.currency_rupee_rounded,
                valueColor:
                    positiveNegativeColor(comparison['amount_difference']),
              ),
              metricCard(
                title: 'Amount Growth',
                value: signedPercentage(comparison['amount_percentage']),
                icon: Icons.stacked_line_chart_rounded,
                valueColor:
                    positiveNegativeColor(comparison['amount_percentage']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildRangeSummaryCard() {
    final comparison = report?['comparison'] ?? {};
    final range1 = report?['range1'] ?? {};
    final range2 = report?['range2'] ?? {};

    return buildCard(
      leftBorderColor: const Color(0xFF2563EB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle(
            title: 'Range Summary',
            subtitle: 'Range 2 is compared against Range 1.',
            icon: Icons.date_range_rounded,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              rangeBox(
                title: 'Range 1 Base',
                date:
                    '${formatDate(filters['range1_start'])} - ${formatDate(filters['range1_end'])}',
                orders: '${range1['order_count'] ?? 0}',
                amount: formatCompactAmount(range1['total_amount']),
              ),
              rangeBox(
                title: 'Range 2 Compare',
                date:
                    '${formatDate(filters['range2_start'])} - ${formatDate(filters['range2_end'])}',
                orders: '${range2['order_count'] ?? 0}',
                amount: formatCompactAmount(range2['total_amount']),
              ),
              rangeBox(
                title: 'Difference',
                date: 'Range 2 - Range 1',
                orders: signedNumber(comparison['order_count_difference']),
                amount: signedAmount(comparison['amount_difference']),
                color: positiveNegativeColor(comparison['amount_difference']),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                const Color(0xFFF8FAFC),
              ),
              dataRowMinHeight: 56,
              dataRowMaxHeight: 64,
              columns: [
                const DataColumn(label: Text('Metric')),
                DataColumn(
                  label: Text(
                    'Range 1\n${formatDate(filters['range1_start'])} to ${formatDate(filters['range1_end'])}',
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Range 2\n${formatDate(filters['range2_start'])} to ${formatDate(filters['range2_end'])}',
                  ),
                ),
                const DataColumn(label: Text('Difference')),
                const DataColumn(label: Text('Growth %')),
              ],
              rows: [
                DataRow(
                  cells: [
                    const DataCell(Text('Total Orders')),
                    DataCell(Text('${range1['order_count'] ?? 0}')),
                    DataCell(Text('${range2['order_count'] ?? 0}')),
                    DataCell(
                      Text(
                        signedNumber(comparison['order_count_difference']),
                        style: TextStyle(
                          color: positiveNegativeColor(
                            comparison['order_count_difference'],
                          ),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        signedPercentage(comparison['order_count_percentage']),
                        style: TextStyle(
                          color: positiveNegativeColor(
                            comparison['order_count_percentage'],
                          ),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                DataRow(
                  cells: [
                    const DataCell(Text('Total Amount')),
                    DataCell(Text(formatAmount(range1['total_amount']))),
                    DataCell(Text(formatAmount(range2['total_amount']))),
                    DataCell(
                      Text(
                        signedAmount(comparison['amount_difference']),
                        style: TextStyle(
                          color: positiveNegativeColor(
                            comparison['amount_difference'],
                          ),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        signedPercentage(comparison['amount_percentage']),
                        style: TextStyle(
                          color: positiveNegativeColor(
                            comparison['amount_percentage'],
                          ),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCompareTable(String title, String type) {
    final selected = getSelectedRowsByType(type);
    final rows = List<dynamic>.from(selected['rows'] ?? []);
    final total = selected['total'];
    final tableRows =
        total != null ? [...rows, {...total, 'is_total': true}] : rows;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle(
              title: title,
              subtitle: '${rows.length} rows found',
              icon: Icons.table_chart_rounded,
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    const Color(0xFFEEF4FF),
                  ),
                  dataRowMinHeight: 54,
                  dataRowMaxHeight: 64,
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Range 1 Orders')),
                    DataColumn(label: Text('Range 1 Amount')),
                    DataColumn(label: Text('Range 2 Orders')),
                    DataColumn(label: Text('Range 2 Amount')),
                    DataColumn(label: Text('Diff Orders')),
                    DataColumn(label: Text('Diff Amount')),
                    DataColumn(label: Text('Order %')),
                    DataColumn(label: Text('Amount %')),
                  ],
                  rows: tableRows.isEmpty
                      ? const [
                          DataRow(
                            cells: [
                              DataCell(Text('No data')),
                              DataCell(Text('')),
                              DataCell(Text('')),
                              DataCell(Text('')),
                              DataCell(Text('')),
                              DataCell(Text('')),
                              DataCell(Text('')),
                              DataCell(Text('')),
                              DataCell(Text('')),
                            ],
                          ),
                        ]
                      : tableRows.map((item) {
                          final isTotal = item['is_total'] == true ||
                              item['name'] == 'TOTAL';

                          final orderDiff = num.tryParse(
                                '${item['order_difference'] ?? 0}',
                              ) ??
                              0;
                          final amountDiff = num.tryParse(
                                '${item['amount_difference'] ?? 0}',
                              ) ??
                              0;
                          final orderPercent = num.tryParse(
                                '${item['order_percentage'] ?? 0}',
                              ) ??
                              0;
                          final amountPercent = num.tryParse(
                                '${item['amount_percentage'] ?? 0}',
                              ) ??
                              0;

                          return DataRow(
                            color: MaterialStateProperty.all(
                              isTotal ? const Color(0xFF0F172A) : Colors.white,
                            ),
                            cells: [
                              tableCell(item['name'] ?? 'N/A', isTotal),
                              tableCell(item['range1_orders'] ?? 0, isTotal),
                              tableCell(
                                formatAmount(item['range1_amount']),
                                isTotal,
                              ),
                              tableCell(item['range2_orders'] ?? 0, isTotal),
                              tableCell(
                                formatAmount(item['range2_amount']),
                                isTotal,
                              ),
                              differenceTableCell(
                                signedNumber(orderDiff),
                                orderDiff,
                                isTotal,
                              ),
                              differenceTableCell(
                                signedAmount(amountDiff),
                                amountDiff,
                                isTotal,
                              ),
                              differenceTableCell(
                                signedPercentage(orderPercent),
                                orderPercent,
                                isTotal,
                              ),
                              differenceTableCell(
                                signedPercentage(amountPercent),
                                amountPercent,
                                isTotal,
                              ),
                            ],
                          );
                        }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataCell tableCell(dynamic value, bool isTotal) {
    return DataCell(
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Text(
          value.toString(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isTotal ? Colors.white : const Color(0xFF0F172A),
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ),
    );
  }

  DataCell differenceTableCell(dynamic value, dynamic number, bool isTotal) {
    return DataCell(
      Text(
        value.toString(),
        style: TextStyle(
          color: isTotal ? Colors.white : positiveNegativeColor(number),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget buildCard({
    required Widget child,
    Color? leftBorderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: leftBorderColor == null
            ? Border.all(color: const Color(0xFFE2E8F0))
            : Border(
                left: BorderSide(
                  color: leftBorderColor,
                  width: 5,
                ),
              ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget sectionTitle({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color valueColor,
  }) {
    return Container(
      width: 245,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: valueColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: valueColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: valueColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget rangeBox({
    required String title,
    required String date,
    required String orders,
    required String amount,
    Color color = const Color(0xFF2563EB),
  }) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: miniValue('Orders', orders, color)),
              const SizedBox(width: 10),
              Expanded(child: miniValue('Amount', amount, color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget miniValue(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget statusBadge(String text) {
    final lower = text.toLowerCase();
    final color = lower == 'increase'
        ? const Color(0xFF16A34A)
        : lower == 'decrease'
            ? const Color(0xFFDC2626)
            : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        text.isEmpty ? 'Result' : text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget headerPill(IconData icon, String text) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 54,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(height: 12),
          Text(
            'No comparison generated yet',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Select date ranges and report type, then click Compare.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.15),
      child: const Center(
        child: Card(
          elevation: 0,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                SizedBox(width: 14),
                Text(
                  'Generating comparison...',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget dateField(String label, String key, double width) {
    return sizedField(
      label,
      InkWell(
        onTap: () => pickDate(key),
        borderRadius: BorderRadius.circular(14),
        child: inputBox(
          Row(
            children: [
              Expanded(
                child: Text(
                  (filters[key] ?? '').isEmpty
                      ? 'Select date'
                      : filters[key]!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: (filters[key] ?? '').isEmpty
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const Icon(
                Icons.calendar_month_rounded,
                size: 17,
                color: Color(0xFF2563EB),
              ),
            ],
          ),
        ),
      ),
      width,
    );
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

else if(dep=="CSO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => cso_dashboard()), // Replace AnotherPage with your target page
            );
}

else if(dep=="Marketing" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => marketing_dashboard()), // Replace AnotherPage with your target page
            );
}
else if(dep=="Warehouse Admin" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => WarehouseAdmin()), // Replace AnotherPage with your target page
            );
}

 else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => dashboard()),
      );
    }
  }

  Widget textField(String label, String key, String hint, double width) {
    return sizedField(
      label,
      TextFormField(
        key: ValueKey('$key-${filters[key]}'),
        initialValue: filters[key],
        onChanged: (value) => handleChange(key, value),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        decoration: inputDecoration(hint),
      ),
      width,
    );
  }

  Widget dropdownField(
    String label,
    String key,
    List<String> values,
    double width, {
    Map<String, String> labels = const {},
  }) {
    return sizedField(
      label,
      DropdownButtonFormField<String>(
        isExpanded: true,
        value: (filters[key] ?? '').isEmpty ? null : filters[key],
        decoration: inputDecoration('All'),
        items: [
          const DropdownMenuItem(
            value: '',
            child: Text(
              'All',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          ...values.map(
            (value) => DropdownMenuItem(
              value: value,
              child: Text(
                labels[value] ?? value,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ],
        onChanged: (value) => handleChange(key, value ?? ''),
      ),
      width,
    );
  }

  Widget dropdownDynamic(
    String label,
    String key,
    List<dynamic> values,
    String Function(dynamic item) labelBuilder,
    double width,
  ) {
    return sizedField(
      label,
      DropdownButtonFormField<String>(
        isExpanded: true,
        value: (filters[key] ?? '').isEmpty ? null : filters[key],
        decoration: inputDecoration('All'),
        items: [
          const DropdownMenuItem(
            value: '',
            child: Text(
              'All',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          ...values.map(
            (item) => DropdownMenuItem(
              value: item['id'].toString(),
              child: Text(
                labelBuilder(item),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ],
        onChanged: (value) => handleChange(key, value ?? ''),
      ),
      width,
    );
  }

  Widget selectBox(
    String label,
    String value,
    VoidCallback onTap,
    double width,
  ) {
    return sizedField(
      label,
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: inputBox(
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: value == 'All' ||
                            value == 'Select report types' ||
                            value == 'Selected'
                        ? const Color(0xFF64748B)
                        : const Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF2563EB),
              ),
            ],
          ),
        ),
      ),
      width,
    );
  }

  Widget sizedField(String label, Widget child, double width) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 12,
      ),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0),
          width: 1.3,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0),
          width: 1.3,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF2563EB),
          width: 1.6,
        ),
      ),
    );
  }

  Widget inputBox(Widget child) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.3,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  Widget actionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback? onTap, {
    double? width,
  }) {
    return SizedBox(
      width: width ?? 170,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withOpacity(0.45),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}