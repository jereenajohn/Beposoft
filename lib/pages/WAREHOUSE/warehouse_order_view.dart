import 'dart:convert';
import 'dart:io';

import 'package:beposoft/pages/ACCOUNTS/customer.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/methods.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_review.dart';
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

class WarehouseOrderView extends StatefulWidget {
  final status;

  WarehouseOrderView({
    super.key,
    required this.status,
  });

  @override
  State<WarehouseOrderView> createState() => _WarehouseOrderViewState();
}

class _WarehouseOrderViewState extends State<WarehouseOrderView> {
  List<Map<String, dynamic>> orders = [];

  List<Map<String, dynamic>> filteredOrders = [];

  String searchQuery = '';

  DateTime? selectedDate;

  DateTime? startDate;

  DateTime? endDate;

  drower d = drower();

  // ============================================================
  // STATUS COUNT SUMMARY
  // ============================================================

  int todayStatusCount = 0;
  int allStatusCount = 0;
  bool isStatusCountLoading = true;
  String? statusCountError;

  // ============================================================
  // STATUS DISPLAY NAME
  // ============================================================
  //
  // IMPORTANT:
  //
  // This method only changes what the USER SEES.
  //
  // Backend values remain:
  //
  // To Print
  // Packed
  // Ready to ship
  //
  // This means API URLs, filters, comparisons and backend
  // functionality remain completely unchanged.
  // ============================================================

  String getStatusDisplayName(dynamic status) {
    final String value = status?.toString().trim() ?? '';

    switch (value) {
      case 'To Print':
        return 'Delivery Order (DO)';

      case 'Packed':
        return 'Packed For Delivery (PFD)';

      case 'Ready to ship':
        return 'Out For Delivery (OFD)';

      default:
        return value;
    }
  }

  // ============================================================
  // DRAWER DROPDOWN
  // ============================================================

  Widget _buildDropdownTile(
    BuildContext context,
    String title,
    List<String> options,
  ) {
    return ExpansionTile(
      title: Text(
        title,
      ),
      children: options.map(
        (option) {
          return ListTile(
            title: Text(
              option,
            ),
            onTap: () {
              Navigator.pop(
                context,
              );

              d.navigateToSelectedPage(
                context,
                option,
              );
            },
          );
        },
      ).toList(),
    );
  }

  @override
  void initState() {
    super.initState();

    fetchOrderData();

    fetchStatusCountSummary();

    getprofiledata();
  }

  // ============================================================
  // ORDER STATUS VALUES
  // ============================================================
  //
  // Keep these RAW values because they are used for filtering.
  // ============================================================

  List<String> orderStatuses = [
    'All',
    // 'Invoice Created',
    // 'Invoice Approved',
    // 'Waiting For Confirmation',
    'Packing under progress',
    'Packing',
    'Ready to ship',
    'To Print',
    'Shipped',
    'Invoice Rejected',
  ];

  String selectedStatus = 'All';

  // ============================================================
  // FILTER BY STATUS
  // ============================================================

  void _filterOrdersByStatus(
    String status,
  ) {
    if (status == 'All') {
      setState(() {
        filteredOrders = orders;
      });
    } else {
      setState(() {
        filteredOrders = orders.where(
          (order) {
            return order['status'] == status;
          },
        ).toList();
      });
    }
  }

  // ============================================================
  // TOKEN
  // ============================================================

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getString(
      'token',
    );
  }

  // ============================================================
  // PROFILE
  // ============================================================

  var viewprofileurl = "$api/api/profile/";

  var username = '';

  Future<void> getprofiledata() async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse(
          '$viewprofileurl',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(
          response.body,
        );

        var productsData = parsed['data'];

        if (!mounted) return;

        setState(() {
          username = productsData['username'] ?? '';
        });
      }
    } catch (error) {
      debugPrint(
        'PROFILE ERROR: $error',
      );
    }
  }


  // ============================================================
  // FETCH STATUS COUNT SUMMARY
  // ============================================================

  // ============================================================
// FETCH STATUS COUNT SUMMARY
//
// SAME API + DATE PARAM LOGIC USED IN WAREHOUSE ADMIN
//
// TODAY:
// ?date=yyyy-MM-dd
//
// TILL TODAY:
// ?start_date=FIRST_DAY_OF_CURRENT_MONTH
// &end_date=TODAY
// ============================================================

Future<void> fetchStatusCountSummary() async {
  if (!mounted) return;

  setState(() {
    isStatusCountLoading = true;
    statusCountError = null;
  });

  try {
    final String? token = await getTokenFromPrefs();

    if (token == null || token.trim().isEmpty) {
      if (!mounted) return;

      setState(() {
        isStatusCountLoading = false;
        statusCountError = 'Authentication token not found';
      });

      return;
    }

    // ============================================================
    // CURRENT DATE
    // ============================================================

    final DateTime now = DateTime.now();

    final String today = DateFormat(
      'yyyy-MM-dd',
    ).format(
      now,
    );

    // ============================================================
    // FIRST DAY OF CURRENT MONTH
    // ============================================================

    final String currentMonthStart = DateFormat(
      'yyyy-MM-dd',
    ).format(
      DateTime(
        now.year,
        now.month,
        1,
      ),
    );

    // ============================================================
    // COMMON STATUS SUMMARY API METHOD
    // ============================================================

    Future<Map<String, int>> fetchStatusSummary({
      String? date,
      String? startDate,
      String? endDate,
      required String requestType,
    }) async {
      final Map<String, String> params = {};

      // ==========================================================
      // TODAY
      // ==========================================================

      if (date != null && date.trim().isNotEmpty) {
        params['date'] = date;
      }

      // ==========================================================
      // CURRENT MONTH RANGE
      // ==========================================================

      if (startDate != null && startDate.trim().isNotEmpty) {
        params['start_date'] = startDate;
      }

      if (endDate != null && endDate.trim().isNotEmpty) {
        params['end_date'] = endDate;
      }

      // ==========================================================
      // SAME API USED IN WAREHOUSE ADMIN
      // ==========================================================

      final Uri uri = Uri.parse(
        '$api/api/shipping/status/history/summary/',
      ).replace(
        queryParameters: params,
      );

      debugPrint(
        '=============================================',
      );

      debugPrint(
        'WAREHOUSE ORDER VIEW STATUS REQUEST: $requestType',
      );

      debugPrint(
        'WAREHOUSE ORDER VIEW STATUS URL: $uri',
      );

      // ==========================================================
      // API REQUEST
      // ==========================================================

      final http.Response response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache',
        },
      );

      debugPrint(
        'STATUS RESPONSE CODE [$requestType]: '
        '${response.statusCode}',
      );

      debugPrint(
        'STATUS RESPONSE BODY [$requestType]: '
        '${response.body}',
      );

      debugPrint(
        '=============================================',
      );

      // ==========================================================
      // RESPONSE VALIDATION
      // ==========================================================

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load $requestType status summary '
          '(${response.statusCode})',
        );
      }

      final dynamic decoded = jsonDecode(
        response.body,
      );

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Invalid response from server',
        );
      }

      final String responseStatus =
          decoded['status']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      if (responseStatus.isNotEmpty &&
          responseStatus != 'success') {
        throw Exception(
          decoded['message']?.toString() ??
              'Failed to load status summary',
        );
      }

      // ==========================================================
      // OPTIONAL BACKEND FILTER DEBUG
      // ==========================================================

      final dynamic filters = decoded['filters'];

      if (filters is Map) {
        debugPrint(
          'BACKEND FILTERS [$requestType]',
        );

        debugPrint(
          'date       : ${filters['date']}',
        );

        debugPrint(
          'start_date : ${filters['start_date']}',
        );

        debugPrint(
          'end_date   : ${filters['end_date']}',
        );
      }

      // ==========================================================
      // DATA
      // ==========================================================

      final dynamic data = decoded['data'];

      if (data is! Map) {
        throw Exception(
          'Invalid status summary data',
        );
      }

      debugPrint(
        'TOTAL COUNT [$requestType]: '
        '${data['total_count']}',
      );

      final dynamic rawStatusCounts =
          data['status_counts'];

      if (rawStatusCounts == null) {
        return <String, int>{};
      }

      if (rawStatusCounts is! Map) {
        throw Exception(
          'Invalid status_counts data',
        );
      }

      // ==========================================================
      // CONVERT BACKEND STATUS MAP INTO Map<String, int>
      // ==========================================================

      final Map<String, int> statusMap =
          <String, int>{};

      rawStatusCounts.forEach(
        (
          dynamic key,
          dynamic value,
        ) {
          final String status =
              key?.toString().trim() ?? '';

          if (status.isEmpty) {
            return;
          }

          int count = 0;

          if (value is int) {
            count = value;
          } else if (value is num) {
            count = value.toInt();
          } else {
            count =
                int.tryParse(
                  value?.toString() ?? '0',
                ) ??
                0;
          }

          statusMap[status] = count;
        },
      );

      debugPrint(
        'PARSED STATUS MAP [$requestType]: '
        '$statusMap',
      );

      return statusMap;
    }

    // ============================================================
    // FETCH TODAY + CURRENT MONTH TOGETHER
    // ============================================================

    final List<Map<String, int>> responses =
        await Future.wait<Map<String, int>>(
      [
        // ========================================================
        // TODAY
        //
        // Example:
        // ?date=2026-09-01
        // ========================================================

        fetchStatusSummary(
          date: today,
          requestType: 'TODAY',
        ),

        // ========================================================
        // TILL TODAY
        //
        // FIRST DAY OF CURRENT MONTH -> TODAY
        //
        // Example:
        // ?start_date=2026-09-01
        // &end_date=2026-09-01
        // ========================================================

        fetchStatusSummary(
          startDate: currentMonthStart,
          endDate: today,
          requestType: 'CURRENT MONTH',
        ),
      ],
    );

    // ============================================================
    // TODAY RESPONSE
    // ============================================================

    final Map<String, int> todayStatusMap =
        responses[0];

    // ============================================================
    // CURRENT MONTH RESPONSE
    // ============================================================

    final Map<String, int> tillTodayStatusMap =
        responses[1];

    // ============================================================
    // CURRENT ORDER VIEW STATUS
    //
    // Examples:
    //
    // To Print
    // Packing under progress
    // Packed
    // Ready to ship
    // Return From Delivery
    // Shipped
    // ============================================================

    final String targetStatus =
        widget.status?.toString().trim() ?? '';

    // ============================================================
    // GET COUNT ONLY FOR CURRENT CARD STATUS
    // ============================================================

    final int todayCount =
        todayStatusMap[targetStatus] ?? 0;

    final int tillTodayCount =
        tillTodayStatusMap[targetStatus] ?? 0;

    debugPrint(
      '=============================================',
    );

    debugPrint(
      'WAREHOUSE ORDER VIEW TARGET STATUS: '
      '$targetStatus',
    );

    debugPrint(
      'TODAY COUNT: $todayCount',
    );

    debugPrint(
      'TILL TODAY COUNT: $tillTodayCount',
    );

    debugPrint(
      '=============================================',
    );

    if (!mounted) return;

    // ============================================================
    // UPDATE EXISTING TOP CARDS
    //
    // todayStatusCount -> Today
    //
    // allStatusCount -> Till Today
    // ============================================================

    setState(() {
      todayStatusCount = todayCount;

      allStatusCount = tillTodayCount;

      isStatusCountLoading = false;

      statusCountError = null;
    });
  } catch (error, stackTrace) {
    debugPrint(
      'WAREHOUSE ORDER STATUS HISTORY SUMMARY ERROR: '
      '$error',
    );

    debugPrintStack(
      stackTrace: stackTrace,
    );

    if (!mounted) return;

    setState(() {
      isStatusCountLoading = false;

      statusCountError =
          'Unable to load status count';
    });
  }
}
  Widget _buildStatusCountSummary() {
    final String statusTitle = widget.status == null
        ? 'Order Summary'
        : getStatusDisplayName(widget.status);

    if (isStatusCountLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
            ),
          ),
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
              ),
            ),
          ),
        ),
      );
    }

    if (statusCountError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFED7AA),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: Color(0xFFEA580C),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statusCountError!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9A3412),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Retry',
                onPressed: fetchStatusCountSummary,
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: Color(0xFFEA580C),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            statusTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStatusCountCard(
                  label: 'Today',
                  count: todayStatusCount,
                  icon: Icons.today_rounded,
                ),
              ),
              const SizedBox(width: 12),
            Expanded(
  child: _buildStatusCountCard(
    label: 'Till Today',
    count: allStatusCount,
    icon: Icons.all_inbox_rounded,
  ),
),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCountCard({
    required String label,
    required int count,
    required IconData icon,
  }) {
    return Container(
      height: 92,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF56AFFF),
            Color(0xFF2C74FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C74FF).withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.22),
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.90),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    count.toString(),
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FORMAT UPDATED AT - INDIA DATE & TIME
  // ============================================================

  String _formatUpdatedAt(dynamic value) {
    final String raw = value?.toString().trim() ?? '';

    if (raw.isEmpty) {
      return '';
    }

    try {
      final DateTime parsed = DateTime.parse(raw);

      final DateTime indiaTime = parsed
          .toUtc()
          .add(
            const Duration(
              hours: 5,
              minutes: 30,
            ),
          );

      return DateFormat(
        'dd MMM yyyy, hh:mm a',
      ).format(
        indiaTime,
      );
    } catch (_) {
      return raw;
    }
  }

  // ============================================================
  // FETCH ORDER DATA
  // ============================================================

  Future<void> fetchOrderData() async {
    try {
      final token = await getTokenFromPrefs();

      final dep = await getdepFromPrefs();

      String url = '$api/api/orders/${widget.status}/';

      List<Map<String, dynamic>> orderList = [];

      var response = await http.get(
        Uri.parse(
          url,
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print(
        "==============================response====================${response.body}",
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(
          response.body,
        );

        final List ordersData = responseData['results'];

        List<Map<String, dynamic>> newOrders = [];

        for (var orderData in ordersData) {
          String rawOrderDate = orderData['order_date'] ?? "";

          String formattedOrderDate = rawOrderDate;

          try {
            DateTime parsedOrderDate = DateFormat(
              'yyyy-MM-dd',
            ).parse(
              rawOrderDate,
            );

            formattedOrderDate = DateFormat(
              'yyyy-MM-dd',
            ).format(
              parsedOrderDate,
            );
          } catch (e) {
            debugPrint(
              'ORDER DATE PARSE ERROR: $e',
            );
          }

          if (widget.status == null ||
              widget.status == orderData['status']) {
            if (orderData['status'] != "Order Request by Warehouse") {
              newOrders.add({
                'id': orderData['id'],

                'invoice': orderData['invoice'],

                'manage_staff': orderData['manage_staff'],

                'customer': {
                  'id': orderData['customer']['id'],
                  'name': orderData['customer']['name'],
                  'phone': orderData['customer']['phone'],
                  'email': orderData['customer']['email'],
                  'address': orderData['customer']['address'],
                },

                'warehouse': orderData['warehouse_data'],

                // ================================================
                // STATE
                // ================================================

                'state': orderData['state'] ?? '',

                // ================================================
                // ZIP CODE
                // ================================================

                'zipcode': orderData['billing_address']?['zipcode']
                        ?.toString()
                        .replaceAll("'", "")
                        .trim() ??
                    '',

                // Keep RAW backend status
                'status': orderData['status'],

                'total_amount': orderData['total_amount'],

                'order_date': formattedOrderDate,

                'updated_at': orderData['updated_at'] ?? '',

                'locked_by': orderData['locked_by'],
              });
            }
          }
        }

        if (!mounted) return;

        setState(() {
          orders = newOrders;

          filteredOrders = newOrders;
        });
      } else {
        throw Exception(
          "Failed to load order data",
        );
      }
    } catch (error) {
      debugPrint(
        'FETCH ORDER ERROR: $error',
      );
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _filterOrders(
    String query,
  ) {
    setState(() {
      searchQuery = query;

      if (query.isEmpty) {
        filteredOrders = orders;
      } else {
        filteredOrders = orders.where(
          (order) {
            final invoice =
                order['invoice']?.toString().toLowerCase() ?? '';

            final manageStaff =
                order['manage_staff']?.toString().toLowerCase() ?? '';

            final totalAmount =
                order['total_amount']?.toString().toLowerCase() ?? '';

            final customer =
                order['customer']?['name']?.toString().toLowerCase() ?? '';

            return invoice.contains(
                  query.toLowerCase(),
                ) ||
                manageStaff.contains(
                  query.toLowerCase(),
                ) ||
                customer.contains(
                  query.toLowerCase(),
                ) ||
                totalAmount.contains(
                  query.toLowerCase(),
                );
          },
        ).toList();
      }
    });
  }

  // ============================================================
  // SINGLE DATE FILTER
  // ============================================================

  void _filterOrdersBySingleDate() {
    if (selectedDate != null) {
      setState(() {
        filteredOrders = orders.where(
          (order) {
            final orderDate = DateTime.parse(
              order['order_date'],
            );

            return orderDate.year == selectedDate!.year &&
                orderDate.month == selectedDate!.month &&
                orderDate.day == selectedDate!.day;
          },
        ).toList();
      });
    }
  }

  // ============================================================
  // LOCK ORDER
  // ============================================================

  Future lockorder(
    var id,
  ) async {
    final token = await getTokenFromPrefs();

    try {
      var response = await http.post(
        Uri.parse(
          '$api/api/orders/$id/lock/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(
          {},
        ),
      );

      debugPrint(
        'LOCK ORDER RESPONSE: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint(
        'LOCK ORDER ERROR: $e',
      );
    }
  }

  // ============================================================
  // DATE RANGE FILTER
  // ============================================================

  void _filterOrdersByDateRange() {
    if (startDate != null && endDate != null) {
      setState(() {
        filteredOrders = orders.where(
          (order) {
            final orderDate = DateTime.parse(
              order['order_date'],
            );

            return orderDate.isAtSameMomentAs(
                  startDate!,
                ) ||
                orderDate.isAtSameMomentAs(
                  endDate!,
                ) ||
                (orderDate.isAfter(
                      startDate!,
                    ) &&
                    orderDate.isBefore(
                      endDate!,
                    ));
          },
        ).toList();
      });
    }
  }

  // ============================================================
  // SELECT SINGLE DATE
  // ============================================================

  Future<void> _selectSingleDate(
    BuildContext context,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(
        2000,
      ),
      lastDate: DateTime(
        2101,
      ),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });

      _filterOrdersBySingleDate();
    }
  }

  // ============================================================
  // SELECT DATE RANGE
  // ============================================================

  Future<void> _selectDateRange(
    BuildContext context,
  ) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(
        2000,
      ),
      lastDate: DateTime(
        2101,
      ),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(
              start: startDate!,
              end: endDate!,
            )
          : null,
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;

        endDate = picked.end;
      });

      _filterOrdersByDateRange();
    }
  }

  // ============================================================
  // EXPORT EXCEL
  // ============================================================

  Future<void> exportToExcel() async {
    var excel = Excel.createExcel();

    Sheet sheetObject = excel['Order List'];

    sheetObject.appendRow([
      'Invoice',
      'Manager',
      'Customer Name',
      'Customer Phone',
      'Customer Email',
      'Customer Address',
      'Billing Name',
      'Billing Email',
      'Billing Phone',
      'Billing Address',
      'Billing City',
      'Billing State',
      'Billing Zipcode',
      'Bank Name',
      'Bank Account Number',
      'Bank IFSC Code',
      'Bank Branch',
      'Item Name',
      'Item Quantity',
      'Item Price',
      'Item Tax',
      'Item Discount',
      'Order Status',
      'Total Amount',
      'Order Date',
    ]);

    for (var order in filteredOrders) {
      final dynamic items = order['items'];

      if (items is List) {
        for (var item in items) {
          sheetObject.appendRow([
            order['invoice'] ?? '',
            order['manage_staff'] ?? '',
            order['customer']?['name'] ?? '',
            order['customer']?['phone'] ?? '',
            order['customer']?['email'] ?? '',
            order['customer']?['address'] ?? '',
            order['billing_address']?['name'] ?? '',
            order['billing_address']?['email'] ?? '',
            order['billing_address']?['phone'] ?? '',
            order['billing_address']?['address'] ?? '',
            order['billing_address']?['city'] ?? '',
            order['billing_address']?['state'] ?? '',
            order['billing_address']?['zipcode'] ?? '',
            order['bank']?['name'] ?? '',
            order['bank']?['account_number'] ?? '',
            order['bank']?['ifsc_code'] ?? '',
            order['bank']?['branch'] ?? '',
            item['name'] ?? '',
            item['quantity'] ?? '',
            item['price'] ?? '',
            item['tax'] ?? '',
            item['discount'] ?? '',

            // ================================================
            // DISPLAY RENAMED STATUS IN EXCEL
            // ================================================

            getStatusDisplayName(
              order['status'],
            ),

            order['total_amount'] ?? '',
            order['order_date'] ?? '',
          ]);
        }
      } else {
        sheetObject.appendRow([
          order['invoice'] ?? '',
          order['manage_staff'] ?? '',
          order['customer']?['name'] ?? '',
          order['customer']?['phone'] ?? '',
          order['customer']?['email'] ?? '',
          order['customer']?['address'] ?? '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',

          // ================================================
          // DISPLAY RENAMED STATUS IN EXCEL
          // ================================================

          getStatusDisplayName(
            order['status'],
          ),

          order['total_amount'] ?? '',
          order['order_date'] ?? '',
        ]);
      }
    }

    final tempDir = await getTemporaryDirectory();

    final tempPath = "${tempDir.path}/order_list.xlsx";

    final tempFile = File(
      tempPath,
    );

    await tempFile.writeAsBytes(
      await excel.encode()!,
    );

    await OpenFilex.open(
      tempPath,
    );
  }

  // ============================================================
  // CREATE PDF
  // ============================================================

  Future<pw.Document> createPdf() async {
    final pdf = pw.Document();

    for (var order in filteredOrders) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (
            pw.Context context,
          ) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(
                24,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // ===============================================
                  // TITLE
                  // ===============================================

                  pw.Center(
                    child: pw.Text(
                      'Order Details',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),

                  pw.SizedBox(
                    height: 20,
                  ),

                  // ===============================================
                  // INVOICE / MANAGER
                  // ===============================================

                  pw.Text(
                    'Invoice: ${order['invoice'] ?? ''}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),

                  pw.Text(
                    'Manager: ${order['manage_staff'] ?? ''}',
                  ),

                  pw.SizedBox(
                    height: 10,
                  ),

                  // ===============================================
                  // CUSTOMER
                  // ===============================================

                  pw.Text(
                    'Customer Details',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),

                  pw.Text(
                    'Name: ${order['customer']?['name'] ?? ''}',
                  ),

                  pw.Text(
                    'Phone: ${order['customer']?['phone'] ?? ''}',
                  ),

                  pw.Text(
                    'Email: ${order['customer']?['email'] ?? ''}',
                  ),

                  pw.Text(
                    'Address: ${order['customer']?['address'] ?? ''}',
                  ),

                  pw.SizedBox(
                    height: 10,
                  ),

                  // ===============================================
                  // BILLING
                  // ===============================================

                  pw.Text(
                    'Billing Address',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),

                  pw.Text(
                    'Name: ${order['billing_address']?['name'] ?? ''}',
                  ),

                  pw.Text(
                    'Email: ${order['billing_address']?['email'] ?? ''}',
                  ),

                  pw.Text(
                    'Phone: ${order['billing_address']?['phone'] ?? ''}',
                  ),

                  pw.Text(
                    'Address: ${order['billing_address']?['address'] ?? ''}',
                  ),

                  pw.Text(
                    'City: ${order['billing_address']?['city'] ?? ''}',
                  ),

                  pw.Text(
                    'State: ${order['billing_address']?['state'] ?? ''}',
                  ),

                  pw.Text(
                    'Zipcode: ${order['billing_address']?['zipcode'] ?? ''}',
                  ),

                  pw.SizedBox(
                    height: 10,
                  ),

                  // ===============================================
                  // BANK
                  // ===============================================

                  pw.Text(
                    'Bank Details',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),

                  pw.Text(
                    'Name: ${order['bank']?['name'] ?? ''}',
                  ),

                  pw.Text(
                    'Account Number: ${order['bank']?['account_number'] ?? ''}',
                  ),

                  pw.Text(
                    'IFSC Code: ${order['bank']?['ifsc_code'] ?? ''}',
                  ),

                  pw.Text(
                    'Branch: ${order['bank']?['branch'] ?? ''}',
                  ),

                  pw.SizedBox(
                    height: 10,
                  ),

                  // ===============================================
                  // ITEMS
                  // ===============================================

                  pw.Text(
                    'Items',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),

                  if (order['items'] is List)
                    pw.Table.fromTextArray(
                      headers: [
                        'Name',
                        'Quantity',
                        'Price',
                        'Tax',
                        'Discount',
                      ],
                      data: [
                        for (var item in order['items'])
                          [
                            item['name'] ?? '',
                            item['quantity']?.toString() ?? '',
                            item['price']?.toString() ?? '',
                            item['tax']?.toString() ?? '',
                            item['discount']?.toString() ?? '',
                          ],
                      ],
                      headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                      cellStyle: pw.TextStyle(
                        fontSize: 8,
                      ),
                      headerDecoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      rowDecoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(
                            color: PdfColors.grey400,
                            width: 0.5,
                          ),
                        ),
                      ),
                    ),

                  pw.SizedBox(
                    height: 10,
                  ),

                  // ===============================================
                  // ORDER SUMMARY
                  // ===============================================

                  pw.Text(
                    'Order Summary',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),

                  // ===============================================
                  // DISPLAY RENAMED STATUS IN PDF
                  // ===============================================

                  pw.Text(
                    'Status: ${getStatusDisplayName(order['status'])}',
                  ),

                  pw.Text(
                    'Total Amount: ${order['total_amount']?.toString() ?? ''}',
                  ),

                  pw.Text(
                    'Order Date: ${order['order_date'] ?? ''}',
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return pdf;
  }

  // ============================================================
  // DOWNLOAD PDF
  // ============================================================

  Future<void> downloadPdf() async {
    final pdf = await createPdf();

    final output = await getTemporaryDirectory();

    final file = File(
      "${output.path}/order_list.pdf",
    );

    await file.writeAsBytes(
      await pdf.save(),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'order_list.pdf',
    );
  }

  // ============================================================
  // DEPARTMENT
  // ============================================================

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getString(
      'department',
    );
  }

  // ============================================================
  // BACK NAVIGATION
  // ============================================================

  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();

    if (!mounted) return;

    if (dep == "BDO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (
            context,
          ) =>
              bdo_dashbord(),
        ),
      );
    } else if (dep == "BDM") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (
            context,
          ) =>
              bdm_dashbord(),
        ),
      );
    } else if (dep == "warehouse") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (
            context,
          ) =>
              WarehouseDashboard(),
        ),
      );
    } else if (dep == "Warehouse Admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (
            context,
          ) =>
              WarehouseAdmin(),
        ),
      );
    } else if (dep == "CEO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (
            context,
          ) =>
              ceo_dashboard(),
        ),
      );
    } else if (dep == "COO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (
            context,
          ) =>
              ceo_dashboard(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (
            context,
          ) =>
              dashboard(),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return WillPopScope(
      onWillPop: () async {
        _navigateBack();

        return false;
      },
      child: Scaffold(
        // ========================================================
        // APP BAR
        // ========================================================

        appBar: AppBar(
          title: Text(
            widget.status == null
                ? 'Order List'
                : getStatusDisplayName(
                    widget.status,
                  ),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          centerTitle: true,

          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
            ),
            onPressed: () async {
              final dep = await getdepFromPrefs();

              if (!mounted) return;

              if (dep == "BDO") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (
                      context,
                    ) =>
                        bdo_dashbord(),
                  ),
                );
              } else if (dep == "CEO") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (
                      context,
                    ) =>
                        ceo_dashboard(),
                  ),
                );
              } else if (dep == "COO") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (
                      context,
                    ) =>
                        ceo_dashboard(),
                  ),
                );
              } else if (dep == "BDM") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (
                      context,
                    ) =>
                        bdm_dashbord(),
                  ),
                );
              } else if (dep == "warehouse") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (
                      context,
                    ) =>
                        WarehouseDashboard(),
                  ),
                );
              } else if (dep == "Warehouse Admin") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (
                      context,
                    ) =>
                        WarehouseAdmin(),
                  ),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (
                      context,
                    ) =>
                        dashboard(),
                  ),
                );
              }
            },
          ),

          actions: [
            IconButton(
              icon: const Icon(
                Icons.calendar_today,
              ),
              onPressed: () => _selectSingleDate(
                context,
              ),
            ),

            IconButton(
              icon: const Icon(
                Icons.date_range,
              ),
              onPressed: () => _selectDateRange(
                context,
              ),
            ),

            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
              ),
              onSelected: (
                value,
              ) {
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
              itemBuilder: (
                BuildContext context,
              ) {
                return const [
                  PopupMenuItem<String>(
                    value: 'Option 1',
                    child: Text(
                      'Export Excel',
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'Option 2',
                    child: Text(
                      'Download Pdf',
                    ),
                  ),
                ];
              },
            ),
          ],
        ),

        // ========================================================
        // BODY
        // ========================================================

        body: RefreshIndicator(
          onRefresh: () async {
            await Future.wait(
              [
                fetchOrderData(),
                fetchStatusCountSummary(),
              ],
            );

            _filterOrdersByStatus(
              selectedStatus,
            );
          },
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // STATUS DROPDOWN
              // CURRENTLY COMMENTED AS IN ORIGINAL PAGE
              // ==================================================

              /*
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(
                    labelText: "Filter by Status",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        30,
                      ),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      selectedStatus = value;
                    });

                    _filterOrdersByStatus(
                      selectedStatus,
                    );
                  },
                  items: orderStatuses.map(
                    (status) {
                      return DropdownMenuItem<String>(
                        // RAW value used internally
                        value: status,

                        // Display name shown to user
                        child: Text(
                          getStatusDisplayName(
                            status,
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),
              ),
              */

              const SizedBox(
                height: 10,
              ),

              // ==================================================
              // TODAY + ALL STATUS SUMMARY
              // ==================================================

              _buildStatusCountSummary(),

              const SizedBox(
                height: 16,
              ),

              // ==================================================
              // SEARCH
              // ==================================================

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        30.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        30.0,
                      ),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2.0,
                      ),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                    ),
                  ),
                  onChanged: _filterOrders,
                ),
              ),

              // ==================================================
              // ORDER LIST
              // ==================================================

              Expanded(
                child: filteredOrders.isEmpty
                    ? Center(
                        child: Text(
                          selectedDate != null ||
                                  (startDate != null && endDate != null)
                              ? 'No orders available in this date range'
                              : 'No orders available',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(
                              255,
                              2,
                              65,
                              96,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredOrders.length,
                        padding: const EdgeInsets.only(
                          right: 10,
                          left: 10,
                        ),
                        itemBuilder: (
                          context,
                          index,
                        ) {
                          final order = filteredOrders[index];

                          final isLocked = order['locked_by'] != null;

                          final isLockedByMe =
                              order['locked_by'] == username;

                          Widget orderCard = Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                15.0,
                              ),
                            ),
                            color: Colors.white,
                            elevation: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // =================================
                                // HEADER
                                // =================================

                                Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(
                                        15.0,
                                      ),
                                      topRight: Radius.circular(
                                        15.0,
                                      ),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(
                                    8.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '#${order['invoice']}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(
                                        width: 8,
                                      ),

                                      Text(
                                        DateFormat(
                                          'dd MMM yy',
                                        ).format(
                                          DateTime.parse(
                                            order['order_date'],
                                          ),
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // =================================
                                // ORDER DETAILS
                                // =================================

                                Padding(
                                  padding: const EdgeInsets.all(
                                    8.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // ===========================
                                      // LOCKED BY
                                      // ===========================

                                      if (isLocked)
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.lock,
                                              color: Colors.red,
                                              size: 16,
                                            ),

                                            const SizedBox(
                                              width: 6,
                                            ),

                                            Expanded(
                                              child: Text(
                                                'Locked by: ${order['locked_by']}',
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.red,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                      if (isLocked)
                                        const SizedBox(
                                          height: 8,
                                        ),

                                      // ===========================
                                      // STATUS
                                      // ===========================

                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Status:',
                                            style: TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),

                                          const SizedBox(
                                            width: 12,
                                          ),

                                          Expanded(
                                            child: Text(
                                              // ====================
                                              // DISPLAY RENAMED STATUS
                                              // ====================

                                              getStatusDisplayName(
                                                order['status'],
                                              ),

                                              textAlign: TextAlign.right,
                                              maxLines: 2,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight:
                                                    FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(
                                        height: 8.0,
                                      ),

                                      // ===========================
                                      // CUSTOMER
                                      // ===========================

                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Customer:',
                                            style: TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),

                                          const SizedBox(
                                            width: 12,
                                          ),

                                          Expanded(
                                            child: Text(
                                              '${order['customer']?['name'] ?? ''}',
                                              textAlign: TextAlign.right,
                                              maxLines: 2,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight:
                                                    FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(
                                        height: 8.0,
                                      ),

                                      // ===========================
                                      // STATE
                                      // ===========================

                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'State:',
                                            style: TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),

                                          const SizedBox(
                                            width: 12,
                                          ),

                                          Expanded(
                                            child: Text(
                                              '${order['state'] ?? ''}',
                                              textAlign: TextAlign.right,
                                              maxLines: 2,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight:
                                                    FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(
                                        height: 8.0,
                                      ),

                                      // ===========================
                                      // ZIP CODE
                                      // ===========================

                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Zip Code:',
                                            style: TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),

                                          const SizedBox(
                                            width: 12,
                                          ),

                                          Expanded(
                                            child: Text(
                                              '${order['zipcode'] ?? ''}',
                                              textAlign: TextAlign.right,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight:
                                                    FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(
                                        height: 8.0,
                                      ),

                                      // ===========================
                                      // UPDATED AT
                                      // ===========================

                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Status Updated At:',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.orange,
                                            ),
                                          ),

                                          const SizedBox(
                                            width: 12,
                                          ),

                                          Expanded(
                                            child: Text(
                                              _formatUpdatedAt(
                                                order['updated_at'],
                                              ),
                                              textAlign: TextAlign.right,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight:
                                                    FontWeight.w600,
                                                    color: Colors.orange,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // =================================
                                // WAREHOUSE DETAILS
                                // =================================

                                if (order['warehouse_orders'] != null &&
                                    order['warehouse_orders'].isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 4.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Warehouse Details:',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),

                                        const SizedBox(
                                          height: 4.0,
                                        ),

                                        ...order['warehouse_orders']
                                            .map<Widget>(
                                          (
                                            warehouse,
                                          ) {
                                            return Card(
                                              color: const Color.fromARGB(
                                                240,
                                                255,
                                                255,
                                                255,
                                              ),
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                vertical: 4.0,
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(
                                                  8.0,
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Image.network(
                                                      "${warehouse['image']}",
                                                      width: 80,
                                                      height: 80,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return const SizedBox(
                                                          width: 80,
                                                          height: 80,
                                                          child: Icon(
                                                            Icons
                                                                .image_not_supported,
                                                          ),
                                                        );
                                                      },
                                                    ),

                                                    const SizedBox(
                                                      width: 10,
                                                    ),

                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'Box: ${warehouse['box']}',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 13,
                                                            ),
                                                          ),

                                                          Text(
                                                            'Total Weight: ${warehouse['total_weight']}',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 13,
                                                            ),
                                                          ),

                                                          Text(
                                                            'Total Volume Weight: ${warehouse['total_volume_weight']}',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 13,
                                                            ),
                                                          ),

                                                          Text(
                                                            'Shipping Charge: \$${warehouse['shipping_charge']}',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 13,
                                                              color:
                                                                  Colors.green,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ).toList(),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );

                          // =======================================
                          // ORDER CLICK
                          // =======================================

                          if (!isLocked || isLockedByMe) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 3.0,
                              ),
                              child: GestureDetector(
                                onTap: () async {
                                  await lockorder(
                                    order['id'],
                                  );

                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          WarehouseOrderReview(
                                        id: order['id'],
                                      ),
                                    ),
                                  );

                                  if (!mounted) return;

                                  // Reload order data and counts when returning
                                  await Future.wait(
                                    [
                                      fetchOrderData(),
                                      fetchStatusCountSummary(),
                                    ],
                                  );
                                },
                                child: orderCard,
                              ),
                            );
                          } else {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 3.0,
                              ),
                              child: orderCard,
                            );
                          }
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}