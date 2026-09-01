import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:beposoft/pages/ACCOUNTS/add_self_attendance.dart';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
import 'package:beposoft/pages/ACCOUNTS/daily_goods_movement.dart';
import 'package:beposoft/pages/ACCOUNTS/mailboxpage..dart';
import 'package:beposoft/pages/ACCOUNTS/order_list.dart';
import 'package:beposoft/pages/ADMIN/add_attendance.dart';
import 'package:beposoft/pages/ADMIN/add_team_staff.dart';
import 'package:beposoft/pages/ADMIN/localpurchaseorderscreen.dart';
import 'package:beposoft/pages/ADMIN/manager_leave_requestpage.dart';
import 'package:beposoft/pages/BDO/EmployeeLeaveFormPage%20.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_request_list.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_product_approval.dart';
import 'package:beposoft/pages/auth_status_checker.dart';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/add_attribute.dart';
import 'package:beposoft/pages/ACCOUNTS/add_bank.dart';
import 'package:beposoft/pages/ACCOUNTS/add_company.dart';
import 'package:beposoft/pages/ACCOUNTS/add_department.dart';
import 'package:beposoft/pages/ACCOUNTS/add_family.dart';
import 'package:beposoft/pages/ACCOUNTS/add_state.dart';
import 'package:beposoft/pages/ACCOUNTS/add_supervisor.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/methods.dart';
import 'package:beposoft/pages/ACCOUNTS/profilepage.dart';
import 'package:beposoft/pages/api.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';

        // ========================================================
        // 5. RETURN FROM DELIVERY (RFD)
        // ========================================================

class _WarehouseDashboardState extends State<WarehouseDashboard>
    with WidgetsBindingObserver {
  List<String> statusOptions = [
    "pending",
    "approved",
    "rejected",
  ];

  List<Map<String, dynamic>> grvlist = [];
  List<Map<String, dynamic>> proforma = [];
  List<Map<String, dynamic>> salesReportList = [];
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  List<Map<String, dynamic>> shippedOrders = [];

  // ============================================================
  // PAGE LOADING
  // ============================================================

  bool isPageLoading = true;

  // ============================================================
  // TODAY STATUS DATA
  // ============================================================

  List<Map<String, dynamic>> todayStatusCounts = [];

  bool isLoadingTodayStatusCounts = true;

  String? todayStatusError;

  Map<String, int> dgmParcelServiceBoxCounts = {};

  bool isLoadingDgmSummary = true;

  String? dgmSummaryError;

  static const List<String> warehouseDashboardStatuses = [
    'To Print',
    'Packing under progress',
    'Packed',
    'Ready to ship',
    'Return From Delivery',
    'Shipped',
  ];

  int inboxMailCount = 0;

  Timer? mailCountTimer;

  String profileImage = '';

  bool isFetchingInboxMailCount = false;

  String? username = '';

  bool isManager = false;

  int toprint = 0;

  int packed = 0;

  // ============================================================
  // BOTTOM NAVIGATION + DASHBOARD SEARCH
  // ============================================================

  bool isBottomSearchOpen = false;

  String dashboardSearchQuery = '';

  final TextEditingController dashboardSearchController =
      TextEditingController();

  final FocusNode dashboardSearchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _loadInitialData();

    mailCountTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) {
        if (mounted) {
          fetchInboxMailCount();
        }
      },
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!mounted) return;

        AuthStatusChecker.start(context);
      },
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!mounted) return;

        checkAppUpdate(context);
      },
    );
  }

  // ============================================================
  // INITIAL DATA LOAD
  // ENTIRE BODY SHIMMER REMAINS UNTIL DATA LOAD FINISHES
  // ============================================================

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    setState(() {
      isPageLoading = true;
    });

    try {
      await Future.wait([
        _getUsername(),
        getGrvList(),
        getProfile(),
        fetchproformaData(),
        getSalesReport(),
        fetchOrderData(),
        fetchTodayStatusCounts(),
        fetchTodayDgmSummary(),
        fetchInboxMailCount(),
      ]);
    } catch (error, stackTrace) {
      debugPrint(
        'INITIAL DASHBOARD LOAD ERROR: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isPageLoading = false;
      });
    }
  }

  // ============================================================
  // FULL PAGE SHIMMER
  // ============================================================

  Widget _buildFullPageShimmer() {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final double availableWidth = constraints.maxWidth;

        final bool isVerySmallPhone = availableWidth < 340;

        final double horizontalSpacing = isVerySmallPhone ? 8 : 12;

        final double verticalSpacing = isVerySmallPhone ? 8 : 12;

        final double cardHeight = isVerySmallPhone ? 185 : 200;

        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          period: const Duration(
            milliseconds: 1200,
          ),
          child: Padding(
            padding: const EdgeInsets.all(
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =================================================
                // PROFILE SHIMMER
                // =================================================

                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    Container(
                      width: availableWidth * 0.40,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          8,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 28,
                ),

                // =================================================
                // DATE + REFRESH SHIMMER
                // =================================================

                Row(
                  children: [
                    Container(
                      width: availableWidth * 0.38,
                      height: 17,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          8,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          10,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 18,
                ),

                // =================================================
                // GRID SHIMMER
                // =================================================

                Expanded(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 7,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: horizontalSpacing,
                        mainAxisSpacing: verticalSpacing,
                        mainAxisExtent: cardHeight,
                      ),
                      itemBuilder: (
                        BuildContext context,
                        int index,
                      ) {
                        return _buildShimmerCard(
                          isVerySmallPhone: isVerySmallPhone,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // SHIMMER CARD
  // ============================================================

  Widget _buildShimmerCard({
    required bool isVerySmallPhone,
  }) {
    return Container(
      padding: EdgeInsets.all(
        isVerySmallPhone ? 10 : 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: Colors.white,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isVerySmallPhone ? 38 : 42,
                height: isVerySmallPhone ? 38 : 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: isVerySmallPhone ? 38 : 46,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    20,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                6,
              ),
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Container(
            width: isVerySmallPhone ? 80 : 105,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                6,
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Container(
            width: 50,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FETCH TODAY STATUS COUNTS
  // ============================================================

 Future<void> fetchTodayStatusCounts() async {
  if (!mounted) return;

  setState(() {
    isLoadingTodayStatusCounts = true;
    todayStatusError = null;
  });

  // ============================================================
  // MAIL COUNT
  // ============================================================

    if (token == null || token.trim().isEmpty) {
      if (!mounted) return;

      setState(() {
        todayStatusCounts = [];
        isLoadingTodayStatusCounts = false;
        todayStatusError = 'Authentication token not found';
      });

      return;
    }

    // ============================================================
    // DATE VALUES
    // ============================================================

    final DateTime now = DateTime.now();

    final String today = DateFormat(
      'yyyy-MM-dd',
    ).format(now);

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
    // COMMON STATUS HISTORY SUMMARY API
    // ============================================================

    Future<Map<String, int>> fetchStatusSummary({
      String? date,
      String? startDate,
      String? endDate,
      required String requestType,
    }) async {
      final Map<String, String> queryParameters =
          <String, String>{};

      // ==========================================================
      // TODAY
      // ==========================================================

      if (date != null && date.trim().isNotEmpty) {
        queryParameters['date'] = date;
      }

      // ==========================================================
      // CURRENT MONTH
      // ==========================================================

      if (startDate != null &&
          startDate.trim().isNotEmpty) {
        queryParameters['start_date'] = startDate;
      }

      if (endDate != null &&
          endDate.trim().isNotEmpty) {
        queryParameters['end_date'] = endDate;
      }

      final Uri uri = Uri.parse(
        '$api/api/shipping/status/history/summary/',
      ).replace(
        queryParameters: queryParameters,
      );

      debugPrint(
        '=============================================',
      );

      debugPrint(
        'STATUS REQUEST TYPE: $requestType',
      );

      debugPrint(
        'STATUS REQUEST URL: $uri',
      );

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

      // ============================================================
      // BACKEND FILTER DEBUG
      // ============================================================

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

      // ============================================================
      // RESPONSE DATA
      // ============================================================

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
    // FETCH TODAY + CURRENT MONTH IN PARALLEL
    // ============================================================

    final List<Map<String, int>> responses =
        await Future.wait<Map<String, int>>(
      [
        // ========================================================
        // TODAY
        //
        // Example:
        // /api/shipping/status/history/summary/
        // ?date=2026-08-31
        // ========================================================

        fetchStatusSummary(
          date: today,
          requestType: 'TODAY',
        ),

        // ========================================================
        // TILL TODAY = CURRENT MONTH
        //
        // Example:
        // /api/shipping/status/history/summary/
        // ?start_date=2026-08-01
        // &end_date=2026-08-31
        // ========================================================

        fetchStatusSummary(
          startDate: currentMonthStart,
          endDate: today,
          requestType: 'CURRENT MONTH',
        ),
      ],
    );

    // ============================================================
    // TODAY COUNTS
    // ============================================================

    final Map<String, int> todayStatusMap =
        responses[0];

    // ============================================================
    // CURRENT MONTH COUNTS
    // ============================================================

    final Map<String, int> tillTodayStatusMap =
        responses[1];

    debugPrint(
      '=============================================',
    );

    debugPrint(
      'FINAL TODAY MAP: $todayStatusMap',
    );

    debugPrint(
      'FINAL CURRENT MONTH MAP: '
      '$tillTodayStatusMap',
    );

    debugPrint(
      '=============================================',
    );

    // ============================================================
    // MAP TO EXISTING WAREHOUSE DASHBOARD CARDS
    // ============================================================

    final List<Map<String, dynamic>>
        filteredStatusList =
        warehouseDashboardStatuses.map(
      (
        String status,
      ) {
        final int todayCount =
            todayStatusMap[status] ?? 0;

        final int tillTodayCount =
            tillTodayStatusMap[status] ?? 0;

        debugPrint(
          '$status => '
          'Today: $todayCount | '
          'Till Today: $tillTodayCount',
        );

        return <String, dynamic>{
          'status': status,

          // Today only
          'today_count': todayCount,

          // First day of current month -> today
          'all_count': tillTodayCount,
        };
      },
    ).toList();

    if (!mounted) return;

    setState(() {
      todayStatusCounts =
          filteredStatusList;

      isLoadingTodayStatusCounts =
          false;

      todayStatusError = null;
    });
  } catch (error, stackTrace) {
    debugPrint(
      'STATUS HISTORY SUMMARY ERROR: $error',
    );

    debugPrintStack(
      stackTrace: stackTrace,
    );

    if (!mounted) return;

    setState(() {
      todayStatusCounts = [];

      isLoadingTodayStatusCounts =
          false;

      todayStatusError =
          'Unable to load order status summary';
    });
  }
}

  // ============================================================
  // FETCH TODAY DGM PARCEL SERVICE SUMMARY
  // ============================================================

  Future<void> fetchTodayDgmSummary() async {
    if (!mounted) return;

    setState(() {
      isLoadingDgmSummary = true;
      dgmSummaryError = null;
    });

    try {
      final String? token = await getTokenFromPrefs();

      if (token == null || token.trim().isEmpty) {
        if (!mounted) return;

        setState(() {
          dgmParcelServiceBoxCounts = {};
          isLoadingDgmSummary = false;
          dgmSummaryError = 'Authentication token not found';
        });

        return;
      }

      final String today = DateFormat(
        'yyyy-MM-dd',
      ).format(
        DateTime.now(),
      );

      final http.Response response = await http.get(
        Uri.parse(
          '$api/api/warehousesdataget/$today/',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint(
        'DGM SUMMARY RESPONSE: ${response.statusCode}',
      );

      debugPrint(
        'DGM SUMMARY BODY: ${response.body}',
      );

      if (response.statusCode == 404) {
        if (!mounted) return;

        setState(() {
          dgmParcelServiceBoxCounts = {};
          isLoadingDgmSummary = false;
          dgmSummaryError = null;
        });

        return;
      }

      if (response.statusCode != 200) {
        if (!mounted) return;

        setState(() {
          dgmParcelServiceBoxCounts = {};
          isLoadingDgmSummary = false;
          dgmSummaryError =
              'Failed to load DGM summary (${response.statusCode})';
        });

        return;
      }

      final dynamic decoded = jsonDecode(
        response.body,
      );

      final Map<String, int> serviceCounts = {};

      if (decoded is Map<String, dynamic>) {
        final dynamic results = decoded['results'];

        if (results is List) {
          for (final dynamic family in results) {
            if (family is! Map) continue;

            final dynamic familyOrders = family['orders'];

            if (familyOrders is! List) continue;

            for (final dynamic order in familyOrders) {
              if (order is! Map) continue;

              final dynamic warehouses = order['warehouses'];

              if (warehouses is! List) continue;

              for (final dynamic warehouse in warehouses) {
                if (warehouse is! Map) continue;

                final String parcelServiceName =
                    warehouse['parcel_service_name']?.toString().trim() ?? '';

                if (parcelServiceName.isEmpty) continue;

                serviceCounts[parcelServiceName] =
                    (serviceCounts[parcelServiceName] ?? 0) + 1;
              }
            }
          }
        }
      }

      final List<MapEntry<String, int>> sortedEntries =
          serviceCounts.entries.toList()
            ..sort(
              (MapEntry<String, int> a, MapEntry<String, int> b) {
                return a.key.toLowerCase().compareTo(
                      b.key.toLowerCase(),
                    );
              },
            );

      if (!mounted) return;

      setState(() {
        dgmParcelServiceBoxCounts = Map<String, int>.fromEntries(
          sortedEntries,
        );
        isLoadingDgmSummary = false;
        dgmSummaryError = null;
      });
    } catch (error, stackTrace) {
      debugPrint(
        'DGM SUMMARY ERROR: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      setState(() {
        dgmParcelServiceBoxCounts = {};
        isLoadingDgmSummary = false;
        dgmSummaryError = 'Unable to load DGM summary';
      });
    }
  }

  // ============================================================
  // DISPLAY NAME
  // ============================================================

  String _getStatusDisplayName(
    String status,
  ) {
    switch (status) {
      case 'To Print':
        return 'Delivery Order (DO)';

      case 'Packing under progress':
        return 'Delivery Order (Packing under Progress)';

      case 'Packed':
        return 'Packed For Delivery (PFD)';

      case 'Ready to ship':
        return 'Out For Delivery (OFD)';

      case 'Return From Delivery':
        return 'Return From Delivery (RFD)';

      case 'Shipped':
        return 'Shipped';

      default:
        return status;
    }
  }

  // ============================================================
  // STATUS ICON
  // ============================================================

  IconData _getStatusIcon(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'to print':
        return Icons.description_rounded;

      case 'packing under progress':
        return Icons.inventory_outlined;

      case 'packed':
        return Icons.inventory_2_rounded;

      case 'ready to ship':
        return Icons.local_shipping_outlined;

      case 'return from delivery':
        return Icons.assignment_return_rounded;

      case 'shipped':
        return Icons.local_shipping_rounded;

      default:
        return Icons.inventory_2_outlined;
    }
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _getStatusColor(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'to print':
        return const Color(
          0xFF6366F1,
        );

      case 'packed':
        return const Color(
          0xFF14B8A6,
        );

      case 'ready to ship':
        return const Color(
          0xFF2563EB,
        );

      case 'return from delivery':
        return const Color(
          0xFFEA580C,
        );

      case 'shipped':
        return const Color(
          0xFF16A34A,
        );

      default:
        return const Color(
          0xFF3B82F6,
        );
    }
  }

  // ============================================================
  // TODAY STATUS SECTION
  // ============================================================

  Widget _buildTodayStatusSection() {
    if (todayStatusError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 30,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            16,
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 36,
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              todayStatusError!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(
              height: 14,
            ),
            OutlinedButton.icon(
              onPressed: fetchTodayStatusCounts,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'Retry',
              ),
            ),
          ],
        ),
      );
    }

    if (todayStatusCounts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: 40,
        ),
        alignment: Alignment.center,
        child: const Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 40,
              color: Colors.grey,
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              'No order status data available today',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final double availableWidth = constraints.maxWidth;

        final bool isVerySmallPhone = availableWidth < 340;

        final double horizontalSpacing = isVerySmallPhone ? 8 : 12;

        final double verticalSpacing = isVerySmallPhone ? 8 : 12;

        final double cardHeight = isVerySmallPhone ? 185 : 200;

        final List<Widget> dashboardCards = [];

        final Map<String, int> todayCountMap = {};
        final Map<String, int> allCountMap = {};

        for (final Map<String, dynamic> item in todayStatusCounts) {
          final String status = item['status']?.toString() ?? '';

          final int todayCount = item['today_count'] is int
              ? item['today_count']
              : int.tryParse(
                    item['today_count']?.toString() ?? '0',
                  ) ??
                  0;

          final int allCount = item['all_count'] is int
              ? item['all_count']
              : int.tryParse(
                    item['all_count']?.toString() ?? '0',
                  ) ??
                  0;

          if (status.isNotEmpty) {
            todayCountMap[status] = todayCount;
            allCountMap[status] = allCount;
          }
        }

        dashboardCards.add(
          _buildTodayStatusCard(
            status: 'To Print',
            todayCount: todayCountMap['To Print'] ?? 0,
            allCount: allCountMap['To Print'] ?? 0,
            isVerySmallPhone: isVerySmallPhone,
          ),
        );

        dashboardCards.add(
          _buildTodayStatusCard(
            status: 'Packing under progress',
            todayCount: todayCountMap['Packing under progress'] ?? 0,
            allCount: allCountMap['Packing under progress'] ?? 0,
            isVerySmallPhone: isVerySmallPhone,
          ),
        );

        dashboardCards.add(
          _buildTodayStatusCard(
            status: 'Packed',
            todayCount: todayCountMap['Packed'] ?? 0,
            allCount: allCountMap['Packed'] ?? 0,
            isVerySmallPhone: isVerySmallPhone,
          ),
        );

        dashboardCards.add(
          _buildDgmCard(
            isVerySmallPhone: isVerySmallPhone,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (
                    BuildContext context,
                  ) {
                    return daily_goods_movement();
                  },
                ),
              );
            },
          ),
        );

        dashboardCards.add(
          _buildTodayStatusCard(
            status: 'Ready to ship',
            todayCount: todayCountMap['Ready to ship'] ?? 0,
            allCount: allCountMap['Ready to ship'] ?? 0,
            isVerySmallPhone: isVerySmallPhone,
          ),
        );

        dashboardCards.add(
          _buildTodayStatusCard(
            status: 'Return From Delivery',
            todayCount: todayCountMap['Return From Delivery'] ?? 0,
            allCount: allCountMap['Return From Delivery'] ?? 0,
            isVerySmallPhone: isVerySmallPhone,
          ),
        );

        dashboardCards.add(
          _buildTodayStatusCard(
            status: 'Shipped',
            todayCount: todayCountMap['Shipped'] ?? 0,
            allCount: allCountMap['Shipped'] ?? 0,
            isVerySmallPhone: isVerySmallPhone,
          ),
        );

        // ============================================================
        // PURCHASES CARD
        // COMMENTED AS REQUESTED
        // ============================================================

        // dashboardCards.add(
        //   _buildGroupedMenuCard(
        //     title: 'Purchases',
        //     icon: Icons.shopping_cart_outlined,
        //     items: _getGroupItems(
        //       'purchases',
        //     ),
        //     isVerySmallPhone: isVerySmallPhone,
        //   ),
        // );

        // ============================================================
        // FRONT MENU CARDS
        // ADDED INTO THE SAME GRID SO THERE IS NO EMPTY CELL
        // ============================================================

        final List<Map<String, dynamic>> frontMenuItems =
            _getFrontMenuItems();

        for (final Map<String, dynamic> item in frontMenuItems) {
          final String itemTitle =
              item['title']?.toString() ?? '';

          final IconData itemIcon =
              item['icon'] as IconData;

          final String? groupType =
              item['groupType']?.toString();

          if (groupType != null && groupType.isNotEmpty) {
            if (groupType == 'reports') {
              dashboardCards.add(
                _buildReportsCard(
                  isVerySmallPhone: isVerySmallPhone,
                ),
              );
            } else {
              dashboardCards.add(
                _buildGroupedMenuCard(
                  title: itemTitle,
                  icon: itemIcon,
                  items: _getGroupItems(
                    groupType,
                  ),
                  isVerySmallPhone: isVerySmallPhone,
                ),
              );
            }
          } else {
            dashboardCards.add(
              _buildFrontMenuCard(
                title: itemTitle,
                icon: itemIcon,
                onTap: () {
                  _navigateFromFrontCard(
                    itemTitle,
                  );
                },
              ),
            );
          }
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: horizontalSpacing,
          mainAxisSpacing: verticalSpacing,
          mainAxisExtent: cardHeight,
          children: dashboardCards,
        );
      },
    );
  }

  // ============================================================
  // TODAY STATUS CARD
  // ============================================================

 Widget _buildTodayStatusCard({
  required String status,
  required int todayCount,
  required int allCount,
  required bool isVerySmallPhone,
}) {
  final IconData statusIcon = _getStatusIcon(status);

  final String displayName = _getStatusDisplayName(status);

  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (
              BuildContext context,
            ) {
              return WarehouseOrderView(
                status: status,
              );
            },
          ),
        );
      },
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF56AFFF),
              Color(0xFF2C74FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF2C74FF,
              ).withOpacity(
                0.28,
              ),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(
                0,
                6,
              ),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(
            isVerySmallPhone ? 10 : 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isVerySmallPhone ? 11.5 : 13,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Container(
                    height: isVerySmallPhone ? 32 : 34,
                    width: isVerySmallPhone ? 32 : 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(
                        0.14,
                      ),
                      borderRadius: BorderRadius.circular(
                        11,
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(
                          0.22,
                        ),
                      ),
                    ),
                    child: Icon(
                      statusIcon,
                      color: Colors.white,
                      size: isVerySmallPhone ? 18 : 19,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 10,
              ),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: isVerySmallPhone ? 10 : 12,
                        vertical: isVerySmallPhone ? 8 : 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(
                          0.11,
                        ),
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(
                            0.24,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Today',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isVerySmallPhone ? 10.5 : 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                todayCount.toString(),
                                maxLines: 1,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isVerySmallPhone ? 17 : 20,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: isVerySmallPhone ? 10 : 12,
                        vertical: isVerySmallPhone ? 8 : 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(
                          0.11,
                        ),
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(
                            0.24,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Till Today',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isVerySmallPhone ? 10.5 : 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                allCount.toString(),
                                maxLines: 1,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isVerySmallPhone ? 17 : 20,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ),
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
    ),
  );
}

  // ============================================================
  // DGM CARD WITH PARCEL SERVICE + TOTAL BOXES
  // ============================================================

Widget _buildDgmCard({
  required bool isVerySmallPhone,
  required VoidCallback onTap,
}) {
  final int totalBoxes = dgmParcelServiceBoxCounts.values.fold<int>(
    0,
    (int sum, int count) => sum + count,
  );

  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF56AFFF),
              Color(0xFF2C74FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF2C74FF,
              ).withOpacity(
                0.28,
              ),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(
                0,
                6,
              ),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(
            isVerySmallPhone ? 10 : 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // TITLE + ICON
              // ==================================================

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Daily Goods Movement(DGM)',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isVerySmallPhone ? 11.5 : 13,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Container(
                    height: isVerySmallPhone ? 32 : 34,
                    width: isVerySmallPhone ? 32 : 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(
                        0.14,
                      ),
                      borderRadius: BorderRadius.circular(
                        11,
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(
                          0.22,
                        ),
                      ),
                    ),
                    child: Icon(
                      Icons.move_down_rounded,
                      color: Colors.white,
                      size: isVerySmallPhone ? 18 : 19,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 8,
              ),

              // ==================================================
              // CONTENT
              // ==================================================

              Expanded(
                child: isLoadingDgmSummary
                    ? const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : dgmSummaryError != null
                        ? Center(
                            child: Text(
                              'Unable to load summary',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(
                                  0.90,
                                ),
                                fontSize: isVerySmallPhone ? 10 : 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : dgmParcelServiceBoxCounts.isEmpty
                            ? Center(
                                child: Text(
                                  'No parcel data today',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(
                                      0.90,
                                    ),
                                    fontSize: isVerySmallPhone ? 10 : 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  // ==========================================
                                  // SCROLLABLE PARCEL SERVICE LIST
                                  // NO SCROLLBAR
                                  // ==========================================

                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ),
                                      child: ListView.separated(
                                        padding: const EdgeInsets.only(
                                          right: 2,
                                        ),
                                        physics:
                                            const BouncingScrollPhysics(),
                                        itemCount:
                                            dgmParcelServiceBoxCounts.length,
                                        separatorBuilder: (
                                          BuildContext context,
                                          int index,
                                        ) {
                                          return const SizedBox(
                                            height: 7,
                                          );
                                        },
                                        itemBuilder: (
                                          BuildContext context,
                                          int index,
                                        ) {
                                          final MapEntry<String, int> entry =
                                              dgmParcelServiceBoxCounts.entries
                                                  .elementAt(
                                            index,
                                          );

                                          return Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  isVerySmallPhone ? 9 : 11,
                                              vertical:
                                                  isVerySmallPhone ? 7 : 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.10,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                12,
                                              ),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(
                                                  0.28,
                                                ),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    entry.key,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize:
                                                          isVerySmallPhone
                                                              ? 9.5
                                                              : 10.5,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 8,
                                                ),
                                                Text(
                                                  entry.value.toString(),
                                                  textAlign: TextAlign.right,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        isVerySmallPhone
                                                            ? 10.5
                                                            : 11.5,
                                                    fontWeight:
                                                        FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 7,
                                  ),

                                  // ==========================================
                                  // TOTAL TAB
                                  // ==========================================

                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          isVerySmallPhone ? 10 : 12,
                                      vertical:
                                          isVerySmallPhone ? 7 : 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF16A34A,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF16A34A,
                                          ).withOpacity(
                                            0.25,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(
                                            0,
                                            3,
                                          ),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            'TOTAL',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          totalBoxes.toString(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize:
                                                isVerySmallPhone ? 11 : 12.5,
                                            fontWeight: FontWeight.w900,
                                          ),
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
    ),
  );
}
  // ============================================================
  // STATIC ACTION CARD
  // ============================================================

 Widget _buildActionCard({
  required String title,
  required String shortCode,
  required IconData icon,
  required Color color,
  required bool isVerySmallPhone,
  required VoidCallback? onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF56AFFF),
              Color(0xFF2C74FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF2C74FF,
              ).withOpacity(
                0.28,
              ),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(
                0,
                6,
              ),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(
            isVerySmallPhone ? 10 : 12,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize:
                            isVerySmallPhone
                                ? 11.5
                                : 13,
                        height: 1.25,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Container(
                    height:
                        isVerySmallPhone
                            ? 32
                            : 34,
                    width:
                        isVerySmallPhone
                            ? 32
                            : 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(
                        0.14,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        11,
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(
                          0.22,
                        ),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size:
                          isVerySmallPhone
                              ? 18
                              : 19,
                    ),
                  ),
                ],
              ),

              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Text(
                        shortCode,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize:
                              isVerySmallPhone
                                  ? 25
                                  : 30,
                          fontWeight:
                              FontWeight.w900,
                          height: 1,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        onTap != null
                            ? 'Open'
                            : 'Pending',
                        style: TextStyle(
                          color: Colors.white.withOpacity(
                            0.88,
                          ),
                          fontSize:
                              isVerySmallPhone
                                  ? 11
                                  : 12,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}


  // ============================================================
  // FRONT MENU NAVIGATION
  // ============================================================

  Future<void> _navigateFromFrontCard(
    String item,
  ) async {
    switch (item) {
      case 'Dashboard':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (
              BuildContext context,
            ) {
              return WarehouseDashboard();
            },
          ),
        );
        return;

      case 'Send Mail':
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (
              BuildContext context,
            ) {
              return const StaffMailPage();
            },
          ),
        );

        if (!mounted) {
          return;
        }

        await fetchInboxMailCount();
        return;

      case 'Delivery Order (DO)':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (
              BuildContext context,
            ) {
              return WarehouseOrderView(
                status: 'To Print',
              );
            },
          ),
        );
        return;

      case 'Delivery Order(Packing under Progress)':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (
              BuildContext context,
            ) {
              return WarehouseOrderView(
                status: 'Packing under progress',
              );
            },
          ),
        );
        return;

      case 'Packed For Delivery(PFD)':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (
              BuildContext context,
            ) {
              return WarehouseOrderView(
                status: 'Packed',
              );
            },
          ),
        );
        return;

      case 'Out For Delivery(OFD)':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (
              BuildContext context,
            ) {
              return WarehouseOrderView(
                status: 'Ready to ship',
              );
            },
          ),
        );
        return;

      case 'Return From Delivery (RFD)':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (
              BuildContext context,
            ) {
              return WarehouseOrderView(
                status: 'Return From Delivery',
              );
            },
          ),
        );
        return;

      case 'Delivery Order(Shipped)':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (
              BuildContext context,
            ) {
              return WarehouseOrderView(
                status: 'Shipped',
              );
            },
          ),
        );
        return;

      case 'Daily Goods Movement':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (
              BuildContext context,
            ) {
              return daily_goods_movement();
            },
          ),
        );
        return;

      case 'Local Purchase Order':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (
              BuildContext context,
            ) {
              return LocalPurchaseOrderScreen();
            },
          ),
        );
        return;

      case 'Order Requests':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (
              BuildContext context,
            ) {
              return Warehouse_Order_Request(
                status: null,
              );
            },
          ),
        );
        return;

      case 'Approve Products':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (
              BuildContext context,
            ) {
              return Approve_products();
            },
          ),
        );
        return;

      case 'Add Attendance':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (
              BuildContext context,
            ) {
              return StaffSelfAttendanceScreen();
            },
          ),
        );
        return;

      case 'Add Team Staff':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (
              BuildContext context,
            ) {
              return StaffAttendanceTeamMemberScreen();
            },
          ),
        );
        return;

      case 'Add & Approve Attendance':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (
              BuildContext context,
            ) {
              return StaffMarkAttendanceScreen();
            },
          ),
        );
        return;

      case 'Approve Leave Requests':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (
              BuildContext context,
            ) {
              return ManagerLeaveRequestsPage();
            },
          ),
        );
        return;

      case 'Employee Leave Form':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (
              BuildContext context,
            ) {
              return EmployeeLeaveFormPage();
            },
          ),
        );
        return;

      case 'Logout':
        logout(
          context,
        );
        return;

      default:
        d.navigateToSelectedPage(
          context,
          item,
        );
        return;
    }
  }

  // ============================================================
  // FRONT MENU CARD
  // SAME BLUE STYLE AS DASHBOARD CARDS
  // ============================================================

  Widget _buildFrontMenuCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(
          20,
        ),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              20,
            ),
            gradient: const LinearGradient(
              colors: [
                Color(
                  0xFF56AFFF,
                ),
                Color(
                  0xFF2C74FF,
                ),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF2C74FF,
                ).withOpacity(
                  0.28,
                ),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(
                  0,
                  6,
                ),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(
              12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(
                          0.14,
                        ),
                        borderRadius: BorderRadius.circular(
                          11,
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(
                            0.22,
                          ),
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      'Open',
                      style: TextStyle(
                        color: Colors.white.withOpacity(
                          0.90,
                        ),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white.withOpacity(
                        0.92,
                      ),
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
// ============================================================
// COMPACT GROUPED MENU CARD
// SAME SIZE AS OTHER DASHBOARD CARDS
// ============================================================

Widget _buildGroupedMenuCard({
  required String title,
  required IconData icon,
  required List<Map<String, dynamic>> items,
  required bool isVerySmallPhone,
}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(
        20,
      ),
      gradient: const LinearGradient(
        colors: [
          Color(0xFF56AFFF),
          Color(0xFF2C74FF),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(
            0xFF2C74FF,
          ).withOpacity(
            0.28,
          ),
          blurRadius: 12,
          spreadRadius: 1,
          offset: const Offset(
            0,
            6,
          ),
        ),
      ],
    ),
    child: Padding(
      padding: EdgeInsets.all(
        isVerySmallPhone ? 10 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isVerySmallPhone ? 11.5 : 13,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Container(
                width: isVerySmallPhone ? 32 : 34,
                height: isVerySmallPhone ? 32 : 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(
                    0.14,
                  ),
                  borderRadius: BorderRadius.circular(
                    11,
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(
                      0.22,
                    ),
                  ),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: isVerySmallPhone ? 18 : 19,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 7,
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (
                BuildContext context,
                int index,
              ) {
                return const SizedBox(
                  height: 4,
                );
              },
              itemBuilder: (
                BuildContext context,
                int index,
              ) {
                final Map<String, dynamic> menuItem =
                    items[index];

                final String itemTitle =
                    menuItem['title']?.toString() ?? '';

                final IconData itemIcon =
                    menuItem['icon'] as IconData;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(
                      9,
                    ),
                    onTap: () {
                      _navigateFromFrontCard(
                        itemTitle,
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            isVerySmallPhone ? 6 : 7,
                        vertical:
                            isVerySmallPhone ? 5 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(
                          0.11,
                        ),
                        borderRadius: BorderRadius.circular(
                          9,
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(
                            0.20,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            itemIcon,
                            color: Colors.white,
                            size:
                                isVerySmallPhone ? 13 : 14,
                          ),
                          const SizedBox(
                            width: 6,
                          ),
                          Expanded(
                            child: Text(
                              itemTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize:
                                    isVerySmallPhone
                                        ? 8.5
                                        : 9.5,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 3,
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color:
                                Colors.white.withOpacity(
                              0.90,
                            ),
                            size: 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

// ============================================================
// REPORTS CARD
// ============================================================

Widget _buildReportsCard({
  required bool isVerySmallPhone,
}) {
  return _buildGroupedMenuCard(
    title: 'Reports',
    icon: Icons.analytics_outlined,
    isVerySmallPhone: isVerySmallPhone,
    items: [
      {
        'title': 'Product Stock Report',
        'icon': Icons.inventory_outlined,
      },
      {
        'title': 'Product Sale Report',
        'icon': Icons.point_of_sale_outlined,
      },
      {
        'title': 'Stock Report',
        'icon': Icons.assessment_outlined,
      },
      {
        'title': 'Damaged Stock',
        'icon': Icons.warning_amber_rounded,
      },
      {
        'title': 'Product Usability Report',
        'icon': Icons.analytics_outlined,
      },
    ],
  );
}

// FRONT MENU GROUP
  // ============================================================

  Widget _buildFrontMenuGroup({
    required String title,
    required List<Map<String, dynamic>> items,
  }) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(
              0xFF111827,
            ),
          ),
        ),
        const SizedBox(
          height: 12,
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 125,
          ),
          itemBuilder: (
            BuildContext context,
            int index,
          ) {
            final Map<String, dynamic> item = items[index];

            final String itemTitle =
                item['title']?.toString() ?? '';

            final IconData itemIcon =
                item['icon'] as IconData;

            return _buildFrontMenuCard(
              title: itemTitle,
              icon: itemIcon,
              onTap: () {
                _navigateFromFrontCard(
                  itemTitle,
                );
              },
            );
          },
        ),
        const SizedBox(
          height: 24,
        ),
      ],
    );
  }

  // ============================================================
  // ALL DRAWER ITEMS ON DASHBOARD
  // ============================================================

  List<Map<String, dynamic>> _getFrontMenuItems() {
    return [
      {
        'title': 'GRV',
        'icon': Icons.assignment_return_outlined,
        'keywords': 'grv create new grv grvs list return',
        'groupType': 'grv',
      },
      {
        'title': 'Attendance',
        'icon': Icons.fingerprint_rounded,
        'keywords':
            'attendance add attendance add team staff add approve attendance',
        'groupType': 'attendance',
      },
      // {
      //   'title': 'Employee Leave',
      //   'icon': Icons.event_note_outlined,
      //   'keywords':
      //       'employee leave employee leave form approve leave requests',
      //   'groupType': 'employeeLeave',
      // },
      {
        'title': 'Reports',
        'icon': Icons.analytics_outlined,
        'keywords':
            'reports product stock report product sale report stock report damaged stock product usability report',
        'groupType': 'reports',
      },
    ];
  }

  List<Map<String, dynamic>> _getGroupItems(
    String groupType,
  ) {
    switch (groupType) {
      case 'purchases':
        return [
          {
            'title': 'Product List',
            'icon': Icons.inventory_2_outlined,
          },
          {
            'title': 'Product Add',
            'icon': Icons.add_box_outlined,
          },
          {
            'title': 'Approve Products',
            'icon': Icons.verified_outlined,
          },
          {
            'title': 'Order Requests',
            'icon': Icons.inventory_2_outlined,
          },
          {
            'title': 'Local Purchase Order',
            'icon': Icons.receipt_long_outlined,
          },
        ];

      case 'grv':
        return [
          {
            'title': 'Create New GRV',
            'icon': Icons.add_task_outlined,
          },
          {
            'title': 'GRVs List',
            'icon': Icons.assignment_return_outlined,
          },
        ];

      case 'attendance':
        return [
          {
            'title': 'Add Attendance',
            'icon': Icons.fingerprint_rounded,
          },
          if (isManager)
            {
              'title': 'Add Team Staff',
              'icon': Icons.group_add_outlined,
            },
          if (isManager)
            {
              'title': 'Add & Approve Attendance',
              'icon': Icons.how_to_reg_outlined,
            },
        ];

      case 'employeeLeave':
        return [
          {
            'title': 'Employee Leave Form',
            'icon': Icons.event_note_outlined,
          },
          if (isManager)
            {
              'title': 'Approve Leave Requests',
              'icon': Icons.fact_check_outlined,
            },
        ];

      case 'reports':
        return [
          {
            'title': 'Product Stock Report',
            'icon': Icons.inventory_outlined,
          },
          {
            'title': 'Product Sale Report',
            'icon': Icons.point_of_sale_outlined,
          },
          {
            'title': 'Stock Report',
            'icon': Icons.assessment_outlined,
          },
          {
            'title': 'Damaged Stock',
            'icon': Icons.warning_amber_rounded,
          },
          {
            'title': 'Product Usability Report',
            'icon': Icons.analytics_outlined,
          },
        ];

      default:
        return [];
    }
  }

  Widget _buildFrontMenuSection() {
    final List<Map<String, dynamic>> items =
        _getFrontMenuItems();

    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final bool isVerySmallPhone =
            constraints.maxWidth < 340;

        final double horizontalSpacing =
            isVerySmallPhone ? 8 : 12;

        final double verticalSpacing =
            isVerySmallPhone ? 8 : 12;

        final double cardHeight =
            isVerySmallPhone ? 185 : 200;

        return GridView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: horizontalSpacing,
            mainAxisSpacing: verticalSpacing,
            mainAxisExtent: cardHeight,
          ),
          itemBuilder: (
            BuildContext context,
            int index,
          ) {
            final Map<String, dynamic> item =
                items[index];

            final String itemTitle =
                item['title']?.toString() ?? '';

            final IconData itemIcon =
                item['icon'] as IconData;

            final String? groupType =
                item['groupType']?.toString();

            if (groupType != null &&
                groupType.isNotEmpty) {
              if (groupType == 'reports') {
                return _buildReportsCard(
                  isVerySmallPhone:
                      isVerySmallPhone,
                );
              }

              return _buildGroupedMenuCard(
                title: itemTitle,
                icon: itemIcon,
                items: _getGroupItems(
                  groupType,
                ),
                isVerySmallPhone:
                    isVerySmallPhone,
              );
            }

            return _buildFrontMenuCard(
              title: itemTitle,
              icon: itemIcon,
              onTap: () {
                _navigateFromFrontCard(
                  itemTitle,
                );
              },
            );
          },
        );
      },
    );
  }

  // ============================================================
  // DASHBOARD SEARCH RESULTS
  // ============================================================

  Widget _buildDashboardSearchResults() {
    final String query =
        dashboardSearchQuery.trim().toLowerCase();

    final List<Map<String, dynamic>> searchableItems = [
      ..._getFrontMenuItems(),
    ];

    final List<Map<String, dynamic>> matchedItems =
        searchableItems.where(
      (Map<String, dynamic> item) {
        final String title =
            item['title']?.toString().toLowerCase() ??
                '';

        final String keywords =
            item['keywords']?.toString().toLowerCase() ??
                '';

        return title.contains(
              query,
            ) ||
            keywords.contains(
              query,
            );
      },
    ).toList();

    if (matchedItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: 52,
          horizontal: 24,
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(
                  0xFFF2F2F7,
                ),
                borderRadius: BorderRadius.circular(
                  20,
                ),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: Color(
                  0xFF8E8E93,
                ),
                size: 28,
              ),
            ),
            const SizedBox(
              height: 14,
            ),
            const Text(
              'No cards found',
              style: TextStyle(
                color: Color(
                  0xFF1C1C1E,
                ),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 6,
            ),
            Text(
              'Try a different search',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final bool isVerySmallPhone =
            constraints.maxWidth < 340;

        final double horizontalSpacing =
            isVerySmallPhone ? 8 : 12;

        final double verticalSpacing =
            isVerySmallPhone ? 8 : 12;

        final double cardHeight =
            isVerySmallPhone ? 185 : 200;

        return GridView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          itemCount: matchedItems.length,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: horizontalSpacing,
            mainAxisSpacing: verticalSpacing,
            mainAxisExtent: cardHeight,
          ),
          itemBuilder: (
            BuildContext context,
            int index,
          ) {
            final Map<String, dynamic> item =
                matchedItems[index];

            final String itemTitle =
                item['title']?.toString() ?? '';

            final IconData itemIcon =
                item['icon'] as IconData;

            final String? groupType =
                item['groupType']?.toString();

            if (groupType != null &&
                groupType.isNotEmpty) {
              if (groupType == 'reports') {
                return _buildReportsCard(
                  isVerySmallPhone:
                      isVerySmallPhone,
                );
              }

              return _buildGroupedMenuCard(
                title: itemTitle,
                icon: itemIcon,
                items: _getGroupItems(
                  groupType,
                ),
                isVerySmallPhone:
                    isVerySmallPhone,
              );
            }

            return _buildFrontMenuCard(
              title: itemTitle,
              icon: itemIcon,
              onTap: () {
                _navigateFromFrontCard(
                  itemTitle,
                );
              },
            );
          },
        );
      },
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION ACTIONS
  // ============================================================

  void _toggleBottomSearch() {
    final bool shouldOpen = !isBottomSearchOpen;

    setState(() {
      isBottomSearchOpen = shouldOpen;

      if (!shouldOpen) {
        dashboardSearchQuery = '';

        dashboardSearchController.clear();
      }
    });

    if (shouldOpen) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          if (!mounted) return;

          dashboardSearchFocusNode.requestFocus();
        },
      );
    } else {
      dashboardSearchFocusNode.unfocus();
    }
  }

  void _closeBottomSearch() {
    if (!isBottomSearchOpen &&
        dashboardSearchController.text.isEmpty &&
        dashboardSearchQuery.isEmpty) {
      return;
    }

    dashboardSearchFocusNode.unfocus();

    setState(() {
      isBottomSearchOpen = false;

      dashboardSearchQuery = '';

      dashboardSearchController.clear();
    });
  }

  Future<void> _openBottomMail() async {
    _closeBottomSearch();

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (
          BuildContext context,
        ) {
          return const StaffMailPage();
        },
      ),
    );

    if (!mounted) {
      return;
    }

    await fetchInboxMailCount();
  }

  void _openBottomProfile() {
    _closeBottomSearch();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (
          BuildContext context,
        ) {
          return EditProfileScreen();
        },
      ),
    );
  }

  void _openBottomApproval() {
    _closeBottomSearch();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (
          BuildContext context,
        ) {
          return Approve_products();
        },
      ),
    );
  }

  // ============================================================
  // MODERN BOTTOM NAVIGATION
  // ============================================================

  Widget _buildModernBottomNavigationBar() {
    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: Material(
        color: Colors.white,
        elevation: 14,
        shadowColor: Colors.black.withOpacity(
          0.10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              height: 68,
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 7,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(
                    26,
                  ),
                  topRight: Radius.circular(
                    26,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildBottomNavigationItem(
                      icon: Icons.person_outline_rounded,
                      label: 'Profile',
                      isSelected: false,
                      onTap: _openBottomProfile,
                    ),
                  ),
                  Expanded(
                    child: _buildBottomNavigationItem(
                      icon: Icons.mail_outline_rounded,
                      label: 'Mail',
                      isSelected: false,
                      badgeCount: inboxMailCount,
                      onTap: () {
                        _openBottomMail();
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildBottomNavigationItem(
                      icon: Icons.search_rounded,
                      label: 'Search',
                      isSelected: isBottomSearchOpen,
                      onTap: _toggleBottomSearch,
                    ),
                  ),
                  Expanded(
                    child: _buildBottomNavigationItem(
                      icon: Icons.verified_outlined,
                      label: 'Approval',
                      isSelected: false,
                      onTap: _openBottomApproval,
                    ),
                  ),
                ],
              ),
            ),

            AnimatedSwitcher(
              duration: const Duration(
                milliseconds: 220,
              ),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: isBottomSearchOpen
                  ? Padding(
                      key: const ValueKey<String>(
                        'dashboard-search-open',
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        12,
                        9,
                        12,
                        4,
                      ),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF2F2F7,
                          ),
                          borderRadius: BorderRadius.circular(
                            16,
                          ),
                          border: Border.all(
                            color: const Color(
                              0xFFE5E5EA,
                            ),
                          ),
                        ),
                        child: TextField(
                          controller: dashboardSearchController,
                          focusNode: dashboardSearchFocusNode,
                          textInputAction: TextInputAction.search,
                          autocorrect: false,
                          enableSuggestions: false,
                          onChanged: (
                            String value,
                          ) {
                            setState(() {
                              dashboardSearchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search cards',
                            hintStyle: const TextStyle(
                              color: Color(
                                0xFF8E8E93,
                              ),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(
                                0xFF8E8E93,
                              ),
                              size: 22,
                            ),
                            suffixIcon: dashboardSearchQuery.isNotEmpty
                                ? IconButton(
                                    tooltip: 'Clear search',
                                    onPressed: () {
                                      dashboardSearchController.clear();

                                      setState(() {
                                        dashboardSearchQuery = '';
                                      });

                                      dashboardSearchFocusNode.requestFocus();
                                    },
                                    icon: const Icon(
                                      Icons.cancel_rounded,
                                      color: Color(
                                        0xFF8E8E93,
                                      ),
                                      size: 20,
                                    ),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(
                      key: ValueKey<String>(
                        'dashboard-search-closed',
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildBottomNavigationItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    final Color foregroundColor = isSelected
        ? const Color(
            0xFF2C74FF,
          )
        : const Color(
            0xFF6B7280,
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(
          20,
        ),
        onTap: onTap,
        child: SizedBox(
          height: 54,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 180,
                    ),
                    width: 36,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(
                              0xFFEAF2FF,
                            )
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: foregroundColor,
                      size: 23,
                    ),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -7,
                      top: -5,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFFF3B30,
                          ),
                          borderRadius: BorderRadius.circular(
                            20,
                          ),
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          badgeCount > 99
                              ? '99+'
                              : badgeCount.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 10.5,
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE
  // ============================================================

  Future<void> getProfile() async {
    try {
      final token = await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse(
          '$api/api/profile/',
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

        final data = parsed['data'];

        if (!mounted) return;

        setState(() {
          isManager = data['is_manager'] ?? false;

          profileImage = data['image']?.toString() ?? '';
        });

        debugPrint(
          "IS MANAGER : $isManager",
        );

        debugPrint(
          "PROFILE IMAGE : $profileImage",
        );
      }
    } catch (e) {
      debugPrint(
        "PROFILE ERROR : $e",
      );
    }
  }

  String getProfileImageUrl() {
    if (profileImage.trim().isEmpty) {
      return '';
    }

    if (profileImage.startsWith(
      'http',
    )) {
      return profileImage;
    }

    return '$api$profileImage';
  }

  // ============================================================
  // APP UPDATE
  // ============================================================

  bool _isUpdateAvailable(
    String currentVersion,
    String storeVersion,
  ) {
    List<int> currentParts = currentVersion
        .split('.')
        .map(
          (e) => int.tryParse(e) ?? 0,
        )
        .toList();

    List<int> storeParts = storeVersion
        .split('.')
        .map(
          (e) => int.tryParse(e) ?? 0,
        )
        .toList();

    int maxLength = currentParts.length > storeParts.length
        ? currentParts.length
        : storeParts.length;

    while (currentParts.length < maxLength) {
      currentParts.add(
        0,
      );
    }

    while (storeParts.length < maxLength) {
      storeParts.add(
        0,
      );
    }

    for (int i = 0; i < maxLength; i++) {
      if (storeParts[i] > currentParts[i]) {
        return true;
      } else if (storeParts[i] < currentParts[i]) {
        return false;
      }

    return false;
  }

  Future<bool> checkAppUpdate(
    BuildContext context,
  ) async {
    final packageInfo = await PackageInfo.fromPlatform();

    final currentVersion = packageInfo.version;

    try {
      String? storeVersion;

      Uri? storeUrl;

      if (Platform.isAndroid) {
        final response = await http.get(
          Uri.parse(
            'https://play.google.com/store/apps/details?id=com.bepositive.beposoft&hl=en',
          ),
        );

        if (response.statusCode == 200) {
          final content = response.body;

          final versionRegex = RegExp(
            r'\[\[\["([0-9.]+)"\]\]',
          );

          final match = versionRegex.firstMatch(
            content,
          );

          if (match != null) {
            storeVersion = match.group(
              1,
            );

            storeUrl = Uri.parse(
              'https://play.google.com/store/apps/details?id=com.bepositive.beposoft',
            );
          }
        }
      } else if (Platform.isIOS) {
        final response = await http.get(
          Uri.parse(
            'https://itunes.apple.com/lookup?id=6748010646&country=in',
          ),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(
            response.body,
          );

          if (data['resultCount'] !=
                  null &&
              data['resultCount'] > 0 &&
              data['results'] != null &&
              data['results'] is List &&
              data['results'].isNotEmpty) {
            final appData = data['results'][0];

            storeVersion = appData['version']?.toString();

            storeUrl = Uri.parse(
              'https://apps.apple.com/in/app/beposoft/id6748010646',
            );
          }
        }
      }

      if (storeVersion != null &&
          _isUpdateAvailable(
            currentVersion,
            storeVersion,
          )) {
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (
            BuildContext context,
          ) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  16,
                ),
              ),
              titlePadding: const EdgeInsets.only(
                top: 20,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              title: const Column(
                children: [
                  Icon(
                    Icons.system_update,
                    size: 48,
                    color: Colors.green,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    'Update Available',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Text(
                'A new version ($storeVersion) is available.\n\n'
                'You are using $currentVersion.\n\n'
                'Please update the app to continue enjoying the latest '
                'features and improvements.',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.open_in_new,
                    size: 18,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        8,
                      ),
                    ),
                  ),
                  label: const Text(
                    "Update Now",
                  ),
                  onPressed: () async {
                    if (storeUrl != null &&
                        await canLaunchUrl(
                          storeUrl,
                        )) {
                      await launchUrl(
                        storeUrl,
                        mode: LaunchMode.externalApplication,
                      );
                    }

                    if (!context.mounted) {
                      return;
                    }

                    Navigator.of(
                      context,
                    ).pop(
                      false,
                    );
                  },
                ),
                TextButton(
                  child: const Text(
                    "Maybe Later",
                  ),
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pop(
                      true,
                    );
                  },
                ),
              ],
            );
          },
        );

        return result == true;
      }
    } catch (e) {
      debugPrint(
        'APP UPDATE ERROR: $e',
      );
    }

    return true;
  }

  // ============================================================
  // ORDER DATA
  // ============================================================

  Future<void> fetchOrderData() async {
    try {
      final token = await getTokenFromPrefs();

      final http.Response response = await http.get(
        Uri.parse(
          '$api/api/orders/',
        ),
        headers: {
          'Authorization':
              'Bearer $token',
          'Content-Type':
              'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(
          response.body,
        );

        var productsData = parsed;

        List<Map<String, dynamic>> orderList = [];

        toprint = 0;

        packed = 0;

        for (var productData in productsData) {
          String rawOrderDate = productData['order_date'];

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

          orderList.add({
            'id':
                productData['id'],
            'invoice':
                productData['invoice'],
            'manage_staff':
                productData[
                    'manage_staff'],
            'customer': {
              'name':
                  productData['customer']
                      ['name'],
              'phone':
                  productData['customer']
                      ['phone'],
              'email':
                  productData['customer']
                      ['email'],
              'address':
                  productData['customer']
                      ['address'],
            },
            'billing_address': {
              'name':
                  productData[
                          'billing_address']
                      ['name'],
              'email':
                  productData[
                          'billing_address']
                      ['email'],
              'zipcode':
                  productData[
                          'billing_address']
                      ['zipcode'],
              'address':
                  productData[
                          'billing_address']
                      ['address'],
              'phone':
                  productData[
                          'billing_address']
                      ['phone'],
              'city':
                  productData[
                          'billing_address']
                      ['city'],
              'state':
                  productData[
                          'billing_address']
                      ['state'],
            },
            'bank': {
              'name':
                  productData['bank']
                      ['name'],
              'account_number':
                  productData['bank']
                      ['account_number'],
              'ifsc_code':
                  productData['bank']
                      ['ifsc_code'],
              'branch':
                  productData['bank']
                      ['branch'],
            },
            'items': productData['items'] != null
                ? productData['items'].map(
                    (item) {
                      return {
                        'id': item['id'],
                        'name': item['name'],
                        'quantity': item['quantity'],
                        'price': item['price'],
                        'tax': item['tax'],
                        'discount': item['discount'],
                        'images': item['images'],
                      };
                    },
                  ).toList()
                : [],
            'status': productData['status'],
            'total_amount': productData['total_amount'],
            'order_date': formattedOrderDate,
          });

          if (productData['status'] == 'To Print') {
            toprint++;
          } else if (productData[
                  'status'] ==
              'Packed') {
            packed++;
          }
        }

        if (!mounted) {
          return;
        }

        setState(() {
          orders = orderList;

          filteredOrders =
              orderList;
        });
      }
    } catch (error) {
      debugPrint(
        'FETCH ORDER ERROR: $error',
      );
    }
  }

  // ============================================================
  // SALES REPORT
  // ============================================================

  Future<void> getSalesReport() async {
    if (!mounted) {
      return;
    }

    try {
      final token =
          await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse(
          '$api/api/salesreport',
        ),
        headers: {
          'Authorization':
              'Bearer $token',
          'Content-Type':
              'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(
          response.body,
        );

        var salesData = parsed['Sales report'];

        List<Map<String, dynamic>> salesReportDataList = [];

        for (var reportData in salesData) {
          salesReportDataList.add({
            'date':
                reportData['date'],
            'total_bills_in_date':
                reportData[
                    'total_bills_in_date'],
            'amount':
                reportData['amount'],
            'approved': {
              'bills': reportData['approved']['bills'],
              'amount': reportData['approved']['amount'],
            },
            'rejected': {
              'bills': reportData['rejected']['bills'],
              'amount': reportData['rejected']['amount'],
            },
          });
        }

        if (!mounted) {
          return;
        }

        setState(() {
          salesReportList = salesReportDataList;
        });
      } else {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to fetch sales report data',
            ),
            duration: Duration(
              seconds: 2,
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Error fetching sales report data',
          ),
          duration: Duration(
            seconds: 2,
          ),
        ),
      );
    }
  }

  String getTodaysBills() {
    String currentDate = DateFormat(
      'yyyy-MM-dd',
    ).format(
      DateTime.now(),
    );

    var todaysReport = salesReportList.firstWhere(
      (report) {
        return report['date'] == currentDate;
      },
      orElse: () => {},
    );

    if (todaysReport['total_bills_in_date'] != null) {
      return todaysReport['total_bills_in_date'].toString();
    }

    return '0';
  }

  // ============================================================
  // PROFORMA
  // ============================================================

  Future<void> fetchproformaData() async {
    try {
      final token = await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse(
          '$api/api/perfoma/invoices/',
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

        final data = parsed['data'] as List;

        List<Map<String, dynamic>> performaInvoiceList = [];

        for (var productData in data) {
          performaInvoiceList.add({
            'id': productData['id'],
            'invoice': productData['invoice'],
            'manage_staff': productData['manage_staff'],
            'customer_name': productData['customer']['name'],
            'status': productData['status'],
            'total_amount': productData['total_amount'],
            'order_date': productData['order_date'],
            'created_at': productData['customer']['created_at'],
          });
        }

        if (!mounted) {
          return;
        }

        setState(() {
          proforma = performaInvoiceList;
        });

        int proformalistcount = proforma.length;

        debugPrint(
          'PROFORMA COUNT: $proformalistcount',
        );
      }
    } catch (error) {
      debugPrint(
        'PROFORMA ERROR: $error',
      );
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
  // APP LIFECYCLE
  // ============================================================

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    super.didChangeAppLifecycleState(
      state,
    );

    if (state == AppLifecycleState.resumed) {
      fetchInboxMailCount();

      fetchTodayStatusCounts();

      fetchTodayDgmSummary();
    }
  }

  // ============================================================
  // MAIL COUNT
  // ============================================================

  Future<void> fetchInboxMailCount() async {
    if (isFetchingInboxMailCount) {
      return;
    }

    isFetchingInboxMailCount = true;

    try {
      final String? token = await getTokenFromPrefs();

      if (token == null || token.trim().isEmpty) {
        return;
      }

      final Uri uri = Uri.parse(
        '$api/api/internal/mails/',
      ).replace(
        queryParameters: {
          'type': 'inbox',
          'read_status': 'unread',
          'page': '1',
        },
      );

      final http.Response response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        debugPrint(
          'MAIL COUNT REQUEST FAILED: '
          '${response.statusCode} ${response.body}',
        );

        return;
      }

      final dynamic decoded = jsonDecode(
        response.body,
      );

      int newUnreadCount = 0;

      if (decoded is Map<String, dynamic>) {
        final dynamic results = decoded['results'];

        final dynamic data = decoded['data'];

        final dynamic rawUnreadCount = decoded['unread_count'] ??
            (results is Map ? results['unread_count'] : null) ??
            (data is Map ? data['unread_count'] : null);

        final dynamic rawFilteredCount = decoded['count'] ??
            (results is Map ? results['count'] : null) ??
            (data is Map ? data['count'] : null);

        if (rawUnreadCount != null) {
          newUnreadCount = rawUnreadCount is int
              ? rawUnreadCount
              : int.tryParse(
                    rawUnreadCount.toString(),
                  ) ??
                  0;
        } else if (rawFilteredCount != null) {
          newUnreadCount = rawFilteredCount is int
              ? rawFilteredCount
              : int.tryParse(
                    rawFilteredCount.toString(),
                  ) ??
                  0;
        } else {
          dynamic mailList;

          if (results is Map && results['data'] is List) {
            mailList = results['data'];
          } else if (data is Map && data['data'] is List) {
            mailList = data['data'];
          } else if (results is List) {
            mailList = results;
          } else if (data is List) {
            mailList = data;
          }

          if (mailList is List) {
            newUnreadCount = mailList.where(
              (dynamic mail) {
                if (mail is! Map) {
                  return false;
                }

                if (mail.containsKey(
                  'is_read',
                )) {
                  return mail['is_read'] != true;
                }

                if (mail.containsKey(
                  'read',
                )) {
                  return mail['read'] != true;
                }

                final dynamic readAt = mail['read_at'];

                return readAt == null || readAt.toString().trim().isEmpty;
              },
            ).length;
          }
        }
      }

      if (!mounted) {
        return;
      }

      if (inboxMailCount != newUnreadCount) {
        setState(() {
          inboxMailCount = newUnreadCount;
        });
      }
    } catch (error, stackTrace) {
      debugPrint(
        'MAIL COUNT ERROR: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );
    } finally {
      isFetchingInboxMailCount = false;
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(
      this,
    );

    mailCountTimer?.cancel();

    dashboardSearchController.dispose();

    dashboardSearchFocusNode.dispose();

    super.dispose();
  }

  // ============================================================
  // GRV
  // ============================================================

  Future<void> getGrvList() async {
    try {
      final token =
          await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse(
          '$api/api/grvget/',
        ),
        headers: {
          'Authorization':
              'Bearer $token',
          'Content-Type':
              'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(
          response.body,
        );

        var productsData = parsed['data'];

        List<Map<String, dynamic>> grvDataList = [];

        for (var productData in productsData) {
          grvDataList.add({
            'id':
                productData['id'],
            'product':
                productData[
                    'product'],
            'returnreason':
                productData[
                    'returnreason'],
            'invoice':
                productData['invoice'],
            'customer':
                productData[
                    'customer'],
            'staff':
                productData['staff'],
            'remark':
                productData['remark'],
            'status':
                productData['status'] ??
                    statusOptions[0],
            'order_date':
                productData[
                    'order_date'],
          });
        }

        if (!mounted) {
          return;
        }

        setState(() {
          grvlist =
              grvDataList;
        });

        int grvListCount = grvlist.length;

        debugPrint(
          'GRV COUNT: $grvListCount',
        );
      } else {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to fetch GRV data',
            ),
            duration: Duration(
              seconds: 2,
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Error fetching GRV data',
          ),
          duration: Duration(
            seconds: 2,
          ),
        ),
      );
    }
  }

  // ============================================================
  // USERNAME
  // ============================================================

  Future<String?> getusernameFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getString(
      'username',
    );
  }

  Future<void> _getUsername() async {
    final name = await getusernameFromPrefs();

    if (!mounted) {
      return;
    }

    setState(() {
      username = name ?? 'Guest';
    });
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  void logout(
    BuildContext context,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await Future.delayed(
      const Duration(
        milliseconds: 100,
      ),
    );

    if (!context.mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (
          BuildContext context,
        ) {
          return login();
        },
      ),
    );
  }

  // ============================================================
  // DRAWER
  // ============================================================

  drower d = drower();

  Widget _buildDropdownTile(
    BuildContext context,
    String title,
    List<String> options, {
    required IconData icon,
  }) {
    return ExpansionTile(
      leading: Icon(
        icon,
      ),
      title: Text(
        title,
      ),
      children: options.map(
        (String option) {
          return ListTile(
            contentPadding: const EdgeInsets.only(
              left: 56,
              right: 16,
            ),
            leading: const Icon(
              Icons.chevron_right_rounded,
              size: 20,
            ),
            title: Text(
              option,
            ),
            onTap: () {
              Navigator.pop(
                context,
              );

              if (option == 'Return From Delivery (RFD)') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) {
                      return WarehouseOrderView(
                        status: 'Return From Delivery',
                      );
                    },
                  ),
                );
                return;
              }

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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      debugShowCheckedModeBanner:
          false,
      home: Scaffold(
        backgroundColor: Colors.white,

        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          actions: [
            Padding(
              padding: const EdgeInsets.only(
                right: 12,
              ),
              child: IconButton(
                tooltip: 'Logout',
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Colors.black,
                  size: 27,
                ),
                onPressed: isPageLoading
                    ? null
                    : () {
                        logout(
                          context,
                        );
                      },
              ),
            ),
          ],
        ),

        // drawer: Drawer(
        //   child: ListView(
        //     padding: EdgeInsets.zero,
        //     children: <Widget>[
        //       DrawerHeader(
        //         decoration: BoxDecoration(
        //           color: Colors.grey[200],
        //         ),
        //         child: Row(
        //           mainAxisAlignment: MainAxisAlignment.center,
        //           children: [
        //             Image.asset(
        //               "lib/assets/logo.png",
        //               width: 150,
        //               height: 150,
        //               fit: BoxFit.contain,
        //             ),
        //           ],
        //         ),
        //       ),
        //       ListTile(
        //         leading: const Icon(
        //           Icons.dashboard,
        //         ),
        //         title: const Text(
        //           'Dashboard',
        //         ),
        //         onTap: () {
        //           Navigator.push(
        //             context,
        //             MaterialPageRoute(
        //               builder: (
        //                 BuildContext context,
        //               ) {
        //                 return WarehouseDashboard();
        //               },
        //             ),
        //           );
        //         },
        //       ),
        //       ListTile(
        //         leading: const Icon(
        //           Icons.mail_outline_rounded,
        //         ),
        //         title: const Text(
        //           'Send Mail',
        //         ),
        //         onTap: () async {
        //           Navigator.pop(
        //             context,
        //           );

        //           await Navigator.push<void>(
        //             context,
        //             MaterialPageRoute(
        //               builder: (
        //                 BuildContext context,
        //               ) {
        //                 return const StaffMailPage();
        //               },
        //             ),
        //           );

        //           if (!mounted) {
        //             return;
        //           }

        //           await fetchInboxMailCount();
        //         },
        //       ),
        //       const Divider(),
        //       _buildDropdownTile(
        //         context,
        //         'Purchase',
        //         [
        //           'Product List',
        //           'Product Add',
        //         ],
        //         icon: Icons.shopping_cart_outlined,
        //       ),
        //       _buildDropdownTile(
        //         context,
        //         'Delivery Note',
        //         [
        //           'Delivery Order (DO)',
        //           'Delivery Order(Packing under Progress)',
        //           'Packed For Delivery(PFD)',
        //           'Out For Delivery(OFD)',
        //           'Return From Delivery (RFD)',
        //           'Delivery Order(Shipped)',
        //           'Daily Goods Movement',
        //         ],
        //         icon: Icons.local_shipping_outlined,
        //       ),
        //       _buildDropdownTile(
        //         context,
        //         'GRV',
        //         [
        //           'Create New GRV',
        //           'GRVs List',
        //         ],
        //         icon: Icons.assignment_return_outlined,
        //       ),
        //       ListTile(
        //         leading: const Icon(
        //           Icons.receipt_long_outlined,
        //         ),
        //         title: const Text(
        //           'Local Purchase Order',
        //         ),
        //         onTap: () {
        //           Navigator.push(
        //             context,
        //             MaterialPageRoute(
        //               builder: (
        //                 BuildContext context,
        //               ) {
        //                 return LocalPurchaseOrderScreen();
        //               },
        //             ),
        //           );
        //         },
        //       ),
        //       ListTile(
        //         leading: const Icon(
        //           Icons.inventory_2_outlined,
        //         ),
        //         title: const Text(
        //           'Order Requests',
        //         ),
        //         onTap: () {
        //           Navigator.push(
        //             context,
        //             MaterialPageRoute(
        //               builder: (
        //                 BuildContext context,
        //               ) {
        //                 return Warehouse_Order_Request(
        //                   status: null,
        //                 );
        //               },
        //             ),
        //           );
        //         },
        //       ),
        //       ListTile(
        //         leading: const Icon(
        //           Icons.verified_outlined,
        //         ),
        //         title: const Text(
        //           'Approve Products',
        //         ),
        //         onTap: () {
        //           Navigator.push(
        //             context,
        //             MaterialPageRoute(
        //               builder: (
        //                 BuildContext context,
        //               ) {
        //                 return Approve_products();
        //               },
        //             ),
        //           );
        //         },
        //       ),
        //       const Divider(),
        //       ListTile(
        //         leading: const Icon(
        //           Icons.fingerprint_rounded,
        //         ),
        //         title: const Text(
        //           'Add Attendance',
        //         ),
        //         onTap: () {
        //           Navigator.push(
        //             context,
        //             MaterialPageRoute(
        //               builder: (
        //                 BuildContext context,
        //               ) {
        //                 return StaffSelfAttendanceScreen();
        //               },
        //             ),
        //           );
        //         },
        //       ),
        //       if (isManager)
        //         ListTile(
        //           leading: const Icon(
        //             Icons.group_add_outlined,
        //           ),
        //           title: const Text(
        //             'Add Team Staff',
        //           ),
        //           onTap: () {
        //             Navigator.push(
        //               context,
        //               MaterialPageRoute(
        //                 builder: (
        //                   BuildContext context,
        //                 ) {
        //                   return StaffAttendanceTeamMemberScreen();
        //                 },
        //               ),
        //             );
        //           },
        //         ),
        //       if (isManager)
        //         ListTile(
        //           leading: const Icon(
        //             Icons.how_to_reg_outlined,
        //           ),
        //           title: const Text(
        //             'Add & Approve Attendance',
        //           ),
        //           onTap: () {
        //             Navigator.push(
        //               context,
        //               MaterialPageRoute(
        //                 builder: (
        //                   BuildContext context,
        //                 ) {
        //                   return StaffMarkAttendanceScreen();
        //                 },
        //               ),
        //             );
        //           },
        //         ),
        //       const Divider(),
        //       if (isManager)
        //         ListTile(
        //           leading: const Icon(
        //             Icons.fact_check_outlined,
        //           ),
        //           title: const Text(
        //             'Approve Leave Requests',
        //           ),
        //           onTap: () {
        //             Navigator.push(
        //               context,
        //               MaterialPageRoute(
        //                 builder: (
        //                   BuildContext context,
        //                 ) {
        //                   return ManagerLeaveRequestsPage();
        //                 },
        //               ),
        //             );
        //           },
        //         ),
        //       ListTile(
        //         leading: const Icon(
        //           Icons.event_note_outlined,
        //         ),
        //         title: const Text(
        //           'Employee Leave Form',
        //         ),
        //         onTap: () {
        //           Navigator.push(
        //             context,
        //             MaterialPageRoute(
        //               builder: (
        //                 BuildContext context,
        //               ) {
        //                 return EmployeeLeaveFormPage();
        //               },
        //             ),
        //           );
        //         },
        //       ),
        //       const Divider(),
        //       _buildDropdownTile(
        //         context,
        //         'Reports',
        //         [
        //           'Product Stock Report',
        //           'Product Sale Report',
        //           'Stock Report',
        //           'Damaged Stock',
        //           'Product Usability Report',
        //         ],
        //         icon: Icons.analytics_outlined,
        //       ),
        //       const Divider(),
        //       ListTile(
        //         leading: const Icon(
        //           Icons.exit_to_app,
        //         ),
        //         title: const Text(
        //           'Logout',
        //         ),
        //         onTap: () {
        //           logout(
        //             context,
        //           );
        //         },
        //       ),
        //     ],
        //   ),
        // ),

        // ========================================================
        // MODERN BOTTOM NAVIGATION
        // ========================================================

        bottomNavigationBar: _buildModernBottomNavigationBar(),

        // ========================================================
        // PAGE BODY
        // ========================================================

        body: SafeArea(
          child: isPageLoading
              ? _buildFullPageShimmer()
              : Padding(
                  padding: const EdgeInsets.all(
                    16.0,
                  ),
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await Future.wait(
                        [
                          fetchTodayStatusCounts(),
                          fetchTodayDgmSummary(),
                          fetchInboxMailCount(),
                        ],
                      );
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        // ===========================================
                        // PROFILE
                        // NOW PART OF THE MAIN SCROLLABLE PAGE
                        // ===========================================
Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    // =========================================
    // PROFILE - LEFT SIDE
    // =========================================
    Expanded(
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (
                    BuildContext context,
                  ) {
                    return EditProfileScreen();
                  },
                ),
              );
            },
            child: CircleAvatar(
              radius: 25,
              backgroundColor: const Color(
                0xFFE5E7EB,
              ),
              backgroundImage:
                  getProfileImageUrl().isNotEmpty
                      ? NetworkImage(
                          getProfileImageUrl(),
                        )
                      : const AssetImage(
                          'lib/assets/female.jpeg',
                        ) as ImageProvider,
            ),
          ),

          const SizedBox(
            width: 16,
          ),

          Expanded(
            child: Text(
              '$username',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),

    const SizedBox(
      width: 12,
    ),

    // =========================================
    // SHIPPING & LOGISTICS LOGO
    // =========================================
    Container(
      width: 105,
      height: 92,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFEAF5FF),
            Color(0xFFF4F8FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color: const Color(
            0xFF2C74FF,
          ).withOpacity(
            0.12,
          ),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // PACKAGE
          Positioned(
            top: 17,
            left: 20,
            child: Transform.rotate(
              angle: -0.08,
              child: const Icon(
                Icons.inventory_2_rounded,
                size: 31,
                color: Color(
                  0xFF56AFFF,
                ),
              ),
            ),
          ),

          // TRUCK
          Positioned(
            right: 15,
            bottom: 22,
            child: const Icon(
              Icons.local_shipping_rounded,
              size: 43,
              color: Color(
                0xFF2C74FF,
              ),
            ),
          ),

          // MOVEMENT LINES
          Positioned(
            left: 13,
            bottom: 27,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF56AFFF,
                    ).withOpacity(
                      0.65,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Container(
                  width: 17,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF56AFFF,
                    ).withOpacity(
                      0.40,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ],
),
                        const SizedBox(
                          height: 20,
                        ),

                        if (isBottomSearchOpen &&
                            dashboardSearchQuery.trim().isNotEmpty)
                          ...[
                            _buildDashboardSearchResults(),

                            const SizedBox(
                              height: 12,
                            ),
                          ]
                        else
                          ...[
                            // ===================================
                            // DATE + REFRESH
                            // ===================================

                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Shipping & Logistics (S & L)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(
                                        0xFF111827,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  width: 10,
                                ),

                                const SizedBox(
                                  width: 4,
                                ),

                                IconButton(
                                  tooltip: 'Refresh',
                                  onPressed:
                                      isLoadingTodayStatusCounts ||
                                              isLoadingDgmSummary
                                          ? null
                                          : () async {
                                              await Future.wait(
                                                [
                                                  fetchTodayStatusCounts(),
                                                  fetchTodayDgmSummary(),
                                                ],
                                              );
                                            },
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                  ),
                                ),
                              ],
                            ),

                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 16,
                                  color: Color(
                                    0xFF6B7280,
                                  ),
                                ),
                                const SizedBox(
                                  width: 4,
                                ),
                                Text(
                                  DateFormat(
                                    'dd MMMM yyyy',
                                  ).format(
                                    DateTime.now(),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color.fromARGB(
                                      255,
                                      69,
                                      72,
                                      78,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            _buildTodayStatusSection(),

                            // Front menu cards are now appended directly
                            // inside _buildTodayStatusSection() so all cards
                            // remain continuous with no empty grid cell.
                          ],

                        const SizedBox(
                          height: 12,
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // ============================================================
  // OLD CARD METHOD
  // ============================================================

  Widget _buildCard(
    IconData icon,
    String title, [
    int count = 0,
  ]) {
    return Container(
      height: 120.0,
      margin: const EdgeInsets.symmetric(
        vertical: 8.0,
      ),
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            12.0,
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(
                  height: 20,
                ),
                ListTile(
                  leading: Icon(
                    icon,
                    size: 40,
                    color: Colors.blue,
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {},
                ),
              ],
            ),
            if (count > 0)
              Positioned(
                top: 8.0,
                right: 8.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(
                      12.0,
                    ),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}