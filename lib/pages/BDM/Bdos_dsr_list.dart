import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:beposoft/Sales%20Directors/SD_dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:excel/excel.dart' as ex;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BdosDsrList extends StatefulWidget {
  const BdosDsrList({super.key});

  @override
  State<BdosDsrList> createState() => _BdosDsrListState();
}

class _BdosDsrListState extends State<BdosDsrList> {
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customerController = TextEditingController();

  Timer? _debounce;

  bool isLoading = true;
  bool isLoadingMore = false;
  bool isInitialLoading = true;
  bool hasNextPage = true;
  bool isExporting = false;
  bool isStaffLoading = false;
  bool isStateLoading = false;

  int currentPage = 1;

  int totalCount = 0;
  int activeCount = 0;
  int productiveCount = 0;
  int dsrApprovedCount = 0;
  int dsrConfirmedCount = 0;
  int dsrRejectedCount = 0;
  int dsrCreatedCount = 0;
  String totalCallDuration = "00:00:00";
  double totalInvoiceAmount = 0.0;
  double callDurationAvg8hrs = 0.0;
  double callDurationPercentage8hrs = 0.0;

  int filteredTotalCount = 0;
  int filteredActiveCount = 0;
  int filteredProductiveCount = 0;
  int filteredDsrApprovedCount = 0;
  int filteredDsrConfirmedCount = 0;
  int filteredDsrRejectedCount = 0;
  int filteredDsrCreatedCount = 0;
  String filteredTotalCallDuration = "00:00:00";
  double filteredTotalInvoiceAmount = 0.0;
  double filteredCallDurationAvg8hrs = 0.0;
  double filteredCallDurationPercentage8hrs = 0.0;

  DateTimeRange? selectedDateRange;
  String selectedSummaryFilter = "";

  int? loggedInFamilyId;
  int? selectedStaffId;
  String selectedStaffName = "";

  int? selectedStateId;
  String selectedStateName = "";

  List<Map<String, dynamic>> dsrList = [];
  List<Map<String, dynamic>> filteredDsrList = [];
  final Set<int> _expandedProductCards = {};
  List<Map<String, dynamic>> staffList = [];
  List<Map<String, dynamic>> stat = [];

  final List<String> allowedStatuses = [
    'dsr approved',
    'dsr rejected',
  ];

  drower d = drower();

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<int?> getFamilyIdFromProfile() async {
    try {
      final token = await gettokenFromPrefs();

      if (token == null || token.isEmpty) {
        return null;
      }

      final response = await http.get(
        Uri.parse('$api/api/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("PROFILE STATUS: ${response.statusCode}");
      print("PROFILE BODY: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        if (parsed is Map && parsed["data"] != null) {
          final familyId =
              parsed["data"]["family_id"] ?? parsed["data"]["family"];

          print("PROFILE FAMILY ID: $familyId");

          if (familyId is int) {
            return familyId;
          }

          return int.tryParse(familyId.toString());
        }
      }

      return null;
    } catch (e) {
      print("PROFILE FETCH ERROR: $e");
      return null;
    }
  }

  Future<void> getstate() async {
    try {
      setState(() {
        isStateLoading = true;
      });

      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/states/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> statelist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'] ?? [];

        for (var productData in productsData) {
          statelist.add({
            'id': productData['id'],
            'name': productData['name']?.toString() ?? "",
          });
        }
      }

      if (!mounted) return;
      setState(() {
        stat = statelist;
        isStateLoading = false;
      });
    } catch (error) {
      print("STATE FETCH ERROR: $error");
      if (!mounted) return;
      setState(() {
        stat = [];
        isStateLoading = false;
      });
    }
  }

  Future<void> fetchStaffByFamily() async {
    try {
      setState(() {
        isStaffLoading = true;
      });

      final token = await gettokenFromPrefs();

      int? familyId = loggedInFamilyId;
      familyId ??= await getFamilyIdFromProfile();

      if (familyId == null) {
        if (!mounted) return;
        setState(() {
          staffList = [];
          isStaffLoading = false;
        });
        return;
      }

      loggedInFamilyId = familyId;

      final response = await http.get(
        Uri.parse('$api/api/users/family/$familyId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("STAFF STATUS: ${response.statusCode}");
      print("STAFF BODY: ${response.body}");

      List<Map<String, dynamic>> tempStaff = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final data = parsed["data"] ?? [];

        for (final item in data) {
          tempStaff.add({
            "id": item["id"],
            "name": item["name"]?.toString() ?? "",
            "department_name": item["department_name"]?.toString() ?? "",
            "family_name": item["family_name"]?.toString() ?? "",
            "email": item["email"]?.toString() ?? "",
            "phone": item["phone"]?.toString() ?? "",
          });
        }
      }

      if (!mounted) return;
      setState(() {
        staffList = tempStaff;
        isStaffLoading = false;
      });
    } catch (e) {
      print("STAFF FETCH ERROR: $e");
      if (!mounted) return;
      setState(() {
        staffList = [];
        isStaffLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initPage();
  }

  Future<void> _initPage() async {
    loggedInFamilyId = await getFamilyIdFromProfile();
    await fetchStaffByFamily();
    await getstate();
    await fetchDsrList(isRefresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _customerController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        !isLoading &&
        hasNextPage) {
      fetchDsrList();
    }
  }

  Future<void> _pickDateRange() async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(2020);
    final DateTime lastDate = DateTime(now.year + 2);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: selectedDateRange,
      helpText: "Select Date Range",
    );

    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
      });
      fetchDsrList(isRefresh: true);
    }
  }

  void _clearDateRange() {
    setState(() {
      selectedDateRange = null;
    });
    fetchDsrList(isRefresh: true);
  }

  String _formatDateForApi(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return "$y-$m-$d";
  }

  int _durationToSeconds(String value) {
    try {
      final parts = value.split(":");
      if (parts.length != 3) return 0;

      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      final seconds = int.tryParse(parts[2]) ?? 0;

      return (hours * 3600) + (minutes * 60) + seconds;
    } catch (e) {
      return 0;
    }
  }

  String _secondsToDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    return "${hours.toString().padLeft(2, '0')}:"
        "${minutes.toString().padLeft(2, '0')}:"
        "${seconds.toString().padLeft(2, '0')}";
  }

  String _safeText(dynamic value) {
    if (value == null) return "-";
    final text = value.toString().trim();
    return text.isEmpty ? "-" : text;
  }

  String _formatAmount(dynamic value) {
    if (value == null) return "0";
    if (value is num) {
      return value.toStringAsFixed(0);
    }
    final cleaned = value.toString().replaceAll(",", "").trim();
    final parsed = double.tryParse(cleaned) ?? 0;
    return parsed.toStringAsFixed(0);
  }

  DateTime? _extractCreatedDate(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    try {
      return DateTime.parse(text).toLocal();
    } catch (e) {
      return null;
    }
  }

  String _buildExcelDateRangeLabel() {
    if (selectedDateRange != null) {
      return "${formatDateOnly(selectedDateRange!.start)} to ${formatDateOnly(selectedDateRange!.end)}";
    }

    DateTime? minDate;
    DateTime? maxDate;

    for (final item in filteredDsrList) {
      final dt = _extractCreatedDate(item["created_at"]);
      if (dt == null) continue;

      if (minDate == null || dt.isBefore(minDate)) {
        minDate = dt;
      }
      if (maxDate == null || dt.isAfter(maxDate)) {
        maxDate = dt;
      }
    }

    if (minDate != null && maxDate != null) {
      return "${formatDateOnly(minDate)} to ${formatDateOnly(maxDate)}";
    }

    return "All Dates";
  }


  Map<String, String> _summaryFilterParams() {
    switch (selectedSummaryFilter) {
      case "active":
        return {"call_status": "active"};
      case "productive":
        return {"call_status": "productive"};
      case "created":
        return {"status": "dsr created"};
      case "approved":
        return {"status": "dsr approved"};
      case "confirmed":
        return {"status": "dsr confirmed"};
      case "rejected":
        return {"status": "dsr rejected"};
      default:
        return {};
    }
  }

  Uri _buildUri({String? nextUrl}) {
    if (nextUrl != null && nextUrl.isNotEmpty) {
      return Uri.parse(nextUrl);
    }

    final familyId = loggedInFamilyId ?? 0;

    final Map<String, String> queryParams = {
      "page": currentPage.toString(),
    };

    if (_searchController.text.trim().isNotEmpty) {
      queryParams["search"] = _searchController.text.trim();
    }

    if (_customerController.text.trim().isNotEmpty) {
      queryParams["customer"] = _customerController.text.trim();
    }

    if (selectedDateRange != null) {
      queryParams["start_date"] = _formatDateForApi(selectedDateRange!.start);
      queryParams["end_date"] = _formatDateForApi(selectedDateRange!.end);
    }

    if (selectedStateName.trim().isNotEmpty) {
      queryParams["state"] = selectedStateName.trim();
    }

    if (selectedStaffId != null) {
      queryParams["created_by"] = selectedStaffId.toString();
    }

    queryParams.addAll(_summaryFilterParams());

    return Uri.parse('$api/api/sales/analysis/family/$familyId/')
        .replace(queryParameters: queryParams);
  }


  void _applyFilters() {
    filteredDsrList = List<Map<String, dynamic>>.from(dsrList);
    filteredTotalCount = totalCount;
    filteredActiveCount = activeCount;
    filteredProductiveCount = productiveCount;
    filteredDsrApprovedCount = dsrApprovedCount;
    filteredDsrConfirmedCount = dsrConfirmedCount;
    filteredDsrRejectedCount = dsrRejectedCount;
    filteredDsrCreatedCount = dsrCreatedCount;
    filteredTotalCallDuration = totalCallDuration;
    filteredTotalInvoiceAmount = totalInvoiceAmount;
    filteredCallDurationAvg8hrs = callDurationAvg8hrs;
    filteredCallDurationPercentage8hrs = callDurationPercentage8hrs;

    if (mounted) {
      setState(() {});
    }
  }


  Future<void> fetchDsrList({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        setState(() {
          isLoading = true;
          isInitialLoading = true;
          currentPage = 1;
          hasNextPage = true;
          dsrList.clear();
          filteredDsrList.clear();
          _expandedProductCards.clear();

          totalCount = 0;
          activeCount = 0;
          productiveCount = 0;
          dsrApprovedCount = 0;
          dsrConfirmedCount = 0;
          dsrRejectedCount = 0;
          dsrCreatedCount = 0;
          totalCallDuration = "00:00:00";
          totalInvoiceAmount = 0.0;
          callDurationAvg8hrs = 0.0;
          callDurationPercentage8hrs = 0.0;

          filteredTotalCount = 0;
          filteredActiveCount = 0;
          filteredProductiveCount = 0;
          filteredDsrApprovedCount = 0;
          filteredDsrConfirmedCount = 0;
          filteredDsrRejectedCount = 0;
          filteredDsrCreatedCount = 0;
          filteredTotalCallDuration = "00:00:00";
          filteredTotalInvoiceAmount = 0.0;
          filteredCallDurationAvg8hrs = 0.0;
          filteredCallDurationPercentage8hrs = 0.0;
        });
      } else {
        if (!hasNextPage) return;
        setState(() {
          isLoadingMore = true;
        });
      }

      final token = await gettokenFromPrefs();
      final familyId = loggedInFamilyId ?? await getFamilyIdFromProfile();

      if (familyId == null) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
          isLoadingMore = false;
          isInitialLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("Family id not found from profile"),
          ),
        );
        return;
      }

      loggedInFamilyId = familyId;

      final uri = _buildUri();

      print("FAMILY DSR URL: $uri");

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("FAMILY DSR STATUS: ${response.statusCode}");
      print("FAMILY DSR BODY: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List data = [];
        int count = 0;
        int tempActiveCount = 0;
        int tempProductiveCount = 0;
        int tempDsrApprovedCount = 0;
        int tempDsrConfirmedCount = 0;
        int tempDsrRejectedCount = 0;
        int tempDsrCreatedCount = 0;
        String tempTotalCallDuration = "00:00:00";
        double tempTotalInvoiceAmount = 0.0;
        double tempCallDurationAvg8hrs = 0.0;
        double tempCallDurationPercentage8hrs = 0.0;
        dynamic nextPageUrl;

        if (parsed is Map) {
          count = parsed["count"] is int
              ? parsed["count"]
              : int.tryParse(parsed["count"]?.toString() ?? "0") ?? 0;

          nextPageUrl = parsed["next"];

          if (parsed["results"] is Map) {
            final resultMap = parsed["results"];

            tempActiveCount = resultMap["active_count"] is int
                ? resultMap["active_count"]
                : int.tryParse(resultMap["active_count"]?.toString() ?? "0") ?? 0;

            tempProductiveCount = resultMap["productive_count"] is int
                ? resultMap["productive_count"]
                : int.tryParse(resultMap["productive_count"]?.toString() ?? "0") ?? 0;

            tempDsrApprovedCount = resultMap["dsr_approved_count"] is int
                ? resultMap["dsr_approved_count"]
                : int.tryParse(resultMap["dsr_approved_count"]?.toString() ?? "0") ?? 0;

            tempDsrConfirmedCount = resultMap["dsr_confirmed_count"] is int
                ? resultMap["dsr_confirmed_count"]
                : int.tryParse(resultMap["dsr_confirmed_count"]?.toString() ?? "0") ?? 0;

            tempDsrRejectedCount = resultMap["dsr_rejected_count"] is int
                ? resultMap["dsr_rejected_count"]
                : int.tryParse(resultMap["dsr_rejected_count"]?.toString() ?? "0") ?? 0;

            tempDsrCreatedCount = resultMap["dsr_created_count"] is int
                ? resultMap["dsr_created_count"]
                : int.tryParse(resultMap["dsr_created_count"]?.toString() ?? "0") ?? 0;

            tempTotalCallDuration =
                resultMap["total_call_duration"]?.toString() ?? "00:00:00";

            tempTotalInvoiceAmount = double.tryParse(
                    (resultMap["total_invoice_amount"] ?? 0).toString()) ??
                0.0;

            tempCallDurationAvg8hrs = double.tryParse(
                    (resultMap["average_call_duration"] ??
                            resultMap["call_duration_average_8hrs"] ??
                            0)
                        .toString()) ??
                0.0;

            tempCallDurationPercentage8hrs = double.tryParse(
                    (resultMap["call_duration_percentage_8hrs"] ?? 0)
                        .toString()) ??
                0.0;

            data = resultMap["results"] ?? [];
          } else if (parsed["results"] is List) {
            data = parsed["results"] ?? [];
          } else if (parsed["data"] is List) {
            data = parsed["data"] ?? [];
          }
        } else if (parsed is List) {
          data = parsed;
        }

        List<Map<String, dynamic>> tempList = [];

        for (var item in data) {
          final List<Map<String, dynamic>> products = [];
          final rawProducts = item["product_details"];
          if (rawProducts is List) {
            for (var p in rawProducts) {
              products.add({
                "product_id": p["product_id"],
                "name": p["name"]?.toString() ?? "",
                "image": p["image"]?.toString() ?? "",
                "quantity": p["quantity"],
                "rate": p["rate"]?.toString() ?? "0",
                "discount": p["discount"]?.toString() ?? "0",
                "tax": p["tax"],
                "description": p["description"]?.toString() ?? "",
              });
            }
          }

          tempList.add({
            "id": item["id"],
            "invoice_no": item["invoice_number"]?.toString() ??
                item["invoice_no"]?.toString() ??
                item["invoice"]?.toString() ??
                "",
            "customer_name": item["customer_name"]?.toString() ??
                item["customer"]?.toString() ??
                "",
                 "phone": item["phone"]?.toString() ?? "",
            "call_status": item["call_status"]?.toString() ?? "",
            "status": item["status"]?.toString() ?? "",
            "call_duration": item["call_duration"]?.toString() ?? "",
            "state_name": item["state_name"]?.toString() ?? "",
            "district_name": item["district_name"]?.toString() ?? "",
            "created_by": item["created_by"],
            "created_by_name": item["created_by_name"]?.toString() ??
                item["user_name"]?.toString() ??
                "",
            "invoice_amount": item["invoice_amount"]?.toString() ?? "",
            "note": item["note"]?.toString() ?? "",
            "created_at": item["created_at"]?.toString() ?? "",
            "product_details": products,
          });
        }

        if (!mounted) return;

        setState(() {
          totalCount = count;
          activeCount = tempActiveCount;
          productiveCount = tempProductiveCount;
          dsrApprovedCount = tempDsrApprovedCount;
          dsrConfirmedCount = tempDsrConfirmedCount;
          dsrRejectedCount = tempDsrRejectedCount;
          dsrCreatedCount = tempDsrCreatedCount;
          totalCallDuration = tempTotalCallDuration;
          totalInvoiceAmount = tempTotalInvoiceAmount;
          callDurationAvg8hrs = tempCallDurationAvg8hrs;
          callDurationPercentage8hrs = tempCallDurationPercentage8hrs;

          if (isRefresh) {
            dsrList = tempList;
          } else {
            dsrList.addAll(tempList);
          }

          hasNextPage = nextPageUrl != null &&
              nextPageUrl.toString().isNotEmpty &&
              tempList.isNotEmpty;

          if (hasNextPage) {
            currentPage++;
          }

          isLoading = false;
          isLoadingMore = false;
          isInitialLoading = false;
        });

        _applyFilters();
      } else {
        if (!mounted) return;

        setState(() {
          isLoading = false;
          isLoadingMore = false;
          isInitialLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Failed: ${response.body}"),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        isLoadingMore = false;
        isInitialLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error: $e"),
        ),
      );
    }
  }

  Future<void> exportToExcel() async {
    try {
      if (filteredDsrList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("No data available to export"),
          ),
        );
        return;
      }

      setState(() {
        isExporting = true;
      });

      var excel = ex.Excel.createExcel();
      final defaultSheet = excel.getDefaultSheet();
      if (defaultSheet != null) {
        excel.delete(defaultSheet);
      }

      ex.Sheet sheet = excel["Family DSR Report"];

      sheet.setColWidth(0, 24);
      sheet.setColWidth(1, 16);
      sheet.setColWidth(2, 18);
      sheet.setColWidth(3, 26);
      sheet.setColWidth(4, 16);
      sheet.setColWidth(5, 18);
      sheet.setColWidth(6, 14);
      sheet.setColWidth(7, 16);
      sheet.setColWidth(8, 18);
      sheet.setColWidth(9, 12);
      sheet.setColWidth(10, 22);
      sheet.setColWidth(11, 30);

      final ex.Border thinBorder = ex.Border(borderStyle: ex.BorderStyle.Thin);

      final ex.CellStyle titleStyle = ex.CellStyle(
        backgroundColorHex: "#1F4E78",
        fontColorHex: "#FFFFFF",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        fontSize: 18,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle dateInfoStyle = ex.CellStyle(
        backgroundColorHex: "#E8F1FB",
        fontColorHex: "#1F1F1F",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        fontSize: 11,
        horizontalAlign: ex.HorizontalAlign.Left,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle headerStyle = ex.CellStyle(
        backgroundColorHex: "#D9E2F3",
        fontColorHex: "#9C0006",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        fontSize: 11,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        textWrapping: ex.TextWrapping.WrapText,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle oddCenterStyle = ex.CellStyle(
        backgroundColorHex: "#F7FBFF",
        fontColorHex: "#000000",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        fontSize: 10,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        textWrapping: ex.TextWrapping.WrapText,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle oddLeftStyle = ex.CellStyle(
        backgroundColorHex: "#F7FBFF",
        fontColorHex: "#000000",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        fontSize: 10,
        horizontalAlign: ex.HorizontalAlign.Left,
        verticalAlign: ex.VerticalAlign.Center,
        textWrapping: ex.TextWrapping.WrapText,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle evenCenterStyle = ex.CellStyle(
        backgroundColorHex: "#EEF4FB",
        fontColorHex: "#000000",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        fontSize: 10,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        textWrapping: ex.TextWrapping.WrapText,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle evenLeftStyle = ex.CellStyle(
        backgroundColorHex: "#EEF4FB",
        fontColorHex: "#000000",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        fontSize: 10,
        horizontalAlign: ex.HorizontalAlign.Left,
        verticalAlign: ex.VerticalAlign.Center,
        textWrapping: ex.TextWrapping.WrapText,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle activeStatusStyle = ex.CellStyle(
        backgroundColorHex: "#FCE4D6",
        fontColorHex: "#9E480E",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        fontSize: 10,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        textWrapping: ex.TextWrapping.WrapText,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle productiveStatusStyle = ex.CellStyle(
        backgroundColorHex: "#E2F0D9",
        fontColorHex: "#2F6B1D",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        fontSize: 10,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        textWrapping: ex.TextWrapping.WrapText,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle createdStatusStyle = ex.CellStyle(
        backgroundColorHex: "#D9EAF7",
        fontColorHex: "#1F4E78",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        fontSize: 10,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        textWrapping: ex.TextWrapping.WrapText,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle approvedStatusStyle = ex.CellStyle(
        backgroundColorHex: "#E2F0D9",
        fontColorHex: "#2F6B1D",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        fontSize: 10,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        textWrapping: ex.TextWrapping.WrapText,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle confirmedStatusStyle = ex.CellStyle(
        backgroundColorHex: "#FFF2CC",
        fontColorHex: "#7F6000",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        fontSize: 10,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        textWrapping: ex.TextWrapping.WrapText,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle rejectedStatusStyle = ex.CellStyle(
        backgroundColorHex: "#F4CCCC",
        fontColorHex: "#990000",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        fontSize: 10,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        textWrapping: ex.TextWrapping.WrapText,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle amountStyle = ex.CellStyle(
        backgroundColorHex: "#FFF2CC",
        fontColorHex: "#000000",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        fontSize: 10,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle summaryHeadingStyle = ex.CellStyle(
        backgroundColorHex: "#1F4E78",
        fontColorHex: "#FFFFFF",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        fontSize: 13,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle summaryLabelStyle = ex.CellStyle(
        backgroundColorHex: "#DCE6F1",
        fontColorHex: "#000000",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        fontSize: 11,
        horizontalAlign: ex.HorizontalAlign.Left,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle summaryValueStyle = ex.CellStyle(
        backgroundColorHex: "#FFFFFF",
        fontColorHex: "#000000",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: false,
        fontSize: 11,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      void setCellValueStyle(
        int col,
        int row,
        String value,
        ex.CellStyle style,
      ) {
        final cell = sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
        );
        cell.value = value;
        cell.cellStyle = style;
      }

      void fillRangeStyle(
        int startCol,
        int endCol,
        int row,
        ex.CellStyle style, {
        String? firstValue,
      }) {
        for (int c = startCol; c <= endCol; c++) {
          final cell = sheet.cell(
            ex.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row),
          );
          cell.value = (c == startCol && firstValue != null) ? firstValue : "";
          cell.cellStyle = style;
        }
      }

      int rowIndex = 0;

      fillRangeStyle(
        0,
        11,
        rowIndex,
        titleStyle,
        firstValue: "FAMILY DSR REPORT",
      );
      sheet.merge(
        ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        ex.CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIndex),
      );

      rowIndex++;

      fillRangeStyle(
        0,
        11,
        rowIndex,
        dateInfoStyle,
        firstValue: "Data Shown From: ${_buildExcelDateRangeLabel()}",
      );
      sheet.merge(
        ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        ex.CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIndex),
      );

      rowIndex++;

      final headers = [
        "#NO",
        "STAFF",
        "INVOICE NO",
        "CUSTOMER",
        "CALL STATUS",
        "DSR STATUS",
        "DURATION",
        "STATE",
        "DISTRICT",
        "AMOUNT",
        "CREATED AT",
        "NOTE",
      ];

      for (int i = 0; i < headers.length; i++) {
        setCellValueStyle(i, rowIndex, headers[i], headerStyle);
      }

      rowIndex++;

      for (int i = 0; i < filteredDsrList.length; i++) {
        final item = filteredDsrList[i];
        final bool isOdd = i.isEven;

        final ex.CellStyle centerStyle =
            isOdd ? oddCenterStyle : evenCenterStyle;
        final ex.CellStyle leftStyle = isOdd ? oddLeftStyle : evenLeftStyle;

        final String callStatus =
            item["call_status"]?.toString().toLowerCase().trim() ?? "";
        final String dsrStatus =
            item["status"]?.toString().toLowerCase().trim() ?? "";

        ex.CellStyle callStatusCellStyle = centerStyle;
        if (callStatus == "active") {
          callStatusCellStyle = activeStatusStyle;
        } else if (callStatus == "productive") {
          callStatusCellStyle = productiveStatusStyle;
        }

        ex.CellStyle dsrStatusCellStyle = centerStyle;
        if (dsrStatus == "dsr created") {
          dsrStatusCellStyle = createdStatusStyle;
        } else if (dsrStatus == "dsr approved") {
          dsrStatusCellStyle = approvedStatusStyle;
        } else if (dsrStatus == "dsr confirmed") {
          dsrStatusCellStyle = confirmedStatusStyle;
        } else if (dsrStatus == "dsr rejected") {
          dsrStatusCellStyle = rejectedStatusStyle;
        }

        final values = [
          "${i + 1}",
          _safeText(item["created_by_name"]),
          _safeText(item["invoice_no"]),
          _safeText(item["customer_name"]),
          _safeText(item["call_status"]),
          _safeText(item["status"]),
          _safeText(item["call_duration"]),
          _safeText(item["state_name"]),
          _safeText(item["district_name"]),
          _formatAmount(item["invoice_amount"]),
          formatDateTime(item["created_at"] ?? ""),
          _safeText(item["note"]),
        ];

        for (int col = 0; col < values.length; col++) {
          final cell = sheet.cell(
            ex.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex),
          );
          cell.value = values[col];

          if (col == 1 || col == 3 || col == 7 || col == 8 || col == 11) {
            cell.cellStyle = leftStyle;
          } else if (col == 4) {
            cell.cellStyle = callStatusCellStyle;
          } else if (col == 5) {
            cell.cellStyle = dsrStatusCellStyle;
          } else if (col == 9) {
            cell.cellStyle = amountStyle;
          } else {
            cell.cellStyle = centerStyle;
          }
        }

        rowIndex++;
      }

      rowIndex++;

      final summaryTitleCell = sheet.cell(
        ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
      );
      summaryTitleCell.value = "CALL REPORT SUMMARY";
      summaryTitleCell.cellStyle = summaryHeadingStyle;

      final summaryTitleCell2 = sheet.cell(
        ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
      );
      summaryTitleCell2.value = "";
      summaryTitleCell2.cellStyle = summaryHeadingStyle;

      sheet.merge(
        ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
      );

      rowIndex++;

      final summaryHeaderLabel = sheet.cell(
        ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
      );
      summaryHeaderLabel.value = "SUMMARY";
      summaryHeaderLabel.cellStyle = headerStyle;

      final summaryHeaderValue = sheet.cell(
        ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
      );
      summaryHeaderValue.value = "VALUE";
      summaryHeaderValue.cellStyle = headerStyle;

      rowIndex++;

      final summaryData = [
        ["TOTAL BILLS", filteredTotalCount.toString()],
        ["TOTAL ACTIVE CALLS", filteredActiveCount.toString()],
        ["TOTAL PRODUCTIVE CALLS", filteredProductiveCount.toString()],
        ["TOTAL DSR CREATED", filteredDsrCreatedCount.toString()],
        ["TOTAL DSR APPROVED", filteredDsrApprovedCount.toString()],
        ["TOTAL DSR CONFIRMED", filteredDsrConfirmedCount.toString()],
        ["TOTAL DSR REJECTED", filteredDsrRejectedCount.toString()],
        ["TOTAL CALL DURATION", filteredTotalCallDuration],
        ["TOTAL INVOICE AMOUNT", "₹${filteredTotalInvoiceAmount.toStringAsFixed(2)}"],
        ["AVG DURATION (8 HRS)", "${filteredCallDurationAvg8hrs.toStringAsFixed(1)} min"],
        ["DURATION % (8 HRS)", "${filteredCallDurationPercentage8hrs.toStringAsFixed(2)}%"],
      ];

      for (final item in summaryData) {
        final labelCell = sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        );
        labelCell.value = item[0];
        labelCell.cellStyle = summaryLabelStyle;

        final valueCell = sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
        );
        valueCell.value = item[1];
        valueCell.cellStyle = summaryValueStyle;

        rowIndex++;
      }

      final fileBytes = excel.encode();
      final tempDir = await getTemporaryDirectory();
      final filePath =
          "${tempDir.path}/Family_DSR_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx";

      final file = File(filePath);
      await file.writeAsBytes(fileBytes!, flush: true);

      if (!mounted) return;

      setState(() {
        isExporting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Excel exported successfully"),
        ),
      );

      await Share.shareXFiles(
        [XFile(file.path)],
        text: "Family DSR Report",
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isExporting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Excel Export Failed: $e"),
        ),
      );
    }
  }

  Future<void> _showStatusBottomSheet(Map<String, dynamic> item) async {
    String selectedStatus =
        item["status"]?.toString().trim().toLowerCase() ?? "";

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        bool isUpdating = false;

        return StatefulBuilder(
          builder: (context, setBottomState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: SizedBox(
                      width: 42,
                      child: Divider(thickness: 4),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Update DSR Status",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    item["invoice_no"].toString().isEmpty
                        ? "No Invoice"
                        : item["invoice_no"].toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...allowedStatuses.map(
                    (status) => RadioListTile<String>(
                      value: status,
                      groupValue: selectedStatus,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _capitalizeWords(status),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onChanged: isUpdating
                          ? null
                          : (value) {
                              if (value == null) return;
                              setBottomState(() {
                                selectedStatus = value;
                              });
                            },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isUpdating
                          ? null
                          : () async {
                              Navigator.pop(context);
                              await updateDsrStatus(
                                item["id"],
                                selectedStatus,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isUpdating
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Update Status",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> updateDsrStatus(int id, String status) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final token = await gettokenFromPrefs();

      final response = await http.patch(
        Uri.parse('$api/api/sales/analysis/edit/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "status": status,
        }),
      );

      final patchUrl = '$api/api/sales/analysis/edit/$id/';
      print("UPDATE STATUS URL: $patchUrl");
      print("UPDATE STATUS ID: $id");
      print("UPDATE STATUS CODE: ${response.statusCode}");
      print("UPDATE STATUS BODY: ${response.body}");
      print("UPDATE STATUS ID: $id");

      if (!mounted) return;
      Navigator.pop(context);

      if (response.statusCode == 200 || response.statusCode == 202) {
        final index = dsrList.indexWhere((e) => e["id"] == id);
        if (index != -1) {
          setState(() {
            dsrList[index]["status"] = status;
          });
        }

        await fetchDsrList(isRefresh: true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("DSR status updated successfully"),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Failed to update status: ${response.body}"),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error updating status: $e"),
        ),
      );
    }
  }

  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();
    if (!mounted) return;

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
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => dashboard()),
      );
    }
  }

  String _capitalizeWords(String value) {
    return value.split(" ").map((e) {
      if (e.isEmpty) return e;
      return e[0].toUpperCase() + e.substring(1);
    }).join(" ");
  }

  Color getCallStatusColor(String status) {
    final s = status.toLowerCase().trim();
    if (s == "productive") return Colors.green;
    if (s == "active") return Colors.orange;
    return Colors.grey;
  }

  Color getDsrStatusColor(String status) {
    final s = status.toLowerCase().trim();
    if (s == "dsr rejected") return Colors.red;
    if (s == "dsr approved") return Colors.green;
    if (s == "dsr created") return Colors.blue;
    if (s == "dsr confirmed") return Colors.orange;
    return Colors.grey;
  }

  String formatDateTime(String value) {
    if (value.isEmpty) return "-";
    try {
      final dt = DateTime.parse(value).toLocal();
      return "${dt.day.toString().padLeft(2, '0')}-"
          "${dt.month.toString().padLeft(2, '0')}-"
          "${dt.year} "
          "${dt.hour.toString().padLeft(2, '0')}:"
          "${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return value;
    }
  }

  String formatDateOnly(DateTime value) {
    return "${value.day.toString().padLeft(2, '0')}-"
        "${value.month.toString().padLeft(2, '0')}-"
        "${value.year}";
  }

  Widget buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              "$title :",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "-" : value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildChip(String label, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label.isEmpty ? "-" : label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }



  Widget buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xff40B0FB)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xff1E293B),
          ),
        ),
      ],
    );
  }

  Widget buildProductDetails(int itemId, List<Map<String, dynamic>> products) {
    if (products.isEmpty) return const SizedBox.shrink();

    final bool isExpanded = _expandedProductCards.contains(itemId);
    final bool hasMore = products.length > 1;
    final visibleProducts = isExpanded ? products : [products.first];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        buildSectionTitle("Product Details", Icons.inventory_2_outlined),
        const SizedBox(height: 10),
        ...visibleProducts.map((p) => _buildProductRow(p)).toList(),
        if (hasMore)
          GestureDetector(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedProductCards.remove(itemId);
                } else {
                  _expandedProductCards.add(itemId);
                }
              });
            },
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xff2196F3).withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xff2196F3).withOpacity(0.18),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: const Color(0xff2196F3),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isExpanded
                        ? "See Less"
                        : "See More (${products.length - 1} more product${products.length - 1 > 1 ? 's' : ''})",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff2196F3),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductRow(Map<String, dynamic> p) {
    final String imageUrl = (p["image"] ?? "").toString().trim().isNotEmpty
        ? "$api${p["image"]}"
        : "";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _buildProductImagePlaceholder(),
                  )
                : _buildProductImagePlaceholder(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p["name"]?.toString().trim().isNotEmpty == true
                      ? p["name"]
                      : "-",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildProductTag("Qty: ${p["quantity"] ?? "-"}", Colors.blue),
                    _buildProductTag("Rate: ₹${p["rate"] ?? "0"}", const Color(0xff0F9D58)),
                    // _buildProductTag("Disc: ${p["discount"] ?? "0"}", Colors.orange),
                    // _buildProductTag("Tax: ${p["tax"] ?? "0"}%", Colors.purple),
                  ],
                ),
                if ((p["description"] ?? "").toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    p["description"],
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImagePlaceholder() {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.image_outlined, size: 26, color: Colors.grey.shade400),
    );
  }

  Widget _buildProductTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
  Widget _buildFilterField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          onChanged: (value) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 500), () {
              fetchDsrList(isRefresh: true);
            });
            setState(() {});
          },
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hintText,
            icon: Icon(icon, color: Colors.grey),
            suffixIcon: controller.text.trim().isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      controller.clear();
                      setState(() {});
                      fetchDsrList(isRefresh: true);
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionField({
    required String hintText,
    required IconData icon,
    required String value,
    required VoidCallback onTap,
    required VoidCallback onClear,
    bool isLoading = false,
  }) {
    final bool hasValue = value.trim().isNotEmpty;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasValue ? value : hintText,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: hasValue ? Colors.black87 : Colors.grey,
                    fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (hasValue)
                GestureDetector(
                  onTap: onClear,
                  child: const Icon(Icons.close, size: 18, color: Colors.grey),
                )
              else
                const Icon(Icons.arrow_drop_down, size: 22, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSearchableSelectionBottomSheet({
    required String title,
    required List<Map<String, dynamic>> items,
    required Function(Map<String, dynamic>) onSelected,
    required String searchHint,
    required String emptyText,
    bool searchStaffFields = false,
  }) async {
    final TextEditingController searchCtrl = TextEditingController();
    List<Map<String, dynamic>> filteredItems =
        List<Map<String, dynamic>>.from(items);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.72,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: SizedBox(
                          width: 42,
                          child: Divider(thickness: 4),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xffF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
                          controller: searchCtrl,
                          decoration: InputDecoration(
                            hintText: searchHint,
                            border: InputBorder.none,
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: searchCtrl.text.trim().isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      searchCtrl.clear();
                                      setModalState(() {
                                        filteredItems =
                                            List<Map<String, dynamic>>.from(
                                          items,
                                        );
                                      });
                                    },
                                  )
                                : null,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onChanged: (value) {
                            final q = value.trim().toLowerCase();
                            setModalState(() {
                              filteredItems = items.where((item) {
                                final name =
                                    item["name"]?.toString().toLowerCase() ?? "";

                                if (!searchStaffFields) {
                                  return name.contains(q);
                                }

                                final department = item["department_name"]
                                        ?.toString()
                                        .toLowerCase() ??
                                    "";
                                final email =
                                    item["email"]?.toString().toLowerCase() ??
                                        "";
                                final phone =
                                    item["phone"]?.toString().toLowerCase() ??
                                        "";

                                return name.contains(q) ||
                                    department.contains(q) ||
                                    email.contains(q) ||
                                    phone.contains(q);
                              }).toList();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: filteredItems.isEmpty
                            ? Center(
                                child: Text(
                                  emptyText,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: filteredItems.length,
                                separatorBuilder: (_, __) =>
                                    Divider(color: Colors.grey.shade200),
                                itemBuilder: (context, index) {
                                  final item = filteredItems[index];
                                  return ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      item["name"]?.toString() ?? "",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: searchStaffFields &&
                                            item["department_name"] != null &&
                                            item["department_name"]
                                                .toString()
                                                .trim()
                                                .isNotEmpty
                                        ? Text(
                                            item["department_name"].toString(),
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          )
                                        : null,
                                    trailing: searchStaffFields &&
                                            item["phone"] != null &&
                                            item["phone"]
                                                .toString()
                                                .trim()
                                                .isNotEmpty
                                        ? Text(
                                            item["phone"].toString(),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          )
                                        : null,
                                    onTap: () {
                                      Navigator.pop(context);
                                      onSelected(item);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              _buildFilterField(
                controller: _searchController,
                hintText: "Search invoice / customer / district",
                icon: Icons.search,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildSelectionField(
                hintText: "Select staff",
                icon: Icons.person_outline,
                value: selectedStaffName,
                isLoading: isStaffLoading,
                onTap: () async {
                  if (isStaffLoading) return;

                  if (staffList.isEmpty) {
                    await fetchStaffByFamily();
                  }

                  if (!mounted) return;

                  if (staffList.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("No staff found"),
                      ),
                    );
                    return;
                  }

                  await _showSearchableSelectionBottomSheet(
                    title: "Select Staff",
                    items: staffList,
                    searchHint: "Search staff...",
                    emptyText: "No staff found",
                    searchStaffFields: true,
                    onSelected: (item) {
                      setState(() {
                        selectedStaffId = item["id"] is int
                            ? item["id"]
                            : int.tryParse(item["id"].toString());
                        selectedStaffName = item["name"]?.toString() ?? "";
                      });
                      fetchDsrList(isRefresh: true);
                    },
                  );
                },
                onClear: () {
                  setState(() {
                    selectedStaffId = null;
                    selectedStaffName = "";
                  });
                  fetchDsrList(isRefresh: true);
                },
              ),
              const SizedBox(width: 10),
              _buildSelectionField(
                hintText: "Select state",
                icon: Icons.location_on_outlined,
                value: selectedStateName,
                isLoading: isStateLoading,
                onTap: () async {
                  if (isStateLoading) return;

                  if (stat.isEmpty) {
                    await getstate();
                  }

                  if (!mounted) return;

                  if (stat.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("No states found"),
                      ),
                    );
                    return;
                  }

                  await _showSearchableSelectionBottomSheet(
                    title: "Select State",
                    items: stat,
                    searchHint: "Search state...",
                    emptyText: "No state found",
                    searchStaffFields: false,
                    onSelected: (item) {
                      setState(() {
                        selectedStateId = item["id"] is int
                            ? item["id"]
                            : int.tryParse(item["id"].toString());
                        selectedStateName = item["name"]?.toString() ?? "";
                      });
                      fetchDsrList(isRefresh: true);
                    },
                  );
                },
                onClear: () {
                  setState(() {
                    selectedStateId = null;
                    selectedStateName = "";
                  });
                  fetchDsrList(isRefresh: true);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildFilterField(
                controller: _customerController,
                hintText: "Search customer",
                icon: Icons.people_outline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSummaryMiniCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    required String filterKey,
  }) {
    final bool isClickable = filterKey.isNotEmpty;
    final bool isSelected = selectedSummaryFilter == filterKey;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: !isClickable
          ? null
          : () {
              setState(() {
                if (selectedSummaryFilter == filterKey) {
                  selectedSummaryFilter = "";
                } else {
                  selectedSummaryFilter = filterKey;
                }
              });
              fetchDsrList(isRefresh: true);
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isClickable
              ? (isSelected
                  ? color.withOpacity(0.18)
                  : color.withOpacity(0.08))
              : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isClickable
                ? (isSelected ? color : color.withOpacity(0.12))
                : color.withOpacity(0.12),
            width: isClickable && isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: color,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color,
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


  Widget _buildTopSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedDateRange != null ||
              _searchController.text.trim().isNotEmpty ||
              selectedStaffName.trim().isNotEmpty ||
              selectedStateName.trim().isNotEmpty ||
              _customerController.text.trim().isNotEmpty ||
              selectedSummaryFilter.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_searchController.text.trim().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Search: ${_searchController.text.trim()}",
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {});
                              fetchDsrList(isRefresh: true);
                            },
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (selectedStaffName.trim().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Staff: $selectedStaffName",
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedStaffId = null;
                                selectedStaffName = "";
                              });
                              fetchDsrList(isRefresh: true);
                            },
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (selectedStateName.trim().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "State: $selectedStateName",
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedStateId = null;
                                selectedStateName = "";
                              });
                              fetchDsrList(isRefresh: true);
                            },
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_customerController.text.trim().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.pink.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Customer: ${_customerController.text.trim()}",
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.pink,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              _customerController.clear();
                              setState(() {});
                              fetchDsrList(isRefresh: true);
                            },
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.pink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (selectedSummaryFilter.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Summary: ${_capitalizeWords(selectedSummaryFilter)}",
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedSummaryFilter = "";
                              });
                              fetchDsrList(isRefresh: true);
                            },
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (selectedDateRange != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${formatDateOnly(selectedDateRange!.start)} to ${formatDateOnly(selectedDateRange!.end)}",
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: _clearDateRange,
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.fromARGB(255, 9, 137, 202),
                          Color.fromARGB(255, 46, 120, 239),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.analytics_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "DSR Summary",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                selectedSummaryFilter.isEmpty
                                    ? "Overview of filtered sales analysis records"
                                    : "Filtered by ${_capitalizeWords(selectedSummaryFilter)}",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Total $filteredTotalCount",
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: buildSummaryMiniCard(
                                title: "Active",
                                value: "$filteredActiveCount",
                                color: Colors.orange,
                                icon: Icons.phone_in_talk_outlined,
                                filterKey: "active",
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: buildSummaryMiniCard(
                                title: "Productive",
                                value: "$filteredProductiveCount",
                                color: Colors.green,
                                icon: Icons.trending_up,
                                filterKey: "productive",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: buildSummaryMiniCard(
                                title: "Created",
                                value: "$filteredDsrCreatedCount",
                                color: Colors.blue,
                                icon: Icons.edit_note,
                                filterKey: "created",
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: buildSummaryMiniCard(
                                title: "Approved",
                                value: "$filteredDsrApprovedCount",
                                color: Colors.green,
                                icon: Icons.verified_outlined,
                                filterKey: "approved",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: buildSummaryMiniCard(
                                title: "Confirmed",
                                value: "$filteredDsrConfirmedCount",
                                color: Colors.orange,
                                icon: Icons.task_alt,
                                filterKey: "confirmed",
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: buildSummaryMiniCard(
                                title: "Rejected",
                                value: "$filteredDsrRejectedCount",
                                color: Colors.red,
                                icon: Icons.cancel_outlined,
                                filterKey: "rejected",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: buildSummaryMiniCard(
                                title: "Total Duration",
                                value: filteredTotalCallDuration,
                                color: Colors.purple,
                                icon: Icons.access_time,
                                filterKey: "",
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: buildSummaryMiniCard(
                                title: "Total Amount",
                                value: "₹${filteredTotalInvoiceAmount.toStringAsFixed(0)}",
                                color: const Color(0xff0F9D58),
                                icon: Icons.currency_rupee_outlined,
                                filterKey: "",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: buildSummaryMiniCard(
                                title: "Avg Duration (8h)",
                                value: "${filteredCallDurationAvg8hrs.toStringAsFixed(1)} mins",
                                color: Colors.indigo,
                                icon: Icons.av_timer_outlined,
                                filterKey: "",
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: buildSummaryMiniCard(
                                title: "Duration % (8h)",
                                value: "${filteredCallDurationPercentage8hrs.toStringAsFixed(2)}%",
                                color: Colors.teal,
                                icon: Icons.pie_chart_outline,
                                filterKey: "",
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
        ],
      ),
    );
  }


  Widget _buildCard(Map<String, dynamic> item, int index) {
    final callColor = getCallStatusColor(item["call_status"]);
    final dsrColor = getDsrStatusColor(item["status"]);
    final int itemId = item["id"] is int
        ? item["id"]
        : (int.tryParse(item["id"].toString()) ?? index);
    final List<Map<String, dynamic>> products =
        (item["product_details"] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xff40B0FB),
                    Color(0xff2196F3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white24,
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item["invoice_no"].toString().isEmpty
                          ? "No Invoice"
                          : item["invoice_no"].toString(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item["created_by_name"].toString().isEmpty
                          ? "Staff : No name"
                          : "Staff : ${item["created_by_name"]}",
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      buildChip(item["call_status"] ?? "", callColor),
                      const SizedBox(width: 8),
                      buildChip(
                        item["status"] ?? "",
                        dsrColor,
                        onTap: () => _showStatusBottomSheet(item),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: (item["status"]?.toString().toLowerCase().trim() ==
                                "dsr confirmed")
                            ? null
                            : () => _showStatusBottomSheet(item),
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: (item["status"]
                                            ?.toString()
                                            .toLowerCase()
                                            .trim() ==
                                        "dsr confirmed")
                                ? Colors.grey.withOpacity(0.10)
                                : Colors.blue.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 18,
                            color: (item["status"]
                                            ?.toString()
                                            .toLowerCase()
                                            .trim() ==
                                        "dsr confirmed")
                                ? Colors.grey
                                : Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  buildInfoRow("Customer", item["customer_name"] ?? ""),
                  buildInfoRow("Phone", item["phone"] ?? ""),
                  buildInfoRow("State", item["state_name"] ?? ""),
                  buildInfoRow("District", item["district_name"] ?? ""),
                  buildInfoRow("Duration", item["call_duration"] ?? ""),
                  buildInfoRow("Invoice Amount", item["invoice_amount"] ?? ""),
                  buildInfoRow(
                    "Created At",
                    formatDateTime(item["created_at"] ?? ""),
                  ),
                  if ((item["note"] ?? "").toString().trim().isNotEmpty)
                    buildInfoRow("Note", item["note"] ?? ""),
                  buildProductDetails(itemId, products),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isInitialLoading) {
      return Column(
        children: [
          _buildSearchBar(),
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: filteredDsrList.isEmpty
              ? RefreshIndicator(
                  onRefresh: () => fetchDsrList(isRefresh: true),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _buildTopSummary(),
                      const SizedBox(height: 220),
                      const Center(
                        child: Text(
                          "No DSR records found",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: filteredDsrList.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildTopSummary();
                    }

                    if (index == filteredDsrList.length + 1) {
                      return Column(
                        children: [
                          if (isLoadingMore)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: CircularProgressIndicator(),
                            ),
                          if (!hasNextPage && filteredDsrList.isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 4, bottom: 18),
                              child: Text(
                                "No more records",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      );
                    }

                    final item = filteredDsrList[index - 1];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _buildCard(item, index - 1),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDropdownTile(
    BuildContext context,
    String title,
    List<String> options,
  ) {
    return ExpansionTile(
      title: Text(title),
      children: options.map((option) {
        return ListTile(
          title: Text(option),
          onTap: () {
            Navigator.pop(context);
            d.navigateToSelectedPage(context, option);
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasFilter = selectedDateRange != null;

    return WillPopScope(
      onWillPop: () async {
        await _navigateBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xffF4F7FB),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () async {
              await _navigateBack();
            },
          ),
          title: const Text(
            "Family DSR List",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black87),
          actions: [
            IconButton(
              tooltip: "Select Date Range",
              onPressed: _pickDateRange,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.date_range, color: Colors.black87),
                  if (hasFilter)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: "Export Excel",
              onPressed: isExporting ? null : exportToExcel,
              icon: isExporting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download, color: Colors.black87),
            ),
            IconButton(
              tooltip: "Refresh",
              onPressed: () async {
                await fetchStaffByFamily();
                await getstate();
                await fetchDsrList(isRefresh: true);
              },
              icon: const Icon(Icons.refresh, color: Colors.black87),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await fetchStaffByFamily();
            await getstate();
            await fetchDsrList(isRefresh: true);
          },
          child: _buildBody(),
        ),
      ),
    );
  }
}