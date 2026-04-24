import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:beposoft/Sales%20Directors/SD_dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/HR/hr_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:excel/excel.dart' as ex;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BdoCallList extends StatefulWidget {
  const BdoCallList({super.key});

  @override
  State<BdoCallList> createState() => _BdoCallListState();
}

class _BdoCallListState extends State<BdoCallList>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;
  bool isFetchingMore = false;
  bool hasMore = true;
  bool isExporting = false;

  List<Map<String, dynamic>> allCallList = [];
  List<Map<String, dynamic>> filteredCallList = [];

  List<Map<String, dynamic>> stat = [];
  List<Map<String, dynamic>> fam = [];
  List<Map<String, dynamic>> staffList = [];

  // Tracks which card ids have their product list expanded
  final Set<int> _expandedProductCards = {};

  String? nextPageUrl;
  DateTimeRange? selectedDateRange;

  late AnimationController _shimmerController;
  late ScrollController _scrollController;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customerController = TextEditingController();

  Timer? _debounce;

  int? selectedStateId;
  String selectedStateName = "";

  int? selectedFamilyId;
  String selectedFamilyName = "";

  int? selectedStaffId;
  String selectedStaffName = "";

  int totalCount = 0;
  int activeCount = 0;
  int productiveCount = 0;
  int dsrCreatedCount = 0;
  int dsrApprovedCount = 0;
  int dsrConfirmedCount = 0;
  int dsrRejectedCount = 0;
  String totalCallDuration = "00:00:00";

  int filteredTotalCount = 0;
  int filteredActiveCount = 0;
  int filteredProductiveCount = 0;
  int filteredDsrCreatedCount = 0;
  int filteredDsrApprovedCount = 0;
  int filteredDsrConfirmedCount = 0;
  int filteredDsrRejectedCount = 0;
  String filteredTotalCallDuration = "00:00:00";

  String selectedSummaryFilter = "";
  double totalInvoiceAmount = 0.0;
  double callDurationAvg8hrs = 0.0;
  double callDurationPercentage8hrs = 0.0;

  double filteredTotalInvoiceAmount = 0.0;
  double filteredCallDurationAvg8hrs = 0.0;
  double filteredCallDurationPercentage8hrs = 0.0;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    getstate();
    getfamily();
    fetchCallList(isRefresh: true);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _customerController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<String?> gettokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<void> getstate() async {
    try {
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
        if (!mounted) return;
        setState(() {
          stat = statelist;
        });
      }
    } catch (error) {}
  }

  Future<void> getfamily() async {
    try {
      final token = await gettokenFromPrefs();
      var response = await http.get(
        Uri.parse('$api/api/familys/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      List<Map<String, dynamic>> familylist = [];
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'] ?? [];
        for (var productData in productsData) {
          familylist.add({
            'id': productData['id'],
            'name': productData['name']?.toString() ?? "",
          });
        }
        if (!mounted) return;
        setState(() {
          fam = familylist;
        });
      }
    } catch (error) {}
  }

  Future<void> getStaffByFamily(int familyId) async {
    try {
      final token = await gettokenFromPrefs();
      final response = await http.get(
        Uri.parse('$api/api/users/family/$familyId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      List<Map<String, dynamic>> tempStaffList = [];
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final data = parsed["data"] ?? [];
        for (var item in data) {
          tempStaffList.add({
            "id": item["id"],
            "name": item["name"]?.toString() ?? "",
            "department_name": item["department_name"]?.toString() ?? "",
            "family_name": item["family_name"]?.toString() ?? "",
          });
        }
      }
      if (!mounted) return;
      setState(() {
        staffList = tempStaffList;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        staffList = [];
      });
    }
  }

  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();
    if (!mounted) return;
    if (dep == "BDO") {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => bdo_dashbord()));
    } else if (dep == "SD") {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => SdDashboard()));
    } else if (dep == "CEO") {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => ceo_dashboard()));
    } else if (dep == "COO") {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => ceo_dashboard()));
    } else if (dep == "BDM") {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => bdm_dashbord()));
    } else if (dep == "warehouse") {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => WarehouseDashboard()));
    } else if (dep == "Warehouse Admin") {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => WarehouseAdmin()));
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => dashboard()));
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 250) {
      if (!isLoading && !isFetchingMore && hasMore) {
        fetchCallList(loadMore: true);
      }
    }
  }

  String formatDateParam(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  String formatDateDisplay(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}";
  }

  String formatDateTime(String value) {
    if (value.isEmpty) return "-";
    try {
      final dt = DateTime.parse(value).toLocal();
      return "${dt.day.toString().padLeft(2, '0')}-"
          "${dt.month.toString().padLeft(2, '0')}-"
          "${dt.year}  "
          "${dt.hour.toString().padLeft(2, '0')}:"
          "${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return value;
    }
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
    if (value is num) return value.toStringAsFixed(0);
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
      return "${formatDateDisplay(selectedDateRange!.start)} to ${formatDateDisplay(selectedDateRange!.end)}";
    }
    DateTime? minDate;
    DateTime? maxDate;
    for (final item in filteredCallList) {
      final dt = _extractCreatedDate(item["created_at"]);
      if (dt == null) continue;
      if (minDate == null || dt.isBefore(minDate)) minDate = dt;
      if (maxDate == null || dt.isAfter(maxDate)) maxDate = dt;
    }
    if (minDate != null && maxDate != null) {
      return "${formatDateDisplay(minDate)} to ${formatDateDisplay(maxDate)}";
    }
    return "All Dates";
  }

  Future<void> openDateRangePicker() async {
    final DateTime now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: selectedDateRange,
      helpText: "Select Date Range",
      saveText: "Apply",
      cancelText: "Cancel",
      confirmText: "Apply",
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xff2196F3)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
        selectedSummaryFilter = "";
      });
      await fetchCallList(isRefresh: true);
    }
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
    if (nextUrl != null && nextUrl.isNotEmpty) return Uri.parse(nextUrl);

    final queryParams = <String, String>{};
    if (_searchController.text.trim().isNotEmpty) {
      queryParams["search"] = _searchController.text.trim();
    }
    if (_customerController.text.trim().isNotEmpty) {
      queryParams["customer"] = _customerController.text.trim();
    }
    if (selectedDateRange != null) {
      queryParams["start_date"] = formatDateParam(selectedDateRange!.start);
      queryParams["end_date"] = formatDateParam(selectedDateRange!.end);
    }
    if (selectedStateName.trim().isNotEmpty) {
      queryParams["state"] = selectedStateName.trim();
    }
    if (selectedFamilyId != null) {
      queryParams["family"] = selectedFamilyId.toString();
    }
    if (selectedStaffName.trim().isNotEmpty) {
      queryParams["created_by"] = selectedStaffName.trim();
    }
    queryParams.addAll(_summaryFilterParams());
    return Uri.parse('$api/api/sales/analysis/all/').replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
  }

  List<Map<String, dynamic>> _parseResults(String responseBody) {
    final parsed = jsonDecode(responseBody);
    List data = [];

    if (parsed is Map && parsed["results"] is Map) {
      final resultContainer = parsed["results"];
      data = resultContainer["results"] ?? [];
      totalCount = parsed["count"] ?? resultContainer["count"] ?? 0;
      activeCount = resultContainer["active_count"] ?? 0;
      productiveCount = resultContainer["productive_count"] ?? 0;
      dsrCreatedCount = resultContainer["dsr_created_count"] ?? 0;
      dsrApprovedCount = resultContainer["dsr_approved_count"] ?? 0;
      dsrConfirmedCount = resultContainer["dsr_confirmed_count"] ?? 0;
      dsrRejectedCount = resultContainer["dsr_rejected_count"] ?? 0;
      totalCallDuration =
          resultContainer["total_call_duration"]?.toString() ?? "00:00:00";
      totalInvoiceAmount =
          (resultContainer["total_invoice_amount"] ?? 0).toDouble();
      callDurationAvg8hrs =
          (resultContainer["call_duration_average_8hrs"] ?? 0).toDouble();
      callDurationPercentage8hrs =
          (resultContainer["call_duration_percentage_8hrs"] ?? 0).toDouble();
    } else if (parsed is Map && parsed["results"] is List) {
      data = parsed["results"] ?? [];
      totalCount = parsed["count"] ?? data.length;
      activeCount = 0;
      productiveCount = 0;
      dsrCreatedCount = 0;
      dsrApprovedCount = 0;
      dsrConfirmedCount = 0;
      dsrRejectedCount = 0;
      totalCallDuration = "00:00:00";
      totalInvoiceAmount = 0.0;
      callDurationAvg8hrs = 0.0;
      callDurationPercentage8hrs = 0.0;
    } else if (parsed is Map && parsed["data"] is List) {
      data = parsed["data"] ?? [];
      totalCount = parsed["count"] ?? data.length;
      activeCount = 0;
      productiveCount = 0;
      dsrCreatedCount = 0;
      dsrApprovedCount = 0;
      dsrConfirmedCount = 0;
      dsrRejectedCount = 0;
      totalCallDuration = "00:00:00";
      totalInvoiceAmount = 0.0;
      callDurationAvg8hrs = 0.0;
      callDurationPercentage8hrs = 0.0;
    } else if (parsed is List) {
      data = parsed;
      totalCount = data.length;
      activeCount = 0;
      productiveCount = 0;
      dsrCreatedCount = 0;
      dsrApprovedCount = 0;
      dsrConfirmedCount = 0;
      dsrRejectedCount = 0;
      totalCallDuration = "00:00:00";
      totalInvoiceAmount = 0.0;
      callDurationAvg8hrs = 0.0;
      callDurationPercentage8hrs = 0.0;
    }

    final List<Map<String, dynamic>> tempList = [];
    for (var item in data) {
      // Parse product_details list
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
        "call_duration": item["call_duration"]?.toString() ?? "",
        "customer": item["customer"],
        "phone": item["phone"]?.toString() ?? "",
        "customer_name": item["customer_name"]?.toString() ?? "",
        "call_status": item["call_status"]?.toString() ?? "",
        "invoice": item["invoice"],
        "invoice_number": item["invoice_number"]?.toString() ?? "",
        "status": item["status"]?.toString() ?? "",
        "note": item["note"]?.toString() ?? "",
        "state": item["state"],
        "state_name": item["state_name"]?.toString() ?? "",
        "district": item["district"],
        "district_name": item["district_name"]?.toString() ?? "",
        "created_by": item["created_by"],
        "created_by_name": item["created_by_name"]?.toString() ?? "",
        "invoice_amount": item["invoice_amount"]?.toString() ?? "",
        "family_id": item["family_id"],
        "family_name": item["family_name"]?.toString() ?? "",
        "created_at": item["created_at"]?.toString() ?? "",
        "updated_at": item["updated_at"]?.toString() ?? "",
        "product_details": products,
      });
    }
    return tempList;
  }

  void _syncFilteredFromServer() {
    filteredCallList = List.from(allCallList);
    filteredTotalCount = totalCount;
    filteredActiveCount = activeCount;
    filteredProductiveCount = productiveCount;
    filteredDsrCreatedCount = dsrCreatedCount;
    filteredDsrApprovedCount = dsrApprovedCount;
    filteredDsrConfirmedCount = dsrConfirmedCount;
    filteredDsrRejectedCount = dsrRejectedCount;
    filteredTotalCallDuration = totalCallDuration;
    filteredTotalInvoiceAmount = totalInvoiceAmount;
    filteredCallDurationAvg8hrs = callDurationAvg8hrs;
    filteredCallDurationPercentage8hrs = callDurationPercentage8hrs;
    if (mounted) setState(() {});
  }

  Future<void> fetchCallList(
      {bool isRefresh = false, bool loadMore = false}) async {
    try {
      if (isRefresh) {
        if (mounted) {
          setState(() {
            isLoading = true;
            isFetchingMore = false;
            hasMore = true;
            nextPageUrl = null;
            allCallList = [];
            filteredCallList = [];
            _expandedProductCards.clear();
            totalCount = 0;
            activeCount = 0;
            productiveCount = 0;
            dsrCreatedCount = 0;
            dsrApprovedCount = 0;
            dsrConfirmedCount = 0;
            dsrRejectedCount = 0;
            totalCallDuration = "00:00:00";
            totalInvoiceAmount = 0.0;
            callDurationAvg8hrs = 0.0;
            callDurationPercentage8hrs = 0.0;
            filteredTotalCount = 0;
            filteredActiveCount = 0;
            filteredProductiveCount = 0;
            filteredDsrCreatedCount = 0;
            filteredDsrApprovedCount = 0;
            filteredDsrConfirmedCount = 0;
            filteredDsrRejectedCount = 0;
            filteredTotalCallDuration = "00:00:00";
            filteredTotalInvoiceAmount = 0.0;
            filteredCallDurationAvg8hrs = 0.0;
            filteredCallDurationPercentage8hrs = 0.0;
          });
        }
      } else if (loadMore) {
        if (!hasMore || isFetchingMore) return;
        if (mounted)
          setState(() {
            isFetchingMore = true;
          });
      }

      final token = await gettokenFromPrefs();
      final uri = _buildUri(nextUrl: loadMore ? nextPageUrl : null);
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      print("CALL LIST STATUS: ${response.statusCode}");
      print("CALL LIST BODY: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final List<Map<String, dynamic>> tempList =
            _parseResults(response.body);
        String? newNext;
        if (parsed is Map) newNext = parsed["next"]?.toString();
        if (!mounted) return;
        setState(() {
          if (loadMore) {
            allCallList.addAll(tempList);
          } else {
            allCallList = tempList;
          }
          nextPageUrl = newNext;
          hasMore = newNext != null && newNext.isNotEmpty;
          isLoading = false;
          isFetchingMore = false;
        });
        _syncFilteredFromServer();
      } else {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          isFetchingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text("Failed to load data: ${response.body}"),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        isFetchingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text("Error: $e"),
      ));
    }
  }

  Future<void> exportToExcel() async {
    try {
      if (filteredCallList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.red,
          content: Text("No data available to export"),
        ));
        return;
      }
      setState(() {
        isExporting = true;
      });

      var excel = ex.Excel.createExcel();
      final defaultSheet = excel.getDefaultSheet();
      if (defaultSheet != null) excel.delete(defaultSheet);
      ex.Sheet sheet = excel["Call List Report"];

      sheet.setColWidth(0, 8);
      sheet.setColWidth(1, 22);
      sheet.setColWidth(2, 18);
      sheet.setColWidth(3, 26);
      sheet.setColWidth(4, 16);
      sheet.setColWidth(5, 18);
      sheet.setColWidth(6, 14);
      sheet.setColWidth(7, 16);
      sheet.setColWidth(8, 18);
      sheet.setColWidth(9, 16);
      sheet.setColWidth(10, 12);
      sheet.setColWidth(11, 22);
      sheet.setColWidth(12, 28);

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
          int col, int row, String value, ex.CellStyle style) {
        final cell = sheet.cell(
            ex.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
        cell.value = value;
        cell.cellStyle = style;
      }

      void fillRangeStyle(int startCol, int endCol, int row, ex.CellStyle style,
          {String? firstValue}) {
        for (int c = startCol; c <= endCol; c++) {
          final cell = sheet.cell(
              ex.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row));
          cell.value = (c == startCol && firstValue != null) ? firstValue : "";
          cell.cellStyle = style;
        }
      }

      int rowIndex = 0;

      fillRangeStyle(0, 12, rowIndex, titleStyle,
          firstValue: "CALL LIST REPORT");
      sheet.merge(
        ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        ex.CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: rowIndex),
      );
      rowIndex++;

      fillRangeStyle(0, 12, rowIndex, dateInfoStyle,
          firstValue: "Data Shown From: ${_buildExcelDateRangeLabel()}");
      sheet.merge(
        ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        ex.CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: rowIndex),
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
        "FAMILY",
        "AMOUNT",
        "CREATED AT",
        "NOTE"
      ];
      for (int i = 0; i < headers.length; i++) {
        setCellValueStyle(i, rowIndex, headers[i], headerStyle);
      }
      rowIndex++;

      for (int i = 0; i < filteredCallList.length; i++) {
        final item = filteredCallList[i];
        final bool isOdd = i.isEven;
        final ex.CellStyle centerStyle =
            isOdd ? oddCenterStyle : evenCenterStyle;
        final ex.CellStyle leftStyle = isOdd ? oddLeftStyle : evenLeftStyle;
        final String callStatus =
            item["call_status"]?.toString().toLowerCase().trim() ?? "";
        final String dsrStatus =
            item["status"]?.toString().toLowerCase().trim() ?? "";

        ex.CellStyle callStatusCellStyle = centerStyle;
        if (callStatus == "active")
          callStatusCellStyle = activeStatusStyle;
        else if (callStatus == "productive")
          callStatusCellStyle = productiveStatusStyle;

        ex.CellStyle dsrStatusCellStyle = centerStyle;
        if (dsrStatus == "dsr created")
          dsrStatusCellStyle = createdStatusStyle;
        else if (dsrStatus == "dsr approved")
          dsrStatusCellStyle = approvedStatusStyle;
        else if (dsrStatus == "dsr confirmed")
          dsrStatusCellStyle = confirmedStatusStyle;
        else if (dsrStatus == "dsr rejected")
          dsrStatusCellStyle = rejectedStatusStyle;

        final values = [
          "${i + 1}",
          _safeText(item["created_by_name"]),
          _safeText(item["invoice_number"]),
          _safeText(item["customer_name"]),
          _safeText(item["call_status"]),
          _safeText(item["status"]),
          _safeText(item["call_duration"]),
          _safeText(item["state_name"]),
          _safeText(item["district_name"]),
          _safeText(item["family_name"]),
          _formatAmount(item["invoice_amount"]),
          formatDateTime(item["created_at"] ?? ""),
          _safeText(item["note"]),
        ];

        for (int col = 0; col < values.length; col++) {
          final cell = sheet.cell(ex.CellIndex.indexByColumnRow(
              columnIndex: col, rowIndex: rowIndex));
          cell.value = values[col];
          if (col == 1 ||
              col == 3 ||
              col == 7 ||
              col == 8 ||
              col == 9 ||
              col == 12) {
            cell.cellStyle = leftStyle;
          } else if (col == 4) {
            cell.cellStyle = callStatusCellStyle;
          } else if (col == 5) {
            cell.cellStyle = dsrStatusCellStyle;
          } else if (col == 10) {
            cell.cellStyle = amountStyle;
          } else {
            cell.cellStyle = centerStyle;
          }
        }
        rowIndex++;
      }

      rowIndex++;

      final summaryTitleCell = sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      summaryTitleCell.value = "CALL REPORT SUMMARY";
      summaryTitleCell.cellStyle = summaryHeadingStyle;
      final summaryTitleCell2 = sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
      summaryTitleCell2.value = "";
      summaryTitleCell2.cellStyle = summaryHeadingStyle;
      sheet.merge(
        ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
      );
      rowIndex++;

      final summaryHeaderLabel = sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      summaryHeaderLabel.value = "SUMMARY";
      summaryHeaderLabel.cellStyle = headerStyle;
      final summaryHeaderValue = sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
      summaryHeaderValue.value = "VALUE";
      summaryHeaderValue.cellStyle = headerStyle;
      rowIndex++;
// REPLACE this block (from summaryData definition to the end of its for loop):

      final summaryData = [
        ["TOTAL BILLS", filteredTotalCount.toString()],
        ["TOTAL ACTIVE CALLS", filteredActiveCount.toString()],
        ["TOTAL PRODUCTIVE CALLS", filteredProductiveCount.toString()],
        ["TOTAL DSR CREATED", filteredDsrCreatedCount.toString()],
        ["TOTAL DSR APPROVED", filteredDsrApprovedCount.toString()],
        ["TOTAL DSR CONFIRMED", filteredDsrConfirmedCount.toString()],
        ["TOTALDSR REJECTED", filteredDsrRejectedCount.toString()],
        ["TOTAL CALL DURATION", filteredTotalCallDuration],
        [
          "TOTAL INVOICE AMOUNT",
          "₹${filteredTotalInvoiceAmount.toStringAsFixed(2)}"
        ],
        [
          "AVG DURATION (8 HRS)",
          "${filteredCallDurationAvg8hrs.toStringAsFixed(1)} min"
        ],
        [
          "DURATION % (8 HRS)",
          "${filteredCallDurationPercentage8hrs.toStringAsFixed(2)}%"
        ],
      ];

// Calculate column widths based on max text length across all rows + header
      double maxLabelWidth = "SUMMARY".length.toDouble();
      double maxValueWidth = "VALUE".length.toDouble();

      for (final item in summaryData) {
        final labelLen = item[0].length.toDouble();
        final valueLen = item[1].length.toDouble();
        if (labelLen > maxLabelWidth) maxLabelWidth = labelLen;
        if (valueLen > maxValueWidth) maxValueWidth = valueLen;
      }

// Character width multiplier ~1.3 + padding of 4
      sheet.setColWidth(0, maxLabelWidth * 1.3 + 4);
      sheet.setColWidth(1, maxValueWidth * 1.3 + 4);

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
          "${tempDir.path}/Call_List_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      final file = File(filePath);
      await file.writeAsBytes(fileBytes!, flush: true);
      if (!mounted) return;
      setState(() {
        isExporting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.green,
        content: Text("Excel exported successfully"),
      ));
      await Share.shareXFiles([XFile(file.path)], text: "Call List Report");
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isExporting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text("Excel Export Failed: $e"),
      ));
    }
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

  Widget buildChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label.isEmpty ? "-" : label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xff40B0FB)),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xff1E293B))),
      ],
    );
  }

  Widget buildInfoRow(String title, String value,
      {IconData? icon, Color? valueColor, FontWeight? valueWeight}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 95,
            child: Text(title,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
          ),
          const Text(":  ",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey)),
          Expanded(
            child: Text(
              value.isEmpty ? "-" : value,
              style: TextStyle(
                fontSize: 12.5,
                color: valueColor ?? Colors.black87,
                fontWeight: valueWeight ?? FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Product details section with see more / see less ───────────────────────
  Widget buildProductDetails(int itemId, List<Map<String, dynamic>> products) {
    if (products.isEmpty) return const SizedBox.shrink();

    final bool isExpanded = _expandedProductCards.contains(itemId);
    final bool hasMore = products.length > 1;

    // Always show first product; show all when expanded
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
                    color: const Color(0xff2196F3).withOpacity(0.18)),
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
          // Product image
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
                      color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildProductTag(
                        "Qty: ${p["quantity"] ?? "-"}", Colors.blue),
                    _buildProductTag(
                        "Rate: ₹${p["rate"] ?? "0"}", const Color(0xff0F9D58)),
                    // _buildProductTag(
                    //     "Disc: ${p["discount"] ?? "0"}%", Colors.orange),
                    // _buildProductTag("Tax: ${p["tax"] ?? "0"}%", Colors.purple),
                  ],
                ),
                // if ((p["description"] ?? "").toString().trim().isNotEmpty) ...[
                //   const SizedBox(height: 4),
                //   Text(
                //     p["description"],
                //     style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                //     maxLines: 2,
                //     overflow: TextOverflow.ellipsis,
                //   ),
                // ],
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
            fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
  // ────────────────────────────────────────────────────────────────────────────

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
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 8))
          ],
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            border: InputBorder.none,
            icon: Icon(icon, color: const Color(0xff2196F3), size: 18),
            suffixIcon: controller.text.trim().isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      controller.clear();
                      setState(() {});
                      fetchCallList(isRefresh: true);
                    },
                  )
                : null,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
          ),
          onChanged: (value) {
            setState(() {});
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 600), () {
              fetchCallList(isRefresh: true);
            });
          },
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
  }) {
    final bool hasValue = value.trim().isNotEmpty;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8))
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xff2196F3), size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasValue ? value : hintText,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: hasValue ? Colors.black87 : Colors.grey.shade500,
                    fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
              if (hasValue)
                GestureDetector(
                    onTap: onClear, child: const Icon(Icons.close, size: 18))
              else
                const Icon(Icons.arrow_drop_down, size: 22),
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
  }) async {
    final TextEditingController searchCtrl = TextEditingController();
    List<Map<String, dynamic>> filteredItems =
        List<Map<String, dynamic>>.from(items);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
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
                              width: 42, child: Divider(thickness: 4))),
                      const SizedBox(height: 10),
                      Text(title,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xffF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
                          controller: searchCtrl,
                          decoration: const InputDecoration(
                            hintText: "Search...",
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search),
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          onChanged: (value) {
                            final q = value.trim().toLowerCase();
                            setModalState(() {
                              filteredItems = items.where((item) {
                                final name =
                                    item["name"]?.toString().toLowerCase() ??
                                        "";
                                return name.contains(q);
                              }).toList();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: filteredItems.isEmpty
                            ? const Center(
                                child: Text("No items found",
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.grey)))
                            : ListView.separated(
                                itemCount: filteredItems.length,
                                separatorBuilder: (_, __) =>
                                    Divider(color: Colors.grey.shade200),
                                itemBuilder: (context, index) {
                                  final item = filteredItems[index];
                                  return ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(item["name"]?.toString() ?? "",
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500)),
                                    subtitle: item["department_name"] != null &&
                                            item["department_name"]
                                                .toString()
                                                .trim()
                                                .isNotEmpty
                                        ? Text(
                                            item["department_name"].toString(),
                                            style:
                                                const TextStyle(fontSize: 12))
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

  Widget buildSearchBar() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8))
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search invoice, customer, note...",
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search, color: Color(0xff2196F3)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                        fetchCallList(isRefresh: true);
                      },
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
            ),
            onChanged: (value) {
              setState(() {});
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 600), () {
                fetchCallList(isRefresh: true);
              });
            },
          ),
        ),
        Row(
          children: [
            _buildSelectionField(
              hintText: "Select family",
              icon: Icons.category_outlined,
              value: selectedFamilyName,
              onTap: () async {
                await _showSearchableSelectionBottomSheet(
                  title: "Select Family",
                  items: fam,
                  onSelected: (item) async {
                    final newFamilyId = item["id"] is int
                        ? item["id"]
                        : int.tryParse(item["id"].toString());
                    setState(() {
                      selectedFamilyId = newFamilyId;
                      selectedFamilyName = item["name"]?.toString() ?? "";
                      selectedStaffId = null;
                      selectedStaffName = "";
                      staffList = [];
                    });
                    if (newFamilyId != null)
                      await getStaffByFamily(newFamilyId);
                    fetchCallList(isRefresh: true);
                  },
                );
              },
              onClear: () {
                setState(() {
                  selectedFamilyId = null;
                  selectedFamilyName = "";
                  selectedStaffId = null;
                  selectedStaffName = "";
                  staffList = [];
                });
                fetchCallList(isRefresh: true);
              },
            ),
            const SizedBox(width: 10),
            _buildSelectionField(
              hintText: "Select staff",
              icon: Icons.person_outline,
              value: selectedStaffName,
              onTap: () async {
                if (selectedFamilyId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Please select family first")));
                  return;
                }
                await _showSearchableSelectionBottomSheet(
                  title: "Select Staff",
                  items: staffList,
                  onSelected: (item) {
                    setState(() {
                      selectedStaffId = item["id"] is int
                          ? item["id"]
                          : int.tryParse(item["id"].toString());
                      selectedStaffName = item["name"]?.toString() ?? "";
                    });
                    fetchCallList(isRefresh: true);
                  },
                );
              },
              onClear: () {
                setState(() {
                  selectedStaffId = null;
                  selectedStaffName = "";
                });
                fetchCallList(isRefresh: true);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildSelectionField(
              hintText: "Select state",
              icon: Icons.location_on_outlined,
              value: selectedStateName,
              onTap: () async {
                await _showSearchableSelectionBottomSheet(
                  title: "Select State",
                  items: stat,
                  onSelected: (item) {
                    setState(() {
                      selectedStateId = item["id"] is int
                          ? item["id"]
                          : int.tryParse(item["id"].toString());
                      selectedStateName = item["name"]?.toString() ?? "";
                    });
                    fetchCallList(isRefresh: true);
                  },
                );
              },
              onClear: () {
                setState(() {
                  selectedStateId = null;
                  selectedStateName = "";
                });
                fetchCallList(isRefresh: true);
              },
            ),
            const SizedBox(width: 10),
            _buildFilterField(
              controller: _customerController,
              hintText: "Search customer",
              icon: Icons.people_outline,
            ),
          ],
        ),
      ],
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
      borderRadius: BorderRadius.circular(16),
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
              fetchCallList(isRefresh: true);
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isClickable
              ? (isSelected ? color.withOpacity(0.16) : color.withOpacity(0.08))
              : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isClickable
                ? (isSelected ? color : color.withOpacity(0.18))
                : color.withOpacity(0.18),
            width: isClickable && isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(value,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTopSummary() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 8))
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 9, 137, 202),
                    Color.fromARGB(255, 46, 120, 239)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.analytics_outlined,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Call Summary",
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 3),
                        Text(
                          selectedSummaryFilter.isEmpty
                              ? "Overview of sales analysis records"
                              : "Filtered by ${selectedSummaryFilter[0].toUpperCase()}${selectedSummaryFilter.substring(1)}",
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.85)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text("Total $filteredTotalCount",
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(children: [
                    Expanded(
                        child: buildSummaryMiniCard(
                            title: "Active",
                            value: "$filteredActiveCount",
                            color: Colors.orange,
                            icon: Icons.phone_in_talk_outlined,
                            filterKey: "active")),
                    const SizedBox(width: 10),
                    Expanded(
                        child: buildSummaryMiniCard(
                            title: "Productive",
                            value: "$filteredProductiveCount",
                            color: Colors.green,
                            icon: Icons.trending_up,
                            filterKey: "productive")),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                        child: buildSummaryMiniCard(
                            title: "Created",
                            value: "$filteredDsrCreatedCount",
                            color: Colors.blue,
                            icon: Icons.edit_note,
                            filterKey: "created")),
                    const SizedBox(width: 10),
                    Expanded(
                        child: buildSummaryMiniCard(
                            title: "Approved",
                            value: "$filteredDsrApprovedCount",
                            color: Colors.green,
                            icon: Icons.verified_outlined,
                            filterKey: "approved")),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                        child: buildSummaryMiniCard(
                            title: "Confirmed",
                            value: "$filteredDsrConfirmedCount",
                            color: Colors.orange,
                            icon: Icons.task_alt,
                            filterKey: "confirmed")),
                    const SizedBox(width: 10),
                    Expanded(
                        child: buildSummaryMiniCard(
                            title: "Rejected",
                            value: "$filteredDsrRejectedCount",
                            color: Colors.red,
                            icon: Icons.cancel_outlined,
                            filterKey: "rejected")),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                        child: buildSummaryMiniCard(
                            title: "Total Duration",
                            value: filteredTotalCallDuration,
                            color: Colors.purple,
                            icon: Icons.access_time,
                            filterKey: "")),
                    const SizedBox(width: 10),
                    Expanded(
                        child: buildSummaryMiniCard(
                            title: "Total Amount",
                            value:
                                "₹${filteredTotalInvoiceAmount.toStringAsFixed(0)}",
                            color: const Color(0xff0F9D58),
                            icon: Icons.currency_rupee_outlined,
                            filterKey: "")),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                        child: buildSummaryMiniCard(
                            title: "Avg Duration (8h)",
                            value:
                                "${filteredCallDurationAvg8hrs.toStringAsFixed(1)} mins",
                            color: Colors.indigo,
                            icon: Icons.av_timer_outlined,
                            filterKey: "")),
                    const SizedBox(width: 10),
                    Expanded(
                        child: buildSummaryMiniCard(
                            title: "Duration % (8h)",
                            value:
                                "${filteredCallDurationPercentage8hrs.toStringAsFixed(2)}%",
                            color: Colors.teal,
                            icon: Icons.pie_chart_outline,
                            filterKey: "")),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDateRangeBar() {
    final bool hasAnyFilter = selectedDateRange != null ||
        _searchController.text.trim().isNotEmpty ||
        _customerController.text.trim().isNotEmpty ||
        selectedStateName.isNotEmpty ||
        selectedFamilyName.isNotEmpty ||
        selectedStaffName.isNotEmpty ||
        selectedSummaryFilter.isNotEmpty;
    if (!hasAnyFilter) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 6))
        ],
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (selectedDateRange != null)
            _buildActiveChip(
              "${formatDateDisplay(selectedDateRange!.start)} to ${formatDateDisplay(selectedDateRange!.end)}",
              Colors.blue,
              onClear: () async {
                setState(() {
                  selectedDateRange = null;
                });
                await fetchCallList(isRefresh: true);
              },
            ),
          if (_searchController.text.trim().isNotEmpty)
            _buildActiveChip(
                "Search: ${_searchController.text.trim()}", Colors.indigo,
                onClear: () {
              _searchController.clear();
              setState(() {});
              fetchCallList(isRefresh: true);
            }),
          if (_customerController.text.trim().isNotEmpty)
            _buildActiveChip(
                "Customer: ${_customerController.text.trim()}", Colors.pink,
                onClear: () {
              _customerController.clear();
              setState(() {});
              fetchCallList(isRefresh: true);
            }),
          if (selectedStateName.isNotEmpty)
            _buildActiveChip("State: $selectedStateName", Colors.teal,
                onClear: () {
              setState(() {
                selectedStateId = null;
                selectedStateName = "";
              });
              fetchCallList(isRefresh: true);
            }),
          if (selectedFamilyName.isNotEmpty)
            _buildActiveChip("Family: $selectedFamilyName", Colors.brown,
                onClear: () {
              setState(() {
                selectedFamilyId = null;
                selectedFamilyName = "";
                selectedStaffId = null;
                selectedStaffName = "";
                staffList = [];
              });
              fetchCallList(isRefresh: true);
            }),
          if (selectedStaffName.isNotEmpty)
            _buildActiveChip("Staff: $selectedStaffName", Colors.deepPurple,
                onClear: () {
              setState(() {
                selectedStaffId = null;
                selectedStaffName = "";
              });
              fetchCallList(isRefresh: true);
            }),
          if (selectedSummaryFilter.isNotEmpty)
            _buildActiveChip(
              "Summary: ${selectedSummaryFilter[0].toUpperCase()}${selectedSummaryFilter.substring(1)}",
              Colors.orange,
              onClear: () {
                setState(() {
                  selectedSummaryFilter = "";
                });
                fetchCallList(isRefresh: true);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActiveChip(String text, Color color,
      {required VoidCallback onClear}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(width: 6),
          GestureDetector(
              onTap: onClear, child: Icon(Icons.close, size: 15, color: color)),
        ],
      ),
    );
  }

  Widget buildEmptyState() {
    return ListView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        buildSearchBar(),
        const SizedBox(height: 12),
        buildDateRangeBar(),
        buildTopSummary(),
        const SizedBox(height: 70),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 8))
            ],
          ),
          child: Column(
            children: [
              Icon(Icons.description_outlined,
                  size: 52, color: Colors.grey.shade400),
              const SizedBox(height: 14),
              const Text("No call records found",
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildSkeletonLine(
      {double width = double.infinity, double height = 12, double radius = 8}) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + (_shimmerController.value * 2), 0),
              end: Alignment(1.0 + (_shimmerController.value * 2), 0),
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildSkeletonCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 8))
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        buildSkeletonLine(width: 120, height: 14),
                        const SizedBox(height: 8),
                        buildSkeletonLine(width: 170, height: 10),
                      ])),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      buildSkeletonLine(width: 90, height: 28, radius: 20),
                      const SizedBox(width: 8),
                      buildSkeletonLine(width: 100, height: 28, radius: 20),
                    ]),
                    const SizedBox(height: 18),
                    buildSkeletonLine(width: 130, height: 14),
                    const SizedBox(height: 14),
                    buildSkeletonLine(height: 12),
                    const SizedBox(height: 12),
                    buildSkeletonLine(height: 12),
                    const SizedBox(height: 12),
                    buildSkeletonLine(height: 12),
                    const SizedBox(height: 12),
                    buildSkeletonLine(height: 12),
                    const SizedBox(height: 12),
                    buildSkeletonLine(width: 140, height: 12),
                    const SizedBox(height: 16),
                    buildSkeletonLine(
                        width: double.infinity, height: 60, radius: 14),
                  ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSkeletonList() {
    return ListView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        buildSearchBar(),
        const SizedBox(height: 12),
        buildDateRangeBar(),
        buildTopSummary(),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          itemBuilder: (context, index) => buildSkeletonCard(index),
        ),
      ],
    );
  }

  Widget buildBottomLoader() {
    if (!isFetchingMore) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Center(
          child: SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _navigateBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xffF4F7FB),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () async {
              final dep = await getdepFromPrefs();
              if (dep == "BDO") {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => bdo_dashbord()));
              } else if (dep == "SD") {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => SdDashboard()));
              } else if (dep == "BDM") {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => bdm_dashbord()));
              } else if (dep == "warehouse") {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => WarehouseDashboard()));
              } else if (dep == "Warehouse Admin") {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => WarehouseAdmin()));
              } else if (dep == "CEO") {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => ceo_dashboard()));
              } else if (dep == "COO") {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => ceo_dashboard()));
              } else if (dep == "CSO") {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => cso_dashboard()));
              } else if (dep == "HR") {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => HrDashboard()));
              } else {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => dashboard()));
              }
            },
          ),
          titleSpacing: 0,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Call List",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              SizedBox(height: 2),
              Text("Sales analysis records",
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          actions: [
            IconButton(
              onPressed: openDateRangePicker,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.date_range, color: Colors.black87),
                  if (selectedDateRange != null)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        height: 8,
                        width: 8,
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: isExporting ? null : exportToExcel,
              icon: isExporting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download, color: Colors.black87),
            ),
            IconButton(
              onPressed: () => fetchCallList(isRefresh: true),
              icon: const Icon(Icons.refresh, color: Colors.black87),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => fetchCallList(isRefresh: true),
          child: isLoading
              ? buildSkeletonList()
              : filteredCallList.isEmpty
                  ? buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                      itemCount: filteredCallList.length + 5,
                      itemBuilder: (context, index) {
                        if (index == 0) return buildSearchBar();
                        if (index == 1) return const SizedBox(height: 12);
                        if (index == 2) return buildDateRangeBar();
                        if (index == 3) return buildTopSummary();
                        if (index == filteredCallList.length + 4)
                          return buildBottomLoader();

                        final item = filteredCallList[index - 4];
                        final int itemId = item["id"] is int
                            ? item["id"]
                            : (int.tryParse(item["id"].toString()) ?? index);
                        final callColor =
                            getCallStatusColor(item["call_status"]);
                        final dsrColor = getDsrStatusColor(item["status"]);
                        final List<Map<String, dynamic>> products =
                            (item["product_details"] as List?)
                                    ?.cast<Map<String, dynamic>>() ??
                                [];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8))
                            ],
                          ),
                          child: Card(
                            margin: EdgeInsets.zero,
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            child: Column(
                              children: [
                                // Card header
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xff40B0FB),
                                        Color(0xff2196F3)
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
                                            color:
                                                Colors.white.withOpacity(0.18),
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        child: Center(
                                          child: Text("${index - 3}",
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              (item["invoice_number"] ?? "")
                                                      .toString()
                                                      .trim()
                                                      .isEmpty
                                                  ? "No Invoice"
                                                  : item["invoice_number"],
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              item["customer_name"]
                                                      .toString()
                                                      .trim()
                                                      .isEmpty
                                                  ? "-"
                                                  : item["customer_name"],
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white
                                                      .withOpacity(0.9)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 5),
                                        decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.18),
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        child: Text(
                                          item["created_by_name"]
                                                  .toString()
                                                  .trim()
                                                  .isEmpty
                                              ? "No Staff"
                                              : item["created_by_name"],
                                          style: const TextStyle(
                                              fontSize: 10.5,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Card body
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          buildChip(
                                            item["call_status"],
                                            callColor,
                                            item["call_status"]
                                                        .toString()
                                                        .toLowerCase() ==
                                                    "productive"
                                                ? Icons.trending_up
                                                : Icons.phone_in_talk,
                                          ),
                                          buildChip(item["status"], dsrColor,
                                              Icons.verified_outlined),
                                        ],
                                      ),
                                      const SizedBox(height: 18),
                                      buildSectionTitle(
                                          "Call Details", Icons.info_outline),
                                      const SizedBox(height: 12),
                                      buildInfoRow("Customer",
                                          item["customer_name"] ?? "",
                                          icon: Icons.person_outline,
                                          valueWeight: FontWeight.w600),
                                      buildInfoRow("Phone", item["phone"] ?? "",
                                          icon: Icons.person_outline,
                                          valueWeight: FontWeight.w600),

                                      buildInfoRow(
                                          "State", item["state_name"] ?? "",
                                          icon: Icons.map_outlined),
                                      buildInfoRow("District",
                                          item["district_name"] ?? "",
                                          icon: Icons.location_city_outlined),
                                      buildInfoRow("Created By",
                                          item["created_by_name"] ?? "",
                                          icon: Icons.badge_outlined),
                                      buildInfoRow(
                                          "Family", item["family_name"] ?? "",
                                          icon: Icons.category_outlined),
                                      buildInfoRow("Duration",
                                          item["call_duration"] ?? "",
                                          icon: Icons.timer_outlined),
                                      buildInfoRow("Invoice Amount",
                                          item["invoice_amount"] ?? "",
                                          icon: Icons.currency_rupee_outlined,
                                          valueColor: const Color(0xff0F9D58),
                                          valueWeight: FontWeight.w700),
                                      buildInfoRow(
                                          "Created At",
                                          formatDateTime(
                                              item["created_at"] ?? ""),
                                          icon: Icons.calendar_today_outlined),

                                      // Product details with see more / see less

                                      // Note section
                                      if ((item["note"] ?? "")
                                          .toString()
                                          .trim()
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xffF8FAFC),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                                color: Colors.grey.shade200),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                      Icons
                                                          .sticky_note_2_outlined,
                                                      size: 16,
                                                      color:
                                                          Colors.grey.shade700),
                                                  const SizedBox(width: 6),
                                                  Text("Note",
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors
                                                              .grey.shade800)),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(item["note"],
                                                  style: const TextStyle(
                                                      fontSize: 12.5,
                                                      color: Colors.black87,
                                                      height: 1.4)),
                                            ],
                                          ),
                                        ),
                                      ],
                                      buildProductDetails(itemId, products),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
