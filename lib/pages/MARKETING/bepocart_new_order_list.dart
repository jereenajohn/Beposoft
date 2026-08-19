import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/order.review.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/MARKETING/marketing_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'dart:typed_data';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyFamilyOrderList extends StatefulWidget {
  final String? status;

  const MyFamilyOrderList({
    super.key,
    this.status,
  });

  @override
  State<MyFamilyOrderList> createState() => _MyFamilyOrderListState();
}

class _MyFamilyOrderListState extends State<MyFamilyOrderList> {
  final TextEditingController _searchController = TextEditingController();

  Timer? _searchDebounce;

  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> filteredOrders = [];

  final List<String> orderStatuses = [
    'All',
    'Invoice Created',
    'Invoice Approved',
    'Waiting For Confirmation',
    'Pre Booked',
    'Packing under progress',
    // 'Packing',
    'Packed',
    'Ready to ship',
    'To Print',
    'Shipped',
    'Invoice Rejected',
  ];

  String selectedStatus = 'All';
  String searchQuery = '';

  int currentPage = 1;
  int totalPages = 1;
  int totalOrderCount = 0;

  // This is sent to the backend.
  // Remove page_size from the request if your backend does not support it.
  static const int pageSize = 20;

  int invoiceCreatedCount = 0;
  int invoiceApprovedCount = 0;

  bool isInitialLoading = true;
  bool isPageLoading = false;
  bool isExportingExcel = false;
  bool isExportingPdf = false;

  DateTime? selectedDate;
  DateTime? startDate;
  DateTime? endDate;

  String? errorMessage;

  bool get hasPreviousPage => currentPage > 1;
  bool get hasNextPage => currentPage < totalPages;

  @override
  void initState() {
    super.initState();

    final String? requestedStatus = widget.status?.trim();

    if (requestedStatus != null &&
        requestedStatus.isNotEmpty &&
        orderStatuses.contains(requestedStatus)) {
      selectedStatus = requestedStatus;
    }

    fetchOrderData(showFullLoader: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<String?> getTokenFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getDepartmentFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<void> fetchOrderData({
    bool showFullLoader = false,
  }) async {
    if (showFullLoader) {
      if (mounted) {
        setState(() {
          isInitialLoading = true;
          errorMessage = null;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          isPageLoading = true;
          errorMessage = null;
        });
      }
    }

    try {
      final String? token = await getTokenFromPrefs();

      if (token == null || token.trim().isEmpty) {
        if (!mounted) return;

        setState(() {
          orders = [];
          filteredOrders = [];
          errorMessage = 'Authentication token not found. Please log in again.';
        });

        return;
      }

      final Map<String, String> queryParameters = {
        'page': currentPage.toString(),
        'page_size': pageSize.toString(),
      };

      if (searchQuery.trim().isNotEmpty) {
        queryParameters['search'] = searchQuery.trim();
      }

      if (selectedStatus != 'All') {
        queryParameters['status'] = selectedStatus;
      }

      if (startDate != null) {
        queryParameters['start_date'] =
            DateFormat('yyyy-MM-dd').format(startDate!);
      }

      if (endDate != null) {
        queryParameters['end_date'] =
            DateFormat('yyyy-MM-dd').format(endDate!);
      }

      final Uri uri = Uri.parse(
        '$api/api/orders/my/family/',
      ).replace(
        queryParameters: queryParameters,
      );

      debugPrint('MY FAMILY ORDER LIST URL: $uri');

      final http.Response response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
      );

      debugPrint(
        'MY FAMILY ORDER LIST STATUS: ${response.statusCode}',
      );
      debugPrint(
        'MY FAMILY ORDER LIST RESPONSE: ${response.body}',
      );

      if (response.statusCode == 200) {
        final dynamic decodedBody = jsonDecode(response.body);

        if (decodedBody is! Map<String, dynamic>) {
          throw const FormatException(
            'Invalid response format received from server.',
          );
        }

        final Map<String, dynamic> responseData = decodedBody;

        final int count = _toInt(responseData['count']);
        final bool backendHasNextPage = responseData['next'] != null;

        final dynamic resultWrapperValue = responseData['results'];

        Map<String, dynamic> resultWrapper = {};

        if (resultWrapperValue is Map<String, dynamic>) {
          resultWrapper = resultWrapperValue;
        } else if (resultWrapperValue is Map) {
          resultWrapper = Map<String, dynamic>.from(resultWrapperValue);
        }

        final int createdCount =
            _toInt(resultWrapper['invoice_created_count']);
        final int approvedCount =
            _toInt(resultWrapper['invoice_approved_count']);

        final dynamic rawOrdersValue = resultWrapper['results'];

        final List<dynamic> rawOrders = rawOrdersValue is List
            ? rawOrdersValue
            : <dynamic>[];

        final List<Map<String, dynamic>> newOrders = rawOrders
            .whereType<Map>()
            .map(
              (dynamic order) => _mapOrder(
                Map<String, dynamic>.from(order as Map),
              ),
            )
            .toList();

        int calculatedPages = 1;

        if (count > 0) {
          calculatedPages = (count / pageSize).ceil();
        }

        // Fallback when backend ignores page_size.
        if (backendHasNextPage && calculatedPages <= currentPage) {
          calculatedPages = currentPage + 1;
        }

        if (!mounted) return;

        setState(() {
          totalOrderCount = count;
          totalPages = calculatedPages < 1 ? 1 : calculatedPages;

          invoiceCreatedCount = createdCount;
          invoiceApprovedCount = approvedCount;

          orders = newOrders;
          filteredOrders = List<Map<String, dynamic>>.from(newOrders);

          errorMessage = null;
        });
      } else if (response.statusCode == 401) {
        if (!mounted) return;

        setState(() {
          orders = [];
          filteredOrders = [];
          errorMessage =
              'Authentication failed. Please log in again and retry.';
        });
      } else {
        String serverMessage = 'Unable to fetch family orders.';

        try {
          final dynamic errorData = jsonDecode(response.body);

          if (errorData is Map<String, dynamic>) {
            serverMessage = errorData['message']?.toString() ??
                errorData['detail']?.toString() ??
                serverMessage;
          }
        } catch (_) {
          // Keep the default error message.
        }

        if (!mounted) return;

        setState(() {
          orders = [];
          filteredOrders = [];
          errorMessage =
              '$serverMessage Server status: ${response.statusCode}.';
        });
      }
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        orders = [];
        filteredOrders = [];
        errorMessage =
            'The request timed out. Check your internet connection and retry.';
      });
    } on SocketException {
      if (!mounted) return;

      setState(() {
        orders = [];
        filteredOrders = [];
        errorMessage =
            'No internet connection. Check your network and retry.';
      });
    } on FormatException catch (error) {
      if (!mounted) return;

      setState(() {
        orders = [];
        filteredOrders = [];
        errorMessage = error.message;
      });
    } catch (error, stackTrace) {
      debugPrint('MY FAMILY ORDER LIST ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        orders = [];
        filteredOrders = [];
        errorMessage = 'Something went wrong while fetching family orders.';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        isInitialLoading = false;
        isPageLoading = false;
      });
    }
  }

  Map<String, dynamic> _mapOrder(Map<String, dynamic> orderData) {
    final Map<String, dynamic> customer =
        _toMap(orderData['customer']);

    final Map<String, dynamic> billingAddress =
        _toMap(orderData['billing_address']);

    final List<Map<String, dynamic>> warehouseData =
        _toMapList(orderData['warehouse_data']);

    return {
      'id': _toInt(orderData['id']),
      'invoice': orderData['invoice']?.toString() ?? '',
      'manage_staff': orderData['manage_staff']?.toString() ?? '',
      'staff_id': orderData['staffID']?.toString() ?? '',
      'family': orderData['family']?.toString() ?? '',
      'family_id': _toInt(orderData['family_id']),
      'family_name': orderData['family_name']?.toString() ?? '',
      'customer': {
        'id': _toInt(
          customer['id'] ?? orderData['customerID'],
        ),
        'name': customer['name']?.toString() ??
            billingAddress['name']?.toString() ??
            '',
      },
      'customer_id': _toInt(
        orderData['customerID'] ?? customer['id'],
      ),
      'billing_address': billingAddress,
      'state': orderData['state']?.toString() ??
          billingAddress['state']?.toString() ??
          '',
      'company': orderData['company']?.toString() ?? '',
      'warehouse': warehouseData,
      'warehouse_data': warehouseData,
      'status': orderData['status']?.toString() ?? '',
      'total_amount': _toDouble(orderData['total_amount']),
      'order_date': orderData['order_date']?.toString() ?? '',
      'billing_date': orderData['billing_date']?.toString(),
      'shipping_mode': orderData['shipping_mode']?.toString() ?? '',
      'shipping_charge': _toDouble(orderData['shipping_charge']),
      'cod_amount': _toDouble(orderData['cod_amount']),
      'payment_status': orderData['payment_status']?.toString() ?? '',
      'payment_method': orderData['payment_method']?.toString() ?? '',
      'cod_status': orderData['cod_status']?.toString() ?? '',
      'accounts_note': orderData['accounts_note']?.toString() ?? '',
      'note': orderData['note']?.toString() ?? '',
      'locked_by': orderData['locked_by']?.toString() ?? '',
      'updated_at': orderData['updated_at']?.toString() ?? '',
      'bank': orderData['bank'],
    };
  }

  Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _toMapList(dynamic value) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map(
          (dynamic item) => Map<String, dynamic>.from(item as Map),
        )
        .toList();
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  String _text(dynamic value, {String fallback = ''}) {
    final String result = value?.toString().trim() ?? '';
    return result.isEmpty ? fallback : result;
  }

  String _getDisplayStatus(dynamic rawStatus) {
    final String status = _text(rawStatus);

    switch (status) {
      case 'Invoice Created':
        return 'Waiting For Approval';

      case 'To Print':
        return 'Delivery Order (DO)';

      case 'Packed':
        return 'Packed For Delivery (PFD)';

      case 'Ready to ship':
        return 'Out For Delivery (OFD)';

      default:
        return status;
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(
      const Duration(milliseconds: 600),
      () {
        if (!mounted) return;

        setState(() {
          searchQuery = value.trim();
          currentPage = 1;
        });

        fetchOrderData();
      },
    );
  }

  Future<void> _clearAllFilters() async {
    _searchDebounce?.cancel();
    _searchController.clear();

    setState(() {
      searchQuery = '';
      selectedStatus = 'All';
      selectedDate = null;
      startDate = null;
      endDate = null;
      currentPage = 1;
    });

    await fetchOrderData();
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page > totalPages || isPageLoading) {
      return;
    }

    setState(() {
      currentPage = page;
    });

    await fetchOrderData();
  }

  Future<void> _selectSingleDate(BuildContext context) async {
    final DateTime initialDate = selectedDate ?? DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      selectedDate = picked;
      startDate = picked;
      endDate = picked;
      currentPage = 1;
    });

    await fetchOrderData();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? initialDateRange =
        startDate != null && endDate != null
            ? DateTimeRange(
                start: startDate!,
                end: endDate!,
              )
            : null;

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: initialDateRange,
    );

    if (picked == null) {
      return;
    }

    setState(() {
      selectedDate = null;
      startDate = picked.start;
      endDate = picked.end;
      currentPage = 1;
    });

    await fetchOrderData();
  }

  Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.remove('userId');
    await prefs.remove('token');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logged out successfully'),
        duration: Duration(seconds: 2),
      ),
    );

    await Future<void>.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => login(),
      ),
      (route) => false,
    );
  }

Future<void> exportToExcel() async {
  if (filteredOrders.isEmpty || isExportingExcel) {
    if (filteredOrders.isEmpty) {
      _showMessage('No orders available to export.');
    }
    return;
  }

  setState(() {
    isExportingExcel = true;
  });

  try {
    final Excel excel = Excel.createExcel();
    final Sheet sheetObject = excel['Family Order List'];

    // Compatible with older excel package versions.
    sheetObject.appendRow([
      'Invoice',
      'Order Date',
      'Customer Name',
      'Customer Phone',
      'Customer Email',
      'Billing Address',
      'City',
      'State',
      'Zipcode',
      'Staff',
      'Family',
      'Status',
      'Payment Status',
      'Payment Method',
      'Total Amount',
      'COD Amount',
      'Shipping Charge',
      'Shipping Mode',
      'Tracking Details',
    ]);

    for (final Map<String, dynamic> order in filteredOrders) {
      final Map<String, dynamic> customer = _toMap(
        order['customer'],
      );

      final Map<String, dynamic> billingAddress = _toMap(
        order['billing_address'],
      );

      final List<Map<String, dynamic>> warehouseData = _toMapList(
        order['warehouse'],
      );

      final String trackingDetails = warehouseData.map((warehouse) {
        final String box = _text(
          warehouse['box'],
          fallback: 'Box',
        );

        final String trackingId = _text(
          warehouse['tracking_id'],
          fallback: 'N/A',
        );

        final String parcelService = _text(
          warehouse['parcel_service_name'],
        );

        if (parcelService.isNotEmpty) {
          return '$box - $trackingId - $parcelService';
        }

        return '$box - $trackingId';
      }).join('\n');

      sheetObject.appendRow([
        _text(order['invoice']),
        _text(order['order_date']),
        _text(customer['name']),
        _text(billingAddress['phone']),
        _text(billingAddress['email']),
        _text(billingAddress['address']),
        _text(billingAddress['city']),
        _text(
          billingAddress['state'],
          fallback: _text(order['state']),
        ),
        _text(billingAddress['zipcode']),
        _text(order['manage_staff']),
        _text(
          order['family_name'],
          fallback: _text(order['family']),
        ),
        _getDisplayStatus(order['status']),
        _text(order['payment_status']),
        _text(order['payment_method']),
        _toDouble(order['total_amount']),
        _toDouble(order['cod_amount']),
        _toDouble(order['shipping_charge']),
        _text(order['shipping_mode']),
        trackingDetails,
      ]);
    }

    // Remove the automatically created Sheet1 if it exists.
    if (excel.tables.containsKey('Sheet1') &&
        excel.tables.length > 1) {
      excel.delete('Sheet1');
    }

    final List<int>? encodedFile = excel.encode();

    if (encodedFile == null) {
      throw Exception('Unable to generate Excel file.');
    }

    final Directory tempDirectory =
        await getTemporaryDirectory();

    final String fileName =
        'my_family_orders_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

    final String filePath =
        '${tempDirectory.path}/$fileName';

    final File file = File(filePath);

    await file.writeAsBytes(
      encodedFile,
      flush: true,
    );

    final OpenResult openResult =
        await OpenFilex.open(filePath);

    debugPrint(
      'EXCEL OPEN RESULT: '
      '${openResult.type} - ${openResult.message}',
    );

    if (openResult.type != ResultType.done &&
        openResult.type != ResultType.noAppToOpen) {
      _showMessage(
        openResult.message,
        isError: true,
      );
    }
  } catch (error, stackTrace) {
    debugPrint('EXCEL EXPORT ERROR: $error');
    debugPrintStack(stackTrace: stackTrace);

    _showMessage(
      'Unable to export the Excel file.',
      isError: true,
    );
  } finally {
    if (mounted) {
      setState(() {
        isExportingExcel = false;
      });
    }
  }
}

  Future<pw.Document> createPdf() async {
    final pw.Document pdf = pw.Document();

    for (final Map<String, dynamic> order in filteredOrders) {
      final Map<String, dynamic> customer =
          _toMap(order['customer']);

      final Map<String, dynamic> billingAddress =
          _toMap(order['billing_address']);

      final List<Map<String, dynamic>> warehouseData =
          _toMapList(order['warehouse']);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return [
              pw.Center(
                child: pw.Text(
                  'My Family Order Details',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              _buildPdfSection(
                title: 'Order Information',
                rows: {
                  'Invoice': _text(order['invoice']),
                  'Order Date': _formatDateForDisplay(
                    _text(order['order_date']),
                  ),
                  'Status': _getDisplayStatus(order['status']),
                  'Family': _text(order['family_name']),
                  'Staff': _text(order['manage_staff']),
                  'Company': _text(order['company']),
                },
              ),
              pw.SizedBox(height: 12),
              _buildPdfSection(
                title: 'Customer and Billing Information',
                rows: {
                  'Customer Name': _text(customer['name']),
                  'Billing Name': _text(billingAddress['name']),
                  'Phone': _text(billingAddress['phone']),
                  'Alternative Phone': _text(billingAddress['alt_phone']),
                  'Email': _text(billingAddress['email']),
                  'Address': _text(billingAddress['address']),
                  'City': _text(billingAddress['city']),
                  'State': _text(
                    billingAddress['state'],
                    fallback: _text(order['state']),
                  ),
                  'Zipcode': _text(billingAddress['zipcode']),
                },
              ),
              pw.SizedBox(height: 12),
              _buildPdfSection(
                title: 'Payment and Shipping Information',
                rows: {
                  'Payment Status': _text(order['payment_status']),
                  'Payment Method': _text(order['payment_method']),
                  'Total Amount':
                      'Rs. ${_toDouble(order['total_amount']).toStringAsFixed(2)}',
                  'COD Amount':
                      'Rs. ${_toDouble(order['cod_amount']).toStringAsFixed(2)}',
                  'Shipping Charge':
                      'Rs. ${_toDouble(order['shipping_charge']).toStringAsFixed(2)}',
                  'Shipping Mode': _text(order['shipping_mode']),
                  'Accounts Note': _text(order['accounts_note']),
                },
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                'Warehouse Information',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              if (warehouseData.isEmpty)
                pw.Text('No warehouse data available')
              else
                pw.TableHelper.fromTextArray(
                  headers: const [
                    'Box',
                    'Tracking ID',
                    'Parcel Service',
                  ],
                  data: warehouseData.map((warehouse) {
                    return [
                      _text(
                        warehouse['box'],
                        fallback: 'N/A',
                      ),
                      _text(
                        warehouse['tracking_id'],
                        fallback: 'N/A',
                      ),
                      _text(
                        warehouse['parcel_service_name'],
                        fallback: 'N/A',
                      ),
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  cellStyle: const pw.TextStyle(
                    fontSize: 9,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  border: pw.TableBorder.all(
                    color: PdfColors.grey500,
                    width: 0.5,
                  ),
                  cellPadding: const pw.EdgeInsets.all(6),
                ),
            ];
          },
        ),
      );
    }

    return pdf;
  }

  pw.Widget _buildPdfSection({
    required String title,
    required Map<String, String> rows,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        ...rows.entries.map((entry) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: '${entry.key}: ',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  pw.TextSpan(
                    text: entry.value.isEmpty ? '-' : entry.value,
                    style: const pw.TextStyle(
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> downloadPdf() async {
    if (filteredOrders.isEmpty || isExportingPdf) {
      if (filteredOrders.isEmpty) {
        _showMessage('No orders available to export.');
      }
      return;
    }

    setState(() {
      isExportingPdf = true;
    });

    try {
      final pw.Document pdf = await createPdf();

      final Uint8List pdfBytes = await pdf.save();

      final String fileName =
          'my_family_orders_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: fileName,
      );
    } catch (error, stackTrace) {
      debugPrint('PDF EXPORT ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);

      _showMessage(
        'Unable to generate the PDF file.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isExportingPdf = false;
        });
      }
    }
  }

  Future<void> _navigateBack() async {
    final String department =
        (await getDepartmentFromPrefs())?.trim() ?? '';

    if (!mounted) return;

    Widget destination;

    switch (department.toLowerCase()) {
      case 'bdo':
        destination = bdo_dashbord();
        break;

      case 'bdm':
        destination = bdm_dashbord();
        break;

      case 'warehouse':
        destination = WarehouseDashboard();
        break;

      case 'warehouse admin':
        destination = WarehouseAdmin();
        break;

      case 'ceo':
      case 'coo':
        destination = ceo_dashboard();
        break;

      case 'cso':
        destination = cso_dashboard();
        break;

      case 'marketing':
        destination = marketing_dashboard();
        break;

      default:
        destination = dashboard();
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => destination,
      ),
    );
  }

  void _openOrder(Map<String, dynamic> order) {
    final int orderId = _toInt(order['id']);

    final Map<String, dynamic> customer =
        _toMap(order['customer']);

    final int customerId = _toInt(
      customer['id'] ?? order['customer_id'],
    );

    if (orderId <= 0 || customerId <= 0) {
      _showMessage(
        'Order or customer information is missing.',
        isError: true,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderReview(
          id: orderId,
          customer: customerId,
        ),
      ),
    );
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  String _formatDateForDisplay(String value) {
    if (value.trim().isEmpty) {
      return '';
    }

    try {
      return DateFormat('dd MMM yy').format(
        DateTime.parse(value),
      );
    } catch (_) {
      return value;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'invoice created':
        return Colors.orange.shade700;

      case 'invoice approved':
        return Colors.indigo.shade600;

      case 'waiting for confirmation':
        return Colors.deepOrange.shade600;

      case 'pre booked':
        return Colors.purple.shade600;

      case 'packing under progress':
      case 'packing':
        return Colors.blue.shade700;

      case 'packed':
        return Colors.teal.shade600;

      case 'ready to ship':
        return Colors.teal.shade700;

      case 'to print':
        return Colors.cyan.shade700;

      case 'shipped':
        return Colors.green.shade700;

      case 'invoice rejected':
        return Colors.red.shade700;

      default:
        return Colors.blue.shade700;
    }
  }

  String get _activeDateFilterText {
    if (selectedDate != null) {
      return DateFormat('dd MMM yyyy').format(selectedDate!);
    }

    if (startDate != null && endDate != null) {
      return '${DateFormat('dd MMM yyyy').format(startDate!)}'
          ' - '
          '${DateFormat('dd MMM yyyy').format(endDate!)}';
    }

    return '';
  }

  bool get _hasActiveFilters {
    return searchQuery.isNotEmpty ||
        selectedStatus != 'All' ||
        startDate != null ||
        endDate != null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          _navigateBack();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text(
            'Bepocart Orders',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _navigateBack,
          ),
          actions: [
            IconButton(
              tooltip: 'Select date',
              icon: const Icon(Icons.calendar_today),
              onPressed: () => _selectSingleDate(context),
            ),
            IconButton(
              tooltip: 'Select date range',
              icon: const Icon(Icons.date_range),
              onPressed: () => _selectDateRange(context),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (String value) {
                switch (value) {
                  case 'export_excel':
                    exportToExcel();
                    break;

                  case 'download_pdf':
                    downloadPdf();
                    break;

                  case 'clear_filters':
                    _clearAllFilters();
                    break;

                  case 'logout':
                    logout();
                    break;
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    value: 'export_excel',
                    enabled: !isExportingExcel,
                    child: Row(
                      children: [
                        if (isExportingExcel)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        else
                          const Icon(
                            Icons.table_view_outlined,
                            size: 20,
                          ),
                        const SizedBox(width: 10),
                        const Text('Export Excel'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'download_pdf',
                    enabled: !isExportingPdf,
                    child: Row(
                      children: [
                        if (isExportingPdf)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        else
                          const Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 20,
                          ),
                        const SizedBox(width: 10),
                        const Text('Download PDF'),
                      ],
                    ),
                  ),
                  if (_hasActiveFilters)
                    const PopupMenuItem<String>(
                      value: 'clear_filters',
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_alt_off_outlined,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text('Clear Filters'),
                        ],
                      ),
                    ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
        body: SafeArea(
          child: isInitialLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Column(
                  children: [
                    _buildFiltersSection(),
                    const SizedBox(height: 10),
                    _buildPagination(),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _buildOrderListContent(),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: DropdownButtonFormField<String>(
            value: selectedStatus,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Filter by Status',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(
                  color: Colors.grey.shade400,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(
                  color: Colors.blue,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            onChanged: isPageLoading
                ? null
                : (String? value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      selectedStatus = value;
                      currentPage = 1;
                    });

                    fetchOrderData();
                  },
            items: orderStatuses.map((String status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(
                  _getDisplayStatus(status),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
          ),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search invoice or customer...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(
                  color: Colors.grey.shade400,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(
                  color: Colors.blue,
                  width: 2,
                ),
              ),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        _searchDebounce?.cancel();

                        setState(() {
                          searchQuery = '';
                          currentPage = 1;
                        });

                        fetchOrderData();
                      },
                    ),
            ),
            onChanged: (String value) {
              setState(() {});
              _onSearchChanged(value);
            },
            onSubmitted: (String value) {
              _searchDebounce?.cancel();

              setState(() {
                searchQuery = value.trim();
                currentPage = 1;
              });

              fetchOrderData();
            },
          ),
        ),
        if (_activeDateFilterText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.shade100,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 18,
                    color: Colors.blue.shade800,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _activeDateFilterText,
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setState(() {
                        selectedDate = null;
                        startDate = null;
                        endDate = null;
                        currentPage = 1;
                      });

                      fetchOrderData();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Padding(
        //   padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        //   child: Row(
        //     children: [
        //       Expanded(
        //         child: _buildSummaryChip(
        //           title: 'Orders',
        //           value: totalOrderCount.toString(),
        //           icon: Icons.receipt_long_outlined,
        //           color: Colors.blue,
        //         ),
        //       ),
        //       const SizedBox(width: 8),
        //       Expanded(
        //         child: _buildSummaryChip(
        //           title: 'Created',
        //           value: invoiceCreatedCount.toString(),
        //           icon: Icons.description_outlined,
        //           color: Colors.orange,
        //         ),
        //       ),
        //       const SizedBox(width: 8),
        //       Expanded(
        //         child: _buildSummaryChip(
        //           title: 'Approved',
        //           value: invoiceApprovedCount.toString(),
        //           icon: Icons.verified_outlined,
        //           color: Colors.green,
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }

  Widget _buildSummaryChip({
    required String title,
    required String value,
    required IconData icon,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.shade100,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 18,
            color: color.shade700,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color.shade900,
              fontSize: 15,
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color.shade800,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: !hasPreviousPage
                  ? Colors.grey.shade300
                  : Colors.blue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 25,
                vertical: 12,
              ),
            ),
            onPressed: !hasPreviousPage || isPageLoading
                ? null
                : () => goToPage(currentPage - 1),
            child: const Text('Prev'),
          ),
          isPageLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  'Page $currentPage / $totalPages',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  !hasNextPage ? Colors.grey.shade300 : Colors.blue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 25,
                vertical: 12,
              ),
            ),
            onPressed: !hasNextPage || isPageLoading
                ? null
                : () => goToPage(currentPage + 1),
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderListContent() {
    if (errorMessage != null) {
      return _buildErrorState();
    }

    if (filteredOrders.isEmpty) {
      return RefreshIndicator(
        onRefresh: fetchOrderData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.35,
            ),
            Icon(
              Icons.inbox_outlined,
              size: 55,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                startDate != null || endDate != null
                    ? 'No orders available in this date range'
                    : 'No family orders available',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(255, 2, 65, 96),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchOrderData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filteredOrders.length,
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
        itemBuilder: (BuildContext context, int index) {
          final Map<String, dynamic> order =
              filteredOrders[index];

          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return RefreshIndicator(
      onRefresh: () => fetchOrderData(showFullLoader: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.23,
          ),
          Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? 'Unable to fetch orders.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                fetchOrderData(showFullLoader: true);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final Map<String, dynamic> customer =
        _toMap(order['customer']);

    final Map<String, dynamic> billingAddress =
        _toMap(order['billing_address']);

    final List<Map<String, dynamic>> warehouseData =
        _toMapList(order['warehouse']);

    final String invoice = _text(
      order['invoice'],
      fallback: 'N/A',
    );

    final String orderDate =
        _formatDateForDisplay(_text(order['order_date']));

    final String customerName = _text(
      customer['name'],
      fallback: _text(
        billingAddress['name'],
        fallback: 'N/A',
      ),
    );

    final String staffName = _text(
      order['manage_staff'],
      fallback: 'N/A',
    );

    final String status = _text(
      order['status'],
      fallback: 'N/A',
    );

    final String displayStatus = _getDisplayStatus(status);

    final String family = _text(
      order['family_name'],
      fallback: _text(order['family']),
    );

    final double totalAmount =
        _toDouble(order['total_amount']);

    final Color statusColor = _getStatusColor(status);

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 3,
      ),
      child: GestureDetector(
        onTap: () => _openOrder(order),
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
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
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '#$invoice',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (orderDate.isNotEmpty)
                      Text(
                        orderDate,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer: $customerName',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Staff: $staffName',
                      style: const TextStyle(
                        fontSize: 13,
                      ),
                    ),
                    if (family.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Family: $family',
                        style: const TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Status: ',
                          style: TextStyle(
                            fontSize: 13,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            displayStatus,
                            style: TextStyle(
                              fontSize: 13,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Billing Amount:',
                          style: TextStyle(
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          totalAmount.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    if (warehouseData.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        'Warehouse Info:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildWarehouseTable(warehouseData),
                    ] else ...[
                      const SizedBox(height: 5),
                      const Text(
                        'No warehouse data available',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarehouseTable(
    List<Map<String, dynamic>> warehouseData,
  ) {
    return Table(
      border: TableBorder.symmetric(
        inside: BorderSide(
          color: Colors.grey.shade300,
        ),
        outside: BorderSide(
          color: Colors.grey.shade400,
          width: 1,
        ),
      ),
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(2.5),
        2: FlexColumnWidth(2.2),
      },
      defaultVerticalAlignment:
          TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
          ),
          children: [
            _buildWarehouseHeaderCell('Box'),
            _buildWarehouseHeaderCell('Tracking ID'),
            _buildWarehouseHeaderCell('Service'),
          ],
        ),
        ...warehouseData.map((Map<String, dynamic> warehouse) {
          return TableRow(
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            children: [
              _buildWarehouseDataCell(
                _text(
                  warehouse['box'],
                  fallback: 'N/A',
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: SelectableText(
                  _text(
                    warehouse['tracking_id'],
                    fallback: 'N/A',
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ),
              _buildWarehouseDataCell(
                _text(
                  warehouse['parcel_service_name'],
                  fallback: 'N/A',
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildWarehouseHeaderCell(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 6,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildWarehouseDataCell(String value) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 12,
        ),
      ),
    );
  }
}