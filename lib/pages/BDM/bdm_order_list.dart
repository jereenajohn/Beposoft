import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:beposoft/Sales%20Directors/SD_dashboard.dart';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/add_attribute.dart';
import 'package:beposoft/pages/ACCOUNTS/add_bank.dart';
import 'package:beposoft/pages/ACCOUNTS/add_company.dart';
import 'package:beposoft/pages/ACCOUNTS/add_department.dart';
import 'package:beposoft/pages/ACCOUNTS/add_family.dart';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
import 'package:beposoft/pages/ACCOUNTS/add_state.dart';
import 'package:beposoft/pages/ACCOUNTS/add_supervisor.dart';
import 'package:beposoft/pages/ACCOUNTS/customer.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/methods.dart';
import 'package:beposoft/pages/ACCOUNTS/order.review.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/MARKETING/marketing_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as ex;
import 'package:open_filex/open_filex.dart';

class bdm_OrderList extends StatefulWidget {
  var status;
  bdm_OrderList({super.key, required this.status});

  @override
  State<bdm_OrderList> createState() => _bdm_OrderListState();
}

class _bdm_OrderListState extends State<bdm_OrderList> {
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  List<String> staffList = [];
  List<Map<String, dynamic>> sta = [];
  String searchQuery = '';
  String selectedStatus = '';
  String selectedStaff = '';
  List<Map<String, dynamic>> fam = [];

  DateTime? selectedDate;
  DateTime? startDate;
  DateTime? endDate;

  int currentPage = 1;
  int totalCount = 0;
  String? nextPageUrl;
  String? previousPageUrl;

  int invoiceCreatedCount = 0;
  int invoiceApprovedCount = 0;

  bool isLoading = true;
  bool isLoadingMore = false;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  drower d = drower();

  final List<String> statusOptions = [
    'Invoice Created',
    'Invoice Approved',
    'Packing under progress',
    'Ready to ship',
    'Shipped',
    'Invoice Rejected',
    'Order Confirmed',
    'Order Request by Warehouse',
  ];

  Widget _buildDropdownTile(
      BuildContext context, String title, List<String> options) {
    return ExpansionTile(
      title: Text(title),
      children: options.map((option) {
        return ListTile(
          title: Text(option),
          onTap: () {
            Navigator.pop(context);
            d.navigateToSelectedPage3(context, option);
          },
        );
      }).toList(),
    );
  }

  @override
  void initState() {
    super.initState();
    initdata();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void initdata() async {
    setState(() {
      isLoading = true;
    });

    await getfamily();
    await getprofiledata();
    await getstaff();
    await fetchOrderData(reset: true);
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  var family = '';
  String familyName = '';

  Future<void> getstaff() async {
    try {
      final token = await getTokenFromPrefs();
      if (token == null) return;

      var response = await http.get(
        Uri.parse('$api/api/staffs/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> stafflist = [];
      List<String> staffNames = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          dynamic staffFamilyValue;

          if (productData['family'] is Map) {
            staffFamilyValue = productData['family']['id'];
          } else {
            staffFamilyValue = productData['family'] ??
                productData['family_id'] ??
                productData['familyID'];
          }

          if (staffFamilyValue != null &&
              staffFamilyValue.toString() == family.toString()) {
            final staffName = productData['name']?.toString() ?? '';

            if (staffName.isNotEmpty) {
              stafflist.add({
                'id': productData['id'],
                'name': staffName,
              });

              staffNames.add(staffName);
            }
          }
        }

        staffNames = staffNames.toSet().toList()..sort();

        setState(() {
          sta = stafflist;
          staffList = staffNames;
        });
      }
    } catch (error) {}
  }

  Future<void> getprofiledata() async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        setState(() {
          family = productsData['family'].toString();

          var matchingFamily = fam.firstWhere(
            (element) => element['id'].toString() == family,
            orElse: () => {'id': null, 'name': 'Unknown'},
          );

          familyName = matchingFamily['name'];
        });
      }
    } catch (error) {}
  }

  Future<void> getfamily() async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/familys/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];
        List<Map<String, dynamic>> familylist = [];

        for (var productData in productsData) {
          familylist.add({
            'id': productData['id'].toString(),
            'name': productData['name'],
          });
        }

        setState(() {
          fam = familylist;
        });
      }
    } catch (error) {}
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoading &&
        !isLoadingMore &&
        nextPageUrl != null) {
      loadNextPage();
    }
  }

  Future<void> fetchOrderData({bool reset = false}) async {
    try {
      final token = await getTokenFromPrefs();

      if (token == null) {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
        return;
      }

      if (reset) {
        setState(() {
          isLoading = true;
          currentPage = 1;
          orders = [];
          filteredOrders = [];
          nextPageUrl = null;
          previousPageUrl = null;
        });
      } else {
        setState(() {
          isLoadingMore = true;
        });
      }

      final jwt = JWT.decode(token);

      final Map<String, String> queryParams = {
        'page': currentPage.toString(),
      };

      if (searchQuery.trim().isNotEmpty) {
        queryParams['search'] = searchQuery.trim();
      }

      if (selectedStatus.isNotEmpty) {
        queryParams['status'] = selectedStatus;
      } else if (widget.status != null &&
          widget.status.toString().trim().isNotEmpty) {
        queryParams['status'] = widget.status.toString().trim();
      }

      if (selectedStaff.isNotEmpty) {
        queryParams['staff'] = selectedStaff;
      }

      if (selectedDate != null) {
        final singleDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
        queryParams['start_date'] = singleDate;
        queryParams['end_date'] = singleDate;
      } else {
        if (startDate != null) {
          queryParams['start_date'] =
              DateFormat('yyyy-MM-dd').format(startDate!);
        }
        if (endDate != null) {
          queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(endDate!);
        }
      }

      final Uri uri = Uri.parse('$api/api/family/bdm/bdo/orders/')
          .replace(queryParameters: queryParams);

      var response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        final int count = parsed['count'] ?? 0;
        final String? next = parsed['next'];
        final String? previous = parsed['previous'];

        final Map<String, dynamic> wrapper =
            parsed['results'] is Map<String, dynamic>
                ? Map<String, dynamic>.from(parsed['results'])
                : {};

        final int createdCount = wrapper['invoice_created_count'] ?? 0;
        final int approvedCount = wrapper['invoice_approved_count'] ?? 0;

        final List<dynamic> resultsList =
            wrapper['results'] is List ? wrapper['results'] : [];

        List<Map<String, dynamic>> newOrders = [];

        for (var orderData in resultsList) {
          String rawOrderDate = orderData['order_date']?.toString() ?? "";
          String formattedOrderDate = rawOrderDate;
          try {
            DateTime parsedOrderDate =
                DateFormat('yyyy-MM-dd').parse(rawOrderDate);
            formattedOrderDate =
                DateFormat('yyyy-MM-dd').format(parsedOrderDate);
          } catch (e) {}

          Map<String, dynamic> customerMap = {};
          if (orderData['customer'] is Map) {
            customerMap = Map<String, dynamic>.from(orderData['customer']);
          }

          Map<String, dynamic> billingMap = {};
          if (orderData['billing_address'] is Map) {
            billingMap =
                Map<String, dynamic>.from(orderData['billing_address']);
          }

          List<Map<String, dynamic>> warehouseList = [];
          if (orderData['warehouse'] is List) {
            warehouseList = List<Map<String, dynamic>>.from(
              (orderData['warehouse'] as List).map(
                (e) => Map<String, dynamic>.from(e),
              ),
            );
          }

          if (orderData['status'] != "Order Request by Warehouse") {
            final mappedOrder = {
              'id': orderData['id'],
              'family': orderData['family'] ?? '',
              'invoice': orderData['invoice'] ?? '',
              'manage_staff': orderData['manage_staff'] ?? '',
              'staffID': orderData['staffID'] ?? '',
              'customer': customerMap,
              'customer_id': orderData['customerID'],
              'billing_address': billingMap,
              'warehouse': warehouseList,
              'payment_images': orderData['payment_images'] is List
                  ? List<Map<String, dynamic>>.from(
                      (orderData['payment_images'] as List).map(
                        (e) => Map<String, dynamic>.from(e),
                      ),
                    )
                  : <Map<String, dynamic>>[],
              'state': orderData['state'] ?? '',
              'payment_status': orderData['payment_status'] ?? '',
              'payment_method': orderData['payment_method'] ?? '',
              'shipping_mode': orderData['shipping_mode'],
              'shipping_charge': orderData['shipping_charge'] ?? 0,
              'cod_amount': orderData['cod_amount'] ?? 0,
              'status': orderData['status'] ?? '',
              'total_amount': orderData['total_amount'] ?? 0,
              'order_date': formattedOrderDate,
              'note': orderData['note'] ?? '',
              'accounts_note': orderData['accounts_note'] ?? '',
              'updated_at': orderData['updated_at'] ?? '',
              'family_id': orderData['family_id'],
              'family_name': orderData['family_name'] ?? '',
              'company': orderData['company'],
              'bank': orderData['bank'],
              'confirmed_by': orderData['confirmed_by'],
              'locked_by': orderData['locked_by'],
              'locked_at': orderData['locked_at'],
              'box_count': orderData['box_count'],
              'cod_status': orderData['cod_status'],
              'adv_cod_amount': orderData['adv_cod_amount'],
              'warehouses': orderData['warehouses'],
            };

            newOrders.add(mappedOrder);
          }
        }

        setState(() {
          totalCount = count;
          nextPageUrl = next;
          previousPageUrl = previous;
          invoiceCreatedCount = createdCount;
          invoiceApprovedCount = approvedCount;

          if (reset) {
            orders = newOrders;
            filteredOrders = newOrders;
          } else {
            orders.addAll(newOrders);
            filteredOrders = List<Map<String, dynamic>>.from(orders);
          }

          isLoading = false;
          isLoadingMore = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  Future<void> loadNextPage() async {
    if (nextPageUrl == null || isLoadingMore) return;
    currentPage += 1;
    await fetchOrderData(reset: false);
  }

  Future<void> applyFilters() async {
    currentPage = 1;
    await fetchOrderData(reset: true);
  }

  void _filterOrders(String query) {
    searchQuery = query;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      await applyFilters();
    });
  }

  Future<void> _filterOrdersBySingleDate() async {
    startDate = null;
    endDate = null;
    await applyFilters();
  }

  Future<void> _filterOrdersByDateRange() async {
    selectedDate = null;
    await applyFilters();
  }

  Future<void> _selectSingleDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        startDate = null;
        endDate = null;
      });
      await _filterOrdersBySingleDate();
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        selectedDate = null;
        startDate = picked.start;
        endDate = picked.end;
      });
      await _filterOrdersByDateRange();
    }
  }

  Future<void> clearAllFilters() async {
    searchController.clear();
    setState(() {
      searchQuery = '';
      selectedStatus = '';
      selectedStaff = '';
      selectedDate = null;
      startDate = null;
      endDate = null;
      currentPage = 1;
    });
    await fetchOrderData(reset: true);
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('token');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ScaffoldMessenger.of(context).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged out successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });

    await Future.delayed(Duration(seconds: 2));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => login()),
    );
  }

  Future<void> exportToExcel() async {
    var excel = ex.Excel.createExcel();
    ex.Sheet sheetObject = excel['Order List'];

    sheetObject.appendRow([
      'Invoice',
      'Manager',
      'Staff ID',
      'Customer Name',
      'Customer ID',
      'Billing Name',
      'Billing Phone',
      'Billing Alt Phone',
      'Billing Email',
      'Billing Address',
      'Billing City',
      'Billing State',
      'Billing Zipcode',
      'State',
      'Payment Status',
      'Payment Method',
      'Shipping Mode',
      'Shipping Charge',
      'COD Amount',
      'COD Status',
      'Advance COD Amount',
      'Status',
      'Total Amount',
      'Order Date',
      'Note',
      'Accounts Note',
      'Updated At',
      'Warehouse Boxes',
      'Tracking IDs',
      'Family',
      'Family Name',
      'Company',
      'Bank',
      'Confirmed By',
      'Locked By',
      'Locked At',
      'Box Count',
      'Warehouses',
    ]);

    for (var order in filteredOrders) {
      final customer = order['customer'] is Map<String, dynamic>
          ? order['customer'] as Map<String, dynamic>
          : <String, dynamic>{};

      final billingAddress = order['billing_address'] is Map<String, dynamic>
          ? order['billing_address'] as Map<String, dynamic>
          : <String, dynamic>{};

      final warehouse = order['warehouse'] is List
          ? List<Map<String, dynamic>>.from(order['warehouse'])
          : <Map<String, dynamic>>[];

      String warehouseBoxes = warehouse
          .map((e) => e['box']?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .join(', ');

      String trackingIds = warehouse
          .map((e) => e['tracking_id']?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .join(', ');

      sheetObject.appendRow([
        order['invoice']?.toString() ?? '',
        order['manage_staff']?.toString() ?? '',
        order['staffID']?.toString() ?? '',
        customer['name']?.toString() ?? '',
        order['customer_id']?.toString() ?? '',
        billingAddress['name']?.toString() ?? '',
        billingAddress['phone']?.toString() ?? '',
        billingAddress['alt_phone']?.toString() ?? '',
        billingAddress['email']?.toString() ?? '',
        billingAddress['address']?.toString() ?? '',
        billingAddress['city']?.toString() ?? '',
        billingAddress['state']?.toString() ?? '',
        billingAddress['zipcode']?.toString() ?? '',
        order['state']?.toString() ?? '',
        order['payment_status']?.toString() ?? '',
        order['payment_method']?.toString() ?? '',
        order['shipping_mode']?.toString() ?? '',
        order['shipping_charge']?.toString() ?? '',
        order['cod_amount']?.toString() ?? '',
        order['cod_status']?.toString() ?? '',
        order['adv_cod_amount']?.toString() ?? '',
        order['status']?.toString() ?? '',
        order['total_amount']?.toString() ?? '',
        order['order_date']?.toString() ?? '',
        order['note']?.toString() ?? '',
        order['accounts_note']?.toString() ?? '',
        order['updated_at']?.toString() ?? '',
        warehouseBoxes,
        trackingIds,
        order['family']?.toString() ?? '',
        order['family_name']?.toString() ?? '',
        order['company']?.toString() ?? '',
        order['bank']?.toString() ?? '',
        order['confirmed_by']?.toString() ?? '',
        order['locked_by']?.toString() ?? '',
        order['locked_at']?.toString() ?? '',
        order['box_count']?.toString() ?? '',
        order['warehouses']?.toString() ?? '',
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

    for (var order in filteredOrders) {
      final customer = order['customer'] is Map<String, dynamic>
          ? order['customer'] as Map<String, dynamic>
          : <String, dynamic>{};

      final billingAddress = order['billing_address'] is Map<String, dynamic>
          ? order['billing_address'] as Map<String, dynamic>
          : <String, dynamic>{};

      final warehouse = order['warehouse'] is List
          ? List<Map<String, dynamic>>.from(order['warehouse'])
          : <Map<String, dynamic>>[];

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
                  pw.Text(
                    'Invoice: ${order['invoice']}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('Manager: ${order['manage_staff'] ?? ''}'),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Customer Details',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('Name: ${customer['name'] ?? ''}'),
                  pw.Text('Customer ID: ${order['customer_id'] ?? ''}'),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Billing Address',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('Name: ${billingAddress['name'] ?? ''}'),
                  pw.Text('Email: ${billingAddress['email'] ?? ''}'),
                  pw.Text('Phone: ${billingAddress['phone'] ?? ''}'),
                  pw.Text('Address: ${billingAddress['address'] ?? ''}'),
                  pw.Text('City: ${billingAddress['city'] ?? ''}'),
                  pw.Text('State: ${billingAddress['state'] ?? ''}'),
                  pw.Text('Zipcode: ${billingAddress['zipcode'] ?? ''}'),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Warehouse Details',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  warehouse.isEmpty
                      ? pw.Text('No warehouse data available')
                      : pw.Table.fromTextArray(
                          headers: ['Box', 'Tracking ID'],
                          data: [
                            for (var wh in warehouse)
                              [
                                wh['box']?.toString() ?? '',
                                wh['tracking_id']?.toString() ?? '',
                              ],
                          ],
                          headerStyle: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                          cellStyle: pw.TextStyle(
                            fontSize: 8,
                          ),
                          headerDecoration: pw.BoxDecoration(
                            color: PdfColors.grey300,
                          ),
                          rowDecoration: pw.BoxDecoration(
                            border: pw.Border(
                              bottom: pw.BorderSide(
                                  color: PdfColors.grey400, width: 0.5),
                            ),
                          ),
                        ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Order Summary',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('Status: ${order['status'] ?? ''}'),
                  pw.Text(
                      'Total Amount: ${order['total_amount']?.toString() ?? ''}'),
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
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/order_list.pdf");
    await file.writeAsBytes(await pdf.save());
    await Printing.sharePdf(
        bytes: await pdf.save(), filename: 'order_list.pdf');
  }

  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();
    if (dep == "BDO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => bdo_dashbord()),
      );
    } else if (dep == "SD") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SdDashboard()),
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
    } else if (dep == "Warehouse Admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WarehouseAdmin()),
      );
    } else if (dep == "Marketing") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => marketing_dashboard()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => dashboard()),
      );
    }
  }

  Widget buildTopFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide(color: Colors.blue, width: 2.0),
              ),
              prefixIcon: Icon(Icons.search),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () async {
                        searchController.clear();
                        searchQuery = '';
                        await applyFilters();
                      },
                    )
                  : null,
            ),
            onChanged: _filterOrders,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedStatus.isEmpty ? null : selectedStatus,
                  decoration: InputDecoration(
                    hintText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: statusOptions.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    setState(() {
                      selectedStatus = value ?? '';
                    });
                    await applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedStaff.isEmpty ? null : selectedStaff,
                  decoration: InputDecoration(
                    hintText: 'Staff',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: staffList.map((staff) {
                    return DropdownMenuItem<String>(
                      value: staff,
                      child: Text(
                        staff,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    setState(() {
                      selectedStaff = value ?? '';
                    });
                    await applyFilters();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total Orders: $totalCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color.fromARGB(255, 2, 65, 96),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: clearAllFilters,
                child: const Text('Clear Filters'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox({
    required double height,
    required double width,
    double radius = 8,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.35, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      onEnd: () {
        if (mounted && isLoading) {
          setState(() {});
        }
      },
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  Widget _buildShimmerOrderCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 3,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _shimmerBox(
                        height: 18,
                        width: double.infinity,
                        radius: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _shimmerBox(
                      height: 24,
                      width: 82,
                      radius: 20,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(
                      height: 14,
                      width: MediaQuery.of(context).size.width * 0.72,
                      radius: 20,
                    ),
                    const SizedBox(height: 12),
                    _shimmerBox(
                      height: 14,
                      width: MediaQuery.of(context).size.width * 0.55,
                      radius: 20,
                    ),
                    const SizedBox(height: 12),
                    _shimmerBox(
                      height: 14,
                      width: MediaQuery.of(context).size.width * 0.65,
                      radius: 20,
                    ),
                    const SizedBox(height: 12),
                    _shimmerBox(
                      height: 14,
                      width: MediaQuery.of(context).size.width * 0.48,
                      radius: 20,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _shimmerBox(
                          height: 16,
                          width: 16,
                          radius: 20,
                        ),
                        const SizedBox(width: 8),
                        _shimmerBox(
                          height: 14,
                          width: 120,
                          radius: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _shimmerBox(
                                  height: 14,
                                  width: double.infinity,
                                  radius: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: _shimmerBox(
                                  height: 14,
                                  width: double.infinity,
                                  radius: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _shimmerBox(
                                  height: 14,
                                  width: double.infinity,
                                  radius: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: _shimmerBox(
                                  height: 14,
                                  width: double.infinity,
                                  radius: 20,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderListShimmer() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.only(right: 10, left: 10),
        itemCount: 5,
        itemBuilder: (context, index) {
          return _buildShimmerOrderCard();
        },
      ),
    );
  }

  Widget _buildLoadMoreShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: _buildShimmerOrderCard(),
    );
  }

  void _showPaymentImagePopup(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: Colors.white,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 250,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(16),
                          color: Colors.white,
                          child: const Text(
                            'Unable to load image',
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 250,
                          color: Colors.white,
                          alignment: Alignment.center,
                          child: _shimmerBox(
                            height: 250,
                            width: double.infinity,
                            radius: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow({
    required String title,
    required String value,
    Widget? trailing,
    Color? valueColor,
    FontWeight? valueWeight,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Text(
          ':  ',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: valueColor ?? Colors.black87,
              fontWeight: valueWeight ?? FontWeight.w500,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing,
        ],
      ],
    );
  }

  Widget buildOrderCard(Map<String, dynamic> order) {
    final customer = order['customer'] is Map<String, dynamic>
        ? order['customer'] as Map<String, dynamic>
        : <String, dynamic>{};

    final warehouse = order['warehouse'] is List
        ? List<Map<String, dynamic>>.from(order['warehouse'])
        : <Map<String, dynamic>>[];

    final paymentImages = order['payment_images'] is List
        ? List<Map<String, dynamic>>.from(order['payment_images'])
        : <Map<String, dynamic>>[];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderReview(
                id: order['id'],
                customer: order['customer_id'],
              ),
            ),
          );
        },
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 3,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '#${order['invoice']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          DateFormat('dd MMM yy').format(
                            DateTime.parse(order['order_date']),
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow(
                        title: 'Customer',
                        value: '${customer['name'] ?? ''}',
                        valueWeight: FontWeight.w600,
                      ),
                      const SizedBox(height: 10),
                      _infoRow(
                        title: 'Staff',
                        value: '${order['manage_staff'] ?? ''}',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${order['family'] ?? ''}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _infoRow(
                        title: 'Status',
                        value: '${order['status'] ?? ''}',
                        valueColor: Colors.blue.shade700,
                      ),
                      const SizedBox(height: 10),
                      _infoRow(
                        title: 'Billing Amount',
                        value:
                            '${(order['total_amount'] as num).toStringAsFixed(2)}',
                        valueColor: Colors.green.shade700,
                        valueWeight: FontWeight.w700,
                      ),
                      if (paymentImages.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          'Payment Images',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: paymentImages.map<Widget>((img) {
                            final String imagePath =
                                img['image']?.toString() ?? '';
                            final String imageUrl = imagePath.startsWith('http')
                                ? imagePath
                                : '$api$imagePath';

                            return GestureDetector(
                              onTap: () {
                                _showPaymentImagePopup(imageUrl);
                              },
                              child: Container(
                                height: 58,
                                width: 58,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  color: Colors.grey.shade100,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.broken_image_outlined,
                                        color: Colors.grey.shade500,
                                        size: 22,
                                      );
                                    },
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: _shimmerBox(
                                          height: 58,
                                          width: 58,
                                          radius: 10,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 14),
                      if (warehouse.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.local_shipping_outlined,
                              size: 16,
                              color: Colors.blue.shade800,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Warehouse Info',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth:
                                      MediaQuery.of(context).size.width - 70,
                                ),
                                child: Table(
                                  border: TableBorder(
                                    horizontalInside: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                    verticalInside: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  columnWidths: const {
                                    0: FlexColumnWidth(1.1),
                                    1: FlexColumnWidth(2.6),
                                  },
                                  defaultVerticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  children: [
                                    TableRow(
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                      ),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 8,
                                          ),
                                          child: Text(
                                            'Box',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                              color: Colors.blue.shade900,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 8,
                                          ),
                                          child: Text(
                                            'Tracking ID',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                              color: Colors.blue.shade900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    ...warehouse.map<TableRow>((wh) {
                                      return TableRow(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                              horizontal: 8,
                                            ),
                                            child: Text(
                                              wh['box']?.toString() ?? 'N/A',
                                              textAlign: TextAlign.center,
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                              horizontal: 8,
                                            ),
                                            child: Text(
                                              wh['tracking_id']?.toString() ??
                                                  'N/A',
                                              textAlign: TextAlign.center,
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ] else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: Text(
                            'No warehouse data available',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return _buildOrderListShimmer();
    }

    if (filteredOrders.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            selectedDate != null || (startDate != null && endDate != null)
                ? 'No orders available in this date range'
                : 'No orders available',
            style: TextStyle(
              fontSize: 16,
              color: const Color.fromARGB(255, 2, 65, 96),
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        itemCount: filteredOrders.length + (isLoadingMore ? 1 : 0),
        padding: const EdgeInsets.only(right: 10, left: 10),
        itemBuilder: (context, index) {
          if (index == filteredOrders.length) {
            return _buildLoadMoreShimmer();
          }

          final order = filteredOrders[index];
          return buildOrderCard(order);
        },
      ),
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
        appBar: AppBar(
          title: Text(
            "Order List",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final dep = await getdepFromPrefs();
              if (dep == "BDO") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => bdo_dashbord()),
                );
              } else if (dep == "SD") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SdDashboard()),
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
              } else if (dep == "Warehouse Admin") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => WarehouseAdmin()),
                );
              } else if (dep == "Marketing") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => marketing_dashboard(),
                  ),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => dashboard()),
                );
              }
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.calendar_today),
              onPressed: () => _selectSingleDate(context),
            ),
            IconButton(
              icon: Icon(Icons.date_range),
              onPressed: () => _selectDateRange(context),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'Option 1':
                    exportToExcel();
                    break;
                  case 'Option 2':
                    downloadPdf();
                    break;
                  default:
                    break;
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    value: 'Option 1',
                    child: Text('Export Excel'),
                  ),
                  PopupMenuItem<String>(
                    value: 'Option 2',
                    child: Text('Download Pdf'),
                  ),
                ];
              },
            ),
          ],
        ),
        body: Column(
          children: [
            buildTopFilters(),
            buildBody(),
          ],
        ),
      ),
    );
  }
}