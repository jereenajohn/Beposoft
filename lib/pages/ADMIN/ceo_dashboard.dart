import 'dart:convert';
import 'dart:io';
import 'package:beposoft/pages/ACCOUNTS/Create_Purchase_Product_List.dart';
import 'package:beposoft/pages/ACCOUNTS/Today_shipped_orders.dart';
import 'package:beposoft/pages/ACCOUNTS/activity_log.dart';
import 'package:beposoft/pages/ACCOUNTS/add_EMI.dart';
import 'package:beposoft/pages/ACCOUNTS/add_bank_type.dart';
import 'package:beposoft/pages/ACCOUNTS/add_category.dart';
import 'package:beposoft/pages/ACCOUNTS/add_country_code.dart';
import 'package:beposoft/pages/ACCOUNTS/add_currency.dart';
import 'package:beposoft/pages/ACCOUNTS/add_daily_sales_report.dart';
import 'package:beposoft/pages/ACCOUNTS/add_purpose_of_payment.dart';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
import 'package:beposoft/pages/ACCOUNTS/add_supplier.dart';
import 'package:beposoft/pages/ACCOUNTS/add_team.dart';
import 'package:beposoft/pages/ACCOUNTS/add_warehouse.dart';
import 'package:beposoft/pages/ACCOUNTS/all_users_categorywise_sales_report.dart';
import 'package:beposoft/pages/ACCOUNTS/all_users_sales_report.dart';
import 'package:beposoft/pages/ACCOUNTS/assetmanagement.dart';
import 'package:beposoft/pages/ACCOUNTS/assetmanegment2.dart';
import 'package:beposoft/pages/ACCOUNTS/bulk_customer_upload.dart';
import 'package:beposoft/pages/ACCOUNTS/call_log.dart';
import 'package:beposoft/pages/ACCOUNTS/categorywise_sales_report.dart';
import 'package:beposoft/pages/ACCOUNTS/daily_bdo_sales_report.dart';
import 'package:beposoft/pages/ACCOUNTS/daily_goods_movement.dart';
import 'package:beposoft/pages/ACCOUNTS/dailyproductcategorywisecyclingskating.dart';
import 'package:beposoft/pages/ACCOUNTS/finance_report.dart';
import 'package:beposoft/pages/ACCOUNTS/graph.dart';
import 'package:beposoft/pages/ACCOUNTS/grv_list.dart';
import 'package:beposoft/pages/ACCOUNTS/order_list.dart';
import 'package:beposoft/pages/ACCOUNTS/performa_invoice_list.dart';
import 'package:beposoft/pages/ACCOUNTS/product_list.dart';
import 'package:beposoft/pages/ACCOUNTS/purchase_list.dart';
import 'package:beposoft/pages/ACCOUNTS/seller_purchase_invoice_list.dart';
import 'package:beposoft/pages/ACCOUNTS/status_wise_orders_list.dart';

import 'package:beposoft/pages/ACCOUNTS/todays_orders_list.dart';
import 'package:beposoft/pages/ACCOUNTS/tracking_excel.dart';
import 'package:beposoft/pages/ACCOUNTS/uploadbulkorders.dart';
import 'package:beposoft/pages/ACCOUNTS/view_staff.dart';
import 'package:beposoft/pages/ADMIN/Categorywise_dispatched_details.dart';
import 'package:beposoft/pages/ADMIN/OD_bank_monthly_details.dart';
import 'package:beposoft/pages/ADMIN/bdm_family_detailpage.dart';
import 'package:beposoft/pages/ADMIN/bdo_statewise+details_page.dart';
import 'package:beposoft/pages/ADMIN/categoryproductDetailspage.dart';
import 'package:beposoft/pages/ADMIN/ceo_expense_type_wise.dart';
import 'package:beposoft/pages/ADMIN/ceo_monthly_family_summary.dart';
import 'package:beposoft/pages/ADMIN/ceo_parcel_avarage_monthly.dart'
    show PostofficeReport_monthly;
import 'package:beposoft/pages/ADMIN/ceo_todays_family_summary.dart';
import 'package:beposoft/pages/ADMIN/dgm_page.dart';
import 'package:beposoft/pages/ADMIN/family_detailed_summary_page.dart';

import 'package:beposoft/pages/ADMIN/family_wise_analysis_details_page.dart';
import 'package:beposoft/pages/ADMIN/sales_report_excel.dart';
import 'package:beposoft/pages/ADMIN/warehouse_summary.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_product_approval.dart';
import 'package:beposoft/pages/logout_hekper.dart';
import 'package:intl/intl.dart';

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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

class ceo_dashboard extends StatefulWidget {
  @override
  State<ceo_dashboard> createState() => _ceo_dashboardState();
}

class _ceo_dashboardState extends State<ceo_dashboard> {
  List<String> statusOptions = ["pending", "approved", "rejected"];
  final _currency =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  List<Map<String, dynamic>> grvlist = [];
  List<Map<String, dynamic>> proforma = [];
  List<Map<String, dynamic>> salesReportList = [];
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  List<Map<String, dynamic>> shippedOrders = [];
  List<Map<String, dynamic>> Finance = [];
  List<dynamic> internalTransfers = [];
  double todayCredit = 0.0;
  double todayDebit = 0.0;
  double openingBalance = 0.0;
  double monthAverage = 0.0;
  double closingBalance = 0.0;
  var department;
  double dbrOpeningBalanceTotal = 0;
  double dbrTodayCreditTotal = 0;
  double dbrTodayDebitTotal = 0;
  double dbrClosingBalanceTotal = 0;
  List<Map<String, dynamic>> filteredProducts = [];
  int staffCount = 0;
  int activeStaffCount = 0;
  int inactiveStaffCount = 0;
  List<Map<String, dynamic>> bdmOverallRawData = [];
  List<Map<String, dynamic>> ceoFamilyCards = [];
  bool bdmOverallLoading = false;
  String selectedBdmReportDate = "";
  bool dbrLoading = true;

  bool isBankReportLoading = true;
  String monthlyExpenseFrom = "";
  String monthlyExpenseTo = "";
  DateTimeRange? familySummaryTeamSelectedRange;
  String familySummaryTeamFromDate = "";
  String familySummaryTeamToDate = "";

  Map<String, double> expenseTypeWiseTotals =
      {}; // will store totals grouped by expense_type
  Map<String, dynamic>? productsData;
  final List<dynamic> statuswiseorders = [];
  bool _loading = true;
  String? _error;
  bool loading = false;
  List<Map<String, dynamic>> dailyBankReport = [];
  List<Map<String, dynamic>> dailyBdoStatewiseData = [];
  List<Map<String, dynamic>> monthlyBdoStatewiseData = [];
  DateTime? bdmStartDate;
  DateTime? bdmEndDate;
  List<Map<String, dynamic>> familySummaryTeamCards = [];
  bool familySummaryTeamLoading = false;

  bool dailyBdoLoading = false;
  bool monthlyBdoLoading = false;

  String selectedDailyDate = "";
  String monthlyStartDate = "";
  String monthlyEndDate = "";

  List<Map<String, dynamic>> filteredCategoryProducts = [];
  bool filteredCategoryLoading = false;
  String categoryStartDate = "";
  String categoryEndDate = "";
  bool showAllCategories = false;
  double dashboardTotalLandingCostAmount = 0.0;

  List<Map<String, dynamic>> familyAnalysisCards = [];
  Map<String, dynamic> familyAnalysisOverall = {};
  bool familyAnalysisLoading = false;
  String familyAnalysisFromDate = "";
  String familyAnalysisToDate = "";

  List<Map<String, dynamic>> familyAttendanceData = [];

  DateTimeRange? familyAnalysisSelectedRange;

  Map<String, dynamic> dgmTodaySummary = {};
  Map<String, dynamic> dgmCurrentMonthSummary = {};
  List<Map<String, dynamic>> dgmTodayRows = [];
  bool dgmLoading = false;

  Map<String, dynamic> beposoftSummary = {};
  bool beposoftSummaryLoading = false;

  int dashboardTotalStock = 0;
  double dashboardTotalRetailAmount = 0.0;
  bool dashboardInventoryLoading = false;
  double dashboardTotalSellingAmount = 0.0;

  // int getFamilyPresentCount(String familyName) {
  //   return familyAttendanceData.where((item) {
  //     final family =
  //         (item['family_name'] ?? '').toString().toLowerCase().trim();
  //     final status = (item['status'] ?? '').toString().toLowerCase().trim();
  //     return family == familyName.toLowerCase() && status == 'present';
  //   }).length;
  // }

  // int getFamilyAbsentCount(String familyName) {
  //   return familyAttendanceData.where((item) {
  //     final family =
  //         (item['family_name'] ?? '').toString().toLowerCase().trim();
  //     final status = (item['status'] ?? '').toString().toLowerCase().trim();
  //     return family == familyName.toLowerCase() && status == 'absent';
  //   }).length;
  // }

  // Helper method (also inside this State class, not in build)
  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is int) return v.toDouble();
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> _asMap(dynamic v) {
    if (v == null) return {};
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return {};
  }

  String? username = '';
  @override
  void initState() {
    super.initState();
    _getUsername(); // Get the username when the page loads

    final now = DateTime.now();

    selectedRange = DateTimeRange(
      start: DateTime(now.year, now.month, now.day, 0, 0, 0),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );

    initdata();

    getGrvList();
    fetchproformaData();
    getSalesReport();
    fetchOrderData();
    fetchshippedorders();
    getexpenselist();
    getFinancialReport();
    getFinance_without_transfer();
    getTodayODReportTotals();
    getCategoryWiseProducts();
    fetchBdmOverallFamilyReport();
    getstaff();
    fetchOrdersSummaryFamilyData();
    fetchBeposoftSummary();
    fetchDashboardInventorySummary();

    //   fetchInternalTransfersData(
    // getdgnvd);
    getdgm();
    fetchFamilySummaryTeamCards();
    fetchFamilyAnalysisCards();
    fetchInternalTransfersData();
    getFilteredCategoryWiseProducts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAppUpdate(context);
    });

    fetchBdoStatewiseReport(
      startDate: DateTime(now.year, now.month, now.day),
      endDate: DateTime(now.year, now.month, now.day),
      isDaily: true,
    );

    fetchBdoStatewiseReport(
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month, now.day),
      isDaily: false,
    );
  }

  void initdata() async {
    department = await getdepFromPrefs();
    await getdata();
    await getsalescount();
    // fetchorders();
    await fetchReport();
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<void> _refreshDashboard() async {
    final now = DateTime.now();

    setState(() {
      selectedRange = DateTimeRange(
        start: DateTime(now.year, now.month, now.day, 0, 0, 0),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
    });

    await Future.wait([
      Future(() => initdata()),
      Future(() => getGrvList()),
      Future(() => fetchproformaData()),
      Future(() => getSalesReport()),
      Future(() => fetchOrderData()),
      Future(() => fetchshippedorders()),
      Future(() => getexpenselist()),
      Future(() => getFinancialReport()),
      Future(() => getFinance_without_transfer()),
      Future(() => getTodayODReportTotals()),
      Future(() => getCategoryWiseProducts()),
      Future(() => fetchBdmOverallFamilyReport()),
      Future(() => getstaff()),
      Future(() => fetchOrdersSummaryFamilyData()),
      Future(() => getdgm()),
      Future(() => fetchFamilySummaryTeamCards()),
      Future(() => fetchFamilyAnalysisCards()),
      Future(() => fetchInternalTransfersData()),
      Future(() => getFilteredCategoryWiseProducts()),
      Future(() => fetchBeposoftSummary()),
      Future(() => fetchDashboardInventorySummary()),
      Future(() => fetchBdoStatewiseReport(
            startDate: DateTime(now.year, now.month, now.day),
            endDate: DateTime(now.year, now.month, now.day),
            isDaily: true,
          )),
      Future(() => fetchBdoStatewiseReport(
            startDate: DateTime(now.year, now.month, 1),
            endDate: DateTime(now.year, now.month, now.day),
            isDaily: false,
          )),
    ]);
  }

  Future<void> fetchOrdersSummaryFamilyData() async {
    try {
      final token = await getTokenFromPrefs();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$api/api/orders/summary/family/data/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        setState(() {
          productsData = parsed['overall'] ?? {};
        });
      }
    } catch (e) {
      // optional print
      // print("fetchOrdersSummaryFamilyData error: $e");
    }
  }

  String _formatDashboardAmount(dynamic value) {
    final double amount = _asDouble(value);
    final double absAmount = amount.abs();
    final String sign = amount < 0 ? "-" : "";

    if (absAmount >= 10000000) {
      return "$sign₹${(absAmount / 10000000).toStringAsFixed(2)} Cr";
    }

    if (absAmount >= 100000) {
      return "$sign₹${(absAmount / 100000).toStringAsFixed(2)} L";
    }

    if (absAmount >= 1000) {
      return "$sign₹${(absAmount / 1000).toStringAsFixed(2)}K";
    }

    return "$sign${_currency.format(absAmount)}";
  }

  Future<String?> getWarehouseFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? warehouseId = prefs.getInt('warehouse');
    return warehouseId?.toString();
  }

  Future<void> fetchDashboardInventorySummary() async {
    final String? token = await getTokenFromPrefs();
    final String? warehouseId = await getWarehouseFromPrefs();

    if (token == null || warehouseId == null || warehouseId.isEmpty) {
      return;
    }

    setState(() {
      dashboardInventoryLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse("$api/api/warehouse/products/gets/$warehouseId/"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final results = parsed['results'];

        if (results is Map && results['summary'] is Map) {
          final summary = Map<String, dynamic>.from(results['summary']);

          if (!mounted) return;
          setState(() {
            dashboardTotalStock = _asInt(summary['total_stock']);
            dashboardTotalRetailAmount =
                _asDouble(summary['total_retail_amount']);
            dashboardTotalLandingCostAmount =
                _asDouble(summary['total_landing_cost_amount']);

            dashboardTotalSellingAmount =
                _asDouble(summary['total_selling_amount']);
            dashboardInventoryLoading = false;
          });
        } else {
          if (!mounted) return;
          setState(() {
            dashboardInventoryLoading = false;
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          dashboardInventoryLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        dashboardInventoryLoading = false;
      });
      print("DASHBOARD INVENTORY SUMMARY ERROR: $e");
    }
  }

  Future<void> fetchBeposoftSummary() async {
    final token = await getTokenFromPrefs();
    if (token == null) return;

    setState(() {
      beposoftSummaryLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$api/api/beposoft/summary/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (!mounted) return;
        setState(() {
          beposoftSummary = Map<String, dynamic>.from(decoded);
          beposoftSummaryLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          beposoftSummaryLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        beposoftSummaryLoading = false;
      });
      print("BEPOSOFT SUMMARY ERROR: $e");
    }
  }

  Future<void> fetchFamilySummaryTeamCards() async {
    final token = await getTokenFromPrefs();
    if (token == null) return;

    setState(() {
      familySummaryTeamLoading = true;
      familySummaryTeamCards = [];
    });

    try {
      final DateTime now = DateTime.now();

      final DateTime effectiveStart = familySummaryTeamSelectedRange != null
          ? DateTime(
              familySummaryTeamSelectedRange!.start.year,
              familySummaryTeamSelectedRange!.start.month,
              familySummaryTeamSelectedRange!.start.day,
            )
          : DateTime(now.year, now.month, now.day);

      final DateTime effectiveEnd = familySummaryTeamSelectedRange != null
          ? DateTime(
              familySummaryTeamSelectedRange!.end.year,
              familySummaryTeamSelectedRange!.end.month,
              familySummaryTeamSelectedRange!.end.day,
            )
          : DateTime(now.year, now.month, now.day);

      final Map<String, String> queryParams = {
        'start_date': DateFormat('yyyy-MM-dd').format(effectiveStart),
        'end_date': DateFormat('yyyy-MM-dd').format(effectiveEnd),
      };

      final response = await http.get(
        Uri.parse('$api/api/family/summary/team/').replace(
          queryParameters: queryParams,
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("FAMILY SUMMARY TEAM STATUS: ${response.statusCode}");
      print("FAMILY SUMMARY TEAM BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List families = decoded['families'] ?? [];

        List<Map<String, dynamic>> cards = [
          {
            "family_id": 2,
            "family_name": "skating",
            "invoice_count": 0,
            "amount_value": 0.0,
            "total_call_count": 0,
            "total_call_duration": 0.0,
            "call_duration_average": 0.0,
            "call_duration_percentage_8hrs": 0.0,
            "total_bdo_count": 0,
            "active_count": 0,
            "productive_count": 0,
            "unique_customer_count": 0,
            "report_count": 0,
            "present_count": 0,
            "absent_count": 0,
            "half_day_count": 0,
            "total_team_count": 0,
            "from_date": queryParams['start_date'] ?? "",
            "to_date": queryParams['end_date'] ?? "",
          },
          {
            "family_id": 1,
            "family_name": "cycling",
            "invoice_count": 0,
            "amount_value": 0.0,
            "total_call_count": 0,
            "total_call_duration": 0.0,
            "call_duration_average": 0.0,
            "call_duration_percentage_8hrs": 0.0,
            "total_bdo_count": 0,
            "active_count": 0,
            "productive_count": 0,
            "unique_customer_count": 0,
            "report_count": 0,
            "present_count": 0,
            "absent_count": 0,
            "half_day_count": 0,
            "total_team_count": 0,
            "from_date": queryParams['start_date'] ?? "",
            "to_date": queryParams['end_date'] ?? "",
          },
        ];

        for (var item in families) {
          final familyMap = Map<String, dynamic>.from(item);
          final summary = Map<String, dynamic>.from(familyMap['summary'] ?? {});
          final familyName =
              (familyMap["family_name"] ?? "").toString().toLowerCase().trim();

          final updatedCard = {
            "family_id": familyMap["family_id"] ?? 0,
            "family_name": (familyMap["family_name"] ?? "").toString(),
            "invoice_count": _asInt(summary["total_bill"]),
            "amount_value": (summary["total_volume"] ?? 0).toDouble(),
            "total_call_count": _asInt(summary["total_call_count"]),
            "total_call_duration":
                (summary["total_call_duration"] ?? 0).toDouble(),
            "call_duration_average":
                (summary["call_duration_average"] ?? 0).toDouble(),
            "call_duration_percentage_8hrs":
                (summary["call_duration_percentage_8hrs"] ?? 0).toDouble(),
            "total_bdo_count": _asInt(summary["total_bdo_count"]),
            "active_count": _asInt(summary["active_count"]),
            "productive_count": _asInt(summary["productive_count"]),
            "unique_customer_count": _asInt(summary["unique_customer_count"]),
            "report_count": _asInt(summary["report_count"]),
            "present_count": _asInt(summary["present_count"]),
            "absent_count": _asInt(summary["absent_count"]),
            "half_day_count": _asInt(summary["half_day_count"]),
            "total_team_count": _asInt(summary["total_team_count"]),
            "from_date": queryParams['start_date'] ?? "",
            "to_date": queryParams['end_date'] ?? "",
          };

          final index = cards.indexWhere(
            (card) =>
                (card["family_name"] ?? "").toString().toLowerCase().trim() ==
                familyName,
          );

          if (index != -1) {
            cards[index] = updatedCard;
          }
        }

        if (!mounted) return;
        setState(() {
          familySummaryTeamCards = cards;
          familySummaryTeamFromDate = queryParams['start_date'] ?? "";
          familySummaryTeamToDate = queryParams['end_date'] ?? "";
          familySummaryTeamLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          familySummaryTeamLoading = false;
          familySummaryTeamCards = [
            {
              "family_id": 2,
              "family_name": "skating",
              "invoice_count": 0,
              "amount_value": 0.0,
              "total_call_count": 0,
              "total_call_duration": 0.0,
              "call_duration_average": 0.0,
              "call_duration_percentage_8hrs": 0.0,
              "total_bdo_count": 0,
              "active_count": 0,
              "productive_count": 0,
              "unique_customer_count": 0,
              "report_count": 0,
              "present_count": 0,
              "absent_count": 0,
              "half_day_count": 0,
              "total_team_count": 0,
              "from_date": queryParams['start_date'] ?? "",
              "to_date": queryParams['end_date'] ?? "",
            },
            {
              "family_id": 1,
              "family_name": "cycling",
              "invoice_count": 0,
              "amount_value": 0.0,
              "total_call_count": 0,
              "total_call_duration": 0.0,
              "call_duration_average": 0.0,
              "call_duration_percentage_8hrs": 0.0,
              "total_bdo_count": 0,
              "active_count": 0,
              "productive_count": 0,
              "unique_customer_count": 0,
              "report_count": 0,
              "present_count": 0,
              "absent_count": 0,
              "half_day_count": 0,
              "total_team_count": 0,
              "from_date": queryParams['start_date'] ?? "",
              "to_date": queryParams['end_date'] ?? "",
            },
          ];
        });
      }
    } catch (e) {
      print("FAMILY SUMMARY TEAM ERROR: $e");
      if (!mounted) return;
      setState(() {
        familySummaryTeamLoading = false;
        familySummaryTeamCards = [
          {
            "family_id": 2,
            "family_name": "skating",
            "invoice_count": 0,
            "amount_value": 0.0,
            "total_call_count": 0,
            "total_call_duration": 0.0,
            "call_duration_average": 0.0,
            "call_duration_percentage_8hrs": 0.0,
            "total_bdo_count": 0,
            "active_count": 0,
            "productive_count": 0,
            "unique_customer_count": 0,
            "report_count": 0,
            "present_count": 0,
            "absent_count": 0,
            "half_day_count": 0,
            "total_team_count": 0,
            "from_date": "",
            "to_date": "",
          },
          {
            "family_id": 1,
            "family_name": "cycling",
            "invoice_count": 0,
            "amount_value": 0.0,
            "total_call_count": 0,
            "total_call_duration": 0.0,
            "call_duration_average": 0.0,
            "call_duration_percentage_8hrs": 0.0,
            "total_bdo_count": 0,
            "active_count": 0,
            "productive_count": 0,
            "unique_customer_count": 0,
            "report_count": 0,
            "present_count": 0,
            "absent_count": 0,
            "half_day_count": 0,
            "total_team_count": 0,
            "from_date": "",
            "to_date": "",
          },
        ];
      });
    }
  }

  Future<void> pickFamilySummaryTeamDateRange() async {
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(now.year + 1),
      initialDateRange: familySummaryTeamSelectedRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF02347C),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        familySummaryTeamSelectedRange = DateTimeRange(
          start: DateTime(
            picked.start.year,
            picked.start.month,
            picked.start.day,
          ),
          end: DateTime(
            picked.end.year,
            picked.end.month,
            picked.end.day,
          ),
        );
      });

      await fetchFamilySummaryTeamCards();
    }
  }

  bool _isAttendanceWithinSelectedRange(dynamic attendanceDate) {
    if (attendanceDate == null) return false;

    try {
      final DateTime parsedDate =
          DateTime.parse(attendanceDate.toString()).toLocal();

      final DateTime onlyDate =
          DateTime(parsedDate.year, parsedDate.month, parsedDate.day);

      if (familyAnalysisSelectedRange == null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        return onlyDate == today;
      }

      final DateTime start = DateTime(
        familyAnalysisSelectedRange!.start.year,
        familyAnalysisSelectedRange!.start.month,
        familyAnalysisSelectedRange!.start.day,
      );

      final DateTime end = DateTime(
        familyAnalysisSelectedRange!.end.year,
        familyAnalysisSelectedRange!.end.month,
        familyAnalysisSelectedRange!.end.day,
      );

      return !onlyDate.isBefore(start) && !onlyDate.isAfter(end);
    } catch (e) {
      return false;
    }
  }

  Future<void> fetchFamilyAnalysisCards() async {
    final token = await getTokenFromPrefs();
    if (token == null) return;

    setState(() {
      familyAnalysisLoading = true;
    });

    try {
      final Map<String, String> queryParams = {};

      if (familyAnalysisSelectedRange != null) {
        queryParams['from_date'] =
            DateFormat('yyyy-MM-dd').format(familyAnalysisSelectedRange!.start);
        queryParams['to_date'] =
            DateFormat('yyyy-MM-dd').format(familyAnalysisSelectedRange!.end);
      } else {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        queryParams['from_date'] = today;
        queryParams['to_date'] = today;
      }

      Future<Map<String, dynamic>> fetchFamilyCard(int familyId) async {
        final uri =
            Uri.parse('$api/api/family/analysis/staff/summary/$familyId/')
                .replace(
          queryParameters: queryParams,
        );

        final response = await http.get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);

          final family = Map<String, dynamic>.from(decoded['family'] ?? {});
          final summary = Map<String, dynamic>.from(decoded['summary'] ?? {});
          final filters = Map<String, dynamic>.from(decoded['filters'] ?? {});

          return {
            'family_id': family['family_id'] ?? familyId,
            'family_name': (family['family_name'] ?? '').toString(),
            'present': summary['present'] ?? 0,
            'absent': summary['absent'] ?? 0,
            'half_day': summary['half_day'] ?? 0,
            'total_amount': summary['total_amount'] ?? 0,
            'total_invoices': summary['total_invoices'] ?? 0,
            'total_call_count': summary['total_call_count'] ?? 0,
            'total_call_duration': summary['total_call_duration'] ?? 0,
            'call_duration_average_minutes':
                summary['call_duration_average_minutes'] ?? 0,
            'call_duration_average_percentage_8hrs':
                summary['call_duration_average_percentage_8hrs'] ?? 0,
            'from_date': (filters['from_date'] ?? '').toString(),
            'to_date': (filters['to_date'] ?? '').toString(),
            'staff_results': List<Map<String, dynamic>>.from(
              (decoded['results'] ?? [])
                  .map((e) => Map<String, dynamic>.from(e)),
            ),
          };
        }

        return {
          'family_id': familyId,
          'family_name': familyId == 2 ? 'skating' : 'cycling',
          'present': 0,
          'absent': 0,
          'half_day': 0,
          'total_amount': 0,
          'total_invoices': 0,
          'total_call_count': 0,
          'total_call_duration': 0,
          'call_duration_average_minutes': 0,
          'call_duration_average_percentage_8hrs': 0,
          'from_date': queryParams['from_date'] ?? '',
          'to_date': queryParams['to_date'] ?? '',
          'staff_results': <Map<String, dynamic>>[],
        };
      }

      final results = await Future.wait([
        fetchFamilyCard(2),
        fetchFamilyCard(1),
      ]);

      if (!mounted) return;

      setState(() {
        familyAnalysisCards = results;
        familyAnalysisLoading = false;
        familyAnalysisFromDate = queryParams['from_date'] ?? '';
        familyAnalysisToDate = queryParams['to_date'] ?? '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        familyAnalysisLoading = false;
        familyAnalysisCards = [];
      });
      print("FAMILY ANALYSIS CARD ERROR: $e");
    }
  }

  bool _isUpdateAvailable(String currentVersion, String storeVersion) {
    List<int> currentParts =
        currentVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    List<int> storeParts =
        storeVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    int maxLength = currentParts.length > storeParts.length
        ? currentParts.length
        : storeParts.length;

    while (currentParts.length < maxLength) {
      currentParts.add(0);
    }
    while (storeParts.length < maxLength) {
      storeParts.add(0);
    }

    for (int i = 0; i < maxLength; i++) {
      if (storeParts[i] > currentParts[i]) {
        return true;
      } else if (storeParts[i] < currentParts[i]) {
        return false;
      }
    }

    return false;
  }

  Future<void> pickFamilyAnalysisDateRange() async {
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(now.year + 1),
      initialDateRange: familyAnalysisSelectedRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF02347C),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        familyAnalysisSelectedRange = DateTimeRange(
          start:
              DateTime(picked.start.year, picked.start.month, picked.start.day),
          end: DateTime(picked.end.year, picked.end.month, picked.end.day),
        );
      });

      await fetchFamilyAnalysisCards();
    }
  }

//   Future<void> fetchFamilyAnalysisSummary() async {
//     final token = await getTokenFromPrefs();
//     if (token == null) return;

//     setState(() {
//       familyAnalysisLoading = true;
//     });

//     try {
//       final Map<String, String> queryParams = {};

//       if (familyAnalysisSelectedRange != null) {
//         queryParams['from_date'] =
//             DateFormat('yyyy-MM-dd').format(familyAnalysisSelectedRange!.start);
//         queryParams['to_date'] =
//             DateFormat('yyyy-MM-dd').format(familyAnalysisSelectedRange!.end);
//       }

//       final uri = Uri.parse('$api/api/family/analysis/summary/').replace(
//         queryParameters: queryParams.isEmpty ? null : queryParams,
//       );

//       final response = await http.get(
//         uri,
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final decoded = jsonDecode(response.body);

//         final overall = Map<String, dynamic>.from(decoded['overall'] ?? {});
//         final filters = Map<String, dynamic>.from(decoded['filters'] ?? {});
//         final List results = decoded['results'] ?? [];

//         setState(() {
//           familyAnalysisOverall = overall;

//           familyAnalysisCards = List<Map<String, dynamic>>.from(
//             results.map((e) => Map<String, dynamic>.from(e)).where((item) {
//               final family =
//                   (item['family_name'] ?? '').toString().toLowerCase().trim();
//               return family == 'skating' || family == 'cycling';
//             }),
//           );

//           familyAnalysisFromDate = (filters['from_date'] ?? '').toString();
//           familyAnalysisToDate = (filters['to_date'] ?? '').toString();
//           familyAnalysisLoading = false;
//         });
//       } else {
//         setState(() {
//           familyAnalysisLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         familyAnalysisLoading = false;
//       });
//       print("FAMILY ANALYSIS ERROR: $e");
//     }
//   }

// Future<void> fetchFamilyAttendanceCounts() async {
//   final token = await getTokenFromPrefs();
//   if (token == null) return;

//   try {
//     final Map<String, String> queryParams = {};

//     if (familyAnalysisSelectedRange != null) {
//       queryParams['start_date'] =
//           DateFormat('yyyy-MM-dd').format(familyAnalysisSelectedRange!.start);
//       queryParams['end_date'] =
//           DateFormat('yyyy-MM-dd').format(familyAnalysisSelectedRange!.end);
//     } else {
//       final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
//       queryParams['start_date'] = today;
//       queryParams['end_date'] = today;
//     }

//     final uri = Uri.parse('$api/api/bdm/order/analysis/staff/filter/').replace(
//       queryParameters: queryParams,
//     );

//     print("FAMILY ATTENDANCE URL: $uri");

//     final response = await http.get(
//       uri,
//       headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//       },
//     );

//     print("FAMILY ATTENDANCE STATUS: ${response.statusCode}");
//     print("FAMILY ATTENDANCE BODY: ${response.body}");

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body);
//       final List data = decoded['data'] ?? [];

//       setState(() {
//         familyAttendanceData = List<Map<String, dynamic>>.from(
//           data.map((e) => Map<String, dynamic>.from(e)).where((item) {
//             final family =
//                 (item['family_name'] ?? '').toString().toLowerCase().trim();
//             return family == 'skating' || family == 'cycling';
//           }),
//         );
//       });
//     } else {
//       setState(() {
//         familyAttendanceData = [];
//       });
//     }
//   } catch (e) {
//     setState(() {
//       familyAttendanceData = [];
//     });
//     print("FAMILY ATTENDANCE ERROR: $e");
//   }
// }
  Future<void> getFilteredCategoryWiseProducts() async {
    final token = await getTokenFromPrefs();
    if (token == null) return;

    setState(() {
      filteredCategoryLoading = true;
      filteredCategoryProducts = [];
    });

    try {
      final String start = DateFormat('yyyy-MM-dd').format(
        bdmStartDate ?? DateTime.now(),
      );
      final String end = DateFormat('yyyy-MM-dd').format(
        bdmEndDate ?? DateTime.now(),
      );

      final uri = Uri.parse('$api/api/category/wise/product/count/').replace(
        queryParameters: {
          'start_date': start,
          'end_date': end,
        },
      );

      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List data = decoded['data'] ?? [];

        setState(() {
          filteredCategoryProducts = List<Map<String, dynamic>>.from(
            data.map((item) => {
                  "category_id": item["category_id"],
                  "title": (item["category_name"] ?? "Unknown").toString(),
                  "count": item["count"] ?? 0,
                }),
          );
          categoryStartDate = decoded['start_date'] ?? start;
          categoryEndDate = decoded['end_date'] ?? end;
          filteredCategoryLoading = false;
        });
      } else {
        setState(() {
          filteredCategoryLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        filteredCategoryLoading = false;
      });
    }
  }

  Future<void> fetchBdmOverallFamilyReport() async {
    final token = await getTokenFromPrefs();
    if (token == null) return;

    setState(() {
      bdmOverallLoading = true;
    });

    try {
      final String start = DateFormat('yyyy-MM-dd').format(
        bdmStartDate ?? DateTime.now(),
      );
      final String end = DateFormat('yyyy-MM-dd').format(
        bdmEndDate ?? DateTime.now(),
      );

      final uri = Uri.parse('$api/api/bdm/daily/overall/report/').replace(
        queryParameters: {
          'start_date': start,
          'end_date': end,
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final List reportDates = decoded['results']?['data'] is List
            ? decoded['results']['data']
            : [];

        Map<String, dynamic>? latestEntry;

        for (final item in reportDates) {
          if (item is Map<String, dynamic>) {
            final families = item['family_data'];
            if (families is List && families.isNotEmpty) {
              latestEntry = item;
              break;
            }
          }
        }

        if (latestEntry != null) {
          final List families = latestEntry['family_data'] ?? [];

          final List<Map<String, dynamic>> cards =
              families.map<Map<String, dynamic>>((family) {
            return {
              "created_date": latestEntry!['created_date'] ?? "",
              "bdo_present_count": latestEntry['bdo_present_count'] ?? 0,
              "bdo_absent_count": latestEntry['bdo_absent_count'] ?? 0,
              "bdo_half_day_count": latestEntry['bdo_half_day_count'] ?? 0,
              "total_bill_overall": latestEntry['total_bill'] ?? 0,
              "total_volume_overall": latestEntry['total_volume'] ?? 0.0,
              "total_call_duration_overall":
                  latestEntry['total_call_duration'] ?? "00:00:00",
              "call_duration_average_overall":
                  latestEntry['call_duration_average'] ?? 0.0,
              "average_call_duration_minutes_overall":
                  latestEntry['average_call_duration_minutes'] ?? 0.0,
              "family_id": family['family_id'] ?? 0,
              "family_name": family['family_name'] ?? "",
              "bdm_count": family['bdm_count'] ?? 0,
              "total_bill": family['total_bill'] ?? 0,
              "total_order_count": family['total_order_count'] ?? 0,
              "total_volume": family['total_volume'] ?? 0.0,
              "total_call_duration":
                  family['total_call_duration'] ?? "00:00:00",
              "call_duration_average": family['call_duration_average'] ?? 0.0,
              "average_call_duration_minutes":
                  family['average_call_duration_minutes'] ?? 0.0,
              "bdm_data": List<Map<String, dynamic>>.from(
                (family['bdm_data'] ?? [])
                    .map((e) => Map<String, dynamic>.from(e)),
              ),
              "start_date": start,
              "end_date": end,
            };
          }).toList();

          setState(() {
            bdmOverallRawData = List<Map<String, dynamic>>.from(
              reportDates.map((e) => Map<String, dynamic>.from(e)),
            );
            ceoFamilyCards = cards;
            selectedBdmReportDate = "${start} to ${end}";
            bdmOverallLoading = false;
          });
        } else {
          setState(() {
            ceoFamilyCards = [];
            selectedBdmReportDate = "${start} to ${end}";
            bdmOverallLoading = false;
          });
        }
      } else {
        setState(() {
          bdmOverallLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        bdmOverallLoading = false;
      });
    }
  }

  Future<void> fetchBdoStatewiseReport({
    required DateTime startDate,
    required DateTime endDate,
    required bool isDaily,
  }) async {
    final token = await getTokenFromPrefs();
    if (token == null) return;

    final start = DateFormat('yyyy-MM-dd').format(startDate);
    final end = DateFormat('yyyy-MM-dd').format(endDate);

    if (!mounted) return;
    setState(() {
      if (isDaily) {
        dailyBdoLoading = true;
        selectedDailyDate = start;
      } else {
        monthlyBdoLoading = true;
        monthlyStartDate = start;
        monthlyEndDate = end;
      }
    });

    try {
      final response = await http.get(
        Uri.parse(
            '$api/api/reports/state/wise/bdo/?start_date=$start&end_date=$end'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final List data = parsed['data'] ?? [];

        final List<Map<String, dynamic>> reportList =
            List<Map<String, dynamic>>.from(
          data.map((e) => Map<String, dynamic>.from(e)).where((item) {
            final family =
                (item['family'] ?? '').toString().toLowerCase().trim();
            return family == "skating" || family == "cycling";
          }),
        );

        if (!mounted) return;
        setState(() {
          if (isDaily) {
            dailyBdoStatewiseData = reportList;
            dailyBdoLoading = false;
          } else {
            monthlyBdoStatewiseData = reportList;
            monthlyBdoLoading = false;
          }
        });
      } else {
        if (!mounted) return;
        setState(() {
          if (isDaily) {
            dailyBdoLoading = false;
          } else {
            monthlyBdoLoading = false;
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (isDaily) {
          dailyBdoLoading = false;
        } else {
          monthlyBdoLoading = false;
        }
      });
    }
  }

  List<Map<String, dynamic>> sta = [];
  Future<void> getstaff() async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/staffs/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> stafflist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        final List productsData = parsed['data'] ?? [];

        for (var productData in productsData) {
          stafflist.add({
            'id': productData['id'],
            'name': productData['name'],
            'email': productData['email'],
            'designation': productData['designation'],
            'image': productData['image'],
            'approval_status': productData['approval_status'],
          });
        }

        int activeCount = 0;
        int inactiveCount = 0;

        for (var staff in stafflist) {
          final status =
              (staff['approval_status'] ?? '').toString().toLowerCase().trim();

          if (status == 'approved') {
            activeCount++;
          } else if (status == 'disapproved') {
            inactiveCount++;
          }
        }

        setState(() {
          sta = stafflist;
          filteredProducts = List.from(sta);
          staffCount = stafflist.length;
          activeStaffCount = activeCount;
          inactiveStaffCount = inactiveCount;
        });
      } else {
        print("GET STAFF STATUS ERROR: ${response.statusCode}");
        print("GET STAFF BODY: ${response.body}");
      }
    } catch (error) {
      print("GET STAFF ERROR: $error");
    }
  }

  List<Map<String, dynamic>> categoryWiseProducts = [];
  String postOfficeDate = "";
  bool loadingCategoryWise = false;

  Future<void> getCategoryWiseProducts() async {
    DateTime now = DateTime.now();
    String todayDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    setState(() {
      loadingCategoryWise = true;
      categoryWiseProducts = [];
      postOfficeDate = "";
    });

    final token = await getTokenFromPrefs();

    if (token == null) {
      setState(() {
        loadingCategoryWise = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("$api/api/category/wise/product/count/$todayDate/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          postOfficeDate = data["postoffice_date"] ?? todayDate;
          categoryWiseProducts = List<Map<String, dynamic>>.from(
              data["category_wise_products"] ?? []);
          loadingCategoryWise = false;
        });
      } else {
        setState(() {
          loadingCategoryWise = false;
        });
      }
    } catch (e) {
      setState(() {
        loadingCategoryWise = false;
      });
    }
  }

  Map<String, Map<String, dynamic>> familyWiseSummary = {};
  Map<String, Map<String, dynamic>> todayFamilyWiseSummary = {};
  Map<String, Map<String, dynamic>> currentMonthFamilySummary = {};
  Map<String, Map<String, dynamic>> currentMonthFamilyWiseSummary = {};

  int approval = 0;
  int confirm = 0;
  int approvalcount = 0;
  int confirmcount = 0;

  Map<String, double> parseExpenseTypeTotals(Map<String, dynamic> apiResponse) {
    final List summary = apiResponse['summary'] ?? [];

    final Map<String, double> totals = {};

    for (final item in summary) {
      final String type = item['expense_type']?.toString() ?? 'unknown';
      final double total = (item['total'] is int)
          ? (item['total'] as int).toDouble()
          : (item['total'] ?? 0.0).toDouble();

      totals[type] = total;
    }

    return totals;
  }

  Future<bool> checkAppUpdate(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    try {
      String? storeVersion;
      Uri? storeUrl;

      if (Platform.isAndroid) {
        final response = await http.get(Uri.parse(
          'https://play.google.com/store/apps/details?id=com.bepositive.beposoft&hl=en',
        ));

        if (response.statusCode == 200) {
          final content = response.body;
          final versionRegex = RegExp(r'\[\[\["([0-9.]+)"\]\]');
          final match = versionRegex.firstMatch(content);

          if (match != null) {
            storeVersion = match.group(1);
            storeUrl = Uri.parse(
              'https://play.google.com/store/apps/details?id=com.bepositive.beposoft',
            );
          }
        }
      } else if (Platform.isIOS) {
        final response = await http.get(
          Uri.parse('https://itunes.apple.com/lookup?id=6748010646&country=in'),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (data['resultCount'] != null &&
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
          _isUpdateAvailable(currentVersion, storeVersion)) {
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            titlePadding: const EdgeInsets.only(top: 20),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            title: Column(
              children: [
                Icon(
                  Icons.system_update,
                  size: 48,
                  color: Colors.green,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Update Available',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              'A new version ($storeVersion) is available.\n\nYou are using $currentVersion.\n\nPlease update the app to continue enjoying the latest features and improvements.',
              style: const TextStyle(fontSize: 16),
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                label: const Text("Update Now"),
                onPressed: () async {
                  if (storeUrl != null && await canLaunchUrl(storeUrl)) {
                    await launchUrl(
                      storeUrl,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: const Text("Maybe Later"),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        );

        return result == true;
      }
    } catch (e) {
      // Optional: print(e);
    }

    return true;
  }

  Widget buildExpenseTypeTotalsCard(Map<String, double> totals) {
    if (totals.isEmpty) {
      return Card(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text('No expense data',
                style: TextStyle(color: Colors.grey[700])),
          ),
        ),
      );
    }

    // Sort by amount (desc)
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final grandTotal = entries.fold<double>(0.0, (s, e) => s + e.value);

    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monthly Expense (${DateFormat('MMMM yyyy').format(DateTime.now())})',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueAccent),
                ),
              ],
            ),
            Divider(),
            // List of types
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 12),
              itemBuilder: (context, i) {
                final k = entries[i].key; // expense_type name
                final v = entries[i].value; // total amount
                final pct = grandTotal == 0 ? 0 : (v / grandTotal);

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => expence_list_type(
                            type: k,
                            fromDate: monthlyExpenseFrom,
                            toDate: monthlyExpenseTo,
                          ),
                        ));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        // Type + amount
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(k.toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(_currency.format(v),
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700)),
                            ],
                          ),
                        ),

                        // Percentage bar
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              LayoutBuilder(
                                builder: (context, c) {
                                  final w = c.maxWidth;
                                  return Stack(
                                    children: [
                                      Container(
                                        width: w,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                      ),
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        width: w * pct,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 6),
                              Text('${(pct * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Divider(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Grand Total',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 41, 177, 46),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _currency.format(grandTotal),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFamilySummaryTeamCards() {
    if (familySummaryTeamLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final String todayText = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Column(
      children: familySummaryTeamCards.map((item) {
        final fromDate = (item['from_date'] ?? '').toString();
        final toDate = (item['to_date'] ?? '').toString();

        final DateTime effectiveStart = familySummaryTeamSelectedRange != null
            ? DateTime(
                familySummaryTeamSelectedRange!.start.year,
                familySummaryTeamSelectedRange!.start.month,
                familySummaryTeamSelectedRange!.start.day,
              )
            : DateTime.now();

        final DateTime effectiveEnd = familySummaryTeamSelectedRange != null
            ? DateTime(
                familySummaryTeamSelectedRange!.end.year,
                familySummaryTeamSelectedRange!.end.month,
                familySummaryTeamSelectedRange!.end.day,
              )
            : DateTime.now();

        String selectedDateText = todayText;
        if (fromDate.isNotEmpty || toDate.isNotEmpty) {
          selectedDateText =
              "${fromDate.isEmpty ? todayText : fromDate} to ${toDate.isEmpty ? todayText : toDate}";
        }

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FamilyDetailedSummaryPage(
                  familyId: item['family_id'] ?? 0,
                  familyName: (item['family_name'] ?? '').toString(),
                  startDate: effectiveStart,
                  endDate: effectiveEnd,
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF02347C), Color(0xFF82E49D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "BDO Call Duration Report",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: pickFamilySummaryTeamDateRange,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(
                          Icons.calendar_month,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: (item['family_name'] ?? '')
                            .toString()
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: " ($selectedDateText)",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "Present",
                        "${item['present_count'] ?? 0}",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "Absent",
                        "${item['absent_count'] ?? 0}",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "Half Day",
                        "${item['half_day_count'] ?? 0}",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "Amount",
                        "₹${(double.tryParse(item['amount_value'].toString()) ?? 0.0).toStringAsFixed(1)}",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "Invoices",
                        "${item['invoice_count'] ?? 0}",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "Total Call Duration",
                        "${(double.tryParse(item['total_call_duration'].toString()) ?? 0.0).toStringAsFixed(2)} mins",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "Avg Duration",
                        "${(double.tryParse(item['call_duration_average'].toString()) ?? 0.0).toStringAsFixed(2)} mins",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "8hr %",
                        "${(double.tryParse(item['call_duration_percentage_8hrs'].toString()) ?? 0.0).toStringAsFixed(2)}%",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryMiniCard({
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.28),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInfoRowWhite(
    String label,
    String value, {
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.white70),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: icon != null ? 135 : 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _familySummaryCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _familySummaryValue(String text) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _employeeStatusMiniTile({
    required String title,
    required int count,
    required IconData icon,
  }) {
    return Row(
      children: [
        // Icon(
        //   icon,
        //   color: Colors.white,
        //   size: 14,
        // ),
        // const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          "$count",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeColumnItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.22),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.88),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardLineItem({
    required String title,
    required String value,
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.22),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.88),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (value.isNotEmpty)
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget dashboardCards() {
    final bankSummary = _asMap(beposoftSummary['bank_summary']);
    final todayData = _asMap(bankSummary['today_data']);
    final staffSummary = _asMap(beposoftSummary['staff_summary']);

    final totalStaffs = _asInt(staffSummary['total_staffs']);
    final activeStaffs = _asInt(staffSummary['active_staffs']);
    final deactiveStaffs = _asInt(staffSummary['deactive_staffs']);

    final totalFamilyPresentCount = familySummaryTeamCards.fold<int>(
      0,
      (sum, item) => sum + _asInt(item['present_count']),
    );

    final withInternalTransfer = _asMap(todayData['with_internal_transfer']);
    final financeOpeningBalance =
        _asDouble(withInternalTransfer['open_balance']);

    final financeCredit = _asDouble(withInternalTransfer['credit']);
    final financeDebit = _asDouble(withInternalTransfer['debit']);
    final financeClosingBalance =
        _asDouble(withInternalTransfer['closing_balance']);

    final purchaseSummary = _asMap(beposoftSummary['purchase_summary']);
    final purchaseCount = _asInt(purchaseSummary['total_count']);
    final purchaseAmount = _asDouble(purchaseSummary['total_amount']);

    // final billAmountSummary = _asMap(beposoftSummary['bill_amount_summary']);
    // final currentMonthBillData =
    //     _asMap(billAmountSummary['current_month_data']);

    // final currentMonthBillAmount =
    //     _asDouble(currentMonthBillData['total_amount']);

    final assetSummary = _asMap(beposoftSummary['asset_summary']);
    final assetCount = _asInt(assetSummary['total_count']);
    final assetAmount = _asDouble(assetSummary['total_amount']);

    final billAmountSummary = _asMap(beposoftSummary['bill_amount_summary']);
    final currentMonthBillData =
        _asMap(billAmountSummary['current_month_data']);
    final currentMonthBillAmount =
        _asDouble(currentMonthBillData['total_amount']);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.80,
        children: [
          _buildDashboardCard(
            title: "Sales",
            icon: Icons.bar_chart_rounded,
            value: _formatDashboardAmount(
              productsData?['month_total_amount'],
            ),
            lines: [
              "Today's Invoices: ${_asInt(productsData?['today_count'])}",
              "Volume: ${_formatDashboardAmount(productsData?['today_total_amount'])}",
              "Total Invoices: ${_asInt(productsData?['month_count'])}",
            ],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SalesReportExcel()),
              );
            },
          ),
          _buildDashboardCard(
            title: "Finance",
            icon: Icons.account_balance_wallet_rounded,
            valueLabel: "CB",
            value: _formatDashboardAmount(financeClosingBalance),
            lines: [
              "Credit: ${_formatDashboardAmount(financeCredit)}",
              "Debit: ${_formatDashboardAmount(financeDebit)}",
            ],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FinancialReport()),
              );
            },
          ),
          _buildDashboardCard(
            title: "Logistics (DGM)",
            icon: Icons.inventory_2_rounded,
            value: _formatDashboardAmount(currentMonthBillAmount),
            lines: [
              dgmLoading
                  ? "Amount: Loading..."
                  : "PO Amount: ${_formatDashboardAmount(monthTotalParcelAmount)}",
              dgmLoading
                  ? "Weight: Loading."
                  : "Weight: ${monthTotalWeight.toStringAsFixed(2)} kg",
              // "Total Amount: ${_formatDashboardAmount(currentMonthBillAmount)}",
              // dgmLoading
              //     ? "Total Amount: Loading."
              //     : "Total Amount: ${_formatDashboardAmount(currentMonthBillAmount)}",
              dgmLoading
                  ? "Avg: Loading."
                  : "Avg: ₹${monthAverage.toStringAsFixed(2)}/kg",
            ],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => daily_goods_movementt()),
              );
            },
          ),
          _buildDashboardCard(
            title: "Employees",
            icon: Icons.groups_rounded,
            value: "Total $totalStaffs",
            lines: const [],
            bottom: Column(
              children: [
                _buildEmployeeColumnItem(
                  title: "Hired",
                  value: "$activeStaffs",
                  icon: Icons.check_circle_rounded,
                ),
                const SizedBox(height: 6),
                _buildEmployeeColumnItem(
                  title: "Resigned",
                  value: "$deactiveStaffs",
                  icon: Icons.cancel_rounded,
                ),
                const SizedBox(height: 6),
                _buildEmployeeColumnItem(
                  title: "Present",
                  value: "$totalFamilyPresentCount",
                  icon: Icons.person_pin_circle_rounded,
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => staff_list()),
              );
            },
          ),
          _buildDashboardCard(
            title: "Assets",
            icon: Icons.local_shipping_rounded,
            value: _formatDashboardAmount(assetAmount),
            lines: [
              "Count: $assetCount",
              "Asset management",
            ],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AssetManegment()),
              );
            },
          ),
          _buildDashboardCard(
            title: "Purchase",
            icon: Icons.shopping_bag_rounded,
            value: _formatDashboardAmount(purchaseAmount),
            lines: [
              "Invoices: $purchaseCount",
              "Suppliers & Invoices",
            ],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SellerInvoiceListPage()),
              );
            },
          ),
          _buildDashboardCard(
            title: "Inventory",
            icon: Icons.warehouse_rounded,
            valueLabel: "WH",
            value: dashboardInventoryLoading
                ? "Loading..."
                : _formatDashboardAmount(dashboardTotalSellingAmount),
            lines: [
              dashboardInventoryLoading
                  ? "Retail: Loading..."
                  : "Retail: ${_formatDashboardAmount(dashboardTotalRetailAmount)}",
              dashboardInventoryLoading
                  ? "Landing: Loading..."
                  : "Landing: ${_formatDashboardAmount(dashboardTotalLandingCostAmount)}",
              // dashboardInventoryLoading
              //     ? "Stock: Loading..."
              //     : "Stock: $dashboardTotalStock",
            ],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WarehouseSummaryScreen(),
                ),
              );
            },
          ),
          _buildDashboardCard(
            title: "Marketing",
            icon: Icons.campaign_rounded,
            value: "Campaigns",
            lines: [
              "Ads & promotions",
              "Marketing overview",
            ],
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required IconData icon,
    required String value,
    required List<dynamic> lines,
    required VoidCallback onTap,
    String valueLabel = "",
    Widget? bottom,
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
                color: const Color(0xFF2C74FF).withOpacity(0.28),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      height: 31,
                      width: 31,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.22),
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (value.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          valueLabel.isNotEmpty
                              ? "$valueLabel - $value"
                              : value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                if (value.isNotEmpty) const SizedBox(height: 7),
                // ...lines.take(3).map((line) {
                ...lines.map((line) {
                  if (line is Widget) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Container(
                        width: double.infinity,
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.22),
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: line,
                        ),
                      ),
                    );
                  }

                  final text = line?.toString() ?? '';
                  final parts = text.split(':');

                  final String titleText =
                      parts.length > 1 ? parts.first.trim() : text.trim();

                  final String valueText =
                      parts.length > 1 ? parts.sublist(1).join(':').trim() : "";

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: _buildDashboardLineItem(
                      title: titleText,
                      value: valueText,
                    ),
                  );
                }).toList(),
                if (bottom != null) ...[
                  const SizedBox(height: 8),
                  bottom,
                ] else
                  const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardMiniChip({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.20),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 13,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.86),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // Future<void> pickFamilyAnalysisDateRange() async {
  //   final now = DateTime.now();

  //   final picked = await showDateRangePicker(
  //     context: context,
  //     firstDate: DateTime(2023),
  //     lastDate: DateTime(now.year + 1),
  //     initialDateRange: familyAnalysisSelectedRange,
  //     builder: (context, child) {
  //       return Theme(
  //         data: Theme.of(context).copyWith(
  //           colorScheme: const ColorScheme.light(
  //             primary: Color(0xFF02347C),
  //             onPrimary: Colors.white,
  //             surface: Colors.white,
  //             onSurface: Colors.black,
  //           ),
  //         ),
  //         child: child!,
  //       );
  //     },
  //   );

  //   if (picked != null) {
  //     setState(() {
  //       familyAnalysisSelectedRange = picked;
  //     });
  //     await fetchFamilyAnalysisSummary();
  //     await fetchFamilyAttendanceCounts();
  //   }
  // }

  Widget fullWidthCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color1,
    required Color color2,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(2, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCategoryWiseCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => CategoryWiseProductPage()));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF02347C),
              Color(0xFF82E49D),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Category Wise Products",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            if (postOfficeDate.isNotEmpty)
              Text(
                "Date: $postOfficeDate",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            const SizedBox(height: 12),
            Table(
              border: TableBorder.all(color: Colors.white30, width: 1),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
              },
              children: [
                // Header Row
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        "Category",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        "Quantity",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),

                // Dynamic Rows
                ...categoryWiseProducts.map((item) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          item["category"].toString(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          item["total_quantity"].toString(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> todayBankReports = [];
  Future<void> getTodayODReportTotals() async {
    final token = await getTokenFromPrefs();

    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse("$api/api/finance/report/bank/account/type/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        List bankData = body["bank_data"] ?? [];
        String todayDate = DateTime.now().toString().split(" ")[0];

        List<Map<String, dynamic>> reportList = [];

        for (var bank in bankData) {
          List dailyData = bank["daily_data"] ?? [];

          var todayEntry = dailyData.firstWhere(
            (d) => d["date"].toString().trim() == todayDate.trim(),
            orElse: () => null,
          );

          double openingBalance = 0;
          double closingBalance = 0;
          double todayCredit = 0;
          double todayDebit = 0;

          if (todayEntry != null) {
            openingBalance =
                double.tryParse(todayEntry["opening"].toString()) ?? 0;

            closingBalance =
                double.tryParse(todayEntry["closing"].toString()) ?? 0;

            todayCredit =
                double.tryParse(todayEntry["total_credit"].toString()) ?? 0;

            todayDebit =
                double.tryParse(todayEntry["total_debit"].toString()) ?? 0;
          }

          reportList.add({
            "bank_id": bank["bank_id"],
            "bank_name": bank["bank_name"] ?? "",
            "opening_balance": openingBalance,
            "closing_balance": closingBalance,
            "today_credit": todayCredit,
            "today_debit": todayDebit,
            "daily_data": dailyData,
          });
        }

        if (!mounted) return;

        setState(() {
          todayBankReports = reportList;
          dbrLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          dbrLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        dbrLoading = false;
      });
    }
  }

  double calculateTodayInternalTransferAmount(List<dynamic> transfers) {
    final today = DateTime.now();
    double total = 0.0;

    for (final transfer in transfers) {
      final createdAtRaw = DateTime.tryParse(transfer['created_at']);
      final createdAt = createdAtRaw?.toLocal(); // Convert to local timezone

      if (createdAt != null &&
          createdAt.year == today.year &&
          createdAt.month == today.month &&
          createdAt.day == today.day) {
        total += double.tryParse(transfer['amount'].toString()) ?? 0.0;
      }
    }

    return total;
  }

  double todayInternalTransferTotal = 0.0;

  Future<void> fetchInternalTransfersData() async {
    final token = await getTokenFromPrefs();

    try {
      var response = await http.get(
        Uri.parse('$api/api/internal/transfers/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Today transfer
        final double todayTransferAmount =
            calculateTodayInternalTransferAmount(data);

        // NEW – monthly total transfer
        final double monthlyTransferAmount =
            calculateMonthlyInternalTransferAmount(data);

        setState(() {
          internalTransfers = data;
          todayInternalTransferTotal = todayTransferAmount;

          // DAILY (DBR without transfer)
          totalTodayPayments1 -= todayInternalTransferTotal;
          totalTodayBanksAmount1 -= todayInternalTransferTotal;

          // MONTHLY (MBR without transfer)
          totalCurrentMonthPayments -= monthlyTransferAmount;
          totalCurrentMonthExpenses -= monthlyTransferAmount;
        });
      }
    } catch (e) {}
  }

  double salesMonthAmount = 0.0;
  int salesMonthCount = 0;

  Future<void> fetchOrderData() async {
    try {
      final token = await getTokenFromPrefs();
      var response = await http.get(
        Uri.parse('$api/api/orders/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['results'];

        if (productsData != null && productsData is Iterable) {
          List<Map<String, dynamic>> orderList = [];
          Map<String, Map<String, dynamic>> familySummary = {};
          Map<String, Map<String, dynamic>> todayFamilySummary = {};
          Map<String, Map<String, dynamic>> currentMonthFamilySummary = {};

          double monthCodTotalAmount = 0.0;
          int monthCodOrderCount = 0;
          double monthpaidTotalAmount = 0.0;
          int monthpaidOrderCount = 0;
          double monthcrediTotalAmount = 0.0;
          int monthcreditOrderCount = 0;
          int approval = 0;
          int confirm = 0;

          DateTime today = DateTime.now();
          String formattedToday = DateFormat('yyyy-MM-dd').format(today);

          for (var productData in productsData) {
            // Parse order_date
            String rawOrderDate = productData['order_date'];
            String formattedOrderDate = rawOrderDate;
            try {
              DateTime parsedOrderDate = DateTime.parse(rawOrderDate);
              formattedOrderDate =
                  DateFormat('yyyy-MM-dd').format(parsedOrderDate);
            } catch (e) {
              // ignore parse error
            }

            // Build order entry
            var order = {
              'id': productData['id'],
              'invoice': productData['invoice'],
              'manage_staff': productData['manage_staff'],
              'customer': {
                'id': productData['customer']['id'],
                'name': productData['customer']['name'],
                'address': productData['billing_address']?['address'] ?? '',
              },
              'status': productData['status'],
              'order_date': formattedOrderDate,
              'updated_at': productData['updated_at'],
              'total_amount': productData['total_amount'],
              'family': productData['family'],
              'payment_status': productData['payment_status'],
            };

            orderList.add(order);

            // Count invoice statuses
            if (productData['status'] == 'Invoice Created') {
              approval++;
            } else if (productData['status'] == 'Invoice Approved') {
              confirm++;
            }

            // Family name and amount
            String family = productData['family'];
            double amount =
                double.tryParse(productData['total_amount'].toString()) ?? 0.0;

            // ---- Current Month Family Summary (skip rejected) ----
            DateTime parsedOrderDate;
            try {
              parsedOrderDate = DateTime.parse(rawOrderDate);
            } catch (e) {
              parsedOrderDate = today;
            }

            if (productData['status'] != 'Invoice Rejected' &&
                parsedOrderDate.month == today.month &&
                parsedOrderDate.year == today.year) {
              currentMonthFamilySummary.putIfAbsent(
                  family,
                  () => {
                        'total_amount': 0.0,
                        'order_count': 0,
                        'cod_order_count': 0,
                        'cod_total_amount': 0.0,
                        'paid_order_count': 0,
                        'paid_total_amount': 0.0,
                        'credit_order_count': 0,
                        'credit_total_amount': 0.0,
                      });
              currentMonthFamilySummary[family]!['total_amount'] += amount;
              currentMonthFamilySummary[family]!['order_count'] += 1;

              if (productData['payment_status'] == 'COD') {
                currentMonthFamilySummary[family]!['cod_order_count'] += 1;
                currentMonthFamilySummary[family]!['cod_total_amount'] +=
                    amount;
              }
              if (productData['payment_status'] == 'paid') {
                currentMonthFamilySummary[family]!['paid_order_count'] += 1;
                currentMonthFamilySummary[family]!['paid_total_amount'] +=
                    amount;
              }
              if (productData['payment_status'] == 'credit') {
                currentMonthFamilySummary[family]!['credit_order_count'] += 1;
                currentMonthFamilySummary[family]!['credit_total_amount'] +=
                    amount;
              }
            }

            // ---- All-time Family-wise Summary (no filter) ----
            familySummary.putIfAbsent(
                family,
                () => {
                      'total_amount': 0.0,
                      'order_count': 0,
                    });
            familySummary[family]!['total_amount'] += amount;
            familySummary[family]!['order_count'] += 1;

            // ---- Today's Family Summary (skip rejected) ----
            if (productData['status'] != 'Invoice Rejected' &&
                formattedOrderDate == formattedToday) {
              todayFamilySummary.putIfAbsent(
                  family,
                  () => {
                        'total_amount': 0.0,
                        'order_count': 0,
                        'cod_order_count': 0,
                        'cod_total_amount': 0.0,
                        'paid_order_count': 0,
                        'paid_total_amount': 0.0,
                        'credit_order_count': 0,
                        'credit_total_amount': 0.0,
                      });
              todayFamilySummary[family]!['total_amount'] += amount;
              todayFamilySummary[family]!['order_count'] += 1;

              if (productData['payment_status'] == 'COD') {
                todayFamilySummary[family]!['cod_order_count'] += 1;
                todayFamilySummary[family]!['cod_total_amount'] += amount;
              }
              if (productData['payment_status'] == 'paid') {
                todayFamilySummary[family]!['paid_order_count'] += 1;
                todayFamilySummary[family]!['paid_total_amount'] += amount;
              }
              if (productData['payment_status'] == 'credit') {
                todayFamilySummary[family]!['credit_order_count'] += 1;
                todayFamilySummary[family]!['credit_total_amount'] += amount;
              }
            }
          }

          // Shipped Orders Today
          var shippedOrdersToday = orderList.where((order) {
            return order['status'] == 'Shipped' &&
                order['updated_at'].startsWith(formattedToday);
          }).toList();

          // Month totals row
          double monthTotalAmount = 0.0;
          int monthTotalOrders = 0;

          currentMonthFamilySummary.forEach((key, value) {
            if (key == 'Total') return;
            monthTotalAmount += (value['total_amount'] as double);
            monthTotalOrders += (value['order_count'] as int);
            monthCodTotalAmount +=
                (value['cod_total_amount'] as double? ?? 0.0);
            monthCodOrderCount += (value['cod_order_count'] as int? ?? 0);
            monthpaidTotalAmount +=
                (value['paid_total_amount'] as double? ?? 0.0);
            monthpaidOrderCount += (value['paid_order_count'] as int? ?? 0);
            monthcrediTotalAmount +=
                (value['credit_total_amount'] as double? ?? 0.0);
            monthcreditOrderCount += (value['credit_order_count'] as int? ?? 0);
          });

          currentMonthFamilySummary['Month Total'] = {
            'total_amount': monthTotalAmount,
            'order_count': monthTotalOrders,
            'cod_total_amount': monthCodTotalAmount,
            'cod_order_count': monthCodOrderCount,
            'paid_total_amount': monthpaidTotalAmount,
            'paid_order_count': monthpaidOrderCount,
            'credit_total_amount': monthcrediTotalAmount,
            'credit_order_count': monthcreditOrderCount,
          };

          // Update state
          setState(() {
            orders = orderList;
            filteredOrders = orderList;
            shippedOrders = shippedOrdersToday;
            approvalcount = parsed['invoice_created_count'];
            confirmcount = parsed['invoice_approved_count'];
            familyWiseSummary = familySummary;
            todayFamilyWiseSummary = todayFamilySummary;
            currentMonthFamilyWiseSummary = currentMonthFamilySummary;
            salesMonthAmount = monthTotalAmount;
            salesMonthCount = monthTotalOrders;
          });

          // print(salesMonthAmount);
          // print(salesMonthCount);
        }
      }
    } catch (error) {
      // handle error
    }
  }

  List<Map<String, dynamic>> expensedata = [];
  double totalexpenseAmount = 0;
  double todayExpenseAmount = 0.0;

// ...existing code...
  Future<void> getexpenselist() async {
    try {
      final token = await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/dashboard/expense/summary/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) return;

      final parsed = jsonDecode(response.body);

      final List summary = parsed['summary'] ?? [];
      final double monthTotal = (parsed['month_total'] ?? 0).toDouble();

      final String from = parsed['range']?['from']?.toString() ?? "";
      final String to = parsed['range']?['to']?.toString() ?? "";

      Map<String, double> expenseTypeTotals = {};

      for (var item in summary) {
        try {
          final String type = item['expense_type']?.toString() ?? 'Others';
          final double total = (item['total'] ?? 0).toDouble();
          expenseTypeTotals[type] = total;
        } catch (_) {}
      }

      setState(() {
        expenseTypeWiseTotals = expenseTypeTotals;
        totalexpenseAmount = monthTotal;
        monthlyExpenseFrom = from;
        monthlyExpenseTo = to;
      });
    } catch (e) {
      // Handle error safely
    }
  }

// ...existing code...

  int todayShippedCount = 0;
  int todayOrdersTotalAmount = 0; // Add this to your state

  Future<void> fetchshippedorders() async {
    try {
      final token = await getTokenFromPrefs();
      String url = '$api/api/orders/';

      var response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List ordersData = responseData['results'];

        DateTime currentDate = DateTime.now();
        String today = DateFormat('yyyy-MM-dd').format(currentDate);

        int shippedTodayCount = 0;
        double totalAmount = 0.0;

        for (var orderData in ordersData) {
          String rawOrderDate = orderData['order_date'] ?? "";
          try {
            DateTime parsedOrderDate =
                DateFormat('yyyy-MM-dd').parse(rawOrderDate);
            String formattedOrderDate =
                DateFormat('yyyy-MM-dd').format(parsedOrderDate);

            if (formattedOrderDate == today) {
              // Sum total_amount for today's orders
              totalAmount += (orderData['total_amount'] ?? 0).toDouble();
              if (orderData['status'] == "Shipped") {
                shippedTodayCount++;
              }
            }
          } catch (e) {
            continue;
          }
        }

        setState(() {
          todayShippedCount = shippedTodayCount;
          todayOrdersTotalAmount =
              totalAmount.toInt(); // Store as int, or keep as double if needed
        });
      } else {
        throw Exception("Failed to load order data");
      }
    } catch (error) {
      // Handle error if needed
    }
  }

  double totalAdjustedOpeningBalance = 0.0;
  double totalClosingBalance = 0.0;
  double totalTodayPayments = 0.0;
  double totalTodayBanksAmount = 0.0;

  double currentMonthOpening = 0.0;
  double currentMonthClosing = 0.0;
  double totalCurrentMonthPayments1 = 0.0;
  double totalCurrentMonthExpenses1 = 0.0;
  Map<String, dynamic> summary = {};
  DateTimeRange? selectedRange;
  String formatDate(DateTime date) => DateFormat("yyyy-MM-dd").format(date);
  String formatDisplayDate(DateTime date) =>
      DateFormat("dd/MM/yyyy").format(date);
  List<Map<String, dynamic>> Finance1 = [];
  Future<void> fetchReport() async {
    if (!mounted) return;
    final start = formatDate(selectedRange!.start);
    final end = formatDate(selectedRange!.end);

    final url =
        Uri.parse("https://bepocart.in/api/orders/date/report/$start/$end/");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200 && response.body.startsWith("{")) {
        final data = jsonDecode(response.body);

        if (!mounted) return;

        setState(() {
          summary = data["summary"] ?? {};
          orders = data["orders"] ?? [];
        });
      } else {}
    } catch (e) {}
  }

  Future<void> getFinancialReport() async {
    final token = await getTokenFromPrefs();

    // RESET ALL TOTALS
    totalAdjustedOpeningBalance = 0.0;
    totalClosingBalance = 0.0;
    totalTodayPayments = 0.0;
    totalTodayBanksAmount = 0.0;

    currentMonthOpening = 0.0;
    currentMonthClosing = 0.0;
    totalCurrentMonthPayments1 = 0.0;
    totalCurrentMonthExpenses1 = 0.0;

    try {
      final response = await http.get(
        Uri.parse('$api/api/finance-report/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        final now = DateTime.now();

        // TODAY (DATE ONLY)
        final DateTime today = DateTime(now.year, now.month, now.day);

        // CURRENT MONTH START (1st day)
        final int cm = now.month;
        final int cy = now.year;
        final DateTime monthStart = DateTime(cy, cm, 1);

        List<Map<String, dynamic>> financeList = [];

        for (var bankData in parsed["bank_data"] ?? []) {
          String bankName = bankData["name"] ?? "Unknown Bank";

          double openBalance =
              (bankData["open_balance"] as num?)?.toDouble() ?? 0.0;

          // ----------------------------
          // HELPER: NORMALIZE DATE-ONLY
          // ----------------------------
          DateTime? _toDateOnly(String? s) {
            if (s == null || s.isEmpty) return null;
            final d = DateTime.tryParse(s);
            if (d == null) return null;
            return DateTime(d.year, d.month, d.day);
          }

          // ----------------------------
          // DAILY OPENING = opening as of today start
          // ----------------------------
          double paymentsBeforeToday = (bankData["payments"] as List<dynamic>?)
                  ?.where((p) {
                final d = _toDateOnly(p["received_at"]);
                if (d == null) return false;
                return d.isBefore(today);
              }).fold<double>(
                      0.0,
                      (sum, p) =>
                          sum +
                          (double.tryParse(p["amount"].toString()) ?? 0.0)) ??
              0.0;

          double expensesBeforeToday = (bankData["banks"] as List<dynamic>?)
                  ?.where((b) {
                final d = _toDateOnly(b["expense_date"]);
                if (d == null) return false;
                return d.isBefore(today);
              }).fold<double>(
                      0.0,
                      (sum, b) =>
                          sum +
                          (double.tryParse(b["amount"].toString()) ?? 0.0)) ??
              0.0;

          double adjustedOpeningBalance =
              openBalance + paymentsBeforeToday - expensesBeforeToday;

          totalAdjustedOpeningBalance += adjustedOpeningBalance;

          // ----------------------------
          // TODAY CREDIT (PAYMENTS)
          // ----------------------------
          double todayPayments = (bankData["payments"] as List<dynamic>?)
                  ?.where((p) {
                final d = _toDateOnly(p["received_at"]);
                if (d == null) return false;
                return d.isAtSameMomentAs(today);
              }).fold<double>(
                      0.0,
                      (sum, p) =>
                          sum +
                          (double.tryParse(p["amount"].toString()) ?? 0.0)) ??
              0.0;

          totalTodayPayments += todayPayments;

          // ----------------------------
          // TODAY DEBIT (BANK EXPENSES)
          // ----------------------------
          double todayExpenses = (bankData["banks"] as List<dynamic>?)?.where(
                  (b) {
                final d = _toDateOnly(b["expense_date"]);
                if (d == null) return false;
                return d.isAtSameMomentAs(today);
              }).fold<double>(
                  0.0,
                  (sum, b) =>
                      sum + (double.tryParse(b["amount"].toString()) ?? 0.0)) ??
              0.0;

          totalTodayBanksAmount += todayExpenses;

          // ----------------------------
          // DAILY CLOSING
          // ----------------------------
          double closingBalance =
              adjustedOpeningBalance + todayPayments - todayExpenses;

          totalClosingBalance += closingBalance;

          // =====================================================
          //           MONTHLY (FROM MONTH START TO TODAY)
          // =====================================================

          // 1) MONTH OPENING = balance as of monthStart
          double paymentsBeforeMonth = (bankData["payments"] as List<dynamic>?)
                  ?.where((p) {
                final d = _toDateOnly(p["received_at"]);
                if (d == null) return false;
                return d.isBefore(monthStart);
              }).fold<double>(
                      0.0,
                      (sum, p) =>
                          sum +
                          (double.tryParse(p["amount"].toString()) ?? 0.0)) ??
              0.0;

          double expensesBeforeMonth = (bankData["banks"] as List<dynamic>?)
                  ?.where((b) {
                final d = _toDateOnly(b["expense_date"]);
                if (d == null) return false;
                return d.isBefore(monthStart);
              }).fold<double>(
                      0.0,
                      (sum, b) =>
                          sum +
                          (double.tryParse(b["amount"].toString()) ?? 0.0)) ??
              0.0;

          double monthOpening =
              openBalance + paymentsBeforeMonth - expensesBeforeMonth;
          currentMonthOpening += monthOpening;

          // 2) MONTH CREDIT (1st of month → today)
          double monthPayments = (bankData["payments"] as List<dynamic>?)
                  ?.where((p) {
                final d = _toDateOnly(p["received_at"]);
                if (d == null) return false;
                // from monthStart up to today (inclusive)
                return !d.isBefore(monthStart) && !d.isAfter(today);
              }).fold<double>(
                      0.0,
                      (sum, p) =>
                          sum +
                          (double.tryParse(p["amount"].toString()) ?? 0.0)) ??
              0.0;

          totalCurrentMonthPayments1 += monthPayments;

          // 3) MONTH DEBIT (1st of month → today)
          double monthExpenses = (bankData["banks"] as List<dynamic>?)?.where(
                  (b) {
                final d = _toDateOnly(b["expense_date"]);
                if (d == null) return false;
                // from monthStart up to today (inclusive)
                return !d.isBefore(monthStart) && !d.isAfter(today);
              }).fold<double>(
                  0.0,
                  (sum, b) =>
                      sum + (double.tryParse(b["amount"].toString()) ?? 0.0)) ??
              0.0;

          totalCurrentMonthExpenses1 += monthExpenses;

          // 4) MONTH CLOSING (as of today)
          double monthClosing = monthOpening + monthPayments - monthExpenses;
          currentMonthClosing += monthClosing;

          // ADD PER-BANK ROW FOR EXPORT/TABLE IF NEEDED
          financeList.add({
            "Bank Name": bankName,

            // DAILY
            "Opening Balance": adjustedOpeningBalance.toStringAsFixed(2),
            "Closing Balance": closingBalance.toStringAsFixed(2),
            "Today Credit": todayPayments.toStringAsFixed(2),
            "Today Debit": todayExpenses.toStringAsFixed(2),

            // MONTHLY
            "Current Month Opening": monthOpening.toStringAsFixed(2),
            "Current Month Closing": monthClosing.toStringAsFixed(2),
            "Current Month Credit": monthPayments.toStringAsFixed(2),
            "Current Month Debit": monthExpenses.toStringAsFixed(2),
          });
        }

        // UPDATE UI
        setState(() {
          Finance1 = financeList;

          // DAILY
          totalAdjustedOpeningBalance = totalAdjustedOpeningBalance;
          totalClosingBalance = totalClosingBalance;
          totalTodayPayments = totalTodayPayments;
          totalTodayBanksAmount = totalTodayBanksAmount;

          // MONTHLY (MBR CARD)
          currentMonthOpening = currentMonthOpening;
          currentMonthClosing = currentMonthClosing;
          totalCurrentMonthPayments1 = totalCurrentMonthPayments1;
          totalCurrentMonthExpenses1 = totalCurrentMonthExpenses1;
        });
      }
    } catch (e) {}
  }

  double totalAdjustedOpeningBalance1 = 0.0;
  double totalClosingBalance1 = 0.0;
  double totalTodayPayments1 = 0.0;
  double totalTodayBanksAmount1 = 0.0;

// NEW: CURRENT MONTH TOTALS
  double totalCurrentMonthOpeningBalance = 0.0;
  double totalCurrentMonthPayments = 0.0;
  double totalCurrentMonthExpenses = 0.0;
  double totalCurrentMonthClosingBalance = 0.0;

  Future<void> getFinance_without_transfer() async {
    final token = await getTokenFromPrefs();

    // Reset all totals
    totalAdjustedOpeningBalance1 = 0.0;
    totalClosingBalance1 = 0.0;
    totalTodayPayments1 = 0.0;
    totalTodayBanksAmount1 = 0.0;

    totalCurrentMonthOpeningBalance = 0.0;
    totalCurrentMonthPayments = 0.0;
    totalCurrentMonthExpenses = 0.0;
    totalCurrentMonthClosingBalance = 0.0;

    try {
      final response = await http.get(
        Uri.parse('$api/api/finance-report/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        final DateTime currentDate = DateTime.now();
        final DateTime today =
            DateTime(currentDate.year, currentDate.month, currentDate.day);
        final DateTime monthStart = DateTime(today.year, today.month, 1);

        List<Map<String, dynamic>> financeList = [];

        for (var bankData in parsed['bank_data'] ?? []) {
          String bankName = bankData['name'] ?? 'Unknown Bank';

          double openBalance =
              (bankData['open_balance'] as num?)?.toDouble() ?? 0.0;

          // ========== PREVIOUS DAY OPENING BALANCE CALCULATION ==========
          double totalPaymentsBeforeToday =
              (bankData['payments'] as List<dynamic>?)?.where((payment) {
                    final dt = DateTime.tryParse(payment['received_at'] ?? '');
                    if (dt == null) return false;
                    return DateTime(dt.year, dt.month, dt.day).isBefore(today);
                  }).fold(0.0, (sum, payment) {
                    return sum! +
                        (double.tryParse(payment['amount'] ?? '') ?? 0.0);
                  }) ??
                  0.0;

          double totalBankExpensesBeforeToday =
              (bankData['banks'] as List<dynamic>?)?.where((bank) {
                    final dt = DateTime.tryParse(bank['expense_date'] ?? '');
                    if (dt == null) return false;
                    return DateTime(dt.year, dt.month, dt.day).isBefore(today);
                  }).fold(0.0, (sum, bank) {
                    return sum! +
                        (double.tryParse(bank['amount'] ?? '') ?? 0.0);
                  }) ??
                  0.0;

          double adjustedOpeningBalance = openBalance +
              totalPaymentsBeforeToday -
              totalBankExpensesBeforeToday;

          totalAdjustedOpeningBalance1 += adjustedOpeningBalance;

          // ========== TODAY PAYMENTS ==========
          double todayPayments =
              (bankData['payments'] as List<dynamic>?)?.where((payment) {
                    final dt = DateTime.tryParse(payment['received_at'] ?? '');
                    if (dt == null) return false;
                    final d = DateTime(dt.year, dt.month, dt.day);
                    return d.isAtSameMomentAs(today);
                  }).fold(0.0, (sum, payment) {
                    return sum! +
                        (double.tryParse(payment['amount'] ?? '') ?? 0.0);
                  }) ??
                  0.0;

          totalTodayPayments1 += todayPayments;

          // ========== TODAY BANK EXPENSES ==========
          double todayBanksAmount =
              (bankData['banks'] as List<dynamic>?)?.where((bank) {
                    final dt = DateTime.tryParse(bank['expense_date'] ?? '');
                    if (dt == null) return false;
                    final d = DateTime(dt.year, dt.month, dt.day);
                    return d.isAtSameMomentAs(today);
                  }).fold(0.0, (sum, bank) {
                    return sum! +
                        (double.tryParse(bank['amount'] ?? '') ?? 0.0);
                  }) ??
                  0.0;

          totalTodayBanksAmount1 += todayBanksAmount;

          // ========== TODAY CLOSING BALANCE ==========
          double closingBalance =
              adjustedOpeningBalance + todayPayments - todayBanksAmount;
          totalClosingBalance1 += closingBalance;

          // ========================================================================
          //                        CURRENT MONTH CALCULATIONS
          // ========================================================================

          // Payments before month start
          double paymentsBeforeMonthStart =
              (bankData['payments'] as List<dynamic>?)?.where((payment) {
                    final dt = DateTime.tryParse(payment['received_at'] ?? '');
                    if (dt == null) return false;

                    final d = DateTime(dt.year, dt.month, dt.day);
                    return d.isBefore(monthStart);
                  }).fold(0.0, (sum, payment) {
                    return sum! +
                        (double.tryParse(payment['amount'] ?? '') ?? 0.0);
                  }) ??
                  0.0;

          // Expenses before month start
          double expensesBeforeMonthStart =
              (bankData['banks'] as List<dynamic>?)?.where((bank) {
                    final dt = DateTime.tryParse(bank['expense_date'] ?? '');
                    if (dt == null) return false;

                    final d = DateTime(dt.year, dt.month, dt.day);
                    return d.isBefore(monthStart);
                  }).fold(0.0, (sum, bank) {
                    return sum! +
                        (double.tryParse(bank['amount'] ?? '') ?? 0.0);
                  }) ??
                  0.0;

          // CURRENT MONTH OPENING BALANCE
          double monthOpeningBalance =
              openBalance + paymentsBeforeMonthStart - expensesBeforeMonthStart;

          totalCurrentMonthOpeningBalance += monthOpeningBalance;

          // CURRENT MONTH PAYMENTS
          double currentMonthPayments =
              (bankData['payments'] as List<dynamic>?)?.where((payment) {
                    final dt = DateTime.tryParse(payment['received_at'] ?? '');
                    if (dt == null) return false;

                    final d = DateTime(dt.year, dt.month, dt.day);
                    return !d.isBefore(monthStart) && !d.isAfter(today);
                  }).fold(0.0, (sum, payment) {
                    return sum! +
                        (double.tryParse(payment['amount'] ?? '') ?? 0.0);
                  }) ??
                  0.0;

          totalCurrentMonthPayments += currentMonthPayments;

          // CURRENT MONTH EXPENSES
          double currentMonthExpenses =
              (bankData['banks'] as List<dynamic>?)?.where((bank) {
                    final dt = DateTime.tryParse(bank['expense_date'] ?? '');
                    if (dt == null) return false;

                    final d = DateTime(dt.year, dt.month, dt.day);
                    return !d.isBefore(monthStart) && !d.isAfter(today);
                  }).fold(0.0, (sum, bank) {
                    return sum! +
                        (double.tryParse(bank['amount'] ?? '') ?? 0.0);
                  }) ??
                  0.0;

          totalCurrentMonthExpenses += currentMonthExpenses;

          // CURRENT MONTH CLOSING BALANCE
          double monthClosingBalance =
              monthOpeningBalance + currentMonthPayments - currentMonthExpenses;

          totalCurrentMonthClosingBalance += monthClosingBalance;

          // FINANCE LIST ENTRY
          financeList.add({
            'Bank Name': bankName,
            'Opening Balance': adjustedOpeningBalance.toStringAsFixed(2),
            'Closing Balance': closingBalance.toStringAsFixed(2),
            'Credit': todayPayments.toStringAsFixed(2),
            'Debit': todayBanksAmount.toStringAsFixed(2),

            // MONTH-WISE DETAILS
            'Month Opening': monthOpeningBalance.toStringAsFixed(2),
            'Month Credit': currentMonthPayments.toStringAsFixed(2),
            'Month Debit': currentMonthExpenses.toStringAsFixed(2),
            'Month Closing': monthClosingBalance.toStringAsFixed(2),
          });
        }

        setState(() {
          Finance = List<Map<String, dynamic>>.from(financeList);

          totalAdjustedOpeningBalance1 = totalAdjustedOpeningBalance1;
          totalClosingBalance1 = totalClosingBalance1;
          totalTodayPayments1 = totalTodayPayments1;
          totalTodayBanksAmount1 = totalTodayBanksAmount1;

          // SET MONTH TOTALS
          totalCurrentMonthOpeningBalance = totalCurrentMonthOpeningBalance;
          totalCurrentMonthPayments = totalCurrentMonthPayments;
          totalCurrentMonthExpenses = totalCurrentMonthExpenses;
          totalCurrentMonthClosingBalance = totalCurrentMonthClosingBalance;
        });

        fetchInternalTransfersData();
      } else {
        setState(() {
          Finance = [];
        });
      }
    } catch (e) {}
  }

  double calculateMonthlyInternalTransferAmount(List<dynamic> transfers) {
    final now = DateTime.now();
    double total = 0.0;

    for (final transfer in transfers) {
      final createdAt =
          DateTime.tryParse(transfer['created_at'] ?? "")?.toLocal();
      if (createdAt == null) continue;

      if (createdAt.year == now.year && createdAt.month == now.month) {
        total += double.tryParse(transfer['amount'].toString()) ?? 0.0;
      }
    }
    return total;
  }

  Future<void> getSalesReport() async {
    setState(() {}); // Keep the loading state if needed
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/salesreport/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        // Corrected the key
        var salesData = parsed['sales_report'];

        if (salesData != null && salesData is Iterable) {
          List<Map<String, dynamic>> salesReportDataList = [];
          for (var reportData in salesData) {
            salesReportDataList.add({
              'date': reportData['date'],
              'total_bills_in_date': reportData['total_bills_in_date'],
              'amount': reportData['amount'],
              'approved': {
                'bills': reportData['approved']['bills'],
                'amount': reportData['approved']['amount']
              },
              'rejected': {
                'bills': reportData['rejected']['bills'],
                'amount': reportData['rejected']['amount']
              }
            });
          }

          setState(() {
            salesReportList = salesReportDataList;
          });
          getTodaysBills(); // Get today's bills count
        }
      }
    } catch (error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('An error occurred while fetching data')),
        // );
      });
    } finally {
      setState(() {}); // End loading state
    }
  }

  var totalbills = "0";
  void getTodaysBills() {
    // Get today's date in the same format as in the response (yyyy-MM-dd)
    String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Find today's report entry
    var todaysReport = salesReportList.firstWhere(
      (report) => report['date'] == currentDate,
      orElse: () => {}, // Return null if no report for today
    );
    setState(() {
      if (todaysReport['total_bills_in_date'] != null) {
        totalbills = todaysReport['total_bills_in_date'].toString();
        ;
      } else {
        totalbills = '0'; // Return '0' if no report is found for today
      }
    });
  }

  Future<void> fetchproformaData() async {
    try {
      final token = await getTokenFromPrefs();
      final response = await http.get(
        Uri.parse('$api/api/perfoma/invoices/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
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

        setState(() {
          proforma = performaInvoiceList;
        });
        int proformalistcount = proforma.length;
      } else {}
    } catch (error) {}
  }

// Get token from SharedPreferences
  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  int grv = 0;
  int grvcount = 0;
// Function to fetch GRV data
  Future<void> getGrvList() async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/grv/data/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      ;
      ;
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        List<Map<String, dynamic>> grvDataList = [];
        for (var productData in productsData) {
          grvDataList.add({
            'id': productData['id'],
            'product': productData['product'],
            'returnreason': productData['returnreason'],
            'invoice': productData['invoice'],
            'customer': productData['customer'],
            'staff': productData['staff'],
            'remark': productData['remark'],
            'status': productData['status'] ?? statusOptions[0],
            'order_date': productData['order_date'],
          });
          if (productData['status'] == "pending") {
            grv = grv + 1;
          }
        }
        setState(() {
          grvlist = grvDataList;
          grvcount = grv;
        });

        // Get the count of grvlist
        int grvListCount = grvlist.length;
      } else {}
    } catch (error) {}
  }

  Future<void> getdgm() async {
    try {
      final token = await getTokenFromPrefs();

      if (token == null) return;

      setState(() {
        dgmLoading = true;
      });

      final response = await http.get(
        Uri.parse('$api/api/warehouse/get/summary/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        final Map<String, dynamic> todaySummary =
            Map<String, dynamic>.from(parsed['today_summary'] ?? {});
        final Map<String, dynamic> currentMonthSummary =
            Map<String, dynamic>.from(parsed['current_month_summary'] ?? {});
        final Map<String, dynamic> data =
            Map<String, dynamic>.from(parsed['data'] ?? {});

        List<Map<String, dynamic>> rows = [];

        data.forEach((serviceName, serviceValue) {
          final Map<String, dynamic> today =
              Map<String, dynamic>.from(serviceValue['today'] ?? {});

          final int boxes = (today['total_boxes'] ?? 0) is int
              ? today['total_boxes']
              : int.tryParse(today['total_boxes'].toString()) ?? 0;

          if (boxes == 0) return;

          rows.add({
            'service': serviceName.toString(),
            'boxes': boxes,
            'total_post_office_weight_kg': ((today['total_weight_field_kg'] ??
                    today['total_weight_field'] ??
                    0) as num)
                .toDouble(),
            'total_actual_weight_kg':
                ((today['total_actual_weight_kg'] ?? 0) as num).toDouble(),
            'volume_kg': ((today['total_volume'] ?? 0) as num).toDouble(),
            'total_tracking_amount':
                ((today['total_parcel_amount'] ?? 0) as num).toDouble(),
            'total_avg': ((today['average'] ?? 0) as num).toDouble(),
          });
        });

        rows.sort((a, b) =>
            a['service'].toString().compareTo(b['service'].toString()));

        setState(() {
          dgmTodaySummary = todaySummary;
          dgmCurrentMonthSummary = currentMonthSummary;
          dgmTodayRows = rows;

          // keeping your old variables too, if used elsewhere
          parcelData = {
            for (final row in rows)
              row['service']: {
                "box": row['boxes'],
                "total_actual_weight": row['total_actual_weight_kg'],
                "total_weight": row['total_post_office_weight_kg'],
                "total_parcel_amount": row['total_tracking_amount'],
                "total_volume": row['volume_kg'],
              }
          };

          monthTotalActualWeight =
              ((currentMonthSummary["total_actual_weight_kg"] ?? 0) as num)
                  .toDouble();
          totalvolumee =
              ((currentMonthSummary["total_volume"] ?? 0) as num).toDouble();
          totalbox =
              ((currentMonthSummary["total_boxes"] ?? 0) as num).toDouble();
          monthTotalWeight = ((currentMonthSummary["total_weight_field_kg"] ??
                  currentMonthSummary["total_weight_field"] ??
                  0) as num)
              .toDouble();
          monthTotalParcelAmount =
              ((currentMonthSummary["total_parcel_amount"] ?? 0) as num)
                  .toDouble();
          monthAverage =
              ((currentMonthSummary["average"] ?? 0) as num).toDouble();

          dgmLoading = false;
        });
      } else {
        setState(() {
          dgmLoading = false;
          dgmTodayRows = [];
          dgmTodaySummary = {};
          dgmCurrentMonthSummary = {};
        });
      }
    } catch (e) {
      setState(() {
        dgmLoading = false;
        dgmTodayRows = [];
        dgmTodaySummary = {};
        dgmCurrentMonthSummary = {};
      });
    }
  }

  var toprint = 0;
  var readtoship = 0;
  var shipped = 0;

  Future<void> getsalescount() async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/orders/status/count/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        // IMPORTANT: API returns "today"
        List<dynamic> data = parsed['today'] ?? [];

        int toPrintCount = 0;
        int readyToShipCount = 0;
        int shippedCount = 0;

        for (var item in data) {
          final status = item['status']?.toString() ?? "";
          final count = item['count'] ?? 0;

          if (status == "To Print") {
            toPrintCount = count;
          } else if (status == "Ready to ship") {
            readyToShipCount = count;
          } else if (status == "Shipped") {
            shippedCount = count;
          }
        }

        setState(() {
          toprint = toPrintCount;
          readtoship = readyToShipCount;
          shipped = shippedCount;
        });
      }
    } catch (error) {}
  }

  Future<void> getdata() async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/orders/summary/family/data/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        setState(() {
          productsData = parsed['overall'];
        });
      } else {}
    } catch (error) {}
  }

  // Retrieve the username from SharedPreferences
  Future<void> _getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ??
          'Guest'; // Default to 'Guest' if no username
    });
  }

  List<Map<String, dynamic>> parcel = [];
  Map<String, Map<String, dynamic>> parcelData = {};
  String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  double monthTotalActualWeight = 0.0;
  double monthTotalParcelAmount = 0.0;
  double monthTotalWeight = 0.0;
  double totalvolumee = 0.0;
  double totalbox = 0.0;

  DateTime? selectedDate; // For single date filter
  Future<void> fetchorders() async {
    final token = await getTokenFromPrefs();

    if (token == null || token.isEmpty) {
      return;
    }

    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.trim()) ?? 0.0;
      return 0.0;
    }

    final now = DateTime.now();
    final targetYear = now.year;
    final targetMonth = now.month;

    try {
      final response = await http.get(
        Uri.parse('$api/api/warehouse/get/'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final orderdata = parsed['results'] ?? [];

        parcelData.clear();

        double _monthTotalActualWeight = 0.0;
        double _monthTotalParcelAmount = 0.0;
        double _monthTotalWeight = 0.0;

        for (final order in orderdata) {
          final warehouses = order['warehouses'];
          if (warehouses == null || warehouses is! List) continue;

          for (final wh in warehouses) {
            final String parcelService =
                (wh['parcel_service'] ?? '').toString().trim();
            final String postofficeDateStr =
                (wh['postoffice_date'] ?? '').toString().trim();

            if (parcelService.isEmpty || postofficeDateStr.isEmpty) continue;

            final poDate = DateTime.tryParse(postofficeDateStr);
            if (poDate == null) continue;
            if (poDate.year != targetYear || poDate.month != targetMonth)
              continue;

            final double actualWeight = _toDouble(wh['actual_weight']);
            final double parcelAmount = _toDouble(wh['parcel_amount']);
            final double weight = _toDouble(wh['weight']);

            parcelData.putIfAbsent(
                parcelService,
                () => {
                      'total_actual_weight': 0.0,
                      'total_parcel_amount': 0.0,
                      'total_weight': 0.0,
                    });

            parcelData[parcelService]!['total_actual_weight'] =
                (parcelData[parcelService]!['total_actual_weight'] as double) +
                    actualWeight;

            parcelData[parcelService]!['total_parcel_amount'] =
                (parcelData[parcelService]!['total_parcel_amount'] as double) +
                    parcelAmount;

            parcelData[parcelService]!['total_weight'] =
                (parcelData[parcelService]!['total_weight'] as double) + weight;

            _monthTotalActualWeight += actualWeight;
            _monthTotalParcelAmount += parcelAmount;
            _monthTotalWeight += weight;
          }
        }

        if (!mounted) return;
        setState(() {
          monthTotalActualWeight = _monthTotalActualWeight;
          monthTotalParcelAmount = _monthTotalParcelAmount;
          monthTotalWeight = _monthTotalWeight;
        });
      } else {
        if (!mounted) return;
        setState(() {
          parcelData.clear();
          monthTotalActualWeight = 0.0;
          monthTotalParcelAmount = 0.0;
          monthTotalWeight = 0.0;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        parcelData.clear();
        monthTotalActualWeight = 0.0;
        monthTotalParcelAmount = 0.0;
        monthTotalWeight = 0.0;
      });
    }
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // await prefs.remove('userId');
    // await prefs.remove('token');
    // await prefs.remove('username');
    //   await prefs.remove('department');

    // Use a post-frame callback to show the SnackBar after the current frame
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (ScaffoldMessenger.of(context).mounted) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(
    //         content: Text('Logged out successfully'),
    //         duration: Duration(seconds: 2),
    //       ),
    //     );
    //   }
    // });

    // // Wait for the SnackBar to disappear before navigating
    // await Future.delayed(Duration(seconds: 2));

    // Navigate to the HomePage after the snackbar is shown
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => login()),
    );
  }

  drower d = drower();

  Widget _buildDropdownTile(
      BuildContext context, String title, List<String> options) {
    return ExpansionTile(
      backgroundColor: Colors.white,
      collapsedBackgroundColor: Colors.white,
      iconColor: Colors.black,
      collapsedIconColor: Colors.black,
      title: Text(
        title,
        style: const TextStyle(color: Colors.black),
      ),
      children: options.map((option) {
        return ListTile(
          tileColor: Colors.white,
          title: Text(
            option,
            style: const TextStyle(color: Colors.black),
          ),
          onTap: () {
            Navigator.pop(context);
            d.navigateToSelectedPage(context, option);
          },
        );
      }).toList(),
    );
  }

  Widget buildFamilyAnalysisCards() {
    if (familyAnalysisLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (familyAnalysisCards.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF02347C), Color(0xFF82E49D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Text(
            "No family analysis data available",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final String todayText = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Column(
      children: familyAnalysisCards.map((item) {
        final fromDate = (item['from_date'] ?? '').toString();
        final toDate = (item['to_date'] ?? '').toString();

        String selectedDateText = todayText;
        if (fromDate.isNotEmpty || toDate.isNotEmpty) {
          selectedDateText =
              "${fromDate.isEmpty ? todayText : fromDate} to ${toDate.isEmpty ? todayText : toDate}";
        }

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FamilyWiseAnalysisDetailsPage(
                  familyId: item['family_id'] ?? 0,
                  familyName: (item['family_name'] ?? '').toString(),
                  startDate:
                      familyAnalysisSelectedRange?.start ?? DateTime.now(),
                  endDate: familyAnalysisSelectedRange?.end ?? DateTime.now(),
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF02347C), Color(0xFF82E49D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "BDO Call Duration Report",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: pickFamilyAnalysisDateRange,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(
                          Icons.calendar_month,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: (item['family_name'] ?? '')
                            .toString()
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: " ($selectedDateText)",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "Present",
                        "${item['present'] ?? 0}",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "Absent",
                        "${item['absent'] ?? 0}",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "Half Day",
                        "${item['half_day'] ?? 0}",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "Amount",
                        "₹${item['total_amount'] ?? 0}",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "Invoices",
                        "${item['total_invoices'] ?? 0}",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "Total Calls",
                        "${item['total_call_count'] ?? 0}",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "Avg Duration",
                        "${item['call_duration_average_minutes'] ?? 0} min",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "8hr %",
                        "${item['call_duration_average_percentage_8hrs'] ?? 0}%",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _tableHeader(String text, {double fontSize = 12}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _tableCell(
    String text, {
    bool isBold = false,
    TextAlign align = TextAlign.center,
    Color color = Colors.white,
    double fontSize = 11.5,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDouble(dynamic value, {int decimals = 2}) {
    final number = (value ?? 0) is num
        ? (value as num).toDouble()
        : double.tryParse(value.toString()) ?? 0.0;
    return number.toStringAsFixed(decimals);
  }

  String _formatCurrency(dynamic value) {
    final number = (value ?? 0) is num
        ? (value as num).toDouble()
        : double.tryParse(value.toString()) ?? 0.0;

    return "₹${number.toStringAsFixed(2)}";
  }

  Widget buildDailyGoodsMovementTableCard() {
    if (dgmLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF02347C), Color(0xFF82E49D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final int totalDgmBoxes =
        ((dgmTodaySummary['total_boxes'] ?? 0) as num?)?.toInt() ?? 0;

    final double totalDgmPostOfficeWeight =
        ((dgmTodaySummary['total_weight_field_kg'] ??
                    dgmTodaySummary['total_weight_field'] ??
                    0) as num?)
                ?.toDouble() ??
            0.0;

    final double totalDgmActualWeight =
        ((dgmTodaySummary['total_actual_weight_kg'] ?? 0) as num?)
                ?.toDouble() ??
            0.0;

    final double totalDgmVolume =
        ((dgmTodaySummary['total_volume'] ?? 0) as num?)?.toDouble() ?? 0.0;

    final double totalDgmTracking =
        ((dgmTodaySummary['total_parcel_amount'] ?? 0) as num?)?.toDouble() ??
            0.0;

    final double totalDgmAvg =
        ((dgmTodaySummary['average'] ?? 0) as num?)?.toDouble() ?? 0.0;

    final int currentMonthBoxes =
        ((dgmCurrentMonthSummary['total_boxes'] ?? 0) as num?)?.toInt() ?? 0;

    final double currentMonthPostOfficeWeight =
        ((dgmCurrentMonthSummary['total_weight_field_kg'] ??
                    dgmCurrentMonthSummary['total_weight_field'] ??
                    0) as num?)
                ?.toDouble() ??
            0.0;

    final double currentMonthActualWeight =
        ((dgmCurrentMonthSummary['total_actual_weight_kg'] ?? 0) as num?)
                ?.toDouble() ??
            0.0;

    final double currentMonthVolume =
        ((dgmCurrentMonthSummary['total_volume'] ?? 0) as num?)?.toDouble() ??
            0.0;

    final double currentMonthTracking =
        ((dgmCurrentMonthSummary['total_parcel_amount'] ?? 0) as num?)
                ?.toDouble() ??
            0.0;

    final double currentMonthAvg =
        ((dgmCurrentMonthSummary['average'] ?? 0) as num?)?.toDouble() ?? 0.0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => daily_goods_movement(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF02347C), Color(0xFF82E49D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Daily Goods Movement (DGM)",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Divider(color: Colors.white54, height: 1),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  border: TableBorder.all(
                    color: Colors.white70,
                    width: 1,
                  ),
                  columnWidths: const {
                    0: FixedColumnWidth(165),
                    1: FixedColumnWidth(95),
                    2: FixedColumnWidth(170),
                    3: FixedColumnWidth(170),
                    4: FixedColumnWidth(130),
                    5: FixedColumnWidth(165),
                    6: FixedColumnWidth(130),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                      ),
                      children: [
                        _tableHeader("Service", fontSize: 13),
                        _tableHeader("Boxes", fontSize: 13),
                        _tableHeader("Total Post Office Weight\n(kg)",
                            fontSize: 13),
                        _tableHeader("Total Actual Weight (kg)", fontSize: 13),
                        _tableHeader("Volume (Kg)", fontSize: 13),
                        _tableHeader("Total Tracking Amount", fontSize: 13),
                        _tableHeader("Total Avg (₹/kg)", fontSize: 13),
                      ],
                    ),
                    ...dgmTodayRows.map(
                      (row) => TableRow(
                        children: [
                          _tableCell(row['service'].toString()),
                          _tableCell("${row['boxes']}"),
                          _tableCell(_formatDouble(
                              row['total_post_office_weight_kg'])),
                          _tableCell(
                              _formatDouble(row['total_actual_weight_kg'])),
                          _tableCell(_formatDouble(row['volume_kg'])),
                          _tableCell(
                              _formatCurrency(row['total_tracking_amount'])),
                          _tableCell(_formatDouble(row['total_avg'])),
                        ],
                      ),
                    ),
                    TableRow(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                      ),
                      children: [
                        _tableCell("TODAY'S TOTAL (DGM)",
                            isBold: true, align: TextAlign.left),
                        _tableCell("$totalDgmBoxes", isBold: true),
                        _tableCell(_formatDouble(totalDgmPostOfficeWeight),
                            isBold: true),
                        _tableCell(_formatDouble(totalDgmActualWeight),
                            isBold: true),
                        _tableCell(_formatDouble(totalDgmVolume), isBold: true),
                        _tableCell(_formatCurrency(totalDgmTracking),
                            isBold: true),
                        _tableCell(_formatDouble(totalDgmAvg), isBold: true),
                      ],
                    ),
                    TableRow(
                      decoration: BoxDecoration(
                        color: Colors.green,
                      ),
                      children: [
                        _tableCell("CURRENT MONTH (MGM)",
                            isBold: true,
                            align: TextAlign.left,
                            fontSize: 12.5),
                        _tableCell("$currentMonthBoxes",
                            isBold: true, fontSize: 12.5),
                        _tableCell(_formatDouble(currentMonthPostOfficeWeight),
                            isBold: true, fontSize: 12.5),
                        _tableCell(_formatDouble(currentMonthActualWeight),
                            isBold: true, fontSize: 12.5),
                        _tableCell(_formatDouble(currentMonthVolume),
                            isBold: true, fontSize: 12.5),
                        _tableCell(_formatCurrency(currentMonthTracking),
                            isBold: true, fontSize: 12.5),
                        _tableCell(_formatDouble(currentMonthAvg),
                            isBold: true, fontSize: 12.5),
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

  Widget buildBdoStatewiseCard({
    required String title,
    required List<Map<String, dynamic>> data,
    required bool loading,
    required bool isDaily,
  }) {
    final filteredData = data.where((familyItem) {
      final family =
          (familyItem['family'] ?? '').toString().toLowerCase().trim();
      return family == "skating" || family == "cycling";
    }).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF02347C), Color(0xFF82E49D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isDaily
                ? "Date: $selectedDailyDate"
                : "Period: $monthlyStartDate to $monthlyEndDate",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const Divider(color: Colors.white54),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else if (filteredData.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  "No skating/cycling data available",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          else
            Column(
              children: filteredData.map((familyItem) {
                final familyName =
                    (familyItem['family'] ?? '').toString().toUpperCase();
                final familyTotal =
                    (familyItem['family_total'] as num?)?.toDouble() ?? 0.0;
                final familyBills =
                    (familyItem['family_bill_total'] as num?)?.toInt() ?? 0;

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => bdostatewisedetailspage(
                          title:
                              "${isDaily ? "Daily" : "Monthly"} BDO Statewise Report",
                          familyName: familyItem['family'] ?? '',
                          states: List<Map<String, dynamic>>.from(
                            familyItem['states'] ?? [],
                          ),
                          familyTotal: familyTotal,
                          familyBillTotal: familyBills,
                          isDaily: isDaily,
                          dateLabel: isDaily
                              ? selectedDailyDate
                              : "$monthlyStartDate to $monthlyEndDate",
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white24,
                          child: Text(
                            familyName.isNotEmpty ? familyName[0] : "-",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                familyName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Bills: $familyBills",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "Family Total",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              "₹ ${familyTotal.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget buildBdmFamilyCards() {
    if (bdmOverallLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (ceoFamilyCards.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF02347C), Color(0xFF82E49D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "BDO Call Duration Report",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Date: $selectedBdmReportDate",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  "No BDM family report available",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(ceoFamilyCards.length, (index) {
        final item = ceoFamilyCards[index];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF02347C), Color(0xFF82E49D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "BDO Call Duration Report",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Date: $selectedBdmReportDate",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BdmFamilyDetailsPage(
                        familyData: item,
                        startDate: bdmStartDate ?? DateTime.now(),
                        endDate: bdmEndDate ?? DateTime.now(),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (item['family_name'] ?? '').toString().toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFamilyMetricTile(
                              "Active",
                              "${item['bdo_present_count']}",
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFamilyMetricTile(
                              "Non Active",
                              "${item['bdo_absent_count']}",
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFamilyMetricTile(
                              "Half Day",
                              "${item['bdo_half_day_count']}",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFamilyMetricTile(
                              "Total Bill",
                              "${item['total_bill']}",
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFamilyMetricTile(
                              "Total Volume",
                              "₹${item['total_volume']}",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFamilyMetricTile(
                              "Avg. Call Duration",
                              "${item['average_call_duration_minutes']} mins",
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFamilyMetricTile(
                              "Percentage",
                              "${item['call_duration_average']} %",
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget buildFilteredCategoryProductCard() {
    if (filteredCategoryLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final displayList = showAllCategories
        ? filteredCategoryProducts
        : filteredCategoryProducts.take(5).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF02347C), Color(0xFF82E49D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Category Wise Products",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Date: $categoryStartDate to $categoryEndDate",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          if (filteredCategoryProducts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  "No category data available",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else ...[
            Table(
              border: TableBorder.all(color: Colors.white30, width: 1),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        "Category",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        "Count",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                ...displayList.map((item) {
                  return TableRow(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryProductDetailsPage(
                                categoryId: item['category_id'],
                                categoryName: item['title'],
                                startDate: categoryStartDate,
                                endDate: categoryEndDate,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            item['title'].toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              // decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryProductDetailsPage(
                                categoryId: item['category_id'],
                                categoryName: item['title'],
                                startDate: categoryStartDate,
                                endDate: categoryEndDate,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            "${item['count'] ?? 0}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
            if (filteredCategoryProducts.length > 5)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      showAllCategories = !showAllCategories;
                    });
                  },
                  child: Text(
                    showAllCategories ? "See Less" : "See More",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayCount = _asInt(productsData?['today_count']);
    final totalvolume = _asInt(productsData?['today_total_amount']);
    final todaycod = _asInt(
        productsData?['payment_status_summary']['today']['COD']['count']);
    final todaycodamount = _asInt(
        productsData?['payment_status_summary']['today']['COD']['total']);
    final todaypaid = _asInt(
        productsData?['payment_status_summary']['today']['paid']['count']);
    final todaypaidamount = _asInt(
        productsData?['payment_status_summary']['today']['paid']['total']);
    final todaycredit = _asInt(
        productsData?['payment_status_summary']['today']['credit']['count']);
    final todaycreditamount = _asInt(
        productsData?['payment_status_summary']['today']['credit']['total']);

    final monthcount = _asInt(productsData?['month_count']);
    final monthtotalamount = _asInt(productsData?['month_total_amount']);
    final monthcod = _asInt(
        productsData?['payment_status_summary']['month']['COD']['count']);
    final monthcodamount = _asInt(
        productsData?['payment_status_summary']['month']['COD']['total']);
    final monthpaid = _asInt(
        productsData?['payment_status_summary']['month']['paid']['count']);
    final monthpaidamount = _asInt(
        productsData?['payment_status_summary']['month']['paid']['total']);
    final monthcredit = _asInt(
        productsData?['payment_status_summary']['month']['credit']['count']);
    final monthcreditamount = _asInt(
        productsData?['payment_status_summary']['month']['credit']['total']);
    final nonRejected =
        summary["non_rejected_orders"] ?? {"count": 0, "amount": 0.0};
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            // leading: Icon(Icons.arrow_back, color: Colors.black),
            actions: [
              //  IconButton(
              //     icon: Image.asset('lib/assets/profile.png'),

              //     onPressed: () {
              //       Navigator.push(context, MaterialPageRoute(builder: (context)=>EditProfileScreen()));

              //     },
              //   ),
            ],
          ),
          drawer: Drawer(
            backgroundColor: Colors.white,
            child: Container(
              color: Colors.white,
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
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
                  // ListTile(
                  //   leading: Icon(Icons.dashboard),
                  //   title: Text('Dashboard'),
                  //   onTap: () {
                  //     Navigator.push(context,
                  //         MaterialPageRoute(builder: (context) => Graph()));
                  //   },
                  // ),

                  _buildDropdownTile(context, 'Customers', [
                    'Add Customer',
                    'Customers',
                    'customer Transfer',
                    'customer Transfer list',
                    'Customer Type',
                  ]),
                  _buildDropdownTile(context, 'Recipt', [
                    'Add Recipt',
                    'Recipt List',
                    'Bank Recipt',
                    'Advance Recipt',
                    'Order Recipt',
                    'COD Transfer',
                    'COD Transfer List',
                  ]),

                  // ListTile(
                  //   leading: Icon(Icons.dashboard),
                  //   title: Text('Call Report'),
                  //   onTap: () {
                  //     Navigator.push(context,
                  //         MaterialPageRoute(builder: (context) => CallLog()));
                  //   },
                  // ),
                  _buildDropdownTile(context, 'Proforma Invoice', [
                    'New Proforma Invoice',
                    'Proforma Invoice List',
                  ]),
                  _buildDropdownTile(context, 'Delivery Note', [
                    'Delivery Note List(To Print)',
                    'Delivery Note List(Packing under Progress)',
                    'Delivery Note List(Packed)',
                    'Delivery Note List(Ready to ship)',
                    'Delivery Note List(Shipped)',
                    'Daily Goods Movement'
                  ]),
                  _buildDropdownTile(context, 'Orders', [
                    'New Orders',
                    'Orders List',
                    'Invoice Created',
                    'Invoice Approved',
                    'Waiting For Confirmation',
                    'To Print',
                    'Packing Under Progress',
                    'Packed',
                    'Ready to ship',
                    'Shipped',
                    'Invoice Rejected'
                  ]),
                  Divider(),
                  Text("Others"),
                  Divider(),
                  _buildDropdownTile(context, 'Purchase', [
                    'Product List',
                    'Purchase request',
                    'Purchase request List',
                    'Product Add',
                  ]),
                  _buildDropdownTile(context, 'Expence', [
                    'Add Expence',
                    'Expence List',
                  ]),
                  _buildDropdownTile(
                      context, 'GRV', ['Create New GRV', 'GRVs List']),
                  _buildDropdownTile(context, 'Internal Transfer',
                      ['Add Transfer', 'Transfer List']),

                  _buildDropdownTile(context, 'Daily Sales Reports',
                      ['Add Team', 'Team wise Report']),

                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Purchase Invoice'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  CreatePurchaseProductList()));
                      // Navigate to the Settings page or perform any other action
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Purchase Invoice List'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SellerInvoiceListPage()));
                      // Navigate to the Settings page or perform any other action
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Activit Log'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Activity_log()));
                      // Navigate to the Settings page or perform any other action
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Bank Type'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => add_bank_type()));
                      // Navigate to the Settings page or perform any other action
                    },
                  ),
                  // ListTile(
                  //   leading: Icon(Icons.person),
                  //   title: Text('call Log'),
                  //   onTap: () {
                  //     Navigator.push(context,
                  //         MaterialPageRoute(builder: (context) => CallLog()));
                  //     // Navigate to the Settings page or perform any other action
                  //   },
                  // ),

                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Add Supplier'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => add_supplier()));
                      // Navigate to the Settings page or perform any other action
                    },
                  ),

                  //                       ListTile(
                  //               leading: Icon(Icons.person),
                  //               title: Text('Add Daily sales report'),
                  //               onTap: () {
                  //                 Navigator.push(context,
                  //                     MaterialPageRoute(builder: (context) => AddDailySalesReport()));
                  //                 // Navigate to the Settings page or perform any other action
                  //               },
                  //             ),

                  //               ListTile(
                  //               leading: Icon(Icons.person),
                  //               title: Text('Daily BDO sales report'),
                  //               onTap: () {
                  //                 Navigator.push(context,
                  //                     MaterialPageRoute(builder: (context) => DailySalesReportViewPage()));
                  //                 // Navigate to the Settings page or perform any other action
                  //               },
                  //             ),

                  //               ListTile(
                  //               leading: Icon(Icons.person),
                  //               title: Text('All Users sales report'),
                  //               onTap: () {
                  //                 Navigator.push(
                  //                     context,
                  //                     MaterialPageRoute(
                  //                         builder: (context) =>
                  //                             AllUsersDailySalesReportPage()));
                  //                 // Navigate to the Settings page or perform any other action
                  //               },
                  //             ),

                  //              ListTile(
                  //               leading: Icon(Icons.person),
                  //               title: Text('Categorywise sales report'),
                  //               onTap: () {
                  //                 Navigator.push(
                  //                     context,
                  //                     MaterialPageRoute(
                  //                         builder: (context) =>
                  //                             CategorywiseSalesReport()));
                  //                 // Navigate to the Settings page or perform any other action
                  //               },
                  //             ),
                  //  ListTile(
                  //               leading: Icon(Icons.person),
                  //               title: Text('All users Categorywise sales report'),
                  //               onTap: () {
                  //                 Navigator.push(
                  //                     context,
                  //                     MaterialPageRoute(
                  //                         builder: (context) =>
                  //                             UserwiseCategorywiseSalesReport()));
                  //                 // Navigate to the Settings page or perform any other action
                  //               },
                  //             ),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Company'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => add_company()));
                      // Navigate to the Settings page or perform any other action
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Country'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => add_country()));
                      // Navigate to the Settings page or perform any other action
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Currency'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => add_currency()));
                      // Navigate to the Settings page or perform any other action
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Approve Products'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Approve_products()));
                      // Navigate to the Settings page or perform any other action
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Add EMI'),
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => add_Emi()));
                      // Navigate to the Settings page or perform any other action
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Asset Management'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AssetManegment()));
                      // Navigate to the Settings page or perform any other action
                    },
                  ),

                  // ListTile(
                  //   leading: Icon(Icons.person),
                  //   title: Text('Product Stock Report Page'),
                  //   onTap: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (context) => ProductStockReportPage(
                  //           warehouseId: selectedWarehouseId,
                  //           fromDate: fromDate,
                  //           toDate: toDate,
                  //         ),
                  //       ),
                  //     );

                  //   },
                  // ),

                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Category'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => add_categories()));
                      // Navigate to the Settings page or perform any other action
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Bulk Upload Orders'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => UploadBulkProducts()));
                      // Navigate to the Settings page or perform any other action
                    },
                  ),

                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Bulk Upload Customers'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => UploadBulkcustomer()));
                      // Navigate to the Settings page or perform any other action
                    },
                  ),

                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Add Purpose of payment'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => add_purpose_of_payment()));
                      // Navigate to the Settings page or perform any other action
                    },
                  ),
                  //   ListTile(
                  //   leading: Icon(Icons.person),
                  //   title: Text('Bulk Upload'),
                  //   onTap: () {
                  //     Navigator.push(context,
                  //         MaterialPageRoute(builder: (context) => OrderBulkUpload()));
                  //     // Navigate to the Settings page or perform any other action
                  //   },
                  // ),

                  // ListTile(
                  //   leading: Icon(Icons.person),
                  //   title: Text('Add Team'),
                  //   onTap: () {
                  //     Navigator.push(context,
                  //         MaterialPageRoute(builder: (context) => AddTeam()));
                  //     // Navigate to the Settings page or perform any other action
                  //   },
                  // ),

                  // ListTile(
                  //   leading: Icon(Icons.person),
                  //   title: Text('Team wise Report'),
                  //   onTap: () {
                  //     Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //             builder: (context) => TeamWiseReport()));
                  //     // Navigate to the Settings page or perform any other action
                  //   },
                  // ),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Departments'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => add_department()));
                      // Navigate to the Settings page or perform any other action
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Supervisors'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => add_supervisor()));
                      // Navigate to the Settings page or perform any other action
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Division'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => add_family()));
                      // Navigate to the Settings page or perform any other action
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Bank'),
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => add_bank()));
                      // Navigate to the Settings page or perform any other action
                    },
                  ),

                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('States'),
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => add_state()));
                      // Navigate to the Settings page or perform any other action
                    },
                  ),

                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Warehouse'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => add_warehouse()));
                      // Navigate to the Settings page or perform any other action
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Attributes'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => add_attribute()));
                      // Navigate to the Settings page or perform any other action
                    },
                  ),

                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Services'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CourierServices()));
                      // Navigate to the Settings page or perform any other action
                    },
                  ),

                  //  ListTile(
                  //   leading: Icon(Icons.person),
                  //   title: Text('Delivery Notes'),
                  //   onTap: () {
                  //     Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //             builder: (context) => WarehouseOrderView(status: null,)));
                  //     // Navigate to the Settings page or perform any other action
                  //   },
                  // ),
                  Divider(),
                  ListTile(
                    // leading: Icon(Icons.skateboarding),
                    title: Text('Family Wise Excel Report'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  CyclingskatingCategoryDailyProductwiseReport()));
                      // Navigate to the Settings page or perform any other action
                    },
                  ),

                  ListTile(
                    title: Text('Daily Sales Report (DSR)'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  AllUsersDailySalesReportPage()));
                      // Navigate to the Settings page or perform any other action
                    },
                  ),

                  //   ListTile(
                  //   leading: Icon(Icons.person),
                  //   title: Text('Categorywise sales report'),
                  //   onTap: () {
                  //     Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //             builder: (context) => CategorywiseSalesReport()));
                  //     // Navigate to the Settings page or perform any other action
                  //   },
                  // ),

                  ListTile(
                    title: Text('Categorywise sales report'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  UserwiseCategorywiseSalesReport()));
                      // Navigate to the Settings page or perform any other action
                    },
                  ),

                  _buildDropdownTile(
                      context, 'BDO Daily Sales Report', ['BDO Call List']),

                  _buildDropdownTile(context, 'Reports', [
                    'Sales Report',
                    'Sales Report Excel',
                    'GST Report',
                    'Product Stock Report',
                    'Order Items Excel Report',
                    'Shipping Address Excel Report',
                    'Daily Product Sold Report',
                    // 'All Division Product Sale Report',
                    // 'Cycling & Skating Monthly Excel',
                    // 'Cycling & Skating Daily Excel',
                    'Tracking Report',
                    'Credit Sales Report',
                    'COD Sales Report',
                    'Statewise Sales Report',
                    'Expence Report',
                    'Delivery Report',
                    'Product Sale Report',
                    'Stock Report',
                    'Damaged Stock',
                    'Finance Report',
                    'Actual Delivery Report',
                  ]),

                  _buildDropdownTile(context, 'Staff', [
                    'Add Staff',
                    'Staff',
                    'Staff Exit Form',
                    'Staff Exit List',
                  ]),
                  // _buildDropdownTile(context, 'Credit Note', [
                  //   'Add Credit Note',
                  //   'Credit Note List',
                  // ]),

                  Divider(),

                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    onTap: () async {
                      await logoutUser(context);
                    },
                  ),
                  SizedBox(height: 50), // Add some space at the bottom
                ],
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Section
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => EditProfileScreen()),
                            );
                          },
                          child: CircleAvatar(
                            radius: 25,
                            backgroundImage: AssetImage(
                                'lib/assets/female.jpeg'), // Replace with your new image
                          ),
                        ),
                        SizedBox(width: 16),
                        Text(
                          '$username',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    dashboardCards(),

                    SizedBox(height: 10),

                    // Discount/Bonus Section
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blueAccent, Colors.lightBlueAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      padding:
                          EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date and Icon Row
                          Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                DateFormat('EEEE, dd MMMM yyyy')
                                    .format(DateTime.now()),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.95),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),

                          // Divider
                          Container(
                              height: 1, color: Colors.white.withOpacity(0.3)),
                          SizedBox(height: 16),

                          // Table: Metric | Value
                          Table(
                            border:
                                TableBorder.all(color: Colors.white, width: 1),
                            columnWidths: const {
                              0: FlexColumnWidth(2),
                              1: FlexColumnWidth(2),
                            },
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
                            children: [
                              // Header
                              // TableRow(
                              //   decoration: BoxDecoration(color: Colors.white24),
                              //   children: [
                              //     Padding(
                              //       padding: EdgeInsets.all(10),
                              //       child: Text(
                              //         "Metric",
                              //         style: TextStyle(
                              //           color: Colors.white,
                              //           fontWeight: FontWeight.bold,
                              //         ),
                              //       ),
                              //     ),
                              //     Padding(
                              //       padding: EdgeInsets.all(10),
                              //       child: Text(
                              //         "Value",
                              //         textAlign: TextAlign.right,
                              //         style: TextStyle(
                              //           color: Colors.white,
                              //           fontWeight: FontWeight.bold,
                              //         ),
                              //       ),
                              //     ),
                              //   ],
                              // ),

                              // Today's Bills (tappable)
                              TableRow(children: [
                                Padding(
                                  padding: EdgeInsets.all(10),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              today_OrderList(status: null),
                                        ),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Icon(Icons.receipt_long,
                                            size: 18, color: Colors.white70),
                                        SizedBox(width: 6),
                                        Text("Today's Bills",
                                            style:
                                                TextStyle(color: Colors.white)),
                                        SizedBox(width: 6),
                                        Icon(Icons.open_in_new,
                                            size: 14, color: Colors.white70),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Text(
                                    todayCount.toString(),
                                    textAlign: TextAlign.right,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ]),

                              // Total Volume
                              TableRow(children: [
                                Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Row(
                                    children: [
                                      Icon(Icons.stacked_bar_chart,
                                          size: 18, color: Colors.white70),
                                      SizedBox(width: 6),
                                      Text("Total Volume",
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Text(
                                    totalvolume.toString(),
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ]),

                              // Total Expense
                              TableRow(children: [
                                Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Row(
                                    children: [
                                      Icon(Icons.money_off_csred,
                                          size: 18, color: Colors.white70),
                                      SizedBox(width: 6),
                                      Text("Total Expense",
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Text(
                                    todayExpenseAmount.toString(),
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ]),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),

                    if (department == "COO")
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => OrderList2(
                                      status: "Waiting For Confirmation",
                                    )),
                          );
                        },
                        child: Container(
                          margin:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(
                                255, 0, 148, 246), // Light red background
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(255, 149, 205, 254)
                                    .withOpacity(0.2),
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.production_quantity_limits,
                                  color:
                                      const Color.fromARGB(255, 255, 255, 255),
                                  size: 28),
                              SizedBox(width: 7),
                              Text(
                                "$confirmcount - Waiting for Approval",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      const Color.fromARGB(255, 255, 255, 255),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // if (todayFamilyWiseSummary.isNotEmpty) ...[
                    //   /// COD + Paid Summary Box
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ceo_family_summary()),
                        );
                      },
                      child: Builder(builder: (context) {
                        int codOrderCount = 0;
                        double codTotalAmount = 0.0;
                        int paidOrderCount = 0;
                        double paidTotalAmount = 0.0;
                        int creditOrderCount = 0;
                        double creditTotalAmount = 0.0;

                        todayFamilyWiseSummary.forEach((key, value) {
                          codOrderCount += int.tryParse(
                                  value['cod_order_count'].toString()) ??
                              0;
                          codTotalAmount += double.tryParse(
                                  value['cod_total_amount'].toString()) ??
                              0.0;

                          paidOrderCount += int.tryParse(
                                  value['paid_order_count'].toString()) ??
                              0;
                          paidTotalAmount += double.tryParse(
                                  value['paid_total_amount'].toString()) ??
                              0.0;

                          creditOrderCount += int.tryParse(
                                  value['credit_order_count'].toString()) ??
                              0;
                          creditTotalAmount += double.tryParse(
                                  value['credit_total_amount'].toString()) ??
                              0.0;
                        });

                        int grandTotalOrders =
                            codOrderCount + paidOrderCount + creditOrderCount;
                        double grandTotalAmount = codTotalAmount +
                            paidTotalAmount +
                            creditTotalAmount;

                        return Container(
                          margin: EdgeInsets.only(
                              top: 8, left: 6, right: 6, bottom: 12),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF02347C), Color(0xFF82E49D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade100,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// Header Row
                              Row(
                                children: [
                                  Icon(Icons.payments,
                                      color: Colors.white, size: 15),
                                  SizedBox(width: 8),
                                  Text(
                                    "Today's Sales report",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.date_range,
                                      color: Colors.white, size: 15),
                                  SizedBox(width: 8),
                                  Text(
                                    "${DateFormat('dd/MM/yyyy').format(DateTime.now())}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Divider(color: Colors.white60),
                              SizedBox(height: 6),

                              /// Table Layout
                              Table(
                                border: TableBorder.all(
                                    color: Colors.white, width: 1),
                                columnWidths: const {
                                  0: FlexColumnWidth(2),
                                  1: FlexColumnWidth(1),
                                  2: FlexColumnWidth(2),
                                },
                                children: [
                                  /// Table Header
                                  TableRow(
                                    decoration:
                                        BoxDecoration(color: Colors.black26),
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.all(6),
                                        child: Text("Type",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white)),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(6),
                                        child: Text("Count",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white)),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(6),
                                        child: Text("Amount",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white)),
                                      ),
                                    ],
                                  ),

                                  /// COD Row
                                  TableRow(children: [
                                    Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Text("COD Orders",
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Text("$todaycod",
                                          textAlign: TextAlign.center,
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Text(
                                          "₹${todaycodamount.toStringAsFixed(2)}",
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white)),
                                    ),
                                  ]),

                                  /// Cash Row
                                  TableRow(children: [
                                    Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Text("Cash Orders",
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Text("$todaypaid",
                                          textAlign: TextAlign.center,
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Text(
                                          "₹${todaypaidamount.toStringAsFixed(2)}",
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white)),
                                    ),
                                  ]),

                                  /// Credit Row
                                  TableRow(children: [
                                    Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Text("Credit Orders",
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Text("$creditOrderCount",
                                          textAlign: TextAlign.center,
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Text(
                                          "₹${todaycreditamount.toStringAsFixed(2)}",
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white)),
                                    ),
                                  ]),

                                  /// Grand Total Row
                                  TableRow(
                                    decoration:
                                        BoxDecoration(color: Colors.black26),
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.all(6),
                                        child: Text("Grand Total",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white)),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(6),
                                        child: Text("$todayCount",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white)),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(6),
                                        child: Text(
                                            "₹${totalvolume.toStringAsFixed(2)}",
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ),

                    // Column(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     GestureDetector(
                    //       onTap: () {
                    //         Navigator.push(
                    //           context,
                    //           MaterialPageRoute(
                    //               builder: (context) => today_OrderList(
                    //                     status: null,
                    //                   )),
                    //         );
                    //       },
                    //       child: Builder(
                    //         builder: (context) {
                    //           return TweenAnimationBuilder<Offset>(
                    //               duration: Duration(milliseconds: 300),
                    //               tween: Tween<Offset>(
                    //                   begin: Offset(1, 0), end: Offset(0, 0)),
                    //               curve: Curves.easeOut,
                    //               builder: (context, offset, child) {
                    //                 return Transform.translate(
                    //                     offset: offset * 10, child: child);
                    //               },
                    //               child: Container(
                    //                 margin: EdgeInsets.symmetric(
                    //                     vertical: 5, horizontal: 6),
                    //                 padding: EdgeInsets.all(12),
                    //                 decoration: BoxDecoration(
                    //                   borderRadius: BorderRadius.circular(16),
                    //                   gradient: LinearGradient(
                    //                     colors: [
                    //                       Color(0xFF02347C),
                    //                       Color(0xFF82E49D)
                    //                     ],
                    //                     begin: Alignment.topLeft,
                    //                     end: Alignment.bottomRight,
                    //                   ),
                    //                   boxShadow: [
                    //                     BoxShadow(
                    //                       color: Colors.black26,
                    //                       blurRadius: 6,
                    //                       offset: Offset(0, 2),
                    //                     ),
                    //                   ],
                    //                 ),
                    //                 child: Column(
                    //                   crossAxisAlignment:
                    //                       CrossAxisAlignment.start,
                    //                   children: [
                    //                     Text(
                    //                       "Today's Sales report (Date Wise)",
                    //                       style: TextStyle(
                    //                         fontSize: 15,
                    //                         fontWeight: FontWeight.bold,
                    //                         color: Colors.white,
                    //                       ),
                    //                     ),
                    //                     Divider(color: Colors.white54),
                    //                     SizedBox(height: 6),

                    //                     /// Actual table
                    //                     Table(
                    //                       border: TableBorder.all(
                    //                           color: Colors.white, width: 1),
                    //                       columnWidths: const {
                    //                         0: FlexColumnWidth(1),
                    //                         1: FlexColumnWidth(2),
                    //                       },
                    //                       children: [
                    //                         /// Header row
                    //                         TableRow(
                    //                           decoration: BoxDecoration(
                    //                               color: Colors.black26),
                    //                           children: [
                    //                             Padding(
                    //                               padding: EdgeInsets.all(6),
                    //                               child: Text("Count",
                    //                                   style: TextStyle(
                    //                                       fontWeight:
                    //                                           FontWeight.bold,
                    //                                       color: Colors.white)),
                    //                             ),
                    //                             Padding(
                    //                               padding: EdgeInsets.all(6),
                    //                               child: Text("Amount",
                    //                                   textAlign: TextAlign.center,
                    //                                   style: TextStyle(
                    //                                       fontWeight:
                    //                                           FontWeight.bold,
                    //                                       color: Colors.white)),
                    //                             ),
                    //                           ],
                    //                         ),

                    //                         /// COD Row
                    //                         TableRow(children: [
                    //                           Padding(
                    //                             padding: EdgeInsets.all(6),
                    //                             child: Text(
                    //                                 "${summary['non_rejected_orders']?['count'] ?? 0}",
                    //                                 style: TextStyle(
                    //                                     color: Colors.white),
                    //                                 textAlign: TextAlign.center),
                    //                           ),
                    //                           Padding(
                    //                             padding: EdgeInsets.all(6),
                    //                             child: Text(
                    //                                 "₹${(summary['non_rejected_orders']?['amount'] ?? 0).toStringAsFixed(2)}",
                    //                                 style: TextStyle(
                    //                                     fontWeight:
                    //                                         FontWeight.bold,
                    //                                     color: Colors.white),
                    //                                 textAlign: TextAlign.right),
                    //                           ),
                    //                         ]),

                    //                         /// Grand Total Row
                    //                       ],
                    //                     ),
                    //                   ],
                    //                 ),
                    //               ));
                    //         },
                    //       ),
                    //     ),
                    //   ],
                    // ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      ceo_family_summary_monthly()),
                            );
                          },
                          child: Builder(
                            builder: (context) {
                              return TweenAnimationBuilder<Offset>(
                                  duration: Duration(milliseconds: 300),
                                  tween: Tween<Offset>(
                                      begin: Offset(1, 0), end: Offset(0, 0)),
                                  curve: Curves.easeOut,
                                  builder: (context, offset, child) {
                                    return Transform.translate(
                                        offset: offset * 10, child: child);
                                  },
                                  child: Container(
                                    margin: EdgeInsets.symmetric(
                                        vertical: 5, horizontal: 6),
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF02347C),
                                          Color(0xFF82E49D)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Month Total",
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Divider(color: Colors.white54),
                                        SizedBox(height: 6),

                                        /// Actual table
                                        Table(
                                          border: TableBorder.all(
                                              color: Colors.white, width: 1),
                                          columnWidths: const {
                                            0: FlexColumnWidth(2),
                                            1: FlexColumnWidth(1),
                                            2: FlexColumnWidth(2),
                                          },
                                          children: [
                                            /// Header row
                                            TableRow(
                                              decoration: BoxDecoration(
                                                  color: Colors.black26),
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.all(6),
                                                  child: Text("Type",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white)),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(6),
                                                  child: Text("Count",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white)),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(6),
                                                  child: Text("Amount",
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white)),
                                                ),
                                              ],
                                            ),

                                            /// COD Row
                                            TableRow(children: [
                                              Padding(
                                                padding: EdgeInsets.all(6),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delivery_dining,
                                                        size: 14,
                                                        color: Colors.white70),
                                                    SizedBox(width: 4),
                                                    Text("COD",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white)),
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.all(6),
                                                child: Text("$monthcod",
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                    textAlign:
                                                        TextAlign.center),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.all(6),
                                                child: Text(
                                                    "₹${monthcodamount.toStringAsFixed(2)}",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white),
                                                    textAlign: TextAlign.right),
                                              ),
                                            ]),

                                            /// Cash Row
                                            TableRow(children: [
                                              Padding(
                                                padding: EdgeInsets.all(6),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                        Icons.payments_outlined,
                                                        size: 14,
                                                        color: Colors.white70),
                                                    SizedBox(width: 4),
                                                    Text("Cash",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white)),
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.all(6),
                                                child: Text("$monthpaid",
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                    textAlign:
                                                        TextAlign.center),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.all(6),
                                                child: Text(
                                                    "₹${monthpaidamount.toStringAsFixed(2)}",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white),
                                                    textAlign: TextAlign.right),
                                              ),
                                            ]),

                                            /// Credit Row
                                            TableRow(children: [
                                              Padding(
                                                padding: EdgeInsets.all(6),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                        Icons
                                                            .credit_card_outlined,
                                                        size: 14,
                                                        color: Colors.white70),
                                                    SizedBox(width: 4),
                                                    Text("Credit",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white)),
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.all(6),
                                                child: Text("$monthcredit",
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                    textAlign:
                                                        TextAlign.center),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.all(6),
                                                child: Text(
                                                    "₹${monthcreditamount.toStringAsFixed(2)}",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white),
                                                    textAlign: TextAlign.right),
                                              ),
                                            ]),

                                            /// Grand Total Row
                                            TableRow(
                                              decoration: BoxDecoration(
                                                  color: Colors.black26),
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.all(6),
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.shopping_bag,
                                                          size: 14,
                                                          color:
                                                              Colors.white70),
                                                      SizedBox(width: 4),
                                                      Text("Grand Total",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors
                                                                  .white)),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(6),
                                                  child: Text("$monthcount",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white),
                                                      textAlign:
                                                          TextAlign.center),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(6),
                                                  child: Text(
                                                      "₹${monthtotalamount.toStringAsFixed(2)}",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white),
                                                      textAlign:
                                                          TextAlign.right),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ));
                            },
                          ),
                        ),
                      ],
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //       builder: (context) =>
                            //           ceo_family_summary_monthly()),
                            // );
                          },
                          child: Builder(
                            builder: (context) {
                              return TweenAnimationBuilder<Offset>(
                                  duration: Duration(milliseconds: 300),
                                  tween: Tween<Offset>(
                                      begin: Offset(1, 0), end: Offset(0, 0)),
                                  curve: Curves.easeOut,
                                  builder: (context, offset, child) {
                                    return Transform.translate(
                                        offset: offset * 10, child: child);
                                  },
                                  child: Container(
                                    margin: EdgeInsets.symmetric(
                                        vertical: 5, horizontal: 6),
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF02347C),
                                          Color(0xFF82E49D)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Status Wise Total",
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Divider(color: Colors.white54),
                                        SizedBox(height: 6),

                                        /// Actual table
                                        Table(
                                          border: TableBorder.all(
                                              color: Colors.white, width: 1),
                                          columnWidths: const {
                                            0: FlexColumnWidth(2),
                                            1: FlexColumnWidth(1),
                                          },
                                          children: [
                                            /// Header row
                                            TableRow(
                                              decoration: BoxDecoration(
                                                  color: Colors.black26),
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.all(6),
                                                  child: Text("Type",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white)),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(6),
                                                  child: Text("Count",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white)),
                                                ),
                                              ],
                                            ),

                                            /// COD Row
                                            TableRow(children: [
                                              Padding(
                                                padding: EdgeInsets.all(6),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delivery_dining,
                                                        size: 14,
                                                        color: Colors.white70),
                                                    SizedBox(width: 4),
                                                    Text("Approved (ADO)",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white)),
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.all(6),
                                                child: Text("$toprint",
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                    textAlign:
                                                        TextAlign.center),
                                              ),
                                            ]),

                                            /// Cash Row
                                            TableRow(children: [
                                              Padding(
                                                padding: EdgeInsets.all(6),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                        Icons.payments_outlined,
                                                        size: 14,
                                                        color: Colors.white70),
                                                    SizedBox(width: 4),
                                                    Text("Dispatched (DDO)",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white)),
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.all(6),
                                                child: Text("$readtoship",
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                    textAlign:
                                                        TextAlign.center),
                                              ),
                                            ]),

                                            /// Credit Row
                                            TableRow(children: [
                                              Padding(
                                                padding: EdgeInsets.all(6),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                        Icons
                                                            .credit_card_outlined,
                                                        size: 14,
                                                        color: Colors.white70),
                                                    SizedBox(width: 4),
                                                    Text("PDO",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white)),
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.all(6),
                                                child: Text("$shipped",
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                    textAlign:
                                                        TextAlign.center),
                                              ),
                                            ]),

                                            /// Grand Total Row
                                            // TableRow(
                                            //   decoration: BoxDecoration(
                                            //       color: Colors.black26),
                                            //   children: [
                                            //     Padding(
                                            //       padding: EdgeInsets.all(6),
                                            //       child: Row(
                                            //         children: [
                                            //           Icon(Icons.shopping_bag,
                                            //               size: 14,
                                            //               color: Colors.white70),
                                            //           SizedBox(width: 4),
                                            //           Text("Grand Total",
                                            //               style: TextStyle(
                                            //                   fontWeight:
                                            //                       FontWeight.bold,
                                            //                   color:
                                            //                       Colors.white)),
                                            //         ],
                                            //       ),
                                            //     ),
                                            //     Padding(
                                            //       padding: EdgeInsets.all(6),
                                            //       child: Text("$monthcount",
                                            //           style: TextStyle(
                                            //               fontWeight:
                                            //                   FontWeight.bold,
                                            //               color: Colors.white),
                                            //           textAlign:
                                            //               TextAlign.center),
                                            //     ),

                                            //   ],
                                            // ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ));
                            },
                          ),
                        ),
                      ],
                    ),

                    buildBdoStatewiseCard(
                      title: "BDO Daily Statewise Report",
                      data: dailyBdoStatewiseData,
                      loading: dailyBdoLoading,
                      isDaily: true,
                    ),

                    buildBdoStatewiseCard(
                      title: "BDO Monthly Statewise Report",
                      data: monthlyBdoStatewiseData,
                      loading: monthlyBdoLoading,
                      isDaily: false,
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      height: 10,
                    ),
                    buildExpenseTypeTotalsCard(expenseTypeWiseTotals),
                    // buildFamilyAnalysisCards(),
                    // buildBdmFamilyCards(),
                    const SizedBox(height: 10),
                    buildDailyGoodsMovementTableCard(),
                    buildFilteredCategoryProductCard(),
                    buildFamilySummaryTeamCards(),

                    SizedBox(
                      height: 10,
                    ),
                    // buildParcelServiceReportTable(
                    //   context,
                    //   parcelData,
                    //   totalvolumee,
                    //   totalbox,
                    //   monthTotalActualWeight,
                    //   monthTotalWeight,
                    //   monthTotalParcelAmount,
                    //   monthAverage,
                    // ),

                    // Column(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     if (currentMonthFamilyWiseSummary
                    //         .containsKey('Month Total'))
                    //       GestureDetector(
                    //         onTap: () {
                    //           Navigator.push(
                    //             context,
                    //             MaterialPageRoute(
                    //                 builder: (context) =>
                    //                     PostofficeReport_monthly()),
                    //           );
                    //         },
                    //         child: Builder(
                    //           builder: (context) {
                    //             var summary =
                    //                 currentMonthFamilyWiseSummary['Month Total']!;
                    //             return TweenAnimationBuilder<Offset>(
                    //               duration: Duration(milliseconds: 300),
                    //               tween: Tween<Offset>(
                    //                   begin: Offset(1, 0), end: Offset(0, 0)),
                    //               curve: Curves.easeOut,
                    //               builder: (context, offset, child) {
                    //                 return Transform.translate(
                    //                     offset: offset * 10, child: child);
                    //               },
                    //               child: Container(
                    //                 margin: EdgeInsets.symmetric(
                    //                     vertical: 5, horizontal: 6),
                    //                 padding: EdgeInsets.all(12),
                    //                 decoration: BoxDecoration(
                    //                   borderRadius: BorderRadius.circular(16),
                    //                   gradient: LinearGradient(
                    //                     colors: [
                    //                       Color(0xFF02347C),
                    //                       Color(0xFF82E49D)
                    //                     ],
                    //                     begin: Alignment.topLeft,
                    //                     end: Alignment.bottomRight,
                    //                   ),
                    //                   boxShadow: [
                    //                     BoxShadow(
                    //                       color: Colors.black26,
                    //                       blurRadius: 6,
                    //                       offset: Offset(0, 2),
                    //                     ),
                    //                   ],
                    //                 ),
                    //                 child: Column(
                    //                   crossAxisAlignment:
                    //                       CrossAxisAlignment.start,
                    //                   children: [
                    //                     Text(
                    //                       "Monthly Goods Movement (MGM)",
                    //                       style: TextStyle(
                    //                         fontSize: 15,
                    //                         fontWeight: FontWeight.bold,
                    //                         color: Colors.white,
                    //                       ),
                    //                     ),
                    //                     Divider(color: Colors.white60),
                    //                     SizedBox(height: 6),

                    //                     // === TABLE: Metric | Value ===
                    //                     Table(
                    //                       border: TableBorder.all(
                    //                           color: Colors.white60, width: 1),
                    //                       columnWidths: const {
                    //                         0: FlexColumnWidth(3), // Metric
                    //                         1: FlexColumnWidth(2), // Value
                    //                       },
                    //                       defaultVerticalAlignment:
                    //                           TableCellVerticalAlignment.middle,
                    //                       children: [
                    //                         // Header
                    //                         // TableRow(
                    //                         //   decoration: BoxDecoration(color: Colors.white24),
                    //                         //   children: [
                    //                         //     Padding(
                    //                         //       padding: EdgeInsets.all(8),
                    //                         //       child: Text(
                    //                         //         "Metric",
                    //                         //         style: TextStyle(
                    //                         //           color: Colors.white,
                    //                         //           fontWeight: FontWeight.bold,
                    //                         //         ),
                    //                         //       ),
                    //                         //     ),
                    //                         //     Padding(
                    //                         //       padding: EdgeInsets.all(8),
                    //                         //       child: Text(
                    //                         //         "Value",
                    //                         //         textAlign: TextAlign.right,
                    //                         //         style: TextStyle(
                    //                         //           color: Colors.white,
                    //                         //           fontWeight: FontWeight.bold,
                    //                         //         ),
                    //                         //       ),
                    //                         //     ),
                    //                         //   ],
                    //                         // ),

                    //                         // Total Actual Weight
                    //                         TableRow(children: [
                    //                           Padding(
                    //                             padding: EdgeInsets.all(8),
                    //                             child: Row(
                    //                               children: [
                    //                                 Icon(Icons.scale,
                    //                                     size: 16,
                    //                                     color: Colors.white70),
                    //                                 SizedBox(width: 6),
                    //                                 Text("Total Actual Wt.",
                    //                                     style: TextStyle(
                    //                                         color: Colors.white)),
                    //                               ],
                    //                             ),
                    //                           ),
                    //                           Padding(
                    //                             padding: EdgeInsets.all(8),
                    //                             child: Text(
                    //                               "${(monthTotalActualWeight / 1000).toStringAsFixed(2)} kg",
                    //                               textAlign: TextAlign.right,
                    //                               style: TextStyle(
                    //                                   color: Colors.white,
                    //                                   fontWeight:
                    //                                       FontWeight.bold),
                    //                             ),
                    //                           ),
                    //                         ]),

                    //                         // Total Declared Weight
                    //                         TableRow(children: [
                    //                           Padding(
                    //                             padding: EdgeInsets.all(8),
                    //                             child: Row(
                    //                               children: [
                    //                                 Icon(Icons.monitor_weight,
                    //                                     size: 16,
                    //                                     color: Colors.white70),
                    //                                 SizedBox(width: 6),
                    //                                 Text("Total Wt.",
                    //                                     style: TextStyle(
                    //                                         color: Colors.white)),
                    //                               ],
                    //                             ),
                    //                           ),
                    //                           Padding(
                    //                             padding: EdgeInsets.all(8),
                    //                             child: Text(
                    //                               "${(monthTotalWeight / 1000).toStringAsFixed(2)} kg",
                    //                               textAlign: TextAlign.right,
                    //                               style: TextStyle(
                    //                                   color: Colors.white,
                    //                                   fontWeight:
                    //                                       FontWeight.bold),
                    //                             ),
                    //                           ),
                    //                         ]),

                    //                         // Total Parcel Amount
                    //                         TableRow(children: [
                    //                           Padding(
                    //                             padding: EdgeInsets.all(8),
                    //                             child: Row(
                    //                               children: [
                    //                                 Icon(
                    //                                     Icons
                    //                                         .local_shipping_outlined,
                    //                                     size: 16,
                    //                                     color: Colors.white70),
                    //                                 SizedBox(width: 6),
                    //                                 Text("Total Parcel Amount",
                    //                                     style: TextStyle(
                    //                                         color: Colors.white)),
                    //                               ],
                    //                             ),
                    //                           ),
                    //                           Padding(
                    //                             padding: EdgeInsets.all(8),
                    //                             child: Text(
                    //                               "₹${monthTotalParcelAmount.toStringAsFixed(2)}",
                    //                               textAlign: TextAlign.right,
                    //                               style: TextStyle(
                    //                                   color: Colors.white,
                    //                                   fontWeight:
                    //                                       FontWeight.bold),
                    //                             ),
                    //                           ),
                    //                         ]),

                    //                         // Average (₹ per kg)
                    //                         TableRow(
                    //                           decoration: BoxDecoration(
                    //                               color: Colors.black26),
                    //                           children: [
                    //                             Padding(
                    //                               padding: EdgeInsets.all(8),
                    //                               child: Row(
                    //                                 children: [
                    //                                   Icon(Icons.shopping_bag,
                    //                                       size: 16,
                    //                                       color: Colors.white70),
                    //                                   SizedBox(width: 6),
                    //                                   Text("Average (₹/kg)",
                    //                                       style: TextStyle(
                    //                                           color: Colors.white,
                    //                                           fontWeight:
                    //                                               FontWeight
                    //                                                   .w600)),
                    //                                 ],
                    //                               ),
                    //                             ),
                    //                             Padding(
                    //                               padding: EdgeInsets.all(8),
                    //                               child: Text(
                    //                                 (monthTotalActualWeight > 0
                    //                                         ? (monthTotalParcelAmount /
                    //                                             (monthTotalActualWeight /
                    //                                                 1000.0))
                    //                                         : 0.0)
                    //                                     .toStringAsFixed(2),
                    //                                 textAlign: TextAlign.right,
                    //                                 style: TextStyle(
                    //                                     color: Colors.white,
                    //                                     fontWeight:
                    //                                         FontWeight.bold),
                    //                               ),
                    //                             ),
                    //                           ],
                    //                         ),
                    //                       ],
                    //                     ),
                    //                   ],
                    //                 ),
                    //               ),
                    //             );
                    //           },
                    //         ),
                    //       ),
                    //   ],
                    // ),

                    if (categoryWiseProducts.isNotEmpty)
                      buildCategoryWiseCard(),

                    dbrLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: todayBankReports.length,
                            itemBuilder: (context, index) {
                              final bank = todayBankReports[index];

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          BankMonthlyReportPage(
                                        bankId: int.tryParse(
                                                bank["bank_id"].toString()) ??
                                            0,
                                        bankData: bank,
                                      ),
                                    ),
                                  );
                                },
                                child: Card(
                                  elevation: 4,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF02347C),
                                          Color(0xFF82E49D),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${bank["bank_name"]} (OD Account)",
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Table(
                                            border: TableBorder.all(
                                              color: Colors.white,
                                              width: 1.2,
                                            ),
                                            children: [
                                              TableRow(
                                                decoration: const BoxDecoration(
                                                    color: Colors.black26),
                                                children: [
                                                  _buildTableHeader(
                                                      'Opening Balance'),
                                                  _buildTableHeader(
                                                      'Closing Balance'),
                                                ],
                                              ),
                                              TableRow(
                                                children: [
                                                  _buildTableCell(
                                                    "₹${bank["opening_balance"].toStringAsFixed(2)}",
                                                    Colors.white,
                                                  ),
                                                  _buildTableCell(
                                                    "₹${bank["closing_balance"].toStringAsFixed(2)}",
                                                    Colors.white,
                                                  ),
                                                ],
                                              ),
                                              TableRow(
                                                decoration: const BoxDecoration(
                                                    color: Colors.black26),
                                                children: [
                                                  _buildTableHeader(
                                                      'Today Credit'),
                                                  _buildTableHeader(
                                                      'Today Debit'),
                                                ],
                                              ),
                                              TableRow(
                                                children: [
                                                  _buildTableCell(
                                                    "₹${bank["today_credit"].toStringAsFixed(2)}",
                                                    Colors.white,
                                                  ),
                                                  _buildTableCell(
                                                    "₹${bank["today_debit"].toStringAsFixed(2)}",
                                                    Colors.white,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                    SizedBox(height: 4),
                    Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF02347C), // deep blue
                              Color(0xFF82E49D), // turquoise green
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Heading inside card
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Text(
                                  "Daily Banking Report (DBR)",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors
                                        .white, // white text for visibility
                                  ),
                                ),
                              ),

                              Table(
                                border: TableBorder.all(
                                  color: Colors.white,
                                  width: 1.2,
                                ),
                                columnWidths: const {
                                  0: FlexColumnWidth(),
                                  1: FlexColumnWidth(),
                                },
                                children: [
                                  TableRow(
                                    decoration:
                                        BoxDecoration(color: Colors.black26),
                                    children: [
                                      _buildTableHeader('Opening Balance'),
                                      _buildTableHeader('Closing Balance'),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      _buildTableCell(
                                        '₹${totalAdjustedOpeningBalance1.toStringAsFixed(2)}',
                                        Colors.white,
                                      ),
                                      _buildTableCell(
                                        '₹${totalClosingBalance1.toStringAsFixed(2)}',
                                        Colors.white,
                                      ),
                                    ],
                                  ),
                                  TableRow(
                                    decoration:
                                        BoxDecoration(color: Colors.black26),
                                    children: [
                                      _buildTableHeader('Today Credit'),
                                      _buildTableHeader('Today Debit'),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      _buildTableCell(
                                        '₹${totalTodayPayments1.toStringAsFixed(2)}',
                                        Colors.white,
                                      ),
                                      _buildTableCell(
                                        '₹${totalTodayBanksAmount1.toStringAsFixed(2)}',
                                        Colors.white,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF02347C), // deep blue
                              Color(0xFF82E49D), // turquoise green
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Heading inside card
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Text(
                                  "Monthly Banking Report (MBR)",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors
                                        .white, // white text for visibility
                                  ),
                                ),
                              ),

                              Table(
                                border: TableBorder.all(
                                  color: Colors.white,
                                  width: 1.2,
                                ),
                                columnWidths: const {
                                  0: FlexColumnWidth(),
                                  1: FlexColumnWidth(),
                                },
                                children: [
                                  TableRow(
                                    decoration:
                                        BoxDecoration(color: Colors.black26),
                                    children: [
                                      _buildTableHeader('Opening Balance'),
                                      _buildTableHeader('Closing Balance'),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      _buildTableCell(
                                        '₹${totalCurrentMonthOpeningBalance.toStringAsFixed(2)}',
                                        Colors.white,
                                      ),
                                      _buildTableCell(
                                        '₹${totalCurrentMonthClosingBalance.toStringAsFixed(2)}',
                                        Colors.white,
                                      ),
                                    ],
                                  ),
                                  TableRow(
                                    decoration:
                                        BoxDecoration(color: Colors.black26),
                                    children: [
                                      _buildTableHeader('Monthly Credit'),
                                      _buildTableHeader('Monthly Debit'),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      _buildTableCell(
                                        '₹${totalCurrentMonthPayments.toStringAsFixed(2)}',
                                        Colors.white,
                                      ),
                                      _buildTableCell(
                                        '₹${totalCurrentMonthExpenses.toStringAsFixed(2)}',
                                        Colors.white,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF02347C), // deep blue
                              Color(0xFF82E49D), // turquoise green
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Heading inside card
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Text(
                                  "DBR Including Transfers",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white, // white for visibility
                                  ),
                                ),
                              ),

                              Table(
                                border: TableBorder.all(
                                  color: Colors.white,
                                  width: 1.2,
                                ),
                                columnWidths: const {
                                  0: FlexColumnWidth(),
                                  1: FlexColumnWidth(),
                                },
                                children: [
                                  // Row 1: Opening | Closing
                                  TableRow(
                                    decoration:
                                        BoxDecoration(color: Colors.black26),
                                    children: [
                                      _buildTableHeader('Opening Balance'),
                                      _buildTableHeader('Closing Balance'),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      _buildTableCell(
                                        '₹${totalAdjustedOpeningBalance.toStringAsFixed(2)}',
                                        Colors.white,
                                      ),
                                      _buildTableCell(
                                        '₹${totalClosingBalance.toStringAsFixed(2)}',
                                        Colors.white,
                                      ),
                                    ],
                                  ),

                                  // Row 2: Credit | Debit
                                  TableRow(
                                    decoration:
                                        BoxDecoration(color: Colors.black26),
                                    children: [
                                      _buildTableHeader('Today Credit'),
                                      _buildTableHeader('Today Debit'),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      _buildTableCell(
                                        '₹${totalTodayPayments.toStringAsFixed(2)}',
                                        Colors.white,
                                      ),
                                      _buildTableCell(
                                        '₹${totalTodayBanksAmount.toStringAsFixed(2)}',
                                        Colors.white,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF02347C), // deep blue
                              Color(0xFF82E49D), // turquoise green
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Heading inside card
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Text(
                                  "Monthly Banking Report Including Transfer (MBR)",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors
                                        .white, // white text for visibility
                                  ),
                                ),
                              ),

                              Table(
                                border: TableBorder.all(
                                  color: Colors.white,
                                  width: 1.2,
                                ),
                                columnWidths: const {
                                  0: FlexColumnWidth(),
                                  1: FlexColumnWidth(),
                                },
                                children: [
                                  TableRow(
                                    decoration:
                                        BoxDecoration(color: Colors.black26),
                                    children: [
                                      _buildTableHeader('Opening Balance'),
                                      _buildTableHeader('Closing Balance'),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      _buildTableCell(
                                        '₹${currentMonthOpening.toStringAsFixed(2)}',
                                        Colors.white,
                                      ),
                                      _buildTableCell(
                                        '₹${currentMonthClosing.toStringAsFixed(2)}',
                                        Colors.white,
                                      ),
                                    ],
                                  ),
                                  TableRow(
                                    decoration:
                                        BoxDecoration(color: Colors.black26),
                                    children: [
                                      _buildTableHeader('Monthly Credit'),
                                      _buildTableHeader('Monthly Debit'),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      _buildTableCell(
                                        '₹${totalCurrentMonthPayments1.toStringAsFixed(2)}',
                                        Colors.white,
                                      ),
                                      _buildTableCell(
                                        '₹${totalCurrentMonthExpenses1.toStringAsFixed(2)}',
                                        Colors.white,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Body// Header (only when there is data)
                    // if (parcelData.isNotEmpty)
                    //   const Padding(
                    //     padding: EdgeInsets.all(8.0),
                    //     child: Text(
                    //       "Parcel Service Report",
                    //       style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    //     ),
                    //   ),

                    // // Body
                    // parcelData.isEmpty
                    //     ? Center(
                    //         child: Column(
                    //           mainAxisAlignment: MainAxisAlignment.center,
                    //           children: const [
                    //             Icon(Icons.error_outline,
                    //                 color: Color.fromARGB(255, 54, 184, 244), size: 50),
                    //             SizedBox(height: 10),
                    //             Text(
                    //               "data is Fetching....",
                    //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    //             ),
                    //           ],
                    //         ),
                    //       )
                    //     : ListView.separated(
                    //         shrinkWrap: true,
                    //         physics: const NeverScrollableScrollPhysics(), // 👈 outer page scrolls
                    //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    //         itemCount: parcelData.length,
                    //         separatorBuilder: (_, __) => const SizedBox(height: 12),
                    //         itemBuilder: (context, index) {
                    //           final parcelService = parcelData.keys.elementAt(index);
                    //           final data = parcelData[parcelService] ?? {};
                    //           final totalWeightKg =
                    //               ((data['total_actual_weight'] ?? 0) as num).toDouble() / 1000.0;
                    //           final totWeightKg =
                    //               ((data['total_weight'] ?? 0) as num).toDouble() / 1000.0;
                    //           final double totalAmount =
                    //               ((data['total_parcel_amount'] ?? 0) as num).toDouble();
                    //           final double average =
                    //               totalWeightKg > 0 ? totalAmount / totalWeightKg : 0.0;

                    //           String fmtKg(double v) => "${v.toStringAsFixed(2)} kg";
                    //           String fmtRs(double v) => "₹${v.toStringAsFixed(2)}";

                    //           return Card(
                    //             elevation: 4,
                    //             shape:
                    //                 RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    //             child: Container(
                    //               padding: const EdgeInsets.all(15),
                    //               decoration: BoxDecoration(
                    //                 borderRadius: BorderRadius.circular(12),
                    //                 gradient: const LinearGradient(
                    //                   colors: [
                    //                     Color.fromARGB(255, 100, 180, 216),
                    //                     Color.fromARGB(255, 64, 170, 251),
                    //                   ],
                    //                   begin: Alignment.topLeft,
                    //                   end: Alignment.bottomRight,
                    //                 ),
                    //               ),
                    //               child: Column(
                    //                 crossAxisAlignment: CrossAxisAlignment.start,
                    //                 children: [
                    //                   Row(children: const [
                    //                     Icon(Icons.local_shipping, color: Colors.white, size: 20),
                    //                     SizedBox(width: 10),
                    //                   ]),
                    //                   Row(children: [
                    //                     const SizedBox(width: 30),
                    //                     Text(
                    //                       parcelService.toUpperCase(),
                    //                       style: const TextStyle(
                    //                         fontSize: 14,
                    //                         fontWeight: FontWeight.bold,
                    //                         color: Colors.white,
                    //                       ),
                    //                     ),
                    //                   ]),
                    //                   const Divider(color: Colors.white70),
                    //                   const SizedBox(height: 10),
                    //                   Row(
                    //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //                     children: [
                    //                       _buildInfoColumn("A/W", fmtKg(totalWeightKg)),
                    //                       _buildInfoColumn("Amount", fmtRs(totalAmount)),
                    //                       _buildInfoColumn("T/W", fmtKg(totWeightKg)),
                    //                       _buildInfoColumn(
                    //                           "Average", "${average.toStringAsFixed(2)} Rs"),
                    //                     ],
                    //                   ),
                    //                 ],
                    //               ),
                    //             ),
                    //           );
                    //         },
                    //       ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoCard(String value, String label, int notificationCount) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (notificationCount > 0)
              Positioned(
                top: -8,
                right: -8,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.red,
                  child: Text(
                    notificationCount.toString(),
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildGridItem(IconData icon, String title, [int? count]) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Stack(
          clipBehavior: Clip.none, // Prevents the badge from clipping the card
          children: [
            // Main content of the card - Center the text and icon
            Center(
              // Wrap the Column in a Center widget
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Vertically center
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Horizontally center
                children: [
                  Icon(icon, size: 36, color: Colors.blue),
                  SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            // Notification Badge
            if (count != null && count > 0)
              Positioned(
                top: -8,
                right: -8,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[600],
                  child: Text(
                    count.toString(),
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Widget _buildCardWithIcon({
  required String label,
  required String value,
  Color color = Colors.white,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      SizedBox(height: 6),
      Text(
        value,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      SizedBox(height: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color.withOpacity(0.9),
        ),
      ),
    ],
  );
}

Widget _buildRowWithTwoColumns(
    String label1, dynamic value1, String label2, dynamic value2) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label1,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              Text(
                value1.toString(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label2,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              Text(
                value2.toString(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildTableHeader(String text) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 11,
        color: Colors.white, // <-- force white headings
      ),
    ),
  );
}

Widget _buildTableCell(String value, Color color) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Center(
      child: Text(
        value,
        style:
            TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        textAlign: TextAlign.center,
      ),
    ),
  );
}

Widget _buildInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
        Text(
          value,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    ),
  );
}

Widget _buildInfoColumn(String label, String value) {
  return Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

Widget _buildFamilyMetricTile(String title, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.10),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: Colors.white.withOpacity(0.35),
        width: 1.2,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

Widget buildParcelServiceReportTable(
  BuildContext context,
  Map<String, Map<String, dynamic>> parcelData,
  double totalvolumee,
  double totalbox,
  double monthTotalActualWeight,
  double monthTotalWeight,
  double monthTotalParcelAmount,
  double monthAverage,
) {
  List<TableRow> rows = [];

  rows.add(
    const TableRow(
      decoration: BoxDecoration(color: Colors.black26),
      children: [
        _TableHeader("Service"),
        _TableHeader("Boxes"),
        _TableHeader("Total Post Office Weight (kg)"),
        _TableHeader("Total Actual Weight (kg)"),
        _TableHeader("Volume (Kg)"),
        _TableHeader("Total Tracking Amount"),
        _TableHeader("Total Avg (₹/kg)"),
      ],
    ),
  );

  double totalAW = 0.0;
  double totalTW = 0.0;
  double totalAmt = 0.0;
  double totalVolume = 0.0;
  double totalBox = 0.0;

  for (final entry in parcelData.entries) {
    final service = entry.key;
    final d = entry.value;

    final boxCount =
        ((d['box'] ?? d['total_box_count'] ?? 0) as num).toDouble();
    final postOfficeWeightKg =
        ((d['total_weight'] ?? 0) as num).toDouble() / 1000.0;
    final actualWeightKg =
        ((d['total_actual_weight'] ?? 0) as num).toDouble() / 1000.0;
    final amt = ((d['total_parcel_amount'] ?? 0) as num).toDouble();
    final volume = ((d['total_volume'] ?? 0) as num).toDouble();
    final avg = actualWeightKg > 0 ? (amt / actualWeightKg) : 0.0;

    totalAW += actualWeightKg;
    totalBox += boxCount;
    totalTW += postOfficeWeightKg;
    totalAmt += amt;
    totalVolume += volume;

    rows.add(
      TableRow(
        children: [
          _TableCell(service.toUpperCase()),
          _TableCell(boxCount.toStringAsFixed(0)),
          _TableCell(postOfficeWeightKg.toStringAsFixed(2)),
          _TableCell(actualWeightKg.toStringAsFixed(2)),
          _TableCell(volume.toStringAsFixed(2)),
          _TableCell("₹${amt.toStringAsFixed(2)}"),
          _TableCell(avg.toStringAsFixed(2)),
        ],
      ),
    );
  }

  final totalAvg = totalAW > 0 ? (totalAmt / totalAW) : 0.0;

  rows.add(
    TableRow(
      decoration: const BoxDecoration(color: Colors.black26),
      children: [
        const _TableHeader("TOTAL (DGM)"),
        _TableCell(totalBox.toStringAsFixed(0), bold: true),
        _TableCell(totalTW.toStringAsFixed(2), bold: true),
        _TableCell(totalAW.toStringAsFixed(2), bold: true),
        _TableCell(totalVolume.toStringAsFixed(2), bold: true),
        _TableCell("₹${totalAmt.toStringAsFixed(2)}", bold: true),
        _TableCell(totalAvg.toStringAsFixed(2), bold: true),
      ],
    ),
  );

  rows.add(
    TableRow(
      decoration: const BoxDecoration(
        color: Color.fromARGB(115, 41, 154, 1),
      ),
      children: [
        const _TableHeader("CURRENT MONTH (MGM)"),
        _TableCell(totalbox.toStringAsFixed(0), bold: true),
        _TableCell(
          (monthTotalWeight / 1000).toStringAsFixed(2),
          bold: true,
        ),
        _TableCell(
          (monthTotalActualWeight / 1000).toStringAsFixed(2),
          bold: true,
        ),
        _TableCell(totalvolumee.toStringAsFixed(2), bold: true),
        _TableCell(
          "₹${monthTotalParcelAmount.toStringAsFixed(2)}",
          bold: true,
        ),
        _TableCell(
          monthAverage.toStringAsFixed(2),
          bold: true,
        ),
      ],
    ),
  );

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => daily_goods_movement(),
        ),
      );
    },
    child: Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF02347C),
              Color(0xFF82E49D),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Daily Goods Movement",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Divider(color: Colors.white54),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  border: TableBorder.all(color: Colors.white, width: 1),
                  columnWidths: const {
                    0: FixedColumnWidth(170),
                    1: FixedColumnWidth(100),
                    2: FixedColumnWidth(180),
                    3: FixedColumnWidth(180),
                    4: FixedColumnWidth(130),
                    5: FixedColumnWidth(170),
                    6: FixedColumnWidth(150),
                  },
                  children: rows,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// === Reusable Widgets ===
class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool bold;
  const _TableCell(this.text, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }
}
