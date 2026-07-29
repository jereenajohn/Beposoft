import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:beposoft/pages/api.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerLedger extends StatefulWidget {
  final int customerid;
  final String customerName;

  const CustomerLedger({
    super.key,
    required this.customerid,
    required this.customerName,
  });

  @override
  State<CustomerLedger> createState() => _CustomerLedgerState();
}

class _CustomerLedgerState extends State<CustomerLedger> {
  List<Map<String, dynamic>> _orders = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _companyList = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _banks = <Map<String, dynamic>>[];

  List<Map<String, dynamic>> _advanceReceipts =
      <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _paymentReceipts =
      <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _commissionReceipts =
      <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _grvList = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _refundReceipts =
      <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _advanceTransfers =
      <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _ledgerSentTransfers =
      <Map<String, dynamic>>[];

  List<Map<String, dynamic>> _allLedgerRows =
      <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _ledgerRows = <Map<String, dynamic>>[];

  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCompany;

  double _openingBalance = 0.0;
  double _openingBalanceDebit = 0.0;
  double _openingBalanceCredit = 0.0;

  double _totalDebit = 0.0;
  double _totalCredit = 0.0;

  double _closingBalance = 0.0;
  double _closingBalanceDebit = 0.0;
  double _closingBalanceCredit = 0.0;

  bool _isLoading = true;
  bool _isExporting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<String?> _getTokenFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];

    return value
        .whereType<Map>()
        .map(
          (Map item) => Map<String, dynamic>.from(item),
        )
        .toList();
  }

  DateTime? _parseDate(dynamic value) {
    final String raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return null;

    return DateTime.tryParse(
      raw.contains('T') ? raw.split('T').first : raw,
    );
  }

  String _displayDate(dynamic value) {
    final DateTime? date = _parseDate(value);
    if (date == null) return value?.toString() ?? '';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String? token = await _getTokenFromPrefs();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found.');
      }

      await Future.wait<void>([
        _fetchBanks(token),
        _fetchCompanies(token),
        _fetchCustomerLedger(token),
      ]);

      _rebuildLedger();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchBanks(String token) async {
    final http.Response response = await http.get(
      Uri.parse('$api/api/banks/'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch banks. Status: ${response.statusCode}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    final dynamic data = decoded is Map<String, dynamic>
        ? decoded['data']
        : null;

    _banks = _mapList(data);
  }

  Future<void> _fetchCompanies(String token) async {
    final http.Response response = await http.get(
      Uri.parse('$api/api/company/data/'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch companies. Status: ${response.statusCode}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    final dynamic data = decoded is Map<String, dynamic>
        ? decoded['data']
        : null;

    _companyList = _mapList(data);
  }

  Future<void> _fetchCustomerLedger(String token) async {
    final http.Response response = await http.get(
      Uri.parse('$api/api/customer/${widget.customerid}/ledger/'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch ledger data. Status: ${response.statusCode}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic> ||
        decoded['data'] is! Map<String, dynamic>) {
      throw Exception('Invalid ledger response format.');
    }

    final Map<String, dynamic> data =
        Map<String, dynamic>.from(decoded['data'] as Map);

    _orders = _mapList(data['ledger']);
    _advanceReceipts = _mapList(data['advance_receipts']);
    _paymentReceipts = _mapList(data['payment_receipts']);
    _commissionReceipts = _mapList(data['commission_receipts']);
    _grvList = _mapList(data['grv']);
    _refundReceipts = _mapList(data['refund_receipts']);
    _advanceTransfers = _mapList(data['advance_transfers']);
    _ledgerSentTransfers = _mapList(data['ledger_sent_transfers']);


  }

  Map<dynamic, String> get _bankIdToName {
    final Map<dynamic, String> result = <dynamic, String>{};

    for (final Map<String, dynamic> bank in _banks) {
      final dynamic id = bank['id'];
      final String name = bank['name']?.toString() ?? '';

      if (id != null && name.isNotEmpty) {
        result[id] = name;
        result[id.toString()] = name;
      }
    }

    return result;
  }

  Color _particularColor(String colorCode) {
    switch (colorCode) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case '#6f42c1':
        return const Color(0xFF6F42C1);
      case '#fd7e14':
        return const Color(0xFFFD7E14);
      case '#dc3545':
        return const Color(0xFFDC3545);
      case '#0d6efd':
        return const Color(0xFF0D6EFD);
      case '#198754':
        return const Color(0xFF198754);
      default:
        return Colors.black87;
    }
  }

  bool _matchesCompanyFilter(Map<String, dynamic> row) {
    final String filter = _selectedCompany?.trim() ?? '';

    if (filter.isEmpty || filter == 'All Companies') {
      return true;
    }

    final String invoice = row['invoice']?.toString() ?? '';

    // This intentionally matches the React logic:
    // row.invoice.toString().includes(companyFilter)
    return invoice.contains(filter);
  }

  void _rebuildLedger() {
    final List<Map<String, dynamic>> rows =
        <Map<String, dynamic>>[];

    // ===== ORDERS =====
    for (final Map<String, dynamic> order in _orders) {
      final String status = order['status']?.toString() ?? '';

      if (status != 'Invoice Rejected' &&
          status != 'Invoice Created') {
        rows.add(<String, dynamic>{
          'key': 'O-${order['id']}',
          'date': order['order_date'],
          'invoice':
              '${order['invoice'] ?? ''}/${order['company'] ?? ''}',
          'particular': 'Goods Sale',
          'particularColor': 'red',
          'debit': _toDouble(order['total_amount']),
          'credit': null,
        });
      }

      // Same as React: order.recived_payment
      final List<Map<String, dynamic>> receivedPayments =
          _mapList(order['recived_payment']);

      for (final Map<String, dynamic> receipt
          in receivedPayments) {
        rows.add(<String, dynamic>{
          'key': 'OP-${receipt['id']}',
          'date': receipt['received_at'],
          'invoice': receipt['bank']?.toString() ?? '',
          'particular': 'Payment received',
          'particularColor': 'green',
          'debit': null,
          'credit': _toDouble(receipt['amount']),
        });
      }
    }

    // ===== TRANSFERS SENT =====
    for (final Map<String, dynamic> transfer
        in _ledgerSentTransfers) {
      rows.add(<String, dynamic>{
        'key': 'AST-${transfer['id']}',
        'date': transfer['date'],
        'invoice': '-',
        'particular':
            'Advance Transfer Sent to ${transfer['send_to_name'] ?? ''}',
        'particularColor': '#0d6efd',
        'debit': _toDouble(transfer['amount']),
        'credit': null,
      });
    }

    // ===== ADVANCE RECEIPTS =====
    final Map<dynamic, String> bankNames = _bankIdToName;

    for (final Map<String, dynamic> advance
        in _advanceReceipts) {
      final dynamic bankId = advance['bank'];
      final String bankName =
          bankNames[bankId] ??
          bankNames[bankId?.toString()] ??
          bankId?.toString() ??
          '';

      rows.add(<String, dynamic>{
        'key': 'A-${advance['id']}',
        'date': advance['received_at'],
        'invoice': bankName,
        'particular': 'Advance Receipt',
        'particularColor': 'blue',
        'debit': null,
        'credit': _toDouble(advance['amount']),
      });
    }

    // ===== PAYMENT RECEIPTS =====
    for (final Map<String, dynamic> receipt
        in _paymentReceipts) {
      rows.add(<String, dynamic>{
        'key': 'P-${receipt['id']}',
        'date': receipt['received_at'],
        'invoice': receipt['bank']?.toString() ?? '',
        'particular': 'Payment Receipt',
        'particularColor': '#6f42c1',
        'debit': null,
        'credit': _toDouble(receipt['amount']),
      });
    }

    // ===== COMMISSION RECEIPTS =====
    for (final Map<String, dynamic> commission
        in _commissionReceipts) {
      final double creditAmount =
          _toDouble(commission['amount']);

      if (creditAmount <= 0) {
        continue;
      }

      final String paymentReceipt =
          commission['payment_receipt']?.toString().trim() ?? '';

      final String orderName =
          commission['order_name']?.toString().trim() ?? '';

      final String bankName =
          commission['bank_name']?.toString().trim() ?? '';

      final String invoiceReference = orderName.isNotEmpty
          ? '$orderName/$bankName'
          : paymentReceipt.isNotEmpty
              ? paymentReceipt
              : 'COM-${commission['id']}';

      rows.add(<String, dynamic>{
        'key': 'C-${commission['id']}',
        'date': commission['received_at'],
        'invoice': invoiceReference,
        'particular': 'Commission Receipt',
        'particularColor': '#198754',
        'debit': null,
        'credit': creditAmount,
        'receiptNo': paymentReceipt,
        'transactionId': commission['transactionID'],
        'remark': commission['remark'],
      });
    }

    // ===== REFUNDS =====
    for (final Map<String, dynamic> refund
        in _refundReceipts) {
      rows.add(<String, dynamic>{
        'key': 'R-${refund['id']}',
        'date': refund['date'],
        'invoice': refund['invoice_no']?.toString() ?? '',
        'particular':
            'Refund Issued (${refund['refund_no'] ?? ''})',
        'particularColor': '#dc3545',
        'debit': _toDouble(refund['amount']),
        'credit': null,
      });
    }

    // ===== ADVANCE TRANSFERS RECEIVED =====
    for (final Map<String, dynamic> transfer
        in _advanceTransfers) {
      rows.add(<String, dynamic>{
        'key': 'AT-${transfer['id']}',
        'date': transfer['date'],
        'invoice': '-',
        'particular':
            'Advance Transfer Received from ${transfer['send_from_name'] ?? ''}',
        'particularColor': '#198754',
        'debit': null,
        'credit': _toDouble(transfer['amount']),
      });
    }

    // ===== GRV =====
    for (final Map<String, dynamic> grv in _grvList) {
      final String status =
          grv['status']?.toString().toLowerCase() ?? '';

      if (status != 'approved') {
        continue;
      }

      final double quantity = _toDouble(grv['quantity']);
      final double price = _toDouble(grv['price']);

      double amount = quantity * price;
      String label = 'GRV';
      String color = '#fd7e14';

      final String remark = grv['remark']?.toString() ?? '';

      if (remark == 'return') {
        label = 'Sales Return';
      } else if (remark == 'refund') {
        label = 'Refund Issued';
      } else if (remark == 'cod_return') {
        final double codAmount = _toDouble(grv['cod_amount']);
        amount = codAmount != 0 ? codAmount : amount;
        label = 'COD Return';
        color = '#dc3545';
      }

      rows.add(<String, dynamic>{
        'key': 'G-${grv['id']}',
        'date': grv['date'],
        'invoice': grv['invoice']?.toString() ?? '',
        'particular': '$label (${grv['product'] ?? ''})',
        'particularColor': color,
        'debit': null,
        'credit': amount,
      });
    }

    rows.retainWhere(_matchesCompanyFilter);

    rows.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final DateTime? firstDate = _parseDate(a['date']);
      final DateTime? secondDate = _parseDate(b['date']);

      if (firstDate == null && secondDate == null) return 0;
      if (firstDate == null) return 1;
      if (secondDate == null) return -1;

      return firstDate.compareTo(secondDate);
    });

    _allLedgerRows = rows;

    _calculateOpeningBalance();
    _applyDateFilterAndCalculateTotals();

    if (mounted) {
      setState(() {});
    }
  }

  void _calculateOpeningBalance() {
    if (_startDate == null) {
      _openingBalance = 0.0;
      _openingBalanceDebit = 0.0;
      _openingBalanceCredit = 0.0;
      return;
    }

    double previousDebit = 0.0;
    double previousCredit = 0.0;

    for (final Map<String, dynamic> row in _allLedgerRows) {
      final DateTime? rowDate = _parseDate(row['date']);

      if (rowDate != null && rowDate.isBefore(_startDate!)) {
        previousDebit += _toDouble(row['debit']);
        previousCredit += _toDouble(row['credit']);
      }
    }

    _openingBalance = previousDebit - previousCredit;
    _openingBalanceDebit =
        _openingBalance > 0 ? _openingBalance : 0.0;
    _openingBalanceCredit =
        _openingBalance < 0 ? _openingBalance.abs() : 0.0;
  }

  void _applyDateFilterAndCalculateTotals() {
    _ledgerRows = _allLedgerRows.where(
      (Map<String, dynamic> row) {
        final DateTime? rowDate = _parseDate(row['date']);

        if (rowDate == null) {
          return false;
        }

        final bool afterOrEqualStart =
            _startDate == null || !rowDate.isBefore(_startDate!);

        final bool beforeOrEqualEnd =
            _endDate == null || !rowDate.isAfter(_endDate!);

        return afterOrEqualStart && beforeOrEqualEnd;
      },
    ).toList();

    _ledgerRows.sort(
      (Map<String, dynamic> a, Map<String, dynamic> b) {
        final DateTime? firstDate = _parseDate(a['date']);
        final DateTime? secondDate = _parseDate(b['date']);

        if (firstDate == null && secondDate == null) return 0;
        if (firstDate == null) return 1;
        if (secondDate == null) return -1;

        return firstDate.compareTo(secondDate);
      },
    );

    _totalDebit = _ledgerRows.fold<double>(
      0.0,
      (double sum, Map<String, dynamic> row) =>
          sum + _toDouble(row['debit']),
    );

    _totalCredit = _ledgerRows.fold<double>(
      0.0,
      (double sum, Map<String, dynamic> row) =>
          sum + _toDouble(row['credit']),
    );

    _closingBalance =
        _openingBalance + _totalDebit - _totalCredit;

    _closingBalanceDebit =
        _closingBalance > 0 ? _closingBalance : 0.0;

    _closingBalanceCredit =
        _closingBalance < 0 ? _closingBalance.abs() : 0.0;
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange:
          _startDate != null && _endDate != null
              ? DateTimeRange(
                  start: _startDate!,
                  end: _endDate!,
                )
              : null,
    );

    if (picked == null || !mounted) return;

    _startDate = DateTime(
      picked.start.year,
      picked.start.month,
      picked.start.day,
    );

    _endDate = DateTime(
      picked.end.year,
      picked.end.month,
      picked.end.day,
    );

    _rebuildLedger();
  }

  void _clearDateFilter() {
    _startDate = null;
    _endDate = null;
    _rebuildLedger();
  }

  Future<void> _exportToExcel() async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final Excel excel = Excel.createExcel();
      final String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
      final Sheet sheet = excel['Ledger'];

      if (defaultSheet != 'Ledger') {
        excel.delete(defaultSheet);
      }

      sheet.appendRow(<dynamic>[
        '#',
        'DATE',
        'INVOICE',
        'PARTICULAR',
        'DEBIT (₹)',
        'CREDIT (₹)',
      ]);

      sheet.appendRow(<dynamic>[
        '',
        '',
        '',
        'Opening Balance',
        _openingBalanceDebit > 0
            ? _openingBalanceDebit.toStringAsFixed(2)
            : '',
        _openingBalanceCredit > 0
            ? _openingBalanceCredit.toStringAsFixed(2)
            : '',
      ]);

      for (int index = 0; index < _ledgerRows.length; index++) {
        final Map<String, dynamic> row = _ledgerRows[index];

        sheet.appendRow(<dynamic>[
          index + 1,
          _displayDate(row['date']),
          row['invoice']?.toString() ?? '',
          row['particular']?.toString() ?? '',
          row['debit'] != null
              ? _toDouble(row['debit']).toStringAsFixed(2)
              : '-',
          row['credit'] != null
              ? _toDouble(row['credit']).toStringAsFixed(2)
              : '-',
        ]);
      }

      sheet.appendRow(<dynamic>[
        '',
        '',
        '',
        'Grand Total',
        _totalDebit.toStringAsFixed(2),
        _totalCredit.toStringAsFixed(2),
      ]);

      sheet.appendRow(<dynamic>[
        '',
        '',
        '',
        'Closing Balance',
        _closingBalance > 0
            ? _closingBalance.toStringAsFixed(2)
            : '',
        _closingBalance < 0
            ? _closingBalance.abs().toStringAsFixed(2)
            : '',
      ]);

      final List<int>? bytes = excel.encode();

      if (bytes == null) {
        throw Exception('Unable to generate Excel file.');
      }

      final Directory tempDirectory =
          await getTemporaryDirectory();

      final String safeCustomerName = widget.customerName
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

      final String path =
          '${tempDirectory.path}/${safeCustomerName}_Ledger.xlsx';

      final File file = File(path);
      await file.writeAsBytes(bytes, flush: true);

      await OpenFilex.open(path);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Excel export failed: '
            '${error.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isExporting = false;
      });
    }
  }

  String _companyNameForPdf() {
    if (_orders.isNotEmpty) {
      final String company =
          _orders.first['company']?.toString().trim() ?? '';

      if (company.isNotEmpty) {
        return company.toUpperCase();
      }
    }

    return 'COMPANY';
  }

  String _companyAddressForPdf() {
    if (_orders.isEmpty) {
      return 'Address not available';
    }

    final String companyName =
        _orders.first['company']?.toString() ?? '';

    Map<String, dynamic>? selectedCompany;

    for (final Map<String, dynamic> company in _companyList) {
      if ((company['name']?.toString().toUpperCase() ?? '') ==
          companyName.toUpperCase()) {
        selectedCompany = company;
        break;
      }
    }

    if (selectedCompany == null) {
      return 'Address not available';
    }

    final List<String> addressParts = <String>[
      selectedCompany['address']?.toString() ?? '',
      selectedCompany['city']?.toString() ?? '',
      selectedCompany['country']?.toString() ?? '',
    ].where((String value) => value.trim().isNotEmpty).toList();

    String address = addressParts.join(', ');

    final String zip =
        selectedCompany['zip']?.toString().trim() ?? '';

    if (zip.isNotEmpty) {
      address = address.isEmpty ? zip : '$address - $zip';
    }

    return address.isEmpty ? 'Address not available' : address;
  }

  Future<pw.Document> _createPdf() async {
    final pw.Document pdf = pw.Document();

    final String companyName = _companyNameForPdf();
    final String companyAddress = _companyAddressForPdf();

    final List<List<dynamic>> rows = <List<dynamic>>[
      <dynamic>[
        '',
        '',
        '',
        'Opening Balance',
        _openingBalanceDebit > 0
            ? _openingBalanceDebit.toStringAsFixed(2)
            : '',
        _openingBalanceCredit > 0
            ? _openingBalanceCredit.toStringAsFixed(2)
            : '',
      ],
      ...List<List<dynamic>>.generate(
        _ledgerRows.length,
        (int index) {
          final Map<String, dynamic> row = _ledgerRows[index];

          return <dynamic>[
            index + 1,
            _displayDate(row['date']),
            row['invoice']?.toString() ?? '',
            row['particular']?.toString() ?? '',
            row['debit'] != null
                ? _toDouble(row['debit']).toStringAsFixed(2)
                : '-',
            row['credit'] != null
                ? _toDouble(row['credit']).toStringAsFixed(2)
                : '-',
          ];
        },
      ),
      <dynamic>[
        '',
        '',
        '',
        'Grand Total',
        _totalDebit.toStringAsFixed(2),
        _totalCredit.toStringAsFixed(2),
      ],
      <dynamic>[
        '',
        '',
        '',
        'Closing Balance',
        _closingBalance > 0
            ? _closingBalance.toStringAsFixed(2)
            : '',
        _closingBalance < 0
            ? _closingBalance.abs().toStringAsFixed(2)
            : '',
      ],
    ];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 24, 24, 28),
        header: (pw.Context context) {
          return pw.Column(
            children: <pw.Widget>[
              pw.Text(
                companyName,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                companyAddress,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Customer Name: ${widget.customerName}',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Divider(),
              pw.SizedBox(height: 6),
            ],
          );
        },
        build: (pw.Context context) {
          return <pw.Widget>[
            pw.TableHelper.fromTextArray(
              headers: const <String>[
                '#',
                'DATE',
                'INVOICE',
                'PARTICULAR',
                'DEBIT',
                'CREDIT',
              ],
              data: rows,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              border: pw.TableBorder.all(
                color: PdfColors.grey400,
                width: 0.4,
              ),
              cellPadding: const pw.EdgeInsets.all(4),
              columnWidths: <int, pw.TableColumnWidth>{
                0: const pw.FixedColumnWidth(24),
                1: const pw.FixedColumnWidth(62),
                2: const pw.FlexColumnWidth(1.8),
                3: const pw.FlexColumnWidth(1.6),
                4: const pw.FixedColumnWidth(58),
                5: const pw.FixedColumnWidth(58),
              },
              cellAlignments: <int, pw.Alignment>{
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.centerRight,
              },
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  Future<void> _downloadPdf() async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final pw.Document pdf = await _createPdf();
      final Uint8List bytes = await pdf.save();

      final String safeCustomerName = widget.customerName
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

      await Printing.sharePdf(
        bytes: bytes,
        filename: '${safeCustomerName}_Ledger.pdf',
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF export failed: '
            '${error.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isExporting = false;
      });
    }
  }

  List<DataRow> _buildRows() {
    final List<DataRow> rows = <DataRow>[
      DataRow(
        color: WidgetStatePropertyAll<Color>(
          Colors.grey.shade100,
        ),
        cells: <DataCell>[
          const DataCell(Text('')),
          const DataCell(Text('')),
          const DataCell(Text('')),
          const DataCell(
            Text(
              'Opening Balance',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataCell(
            Text(
              _openingBalanceDebit > 0
                  ? _openingBalanceDebit.toStringAsFixed(2)
                  : '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataCell(
            Text(
              _openingBalanceCredit > 0
                  ? _openingBalanceCredit.toStringAsFixed(2)
                  : '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ];

    for (int index = 0; index < _ledgerRows.length; index++) {
      final Map<String, dynamic> row = _ledgerRows[index];

      rows.add(
        DataRow(
          cells: <DataCell>[
            DataCell(Text('${index + 1}')),
            DataCell(Text(_displayDate(row['date']))),
            DataCell(
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Text(
                  row['invoice']?.toString() ?? '',
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
            DataCell(
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  row['particular']?.toString() ?? '',
                  style: TextStyle(
                    color: _particularColor(
                      row['particularColor']?.toString() ?? '',
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            DataCell(
              Text(
                row['debit'] != null
                    ? _toDouble(row['debit']).toStringAsFixed(2)
                    : '-',
              ),
            ),
            DataCell(
              Text(
                row['credit'] != null
                    ? _toDouble(row['credit']).toStringAsFixed(2)
                    : '-',
              ),
            ),
          ],
        ),
      );
    }

    rows.add(
      DataRow(
        cells: <DataCell>[
          const DataCell(Text('')),
          const DataCell(Text('')),
          const DataCell(Text('')),
          const DataCell(
            Text(
              'Grand Total',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataCell(
            Text(
              _totalDebit.toStringAsFixed(2),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataCell(
            Text(
              _totalCredit.toStringAsFixed(2),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    rows.add(
      DataRow(
        color: WidgetStatePropertyAll<Color>(
          Colors.grey.shade200,
        ),
        cells: <DataCell>[
          const DataCell(Text('')),
          const DataCell(Text('')),
          const DataCell(Text('')),
          const DataCell(
            Text(
              'Closing Balance',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataCell(
            Text(
              _closingBalanceDebit > 0
                  ? _closingBalanceDebit.toStringAsFixed(2)
                  : '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataCell(
            Text(
              _closingBalanceCredit > 0
                  ? _closingBalanceCredit.toStringAsFixed(2)
                  : '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    return rows;
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCompany,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Company',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: <DropdownMenuItem<String>>[
                    const DropdownMenuItem<String>(
                      value: 'All Companies',
                      child: Text('All Companies'),
                    ),
                    ..._companyList.map(
                      (Map<String, dynamic> company) {
                        final String name =
                            company['name']?.toString() ?? '';

                        return DropdownMenuItem<String>(
                          value: name,
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ],
                  onChanged: (String? value) {
                    _selectedCompany = value;
                    _rebuildLedger();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Select date range',
                onPressed: _pickDateRange,
                icon: const Icon(Icons.calendar_today),
              ),
            ],
          ),
          if (_startDate != null) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Selected Date Range: '
                    '${DateFormat('yyyy-MM-dd').format(_startDate!)}'
                    ' - '
                    '${DateFormat('yyyy-MM-dd').format(_endDate!)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _clearDateFilter,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadInitialData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: <Widget>[
        _buildFilterSection(),
        Expanded(
          child: _allLedgerRows.isEmpty
              ? const Center(
                  child: Text(
                    'No ledger transactions found',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                )
              : Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor:
                            WidgetStatePropertyAll<Color>(
                          Colors.grey.shade200,
                        ),
                        dataRowMinHeight: 52,
                        dataRowMaxHeight: 76,
                        columnSpacing: 22,
                        columns: const <DataColumn>[
                          DataColumn(
                            label: Text(
                              '#',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'DATE',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'INVOICE',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'PARTICULAR',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            numeric: true,
                            label: Text(
                              'DEBIT (₹)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            numeric: true,
                            label: Text(
                              'CREDIT (₹)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        rows: _buildRows(),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Customer Ledger',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: <Widget>[
          if (_isExporting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (String value) {
                if (value == 'excel') {
                  _exportToExcel();
                } else if (value == 'pdf') {
                  _downloadPdf();
                }
              },
              itemBuilder: (BuildContext context) {
                return const <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'excel',
                    child: Text('Export Excel'),
                  ),
                  PopupMenuItem<String>(
                    value: 'pdf',
                    child: Text('Download PDF'),
                  ),
                ];
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }
}
