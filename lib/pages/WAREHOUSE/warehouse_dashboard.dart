import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:beposoft/pages/ACCOUNTS/add_self_attendance.dart';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
import 'package:beposoft/pages/ACCOUNTS/daily_goods_movement.dart';
import 'package:beposoft/pages/ACCOUNTS/mailboxpage..dart';
import 'package:beposoft/pages/ACCOUNTS/order_list.dart';
import 'package:beposoft/pages/ADMIN/localpurchaseorderscreen.dart';
import 'package:beposoft/pages/BDO/EmployeeLeaveFormPage%20.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:beposoft/pages/logout_hekper.dart';
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

class WarehouseDashboard extends StatefulWidget {
  @override
  State<WarehouseDashboard> createState() => _WarehouseDashboardState();
}

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
  // FULL PAGE LOADING
  // ============================================================

  bool isPageLoading = true;

  // ============================================================
  // TODAY STATUS DATA
  // ============================================================

  List<Map<String, dynamic>> todayStatusCounts = [];

  bool isLoadingTodayStatusCounts = true;

  String? todayStatusError;

  static const List<String> warehouseDashboardStatuses = [
    'To Print',
    'Packed',
    'Ready to ship',
    'Return From Delivery',
    'Shipped',
  ];

  int inboxMailCount = 0;

  Timer? mailCountTimer;

  String profileImage = '';

  bool isManager = false;

  bool isFetchingInboxMailCount = false;

  String? username = '';

  int toprint = 0;

  int packed = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    // Load everything together so entire page shimmers
    _loadInitialData();

    mailCountTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) {
        if (mounted && !isPageLoading) {
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
  // INITIAL PAGE LOAD
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
        fetchproformaData(),
        getSalesReport(),
        fetchOrderData(),
        fetchInboxMailCount(),
        getProfile(),
        fetchTodayStatusCounts(),
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
  // REFRESH DASHBOARD
  // SHOW COMPLETE SHIMMER AGAIN
  // ============================================================

  Future<void> _refreshDashboard() async {
    if (!mounted) return;

    setState(() {
      isPageLoading = true;
    });

    try {
      await Future.wait([
        _getUsername(),
        getProfile(),
        fetchTodayStatusCounts(),
        fetchInboxMailCount(),
      ]);
    } catch (error, stackTrace) {
      debugPrint(
        'DASHBOARD REFRESH ERROR: $error',
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

        final double horizontalSpacing =
            isVerySmallPhone ? 8 : 12;

        final double verticalSpacing =
            isVerySmallPhone ? 8 : 12;

       final double cardHeight =
    isVerySmallPhone ? 185 : 200;

        return Shimmer.fromColors(
          baseColor: const Color(
            0xFFE5E7EB,
          ),
          highlightColor: const Color(
            0xFFF8FAFC,
          ),
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
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: availableWidth * 0.42,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              8,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 28,
                ),

                // =================================================
                // DATE / REFRESH SHIMMER
                // =================================================

                Row(
                  children: [
                    Container(
                      width: availableWidth * 0.38,
                      height: 17,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          7,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 36,
                      width: 36,
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
                        return _buildShimmerDashboardCard(
                          isVerySmallPhone:
                              isVerySmallPhone,
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
  // SHIMMER DASHBOARD CARD
  // ============================================================

  Widget _buildShimmerDashboardCard({
    required bool isVerySmallPhone,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isVerySmallPhone ? 10 : 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          16,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: isVerySmallPhone ? 38 : 42,
                width: isVerySmallPhone ? 38 : 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                ),
              ),

              const Spacer(),

              Container(
                width: isVerySmallPhone ? 38 : 48,
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

          FractionallySizedBox(
            widthFactor: 0.65,
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  6,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Container(
            width: 52,
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

    try {
      final String? token = await getTokenFromPrefs();

      if (token == null || token.trim().isEmpty) {
        if (!mounted) return;

        setState(() {
          isLoadingTodayStatusCounts = false;
          todayStatusError = 'Authentication token not found';
        });

        return;
      }

      final http.Response response = await http.get(
        Uri.parse(
          '$api/api/orders/status/count/',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint(
        'STATUS COUNT RESPONSE: ${response.statusCode}',
      );

      debugPrint(
        'STATUS COUNT BODY: ${response.body}',
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(
          response.body,
        );

        if (decoded is Map<String, dynamic>) {
          final dynamic todayData =
              decoded['today'];

          if (todayData is List) {
            final Map<String, int>
                apiStatusMap = {};

            for (final dynamic item in todayData) {
              if (item is Map) {
                final String status =
                    item['status']
                            ?.toString()
                            .trim() ??
                        '';

                final dynamic rawCount =
                    item['count'];

                final int count =
                    rawCount is int
                        ? rawCount
                        : int.tryParse(
                              rawCount
                                      ?.toString() ??
                                  '0',
                            ) ??
                            0;

                if (status.isNotEmpty) {
                  apiStatusMap[status] = count;
                }
              }
            }

            final List<Map<String, dynamic>>
                filteredStatusList =
                warehouseDashboardStatuses.map(
              (String status) {
                return {
                  'status': status,
                  'count':
                      apiStatusMap[status] ?? 0,
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

            return;
          }
        }

        if (!mounted) return;

        setState(() {
          todayStatusCounts = [];

          isLoadingTodayStatusCounts =
              false;

          todayStatusError =
              'Invalid response from server';
        });
      } else {
        if (!mounted) return;

        setState(() {
          todayStatusCounts = [];

          isLoadingTodayStatusCounts =
              false;

          todayStatusError =
              'Failed to load status counts (${response.statusCode})';
        });
      }
    } catch (error, stackTrace) {
      debugPrint(
        'TODAY STATUS COUNT ERROR: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      setState(() {
        todayStatusCounts = [];

        isLoadingTodayStatusCounts = false;

        todayStatusError =
            'Unable to load today\'s order status';
      });
    }
  }

  // ============================================================
  // DISPLAY NAMES
  // ============================================================

  String _getStatusDisplayName(
    String status,
  ) {
    switch (status) {
      case 'To Print':
        return 'Delivery Order (DO)';

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
  // STATUS ICONS
  // ============================================================

  IconData _getStatusIcon(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'to print':
        return Icons.description_rounded;

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
  // STATUS COLORS
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
              onPressed: _refreshDashboard,
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
        final double availableWidth =
            constraints.maxWidth;

        final bool isVerySmallPhone =
            availableWidth < 340;

        final double horizontalSpacing =
            isVerySmallPhone ? 8 : 12;

        final double verticalSpacing =
            isVerySmallPhone ? 8 : 12;
final double cardHeight =
    isVerySmallPhone ? 185 : 200;

        final List<Widget> dashboardCards = [];

        final Map<String, int> statusCountMap = {};

        for (final Map<String, dynamic> item
            in todayStatusCounts) {
          final String status =
              item['status']?.toString() ?? '';

          final int count =
              item['count'] is int
                  ? item['count']
                  : int.tryParse(
                        item['count']
                                ?.toString() ??
                            '0',
                      ) ??
                      0;

          if (status.isNotEmpty) {
            statusCountMap[status] = count;
          }
        }

        // ========================================================
        // 1. DELIVERY ORDER (DO)
        // ========================================================

        dashboardCards.add(
          _buildTodayStatusCard(
            status: 'To Print',
            count: statusCountMap['To Print'] ?? 0,
            isVerySmallPhone: isVerySmallPhone,
          ),
        );

        // ========================================================
        // 2. PACKED FOR DELIVERY (PFD)
        // ========================================================

        dashboardCards.add(
          _buildTodayStatusCard(
            status: 'Packed',
            count: statusCountMap['Packed'] ?? 0,
            isVerySmallPhone: isVerySmallPhone,
          ),
        );

        // ========================================================
        // 3. DAILY GOODS MOVEMENT (DGM)
        // ========================================================

        dashboardCards.add(
          _buildActionCard(
            title:
                'Daily Goods Movement (DGM)',
            shortCode: 'DGM',
            icon: Icons.move_down_rounded,
            color: const Color(
              0xFF7C3AED,
            ),
            isVerySmallPhone:
                isVerySmallPhone,
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

        // ========================================================
        // 4. OUT FOR DELIVERY (OFD)
        // ========================================================

        dashboardCards.add(
          _buildTodayStatusCard(
            status: 'Ready to ship',
            count: statusCountMap['Ready to ship'] ?? 0,
            isVerySmallPhone: isVerySmallPhone,
          ),
        );

        // ========================================================
        // 5. RETURN FROM DELIVERY (RFD)
        // ========================================================

        dashboardCards.add(
          _buildTodayStatusCard(
            status: 'Return From Delivery',
            count: statusCountMap['Return From Delivery'] ?? 0,
            isVerySmallPhone: isVerySmallPhone,
          ),
        );

        // ========================================================
        // 6. SHIPPED
        // ========================================================

        dashboardCards.add(
          _buildTodayStatusCard(
            status: 'Shipped',
            count: statusCountMap['Shipped'] ?? 0,
            isVerySmallPhone: isVerySmallPhone,
          ),
        );

        // ========================================================
        // 7. PENDING WORK (PW)
        // ========================================================

        dashboardCards.add(
          _buildActionCard(
            title: 'Pending Work (PW)',
            shortCode: 'PW',
            icon:
                Icons.pending_actions_rounded,
            color: const Color(
              0xFFF59E0B,
            ),
            isVerySmallPhone:
                isVerySmallPhone,
            onTap: null,
          ),
        );

        return GridView.count(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing:
              horizontalSpacing,
          mainAxisSpacing:
              verticalSpacing,
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
  required int count,
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
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      displayName,
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
                      statusIcon,
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
                        count.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize:
                              isVerySmallPhone
                                  ? 30
                                  : 36,
                          fontWeight:
                              FontWeight.w900,
                          height: 1,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        'Today',
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
  // ACTION CARD
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
  // APP LIFECYCLE
  // ============================================================

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    super.didChangeAppLifecycleState(
      state,
    );

    if (state ==
        AppLifecycleState.resumed) {
      fetchInboxMailCount();

      fetchTodayStatusCounts();
    }
  }

  // ============================================================
  // PROFILE
  // ============================================================

  Future<void> getProfile() async {
    try {
      final token =
          await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse(
          '$api/api/profile/',
        ),
        headers: {
          'Authorization':
              'Bearer $token',
          'Content-Type':
              'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed =
            jsonDecode(
          response.body,
        );

        final data =
            parsed['data'];

        if (!mounted) return;

        setState(() {
          isManager =
              data['is_manager'] ?? false;

          profileImage =
              data['image']?.toString() ?? '';
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
  // VERSION CHECK
  // ============================================================

  bool _isUpdateAvailable(
    String currentVersion,
    String storeVersion,
  ) {
    List<int> currentParts =
        currentVersion
            .split('.')
            .map(
              (e) =>
                  int.tryParse(e) ?? 0,
            )
            .toList();

    List<int> storeParts =
        storeVersion
            .split('.')
            .map(
              (e) =>
                  int.tryParse(e) ?? 0,
            )
            .toList();

    int maxLength =
        currentParts.length >
                storeParts.length
            ? currentParts.length
            : storeParts.length;

    while (currentParts.length <
        maxLength) {
      currentParts.add(
        0,
      );
    }

    while (storeParts.length <
        maxLength) {
      storeParts.add(
        0,
      );
    }

    for (int i = 0;
        i < maxLength;
        i++) {
      if (storeParts[i] >
          currentParts[i]) {
        return true;
      } else if (storeParts[i] <
          currentParts[i]) {
        return false;
      }
    }

    return false;
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

    super.dispose();
  }

  // ============================================================
  // MAIL COUNT
  // ============================================================

  Future<void>
      fetchInboxMailCount() async {
    if (isFetchingInboxMailCount) {
      return;
    }

    isFetchingInboxMailCount = true;

    try {
      final String? token =
          await getTokenFromPrefs();

      if (token == null ||
          token.trim().isEmpty) {
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

      final http.Response response =
          await http.get(
        uri,
        headers: {
          'Authorization':
              'Bearer $token',
          'Content-Type':
              'application/json',
        },
      );

      if (response.statusCode != 200) {
        debugPrint(
          'MAIL COUNT REQUEST FAILED: '
          '${response.statusCode} ${response.body}',
        );

        return;
      }

      final dynamic decoded =
          jsonDecode(
        response.body,
      );

      int newUnreadCount = 0;

      if (decoded
          is Map<String, dynamic>) {
        final dynamic results =
            decoded['results'];

        final dynamic data =
            decoded['data'];

        final dynamic rawUnreadCount =
            decoded['unread_count'] ??
                (results is Map
                    ? results[
                        'unread_count']
                    : null) ??
                (data is Map
                    ? data[
                        'unread_count']
                    : null);

        final dynamic rawFilteredCount =
            decoded['count'] ??
                (results is Map
                    ? results['count']
                    : null) ??
                (data is Map
                    ? data['count']
                    : null);

        if (rawUnreadCount != null) {
          newUnreadCount =
              rawUnreadCount is int
                  ? rawUnreadCount
                  : int.tryParse(
                        rawUnreadCount
                            .toString(),
                      ) ??
                      0;
        } else if (rawFilteredCount !=
            null) {
          newUnreadCount =
              rawFilteredCount is int
                  ? rawFilteredCount
                  : int.tryParse(
                        rawFilteredCount
                            .toString(),
                      ) ??
                      0;
        } else {
          dynamic mailList;

          if (results is Map &&
              results['data'] is List) {
            mailList =
                results['data'];
          } else if (data is Map &&
              data['data'] is List) {
            mailList =
                data['data'];
          } else if (results is List) {
            mailList = results;
          } else if (data is List) {
            mailList = data;
          }

          if (mailList is List) {
            newUnreadCount =
                mailList.where(
              (dynamic mail) {
                if (mail is! Map) {
                  return false;
                }

                if (mail.containsKey(
                  'is_read',
                )) {
                  return mail[
                          'is_read'] !=
                      true;
                }

                if (mail.containsKey(
                  'read',
                )) {
                  return mail['read'] !=
                      true;
                }

                final dynamic readAt =
                    mail['read_at'];

                return readAt == null ||
                    readAt
                        .toString()
                        .trim()
                        .isEmpty;
              },
            ).length;
          }
        }
      }

      if (!mounted) return;

      if (inboxMailCount !=
          newUnreadCount) {
        setState(() {
          inboxMailCount =
              newUnreadCount;
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
  // APP UPDATE
  // ============================================================

  Future<bool> checkAppUpdate(
    BuildContext context,
  ) async {
    final packageInfo =
        await PackageInfo.fromPlatform();

    final currentVersion =
        packageInfo.version;

    try {
      String? storeVersion;

      Uri? storeUrl;

      if (Platform.isAndroid) {
        final response =
            await http.get(
          Uri.parse(
            'https://play.google.com/store/apps/details?id=com.bepositive.beposoft&hl=en',
          ),
        );

        if (response.statusCode ==
            200) {
          final content =
              response.body;

          final versionRegex =
              RegExp(
            r'\[\[\["([0-9.]+)"\]\]',
          );

          final match =
              versionRegex.firstMatch(
            content,
          );

          if (match != null) {
            storeVersion =
                match.group(
              1,
            );

            storeUrl =
                Uri.parse(
              'https://play.google.com/store/apps/details?id=com.bepositive.beposoft',
            );
          }
        }
      } else if (Platform.isIOS) {
        final response =
            await http.get(
          Uri.parse(
            'https://itunes.apple.com/lookup?id=6748010646&country=in',
          ),
        );

        if (response.statusCode ==
            200) {
          final data =
              jsonDecode(
            response.body,
          );

          if (data['resultCount'] !=
                  null &&
              data['resultCount'] > 0 &&
              data['results'] != null &&
              data['results']
                  is List &&
              data['results']
                  .isNotEmpty) {
            final appData =
                data['results'][0];

            storeVersion =
                appData['version']
                    ?.toString();

            storeUrl =
                Uri.parse(
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
        final result =
            await showDialog<bool>(
          context: context,
          barrierDismissible:
              false,
          builder: (
            BuildContext context,
          ) {
            return AlertDialog(
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius
                        .circular(
                  16,
                ),
              ),
              titlePadding:
                  const EdgeInsets
                      .only(
                top: 20,
              ),
              contentPadding:
                  const EdgeInsets
                      .symmetric(
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
                      fontWeight:
                          FontWeight.bold,
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
              actionsAlignment:
                  MainAxisAlignment
                      .spaceEvenly,
              actions: [
                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.open_in_new,
                    size: 18,
                  ),
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        Colors.green,
                    foregroundColor:
                        Colors.white,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        8,
                      ),
                    ),
                  ),
                  label: const Text(
                    "Update Now",
                  ),
                  onPressed:
                      () async {
                    if (storeUrl !=
                            null &&
                        await canLaunchUrl(
                          storeUrl,
                        )) {
                      await launchUrl(
                        storeUrl,
                        mode: LaunchMode
                            .externalApplication,
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
      final token =
          await getTokenFromPrefs();

      final response =
          await http.get(
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

      if (response.statusCode ==
          200) {
        final parsed =
            jsonDecode(
          response.body,
        );

        var productsData = parsed;

        List<Map<String, dynamic>>
            orderList = [];

        toprint = 0;

        packed = 0;

        for (var productData
            in productsData) {
          String rawOrderDate =
              productData['order_date'];

          String formattedOrderDate =
              rawOrderDate;

          try {
            DateTime parsedOrderDate =
                DateFormat(
              'yyyy-MM-dd',
            ).parse(
              rawOrderDate,
            );

            formattedOrderDate =
                DateFormat(
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
            'items':
                productData['items'] !=
                        null
                    ? productData['items']
                        .map(
                        (item) {
                          return {
                            'id':
                                item['id'],
                            'name':
                                item['name'],
                            'quantity':
                                item[
                                    'quantity'],
                            'price':
                                item['price'],
                            'tax':
                                item['tax'],
                            'discount':
                                item[
                                    'discount'],
                            'images':
                                item['images'],
                          };
                        },
                      ).toList()
                    : [],
            'status':
                productData['status'],
            'total_amount':
                productData[
                    'total_amount'],
            'order_date':
                formattedOrderDate,
          });

          if (productData['status'] ==
              'To Print') {
            toprint++;
          } else if (productData[
                  'status'] ==
              'Packed') {
            packed++;
          }
        }

        if (!mounted) return;

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
    if (!mounted) return;

    try {
      final token =
          await getTokenFromPrefs();

      final response =
          await http.get(
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

      if (response.statusCode ==
          200) {
        final parsed =
            jsonDecode(
          response.body,
        );

        var salesData =
            parsed['Sales report'];

        List<Map<String, dynamic>>
            salesReportDataList = [];

        for (var reportData
            in salesData) {
          salesReportDataList.add({
            'date':
                reportData['date'],
            'total_bills_in_date':
                reportData[
                    'total_bills_in_date'],
            'amount':
                reportData['amount'],
            'approved': {
              'bills':
                  reportData['approved']
                      ['bills'],
              'amount':
                  reportData['approved']
                      ['amount'],
            },
            'rejected': {
              'bills':
                  reportData['rejected']
                      ['bills'],
              'amount':
                  reportData['rejected']
                      ['amount'],
            },
          });
        }

        if (!mounted) return;

        setState(() {
          salesReportList =
              salesReportDataList;
        });
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to fetch sales report data',
            ),
            duration:
                Duration(
              seconds: 2,
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Error fetching sales report data',
          ),
          duration:
              Duration(
            seconds: 2,
          ),
        ),
      );
    }
  }

  String getTodaysBills() {
    String currentDate =
        DateFormat(
      'yyyy-MM-dd',
    ).format(
      DateTime.now(),
    );

    var todaysReport =
        salesReportList.firstWhere(
      (report) {
        return report['date'] ==
            currentDate;
      },
      orElse: () => {},
    );

    if (todaysReport[
            'total_bills_in_date'] !=
        null) {
      return todaysReport[
              'total_bills_in_date']
          .toString();
    }

    return '0';
  }

  // ============================================================
  // PROFORMA
  // ============================================================

  Future<void>
      fetchproformaData() async {
    try {
      final token =
          await getTokenFromPrefs();

      final response =
          await http.get(
        Uri.parse(
          '$api/api/perfoma/invoices/',
        ),
        headers: {
          'Authorization':
              'Bearer $token',
          'Content-Type':
              'application/json',
        },
      );

      if (response.statusCode ==
          200) {
        final parsed =
            jsonDecode(
          response.body,
        );

        final data =
            parsed['data']
                as List;

        List<Map<String, dynamic>>
            performaInvoiceList = [];

        for (var productData
            in data) {
          performaInvoiceList.add({
            'id':
                productData['id'],
            'invoice':
                productData['invoice'],
            'manage_staff':
                productData[
                    'manage_staff'],
            'customer_name':
                productData['customer']
                    ['name'],
            'status':
                productData['status'],
            'total_amount':
                productData[
                    'total_amount'],
            'order_date':
                productData[
                    'order_date'],
            'created_at':
                productData['customer']
                    ['created_at'],
          });
        }

        if (!mounted) return;

        setState(() {
          proforma =
              performaInvoiceList;
        });

        int proformalistcount =
            proforma.length;

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

  Future<String?>
      getTokenFromPrefs() async {
    SharedPreferences prefs =
        await SharedPreferences
            .getInstance();

    return prefs.getString(
      'token',
    );
  }

  // ============================================================
  // GRV
  // ============================================================

  Future<void> getGrvList() async {
    try {
      final token =
          await getTokenFromPrefs();

      final response =
          await http.get(
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

      if (response.statusCode ==
          200) {
        final parsed =
            jsonDecode(
          response.body,
        );

        var productsData =
            parsed['data'];

        List<Map<String, dynamic>>
            grvDataList = [];

        for (var productData
            in productsData) {
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

        if (!mounted) return;

        setState(() {
          grvlist =
              grvDataList;
        });

        int grvListCount =
            grvlist.length;

        debugPrint(
          'GRV COUNT: $grvListCount',
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to fetch GRV data',
            ),
            duration:
                Duration(
              seconds: 2,
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Error fetching GRV data',
          ),
          duration:
              Duration(
            seconds: 2,
          ),
        ),
      );
    }
  }

  // ============================================================
  // USERNAME
  // ============================================================

  Future<String?>
      getusernameFromPrefs() async {
    SharedPreferences prefs =
        await SharedPreferences
            .getInstance();

    return prefs.getString(
      'username',
    );
  }

  Future<void> _getUsername() async {
    final name =
        await getusernameFromPrefs();

    if (!mounted) return;

    setState(() {
      username = name ?? 'Guest';
    });
  }

  // ============================================================
  // OLD LOGOUT METHOD
  // ============================================================

  void logout(
    BuildContext context,
  ) async {
    SharedPreferences prefs =
        await SharedPreferences
            .getInstance();

    await Future.delayed(
      const Duration(
        milliseconds: 100,
      ),
    );

    if (!context.mounted) return;

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
      backgroundColor: Colors.white,
      collapsedBackgroundColor: Colors.white,
      leading: Icon(
        icon,
        color: Colors.black,
      ),
      iconColor: Colors.black,
      collapsedIconColor: Colors.black,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
        ),
      ),
      children: options.map(
        (String option) {
          return ListTile(
            tileColor: Colors.white,
            contentPadding: const EdgeInsets.only(
              left: 56,
              right: 16,
            ),
            leading: const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Colors.black54,
            ),
            title: Text(
              option,
              style: const TextStyle(
                color: Colors.black,
              ),
            ),
            onTap: () {
              Navigator.pop(
                context,
              );

              if (option == 'Return From Delivery (RFD)') {
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
        backgroundColor:
            Colors.white,

        // ========================================================
        // APP BAR
        // ========================================================

        appBar: AppBar(
          elevation: 0,
          backgroundColor:
              Colors.white,
          actions: [
            Padding(
              padding:
                  const EdgeInsets.only(
                right: 12,
              ),
              child: Stack(
                clipBehavior:
                    Clip.none,
                children: [
                  IconButton(
                    icon:
                        const Icon(
                      Icons
                          .mail_outline_rounded,
                      color:
                          Colors.black,
                      size: 28,
                    ),
                    onPressed:
                        isPageLoading
                            ? null
                            : () async {
                                await Navigator.push<
                                    void>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const StaffMailPage(),
                                  ),
                                );

                                if (!mounted) {
                                  return;
                                }

                                await fetchInboxMailCount();
                              },
                  ),

                  if (!isPageLoading &&
                      inboxMailCount >
                          0)
                    Positioned(
                      right: 4,
                      top: 6,
                      child:
                          Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal:
                              6,
                          vertical:
                              2,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.red,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                        ),
                        constraints:
                            const BoxConstraints(
                          minWidth:
                              18,
                          minHeight:
                              18,
                        ),
                        child: Text(
                          inboxMailCount >
                                  99
                              ? '99+'
                              : inboxMailCount
                                  .toString(),
                          textAlign:
                              TextAlign
                                  .center,
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize:
                                11,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        // ========================================================
        // DRAWER
        // ========================================================

        drawer: Drawer(
          backgroundColor: Colors.white,
          child: Container(
            color: Colors.white,
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          18,
                        ),
                        child: Image.asset(
                          "lib/assets/appstore.png",
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // MAIN
                // ==================================================

                ListTile(
                  leading: const Icon(
                    Icons.dashboard,
                  ),
                  title: const Text(
                    'Dashboard',
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (
                          context,
                        ) =>
                            WarehouseDashboard(),
                      ),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.mail_outline_rounded,
                  ),
                  title: const Text(
                    'Send Mail',
                  ),
                  onTap: () async {
                    Navigator.pop(
                      context,
                    );

                    await Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const StaffMailPage(),
                      ),
                    );

                    if (!mounted) {
                      return;
                    }

                    await fetchInboxMailCount();
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.fingerprint_rounded,
                  ),
                  title: const Text(
                    'Add Attendance',
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (
                          context,
                        ) =>
                            StaffSelfAttendanceScreen(),
                      ),
                    );
                  },
                ),

                const Divider(),

                // ==================================================
                // OPERATIONS
                // ==================================================

                _buildDropdownTile(
                  context,
                  'Purchase',
                  [
                    'Product List',
                    'Product Add',
                  ],
                  icon: Icons.shopping_cart_outlined,
                ),

                _buildDropdownTile(
                  context,
                  'Delivery Note',
                  [
                    'Delivery Order (DO)',
                    'Delivery Order(Packing under Progress)',
                    'Packed For Delivery(PFD)',
                    'Out For Delivery(OFD)',
                    'Return From Delivery (RFD)',
                    'Delivery Order(Shipped)',
                    'Daily Goods Movement',
                  ],
                  icon: Icons.local_shipping_outlined,
                ),

                _buildDropdownTile(
                  context,
                  'GRV',
                  [
                    'Create New GRV',
                    'GRVs List',
                  ],
                  icon: Icons.assignment_return_outlined,
                ),

                ListTile(
                  leading: const Icon(
                    Icons.receipt_long_outlined,
                  ),
                  title: const Text(
                    'Local Purchase Order',
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (
                          context,
                        ) =>
                            LocalPurchaseOrderScreen(),
                      ),
                    );
                  },
                ),

                const Divider(),

                // ==================================================
                // LEAVE
                // ==================================================

                ListTile(
                  leading: const Icon(
                    Icons.event_note_outlined,
                  ),
                  title: const Text(
                    'Employee Leave Form',
                  ),
                  onTap: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (
                          context,
                        ) =>
                            EmployeeLeaveFormPage(),
                      ),
                    );
                  },
                ),

                const Divider(),

                // ==================================================
                // REPORTS
                // ==================================================

                _buildDropdownTile(
                  context,
                  'Reports',
                  [
                    'Product Stock Report',
                    'Product Sale Report',
                    'Stock Report',
                    'Damaged Stock',
                    'Product Usability Report',
                  ],
                  icon: Icons.analytics_outlined,
                ),

                const Divider(),

                // ==================================================
                // LOGOUT
                // ==================================================

                ListTile(
                  leading: const Icon(
                    Icons.logout,
                  ),
                  title: const Text(
                    'Logout',
                  ),
                  onTap: () async {
                    await logoutUser(
                      context,
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // ========================================================
        // BODY
        // ========================================================

        body: SafeArea(
          child: isPageLoading
              ? _buildFullPageShimmer()
              : Padding(
                  padding:
                      const EdgeInsets
                          .all(
                    16.0,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      // ===========================================
                      // PROFILE
                      // ===========================================

                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          EditProfileScreen(),
                                ),
                              );
                            },
                            child:
                                CircleAvatar(
                              radius:
                                  25,
                              backgroundColor:
                                  const Color(
                                0xFFE5E7EB,
                              ),
                              backgroundImage:
                                  getProfileImageUrl()
                                          .isNotEmpty
                                      ? NetworkImage(
                                          getProfileImageUrl(),
                                        )
                                      : const AssetImage(
                                          'lib/assets/female.jpeg',
                                        )
                                          as ImageProvider,
                            ),
                          ),

                          const SizedBox(
                            width:
                                16,
                          ),

                          Expanded(
                            child:
                                Text(
                              '$username',
                              maxLines:
                                  1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                fontSize:
                                    15,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height:
                            20,
                      ),

                      // ===========================================
                      // DASHBOARD
                      // ===========================================

                      Expanded(
                        child:
                            RefreshIndicator(
                          onRefresh:
                              _refreshDashboard,
                          child:
                              ListView(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            children: [
                              // ===================================
                              // DATE + REFRESH
                              // ===================================

                                      Row(
                                children: [
                                  // Shipping & Logistics title
                                  const Expanded(
                                    child: Text(
                                      'Shipping & Logistics (S & L)',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  // Current Date
                               
                                  const SizedBox(width: 4),

                                  // Refresh
                                  IconButton(
                                    tooltip: 'Refresh',
                                    onPressed: isLoadingTodayStatusCounts
                                        ? null
                                        : fetchTodayStatusCounts,
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
                                    color: Color(0xFF6B7280),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('dd MMMM yyyy').format(
                                      DateTime.now(),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color.fromARGB(255, 69, 72, 78),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height:
                                    14,
                              ),

                              // ===================================
                              // DASHBOARD GRID
                              // ===================================

                              _buildTodayStatusSection(),

                              const SizedBox(
                                height:
                                    30,
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
  // OLD CARD METHOD
  // ============================================================

  Widget _buildCard(
    IconData icon,
    String title, [
    int count = 0,
  ]) {
    return Container(
      height: 120.0,
      margin:
          const EdgeInsets.symmetric(
        vertical: 8.0,
      ),
      child: Card(
        elevation: 4.0,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
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
                    color:
                        Colors.blue,
                  ),
                  title: Text(
                    title,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
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
                child:
                    Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal:
                        8.0,
                    vertical:
                        4.0,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.grey,
                    borderRadius:
                        BorderRadius
                            .circular(
                      12.0,
                    ),
                  ),
                  child: Text(
                    '$count',
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontWeight:
                          FontWeight
                              .bold,
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