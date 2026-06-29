import 'dart:convert';
import 'dart:io';

import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/order.review.dart';
import 'package:beposoft/pages/ACCOUNTS/sales_report.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' hide Border;
import 'package:open_filex/open_filex.dart';

class InvoiceReportStaffwise extends StatefulWidget {
  final dynamic id;
  final dynamic date;
  final dynamic familyId;
  final dynamic staffName;
  final dynamic familyName;

  const InvoiceReportStaffwise({
    super.key,
    required this.id,
    required this.date,
    this.familyId,
    this.staffName,
    this.familyName,
  });

  @override
  State<InvoiceReportStaffwise> createState() => _InvoiceReportStaffwiseState();
}

class _InvoiceReportStaffwiseState extends State<InvoiceReportStaffwise> {
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> filteredOrders = [];

  String searchQuery = '';
  bool isLoading = false;

  DateTime? selectedDate;
  DateTime? startDate;
  DateTime? endDate;

  final DateFormat apiDateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    fetchOrderData();
  }

  Future<String?> getTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  String _formatApiDate(dynamic value) {
    if (value == null) return "";

    final rawDate = value.toString();

    try {
      return DateFormat('yyyy-MM-dd').format(DateTime.parse(rawDate));
    } catch (_) {
      return rawDate;
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Future<void> fetchOrderData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = await getTokenFromPrefs();

      if (token == null || token.isEmpty) {
        setState(() {
          orders = [];
          filteredOrders = [];
          isLoading = false;
        });
        return;
      }

      final selectedDateString = _formatApiDate(widget.date);

      final uri = Uri.parse('$api/api/salesreport/').replace(
        queryParameters: {
          'start_date': selectedDateString,
          'end_date': selectedDateString,
          if (widget.familyId != null && widget.familyId.toString().isNotEmpty)
            'family': widget.familyId.toString(),
          if (widget.id != null && widget.id.toString().isNotEmpty)
            'staff': widget.id.toString(),
        },
      );

      debugPrint('STAFFWISE BREAKUP URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('STAFFWISE BREAKUP STATUS: ${response.statusCode}');
      debugPrint('STAFFWISE BREAKUP BODY: ${response.body}');

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final salesReport = parsed['sales_report'] ?? [];

        final List<Map<String, dynamic>> newOrders = [];

        if (salesReport.isNotEmpty) {
          final orderDetails = salesReport[0]['order_details'] ?? [];

          for (final orderData in orderDetails) {
            if (orderData is! Map<String, dynamic>) continue;

            newOrders.add({
              'id': orderData['id'],
              'invoice': orderData['invoice'] ?? '',
              'order_date': orderData['order_date'] ?? selectedDateString,
              'status': orderData['status'] ?? '',
              'total_amount': _toDouble(orderData['total_amount']),
              'manage_staff': orderData['manage_staff__name'] ?? '',
              'customer': {
                'id': orderData['customer'] ??
                    orderData['customer_id'] ??
                    orderData['customer__id'],
                'name': orderData['customer__name'] ?? '',
                'phone': orderData['customer__phone'] ?? '',
                'email': orderData['customer__email'] ?? '',
                'address': orderData['customer__address'] ?? '',
              },
              'billing_address': {
                'name': orderData['customer__name'] ?? '',
                'email': orderData['customer__email'] ?? '',
                'zipcode': '',
                'address': '',
                'phone': orderData['customer__phone'] ?? '',
                'city': '',
                'state': orderData['state__name'] ?? '',
              },
              'bank': {
                'name': '',
                'account_number': '',
                'ifsc_code': '',
                'branch': '',
              },
              'items': [],
              'payment_status': orderData['payment_status'] ?? '',
              'payment_method': orderData['payment_method'] ?? '',
              'shipping_mode': orderData['shipping_mode'] ?? '',
              'shipping_charge': orderData['shipping_charge'] ?? '',
              'parcel_service_note': orderData['parcel_service_note'] ?? '',
              'state': orderData['state__name'] ?? '',
              'company': orderData['company__name'] ?? '',
              'family': orderData['family__name'] ?? '',
              'family_name': orderData['family__name'] ?? '',
            });
          }
        }

        setState(() {
          orders = newOrders;
          filteredOrders = newOrders;
          isLoading = false;
        });
      } else {
        setState(() {
          orders = [];
          filteredOrders = [];
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch order breakup (${response.statusCode})'),
          ),
        );
      }
    } catch (error) {
      debugPrint('FETCH STAFFWISE BREAKUP ERROR: $error');

      setState(() {
        orders = [];
        filteredOrders = [];
        isLoading = false;
      });
    }
  }

  void _filterOrders(String query) {
    setState(() {
      searchQuery = query;

      if (query.trim().isEmpty) {
        filteredOrders = orders;
      } else {
        final normalizedQuery = query.toLowerCase();

        filteredOrders = orders.where((order) {
          final customerName =
              order['customer']?['name']?.toString().toLowerCase() ?? '';
          final invoice = order['invoice']?.toString().toLowerCase() ?? '';
          final manageStaff =
              order['manage_staff']?.toString().toLowerCase() ?? '';
          final totalAmount =
              order['total_amount']?.toString().toLowerCase() ?? '';
          final status = order['status']?.toString().toLowerCase() ?? '';
          final family = order['family']?.toString().toLowerCase() ?? '';
          final state = order['state']?.toString().toLowerCase() ?? '';

          return customerName.contains(normalizedQuery) ||
              invoice.contains(normalizedQuery) ||
              manageStaff.contains(normalizedQuery) ||
              totalAmount.contains(normalizedQuery) ||
              status.contains(normalizedQuery) ||
              family.contains(normalizedQuery) ||
              state.contains(normalizedQuery);
        }).toList();
      }
    });
  }

  Future<void> exportToExcel() async {
    final excel = Excel.createExcel();
    final sheetObject = excel['Order List'];

sheetObject.appendRow([
  'Invoice',
  'Manager',
  'Customer Name',
  'State',
  'Family',
  'Company',
  'Order Status',
  'Total Amount',
  'Order Date',
]);

for (final order in filteredOrders) {
  sheetObject.appendRow([
    order['invoice']?.toString() ?? '',
    order['manage_staff']?.toString() ?? '',
    order['customer']?['name']?.toString() ?? '',
    order['state']?.toString() ?? '',
    order['family']?.toString() ?? '',
    order['company']?.toString() ?? '',
    order['status']?.toString() ?? '',
    order['total_amount']?.toString() ?? '',
    order['order_date']?.toString() ?? '',
  ]);
}

    final tempDir = await getTemporaryDirectory();
    final tempPath = "${tempDir.path}/order_list.xlsx";
    final tempFile = File(tempPath);

    await tempFile.writeAsBytes(excel.encode()!);
    await OpenFilex.open(tempPath);
  }

  Future<pw.Document> createPdf() async {
    final pdf = pw.Document();

    for (final order in filteredOrders) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Text(
                      'Order Details',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text('Invoice: ${order['invoice']}'),
                  pw.Text('Manager: ${order['manage_staff'] ?? ''}'),
                  pw.Text('Customer: ${order['customer']?['name'] ?? ''}'),
                  pw.Text('Status: ${order['status'] ?? ''}'),
                  pw.Text('Family: ${order['family'] ?? ''}'),
                  pw.Text('State: ${order['state'] ?? ''}'),
                  pw.Text('Company: ${order['company'] ?? ''}'),
                  pw.Text('Total Amount: ${order['total_amount'] ?? 0}'),
                  pw.Text('Order Date: ${order['order_date'] ?? ''}'),
                ],
              ),
            );
          },
        ),
      );
    }

    return pdf;
  }

  Future<void> downloadPdf() async {
    final pdf = await createPdf();
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'order_list.pdf',
    );
  }

  String _titleText() {
    if (widget.staffName != null && widget.staffName.toString().isNotEmpty) {
      return 'Orders - ${widget.staffName}';
    }

    if (widget.familyName != null && widget.familyName.toString().isNotEmpty) {
      return 'Orders - ${widget.familyName}';
    }

    return 'Order List';
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.blue),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final customerId = order['customer']?['id'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: GestureDetector(
      onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => OrderReview(
        id: order['id'],
        customer: order['customer']?['id'],
      ),
    ),
  );
},
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          color: Colors.white,
          elevation: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    topRight: Radius.circular(16.0),
                  ),
                ),
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '#${order['invoice'] ?? ''}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      order['order_date'] != null &&
                              order['order_date'].toString().isNotEmpty
                          ? DateFormat('dd MMM yy').format(
                              DateTime.parse(order['order_date']),
                            )
                          : '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(11.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer: ${order['customer']?['name'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Staff: ${order['manage_staff'] ?? ''}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Family: ${order['family'] ?? ''}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'State: ${order['state'] ?? ''}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Text(
                          'Status: ',
                          style: TextStyle(fontSize: 13),
                        ),
                        Expanded(
                          child: Text(
                            '${order['status'] ?? ''}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.blue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Billing Amount:',
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          '₹${_toDouble(order['total_amount']).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        searchQuery.isNotEmpty
            ? 'No matching orders found'
            : 'No orders available',
        style: const TextStyle(
          fontSize: 16,
          color: Color.fromARGB(255, 2, 65, 96),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDateText = _formatApiDate(widget.date);

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _titleText(),
          style: const TextStyle(
            fontSize: 14,
            color: Color.fromARGB(255, 32, 43, 61),
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color.fromARGB(255, 32, 43, 61),
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Sales_Report()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: const Color.fromARGB(255, 32, 43, 61),
            onPressed: fetchOrderData,
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Color.fromARGB(255, 32, 43, 61),
            ),
            onSelected: (value) {
              switch (value) {
                case 'excel':
                  exportToExcel();
                  break;
                case 'pdf':
                  downloadPdf();
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return const [
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip(
                  icon: Icons.calendar_today,
                  label: selectedDateText,
                ),
                if (widget.familyName != null &&
                    widget.familyName.toString().isNotEmpty)
                  _buildInfoChip(
                    icon: Icons.category_outlined,
                    label: widget.familyName.toString(),
                  ),
                if (widget.staffName != null &&
                    widget.staffName.toString().isNotEmpty)
                  _buildInfoChip(
                    icon: Icons.person_outline,
                    label: widget.staffName.toString(),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search invoice, customer, staff, status...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: _filterOrders,
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  )
                : filteredOrders.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: fetchOrderData,
                        color: Colors.blue,
                        child: ListView.builder(
                          itemCount: filteredOrders.length,
                          padding: const EdgeInsets.only(
                            right: 10,
                            left: 10,
                            bottom: 16,
                          ),
                          itemBuilder: (context, index) {
                            return _buildOrderCard(filteredOrders[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}