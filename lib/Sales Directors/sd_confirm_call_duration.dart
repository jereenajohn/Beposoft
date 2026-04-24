import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:beposoft/Sales%20Directors/SD_dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
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

class SdConfirmCallDuration extends StatefulWidget {
  const SdConfirmCallDuration({super.key});

  @override
  State<SdConfirmCallDuration> createState() => _SdConfirmCallDurationState();
}

class _SdConfirmCallDurationState extends State<SdConfirmCallDuration> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;

  bool isLoading = true;
  bool isInitialLoading = true;
  bool isLoadingMore = false;
  bool hasNextPage = true;
  bool isExporting = false;
  bool isStaffLoading = false;
  bool isStateLoading = false;
  bool isDistrictLoading = false;
  bool isUpdatingStatus = false;
  String summaryTeamName = "";

  int currentPage = 1;
List<Map<String, dynamic>> staffHourlySummaryList = [];
  int totalCount = 0;
  int staffCount = 0;
  String totalCallDuration = "00:00:00";
  double callDurationAverage8hrs = 0.0;
  int excelSummaryBilling = 0;
  double excelSummaryTotalVolume = 0.0;
  int filteredTotalCount = 0;
  int filteredStaffCount = 0;
  String filteredTotalCallDuration = "00:00:00";
  double filteredCallDurationAverage8hrs = 0.0;

  DateTimeRange? selectedDateRange;
  String selectedSummaryFilter = "";

  int? loggedInFamilyId;

  int? selectedStaffId;
  String selectedStaffName = "";

  int? selectedStateId;
  String selectedStateName = "";

  int? selectedDistrictId;
  String selectedDistrictName = "";
  double excelSummaryTotalCallDuration = 0.0;
  double excelSummaryCallDurationAverage = 0.0;
  double excelSummaryCallDuration8hrs = 0.0;

  List<Map<String, dynamic>> dsrList = [];
  List<Map<String, dynamic>> filteredDsrList = [];

  List<Map<String, dynamic>> staffList = [];
  List<Map<String, dynamic>> stat = [];
  List<Map<String, dynamic>> districtList = [];
  List<Map<String, dynamic>> allDistrictList = [];
  double totalCallDurationMinutes = 0.0;
  double callDurationAverage = 0.0;

  Map<String, dynamic> summaryHourlyDurations = {};
  bool isSummaryHourlyExpanded = false;

  double filteredTotalCallDurationMinutes = 0.0;
  double filteredCallDurationAverage = 0.0;

  final Set<int> _expandedProductCards = {};
  bool isFilterExpanded = false;

  final List<String> allowedStatuses = [
    'dsr approved',
    'dsr rejected',
  ];

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
    await getDistricts();
    await fetchDsrList(isRefresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
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

  Future<void> getstate() async {
    try {
      setState(() {
        isStateLoading = true;
      });

      final token = await gettokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/states/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> statelist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final data = parsed['data'] ?? [];

        for (final item in data) {
          statelist.add({
            'id': item['id'],
            'name': item['name']?.toString() ?? "",
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

  Future<void> getDistricts() async {
    try {
      setState(() {
        isDistrictLoading = true;
      });

      final token = await gettokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/districts/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("DISTRICT STATUS: ${response.statusCode}");
      print("DISTRICT BODY: ${response.body}");

      List<Map<String, dynamic>> tempDistricts = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        dynamic rawData;

        if (parsed is Map && parsed["data"] is List) {
          rawData = parsed["data"];
        } else if (parsed is List) {
          rawData = parsed;
        } else {
          rawData = [];
        }

        for (final item in rawData) {
          tempDistricts.add({
            "id": item["id"],
            "name": item["name"]?.toString() ??
                item["district_name"]?.toString() ??
                "",
            "state_id": item["state"] ??
                item["state_id"] ??
                item["state_name_id"] ??
                item["stateId"],
            "state_name": item["state_name"]?.toString() ?? "",
          });
        }
      }

      if (!mounted) return;
      setState(() {
        allDistrictList = tempDistricts;
        districtList = _getFilteredDistrictsForSelectedState();
        isDistrictLoading = false;
      });
    } catch (e) {
      print("DISTRICT FETCH ERROR: $e");
      if (!mounted) return;
      setState(() {
        allDistrictList = [];
        districtList = [];
        isDistrictLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredDistrictsForSelectedState() {
    if (selectedStateId == null) {
      return List<Map<String, dynamic>>.from(allDistrictList);
    }

    return allDistrictList.where((item) {
      final dynamic stateValue = item["state_id"];
      if (stateValue == null) return false;

      final int? districtStateId =
          stateValue is int ? stateValue : int.tryParse(stateValue.toString());

      return districtStateId == selectedStateId;
    }).toList();
  }

  void _refreshDistrictOptionsAfterStateChange() {
    districtList = _getFilteredDistrictsForSelectedState();

    if (selectedDistrictId != null) {
      final exists = districtList.any((e) => e["id"] == selectedDistrictId);
      if (!exists) {
        selectedDistrictId = null;
        selectedDistrictName = "";
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoading &&
        !isLoadingMore &&
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

  String _capitalizeWords(String value) {
    return value.split(" ").map((e) {
      if (e.isEmpty) return e;
      return e[0].toUpperCase() + e.substring(1);
    }).join(" ");
  }

  int _durationToSeconds(String value) {
    try {
      final parts = value.split(":");
      if (parts.length != 3) return 0;

      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final s = int.tryParse(parts[2]) ?? 0;

      return (h * 3600) + (m * 60) + s;
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

  String _formatDurationFromMinutes(dynamic minutes) {
    final double totalMinutes = minutes is num
        ? minutes.toDouble()
        : double.tryParse(minutes.toString()) ?? 0.0;

    final int totalSeconds = (totalMinutes * 60).round();
    final int hours = totalSeconds ~/ 3600;
    final int mins = (totalSeconds % 3600) ~/ 60;
    final int secs = totalSeconds % 60;

    return "${hours.toString().padLeft(2, '0')}:"
        "${mins.toString().padLeft(2, '0')}:"
        "${secs.toString().padLeft(2, '0')}";
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

    final Map<String, String> queryParams = {};

    if (_searchController.text.trim().isNotEmpty) {
      queryParams["search"] = _searchController.text.trim();
    }

    if (selectedDateRange != null) {
      queryParams["start_date"] = _formatDateForApi(selectedDateRange!.start);
      queryParams["end_date"] = _formatDateForApi(selectedDateRange!.end);
    }

    if (selectedStaffId != null) {
      queryParams["staff_id"] = selectedStaffId.toString();
    }

    if (selectedStateId != null) {
      queryParams["state_id"] = selectedStateId.toString();
    }

    if (selectedDistrictId != null) {
      queryParams["district_id"] = selectedDistrictId.toString();
    }

    // add summary filter params to backend request
    queryParams.addAll(_summaryFilterParams());

    return Uri.parse('$api/api/my/sales/team/detailed/summary/')
        .replace(queryParameters: queryParams);
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      selectedDateRange = null;
      selectedSummaryFilter = "";

      selectedStaffId = null;
      selectedStaffName = "";

      selectedStateId = null;
      selectedStateName = "";

      selectedDistrictId = null;
      selectedDistrictName = "";

      _refreshDistrictOptionsAfterStateChange();
    });

    fetchDsrList(isRefresh: true);
  }

  Widget _buildFilterContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  void _applyFilters() {
    filteredDsrList = dsrList.where((item) {
      final callStatus =
          (item["call_status"] ?? "").toString().toLowerCase().trim();
      final dsrStatus = (item["status"] ?? "").toString().toLowerCase().trim();
      final search = _searchController.text.trim().toLowerCase();

      final matchesSearch = search.isEmpty ||
          (item["invoice_no"] ?? "")
              .toString()
              .toLowerCase()
              .contains(search) ||
          (item["customer_name"] ?? "")
              .toString()
              .toLowerCase()
              .contains(search) ||
          (item["district_name"] ?? "")
              .toString()
              .toLowerCase()
              .contains(search) ||
          (item["created_by_name"] ?? "")
              .toString()
              .toLowerCase()
              .contains(search) ||
          (item["state_name"] ?? "").toString().toLowerCase().contains(search);

      final createdByName =
          (item["created_by_name"] ?? "").toString().toLowerCase().trim();

      final matchesStaff = selectedStaffName.trim().isEmpty ||
          createdByName == selectedStaffName.toLowerCase().trim();

      final stateName =
          (item["state_name"] ?? "").toString().toLowerCase().trim();

      final matchesState = selectedStateName.trim().isEmpty ||
          stateName == selectedStateName.toLowerCase().trim();

      final districtName =
          (item["district_name"] ?? "").toString().toLowerCase().trim();

      final matchesDistrict = selectedDistrictName.trim().isEmpty ||
          districtName == selectedDistrictName.toLowerCase().trim();

      final matchesSummary = selectedSummaryFilter.isEmpty ||
          (selectedSummaryFilter == "active" && callStatus == "active") ||
          (selectedSummaryFilter == "productive" &&
              callStatus == "productive") ||
          (selectedSummaryFilter == "created" && dsrStatus == "dsr created") ||
          (selectedSummaryFilter == "approved" &&
              dsrStatus == "dsr approved") ||
          (selectedSummaryFilter == "confirmed" &&
              dsrStatus == "dsr confirmed") ||
          (selectedSummaryFilter == "rejected" && dsrStatus == "dsr rejected");

      return matchesSearch &&
          matchesStaff &&
          matchesState &&
          matchesDistrict &&
          matchesSummary;
    }).toList();

    filteredTotalCount = filteredDsrList.length;

    final uniqueStaff = <String>{};
    int totalSeconds = 0;

    for (final item in filteredDsrList) {
      final name = (item["created_by_name"] ?? "").toString().trim();
      if (name.isNotEmpty) {
        uniqueStaff.add(name);
      }

      totalSeconds += _durationToSeconds(item["call_duration"] ?? "00:00:00");
    }

    filteredStaffCount = uniqueStaff.length;
    filteredTotalCallDuration = _secondsToDuration(totalSeconds);
    filteredTotalCallDurationMinutes =
        filteredDsrList.isEmpty ? 0.0 : totalSeconds / 60.0;

    // use API response values directly - no frontend calculation
    filteredCallDurationAverage = callDurationAverage;
    filteredCallDurationAverage8hrs = callDurationAverage8hrs;

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
          hasNextPage = false;
          dsrList.clear();
          filteredDsrList.clear();
          _expandedProductCards.clear();
          staffHourlySummaryList = [];
          excelSummaryBilling = 0;
          excelSummaryTotalVolume = 0.0;
          totalCount = 0;
          staffCount = 0;
          totalCallDuration = "00:00:00";
          totalCallDurationMinutes = 0.0;
          callDurationAverage = 0.0;
          callDurationAverage8hrs = 0.0;
          excelSummaryTotalCallDuration = 0.0;
          excelSummaryCallDurationAverage = 0.0;
          excelSummaryCallDuration8hrs = 0.0;

          filteredTotalCount = 0;
          filteredStaffCount = 0;
          filteredTotalCallDuration = "00:00:00";
          filteredTotalCallDurationMinutes = 0.0;
          filteredCallDurationAverage = 0.0;
          filteredCallDurationAverage8hrs = 0.0;
          List<Map<String, dynamic>> tempStaffHourlySummaryList = [];

          summaryTeamName = "";
          summaryHourlyDurations = {};
          isSummaryHourlyExpanded = false;
        });
      } else {
        if (!hasNextPage) return;
        setState(() {
          isLoadingMore = true;
        });
      }

      final token = await gettokenFromPrefs();
      final uri = _buildUri();

      print("FETCH DSR URL: $uri");

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("FETCH DSR STATUS: ${response.statusCode}");
      print("FETCH DSR BODY: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        int tempCount = 0;
        int tempStaffCount = 0;
        String tempTotalCallDuration = "00:00:00";
        double tempTotalCallDurationMinutes = 0.0;
        double tempCallDurationAverage = 0.0;
        double tempCallDurationAverage8hrs = 0.0;
        int tempExcelSummaryBilling = 0;
        double tempExcelSummaryTotalVolume = 0.0;
        double tempExcelSummaryTotalCallDuration = 0.0;
        double tempExcelSummaryCallDurationAverage = 0.0;
        double tempExcelSummaryCallDuration8hrs = 0.0;
        String tempSummaryTeamName = "";
        List<Map<String, dynamic>> tempStaffHourlySummaryList = [];
        Map<String, dynamic> tempSummaryHourlyDurations = {};
        List<Map<String, dynamic>> tempList = [];

        if (parsed is Map && parsed["data"] is List) {
          final List teamData = parsed["data"];

          for (final teamItem in teamData) {
            final teamDetails = teamItem["team"] ?? {};
            final teamSummary = teamItem["summary"] ?? {};
            if (tempSummaryHourlyDurations.isEmpty &&
                teamSummary["hourly_durations"] is Map) {
              tempSummaryHourlyDurations =
                  Map<String, dynamic>.from(teamSummary["hourly_durations"]);
            }
            final List members = teamItem["members"] ?? [];

            final String teamName = teamDetails["team_name"]?.toString() ?? "";
            if (tempSummaryTeamName.isEmpty && teamName.trim().isNotEmpty) {
              tempSummaryTeamName = teamName;
            }

            final billingValue = teamSummary["billing"];
            final int billingCount = billingValue is int
                ? billingValue
                : billingValue is num
                    ? billingValue.toInt()
                    : int.tryParse(billingValue?.toString() ?? "0") ?? 0;

            final totalVolumeValue = teamSummary["total_volume"];
            final double totalVolume = totalVolumeValue is num
                ? totalVolumeValue.toDouble()
                : double.tryParse(totalVolumeValue?.toString() ?? "0") ?? 0.0;

            tempExcelSummaryBilling += billingCount;
            tempExcelSummaryTotalVolume += totalVolume;

            final totalCallDurationSummaryValue =
                teamSummary["total_call_duration"];
            final double totalCallDurationSummary =
                totalCallDurationSummaryValue is num
                    ? totalCallDurationSummaryValue.toDouble()
                    : double.tryParse(
                            totalCallDurationSummaryValue?.toString() ?? "0") ??
                        0.0;

            final callDurationAverageSummaryValue =
                teamSummary["call_duration_average"];
            final double callDurationAverageSummary =
                callDurationAverageSummaryValue is num
                    ? callDurationAverageSummaryValue.toDouble()
                    : double.tryParse(
                            callDurationAverageSummaryValue?.toString() ??
                                "0") ??
                        0.0;

            final callDuration8hrsSummaryValue =
                teamSummary["call_duration_percentage_8hrs"];
            final double callDuration8hrsSummary =
                callDuration8hrsSummaryValue is num
                    ? callDuration8hrsSummaryValue.toDouble()
                    : double.tryParse(
                            callDuration8hrsSummaryValue?.toString() ?? "0") ??
                        0.0;

            tempExcelSummaryTotalCallDuration += totalCallDurationSummary;
            tempExcelSummaryCallDurationAverage += callDurationAverageSummary;
            tempExcelSummaryCallDuration8hrs += callDuration8hrsSummary;

            final reportCountValue = teamSummary["report_count"];
            final int reportCount = reportCountValue is int
                ? reportCountValue
                : reportCountValue is num
                    ? reportCountValue.toInt()
                    : int.tryParse(reportCountValue?.toString() ?? "0") ?? 0;

            tempCount += reportCount;

            final totalBdoCountValue = teamSummary["total_bdo_count"];
            final int totalBdoCount = totalBdoCountValue is int
                ? totalBdoCountValue
                : totalBdoCountValue is num
                    ? totalBdoCountValue.toInt()
                    : int.tryParse(totalBdoCountValue?.toString() ?? "0") ?? 0;

            tempStaffCount += totalBdoCount;

            final totalCallDurationValue = teamSummary["total_call_duration"];
            final double teamTotalCallDuration = totalCallDurationValue is num
                ? totalCallDurationValue.toDouble()
                : double.tryParse(totalCallDurationValue?.toString() ?? "0") ??
                    0.0;

            tempTotalCallDurationMinutes += teamTotalCallDuration;

            final callDurationAverageValue =
                teamSummary["call_duration_average"];
            final double teamCallDurationAverage =
                callDurationAverageValue is num
                    ? callDurationAverageValue.toDouble()
                    : double.tryParse(
                            callDurationAverageValue?.toString() ?? "0") ??
                        0.0;

            final callDurationPercentageValue =
                teamSummary["call_duration_percentage_8hrs"];
            final double teamCallDurationPercentage =
                callDurationPercentageValue is num
                    ? callDurationPercentageValue.toDouble()
                    : double.tryParse(
                            callDurationPercentageValue?.toString() ?? "0") ??
                        0.0;

            tempCallDurationAverage = teamCallDurationAverage;
            tempCallDurationAverage8hrs = teamCallDurationPercentage;

            for (final member in members) {
              final memberSummary = member["summary"] ?? {};
             

tempStaffHourlySummaryList.add({
  "staff_id": member["staff_id"],
  "staff_name": member["staff_name"]?.toString() ?? "",
  "hourly_durations": memberSummary["hourly_durations"] is Map
      ? Map<String, dynamic>.from(memberSummary["hourly_durations"])
      : {},
  "total_call_duration": memberSummary["total_call_duration"] ?? 0,
  "call_duration_average": memberSummary["call_duration_average"] ?? 0,
  "call_duration_percentage_8hrs":
      memberSummary["call_duration_percentage_8hrs"] ?? 0,
});
              final List reports = member["reports"] ?? [];

              for (final item in reports) {
                final invoiceDetails = item["invoice"] ?? {};
                final customerDetails = invoiceDetails["customer"] ?? {};
                final rawProducts = invoiceDetails["items"];
                final List<Map<String, dynamic>> products = [];

                if (rawProducts is List) {
                  for (final p in rawProducts) {
                    final product = p["product"] ?? {};

                    final quantityValue = p["quantity"];
                    final int quantity = quantityValue is int
                        ? quantityValue
                        : quantityValue is num
                            ? quantityValue.toInt()
                            : int.tryParse(quantityValue?.toString() ?? "0") ??
                                0;

                    products.add({
                      "product_id": product["id"],
                      "name": product["name"]?.toString() ?? "",
                      "image": product["image"] != null
                          ? "$api${product["image"].toString()}"
                          : "",
                      "quantity": quantity,
                    });
                  }
                }

                final memberCallDurationPercentageValue =
                    memberSummary["call_duration_percentage_8hrs"];
                final double memberCallDurationPercentage =
                    memberCallDurationPercentageValue is num
                        ? memberCallDurationPercentageValue.toDouble()
                        : double.tryParse(
                                memberCallDurationPercentageValue?.toString() ??
                                    "0") ??
                            0.0;

                final int totalQuantity = products.fold<int>(
                  0,
                  (sum, p) {
                    final qtyValue = p["quantity"];
                    final int qty = qtyValue is int
                        ? qtyValue
                        : qtyValue is num
                            ? qtyValue.toInt()
                            : int.tryParse(qtyValue?.toString() ?? "0") ?? 0;
                    return sum + qty;
                  },
                );

                tempList.add({
                  "id": item["id"],

                  // team details
                  "team": teamDetails["team_id"] ?? item["team"],
                  "team_name": item["team"]?.toString() ??
                      teamDetails["team_name"]?.toString() ??
                      "",

                  // family / division details
                  "family_id": item["family_id"] ??
                      invoiceDetails["family_id"] ??
                      member["family_id"] ??
                      teamDetails["family_id"],
                  "family_name": item["family_name"]?.toString() ??
                      invoiceDetails["family_name"]?.toString() ??
                      member["family_name"]?.toString() ??
                      teamDetails["family_name"]?.toString() ??
                      "",

                  // keep old keys too if your UI is already using them
                  "division": item["family_id"] ??
                      invoiceDetails["family_id"] ??
                      member["family_id"] ??
                      teamDetails["family_id"],
                  "division_name": item["family_name"]?.toString() ??
                      invoiceDetails["family_name"]?.toString() ??
                      member["family_name"]?.toString() ??
                      teamDetails["family_name"]?.toString() ??
                      "",

                  // location
                  "state": item["state"],
                  "state_name": item["state"]?.toString() ?? "",
                  "district": item["district"],
                  "district_name": item["district"]?.toString() ?? "",

                  // staff
                  "created_by": member["staff_id"],
                  "created_by_name": item["created_by"]?.toString() ??
                      member["staff_name"]?.toString() ??
                      "",

                  // invoice
                  "invoice_id": invoiceDetails["id"],
                  "invoice_no": invoiceDetails["invoice"]?.toString() ?? "",
                  "invoice_amount":
                      invoiceDetails["invoice_total"]?.toString() ?? "0",
                  "invoice_payment_status":
                      invoiceDetails["payment_status"]?.toString() ?? "",
                  "invoice_status": invoiceDetails["status"]?.toString() ?? "",
                  "order_date": invoiceDetails["order_date"]?.toString() ?? "",

                  // customer
                  "customer_id": customerDetails["id"],
                  "customer_name":
                      item["customer_name"]?.toString().trim().isNotEmpty ==
                              true
                          ? item["customer_name"].toString()
                          : customerDetails["name"]?.toString() ?? "",
                  "phone": item["phone"]?.toString().trim().isNotEmpty == true
                      ? item["phone"].toString()
                      : customerDetails["phone"]?.toString() ?? "",
                  "customer_state": customerDetails["state"]?.toString() ?? "",

                  // call / dsr data
                  "call_status": item["call_status"]?.toString() ?? "",
                  "status": item["status"]?.toString() ?? "",
                  "call_duration":
                      item["call_duration"]?.toString() ?? "00:00:00",
                  "call_duration_percentage_8hrs": memberCallDurationPercentage,
                  "note": item["note"]?.toString() ?? "",
                  "created_at": item["created_at"]?.toString() ?? "",
                  "updated_at": item["updated_at"]?.toString() ?? "",

                  // product summary
                  "total_quantity": totalQuantity.toString(),
                  "total_items_count": products.length.toString(),
                  "product_details": products,
                });
              }
            }
          }

          int totalSeconds = 0;
          for (final item in tempList) {
            totalSeconds +=
                _durationToSeconds(item["call_duration"] ?? "00:00:00");
          }

          tempTotalCallDuration = _secondsToDuration(totalSeconds);

          if (tempStaffCount == 0) {
            final uniqueStaff = <String>{};
            for (final item in tempList) {
              final name = (item["created_by_name"] ?? "").toString().trim();
              if (name.isNotEmpty) {
                uniqueStaff.add(name);
              }
            }
            tempStaffCount = uniqueStaff.length;
          }

          if (tempCount == 0) {
            tempCount = tempList.length;
          }
        }

        if (!mounted) return;

        setState(() {
          totalCount = tempCount;
          staffCount = tempStaffCount;
          totalCallDuration = tempTotalCallDuration;
          totalCallDurationMinutes = tempTotalCallDurationMinutes;

          // summary card values
          callDurationAverage = tempCallDurationAverage;
          callDurationAverage8hrs = tempCallDurationAverage8hrs;
          summaryTeamName = tempSummaryTeamName;
          summaryHourlyDurations = tempSummaryHourlyDurations;
          isSummaryHourlyExpanded = false;

          excelSummaryBilling = tempExcelSummaryBilling;
          excelSummaryTotalVolume = tempExcelSummaryTotalVolume;
          excelSummaryTotalCallDuration = tempExcelSummaryTotalCallDuration;
          excelSummaryCallDurationAverage = tempExcelSummaryCallDurationAverage;
          excelSummaryCallDuration8hrs = tempExcelSummaryCallDuration8hrs;

          dsrList = tempList;
          staffHourlySummaryList = tempStaffHourlySummaryList;

          hasNextPage = false;
          isLoading = false;
          isInitialLoading = false;
          isLoadingMore = false;
        });

        _applyFilters();
      } else {
        if (!mounted) return;

        setState(() {
          isLoading = false;
          isInitialLoading = false;
          isLoadingMore = false;
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
        isInitialLoading = false;
        isLoadingMore = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error: $e"),
        ),
      );
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

  Widget buildInfoRow(
    String title,
    String value, {
    IconData? icon,
    Color? valueColor,
    FontWeight? valueWeight,
  }) {
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
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const Text(
            ":  ",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
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

  Widget _buildSummaryHourlyDurationSection() {
    if (summaryHourlyDurations.isEmpty) return const SizedBox.shrink();

    final entries = summaryHourlyDurations.entries.toList();
    final visibleEntries = isSummaryHourlyExpanded
        ? entries
        : (entries.length > 3 ? entries.take(3).toList() : entries);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule, size: 16, color: Color(0xff40B0FB)),
              SizedBox(width: 6),
              Text(
                "Hourly Durations",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...visibleEntries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    _formatDurationFromMinutes(entry.value),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (entries.length > 3)
            GestureDetector(
              onTap: () {
                setState(() {
                  isSummaryHourlyExpanded = !isSummaryHourlyExpanded;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(top: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xff2196F3).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xff2196F3).withOpacity(0.18),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSummaryHourlyExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 16,
                      color: const Color(0xff2196F3),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isSummaryHourlyExpanded ? "See Less" : "See More",
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

  Widget _buildProductRow(Map<String, dynamic> p) {
    final String imageUrl = (p["image"] ?? "").toString().trim();

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
                    _buildProductTag(
                        "Qty: ${p["quantity"] ?? "-"}", Colors.blue),
                    if ((p["rate"] ?? "").toString().trim().isNotEmpty)
                      _buildProductTag("Rate: ${p["rate"]}", Colors.green),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildFilterField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        onChanged: (value) {
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 500), () {
            fetchDsrList(isRefresh: true);
          });
          setState(() {});
        },
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 12,
            color: Color(0xff64748B),
          ),
          prefixIcon: Icon(icon, color: const Color(0xff64748B), size: 18),
          suffixIcon: controller.text.trim().isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xff64748B),
                    size: 18,
                  ),
                  onPressed: () {
                    controller.clear();
                    fetchDsrList(isRefresh: true);
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xffF8FAFC),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(color: Color(0xff40B0FB), width: 1.1),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionField({
    required String hintText,
    required IconData icon,
    required String value,
    required bool isLoading,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final bool hasValue = value.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xffF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xff64748B), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isLoading ? "Loading..." : (hasValue ? value : hintText),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  color: hasValue ? Colors.black87 : const Color(0xff64748B),
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (hasValue && onClear != null)
              InkWell(
                onTap: onClear,
                child: const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.close, size: 16, color: Color(0xff64748B)),
                ),
              )
            else
              const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xff64748B),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSearchableSelectionBottomSheet({
    required String title,
    required List<Map<String, dynamic>> items,
    required String searchHint,
    required String emptyText,
    required bool searchStaffFields,
    required Function(Map<String, dynamic>) onSelected,
  }) async {
    final TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> filteredItems = List.from(items);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setBottomState) {
            void applySearch(String query) {
              final q = query.trim().toLowerCase();

              if (q.isEmpty) {
                filteredItems = List.from(items);
              } else {
                filteredItems = items.where((item) {
                  final name = (item["name"] ?? "").toString().toLowerCase();
                  final phone = (item["phone"] ?? "").toString().toLowerCase();
                  final department =
                      (item["department_name"] ?? "").toString().toLowerCase();
                  final email = (item["email"] ?? "").toString().toLowerCase();

                  if (searchStaffFields) {
                    return name.contains(q) ||
                        phone.contains(q) ||
                        department.contains(q) ||
                        email.contains(q);
                  }

                  return name.contains(q);
                }).toList();
              }

              setBottomState(() {});
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 14,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 14,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xffF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: searchController,
                          onChanged: applySearch,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: searchHint,
                            icon: const Icon(Icons.search),
                            suffixIcon: searchController.text.trim().isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      searchController.clear();
                                      applySearch("");
                                    },
                                    icon: const Icon(Icons.close),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filteredItems.isEmpty
                            ? Center(
                                child: Text(
                                  emptyText,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: filteredItems.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final item = filteredItems[index];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      item["name"]?.toString() ?? "",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: searchStaffFields &&
                                            (item["department_name"] ?? "")
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
                                      Navigator.pop(sheetContext);
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

  bool get _hasActiveFilters {
    return _searchController.text.trim().isNotEmpty ||
        selectedStaffId != null ||
        selectedStateId != null ||
        selectedDistrictId != null ||
        selectedDateRange != null ||
        selectedSummaryFilter.isNotEmpty;
  }

  Widget _buildSearchBar({VoidCallback? onApply}) {
    final bool hasAnyFilter = _hasActiveFilters;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (hasAnyFilter)
                InkWell(
                  onTap: () {
                    setState(() {
                      _searchController.clear();
                      selectedDateRange = null;
                      selectedSummaryFilter = "";
                      selectedStaffId = null;
                      selectedStaffName = "";
                      selectedStateId = null;
                      selectedStateName = "";
                      selectedDistrictId = null;
                      selectedDistrictName = "";
                      _refreshDistrictOptionsAfterStateChange();
                    });
                    fetchDsrList(isRefresh: true);
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.red.withOpacity(0.15)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restart_alt,
                            size: 15, color: Colors.redAccent),
                        SizedBox(width: 4),
                        Text(
                          "Clear",
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFilterField(
            controller: _searchController,
            hintText: "Search invoice / customer / district / staff",
            icon: Icons.search,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildSelectionField(
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
                        const SnackBar(content: Text("No staff found")),
                      );
                      return;
                    }

                    await _showSearchableSelectionBottomSheet(
                      title: "Select Staff",
                      items: staffList,
                      searchHint: "Search staff",
                      emptyText: "No staff found",
                      searchStaffFields: true,
                      onSelected: (item) {
                        setState(() {
                          selectedStaffId = item["id"] is int
                              ? item["id"]
                              : int.tryParse(item["id"].toString());
                          selectedStaffName = item["name"]?.toString() ?? "";
                        });
                      },
                    );
                  },
                  onClear: () {
                    setState(() {
                      selectedStaffId = null;
                      selectedStaffName = "";
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSelectionField(
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
                        const SnackBar(content: Text("No states found")),
                      );
                      return;
                    }

                    await _showSearchableSelectionBottomSheet(
                      title: "Select State",
                      items: stat,
                      searchHint: "Search state",
                      emptyText: "No state found",
                      searchStaffFields: false,
                      onSelected: (item) {
                        setState(() {
                          selectedStateId = item["id"] is int
                              ? item["id"]
                              : int.tryParse(item["id"].toString());
                          selectedStateName = item["name"]?.toString() ?? "";
                          _refreshDistrictOptionsAfterStateChange();
                        });
                      },
                    );
                  },
                  onClear: () {
                    setState(() {
                      selectedStateId = null;
                      selectedStateName = "";
                      _refreshDistrictOptionsAfterStateChange();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildSelectionField(
                  hintText: "Select district",
                  icon: Icons.map_outlined,
                  value: selectedDistrictName,
                  isLoading: isDistrictLoading,
                  onTap: () async {
                    if (isDistrictLoading) return;

                    if (allDistrictList.isEmpty) {
                      await getDistricts();
                    }

                    if (!mounted) return;

                    final visibleDistricts =
                        _getFilteredDistrictsForSelectedState();

                    if (visibleDistricts.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No districts found")),
                      );
                      return;
                    }

                    await _showSearchableSelectionBottomSheet(
                      title: "Select District",
                      items: visibleDistricts,
                      searchHint: "Search district",
                      emptyText: "No district found",
                      searchStaffFields: false,
                      onSelected: (item) {
                        setState(() {
                          selectedDistrictId = item["id"] is int
                              ? item["id"]
                              : int.tryParse(item["id"].toString());
                          selectedDistrictName = item["name"]?.toString() ?? "";
                        });
                      },
                    );
                  },
                  onClear: () {
                    setState(() {
                      selectedDistrictId = null;
                      selectedDistrictName = "";
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: _pickDateRange,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xffF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.date_range_outlined,
                          color: Color(0xff64748B),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            selectedDateRange == null
                                ? "Select date range"
                                : "${formatDateOnly(selectedDateRange!.start)} to ${formatDateOnly(selectedDateRange!.end)}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: selectedDateRange == null
                                  ? const Color(0xff64748B)
                                  : Colors.black87,
                              fontWeight: selectedDateRange == null
                                  ? FontWeight.w500
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (selectedDateRange != null)
                          InkWell(
                            onTap: _clearDateRange,
                            child: const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: Color(0xff64748B),
                              ),
                            ),
                          )
                        else
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Color(0xff64748B),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      selectedDateRange = null;
                      selectedSummaryFilter = "";
                      selectedStaffId = null;
                      selectedStaffName = "";
                      selectedStateId = null;
                      selectedStateName = "";
                      selectedDistrictId = null;
                      selectedDistrictName = "";
                      _refreshDistrictOptionsAfterStateChange();
                    });
                    fetchDsrList(isRefresh: true);
                  },
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: const Text("Clear Filters"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: BorderSide(color: Colors.redAccent.withOpacity(0.30)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    fetchDsrList(isRefresh: true);
                    if (onApply != null) {
                      onApply();
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text("Apply Filters"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2196F3),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
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
              ? (isSelected ? color.withOpacity(0.18) : color.withOpacity(0.08))
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
              child: Icon(icon, size: 18, color: color),
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

  Future<void> _openFilterBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 14,
                  right: 14,
                  top: 10,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 14,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.filter_alt_outlined,
                          color: Color(0xff2196F3),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "Filters",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildSearchBar(
                      onApply: () {
                        Navigator.pop(sheetContext);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopSummary() {
    final int activeCount = filteredDsrList
        .where((e) =>
            (e["call_status"] ?? "").toString().toLowerCase().trim() ==
            "active")
        .length;

    final int productiveCount = filteredDsrList
        .where((e) =>
            (e["call_status"] ?? "").toString().toLowerCase().trim() ==
            "productive")
        .length;

    final int createdCount = filteredDsrList
        .where((e) =>
            (e["status"] ?? "").toString().toLowerCase().trim() ==
            "dsr created")
        .length;

    final int approvedCount = filteredDsrList
        .where((e) =>
            (e["status"] ?? "").toString().toLowerCase().trim() ==
            "dsr approved")
        .length;

    final int confirmedCount = filteredDsrList
        .where((e) =>
            (e["status"] ?? "").toString().toLowerCase().trim() ==
            "dsr confirmed")
        .length;

    final int rejectedCount = filteredDsrList
        .where((e) =>
            (e["status"] ?? "").toString().toLowerCase().trim() ==
            "dsr rejected")
        .length;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        // const Text(
                        //   "Approve BDO Call Summary",
                        //   style: TextStyle(
                        //     fontSize: 15,
                        //     fontWeight: FontWeight.bold,
                        //     color: Colors.white,
                        //   ),
                        // ),
                        if (summaryTeamName.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            summaryTeamName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                        ],
                        const SizedBox(height: 3),
                        Text(
                          selectedSummaryFilter.isEmpty
                              ? "BDO call duration records"
                              : "Filtered by ${selectedSummaryFilter[0].toUpperCase()}${selectedSummaryFilter.substring(1)}",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                          title: "Active Calls",
                          value: "$activeCount",
                          color: Colors.orange,
                          icon: Icons.phone_in_talk_outlined,
                          filterKey: "active",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: buildSummaryMiniCard(
                          title: "Productive Calls",
                          value: "$productiveCount",
                          color: Colors.green,
                          icon: Icons.trending_up_outlined,
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
                          title: "DSR Created",
                          value: "$createdCount",
                          color: Colors.blue,
                          icon: Icons.edit_note_outlined,
                          filterKey: "created",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: buildSummaryMiniCard(
                          title: "DSR Approved",
                          value: "$approvedCount",
                          color: Colors.teal,
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
                          title: "DSR Confirmed",
                          value: "$confirmedCount",
                          color: Colors.deepOrange,
                          icon: Icons.task_alt_outlined,
                          filterKey: "confirmed",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: buildSummaryMiniCard(
                          title: "DSR Rejected",
                          value: "$rejectedCount",
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
                          title: "Total Call Duration",
                          value:
                              "$filteredTotalCallDuration (${filteredTotalCallDurationMinutes.toStringAsFixed(2)}) mins",
                          color: const Color(0xff7C3AED),
                          icon: Icons.timer_outlined,
                          filterKey: "",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: buildSummaryMiniCard(
                          title: "Total Volume",
                          value: excelSummaryTotalVolume.toStringAsFixed(2),
                          color: const Color(0xff14B8A6),
                          icon: Icons.inventory_2_outlined,
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
                          title: "Call Avg Mins",
                          value: filteredCallDurationAverage.toStringAsFixed(2),
                          color: const Color(0xff0EA5E9),
                          icon: Icons.av_timer_outlined,
                          filterKey: "",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: buildSummaryMiniCard(
                          title: "8 Hrs %",
                          value:
                              "${filteredCallDurationAverage8hrs.toStringAsFixed(2)}%",
                          color: const Color(0xff8B5CF6),
                          icon: Icons.percent_outlined,
                          filterKey: "",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildSummaryHourlyDurationSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterChip({
    required String label,
    required Color color,
    required VoidCallback onClear,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onClear,
            child: Icon(Icons.close, size: 16, color: color),
          ),
        ],
      ),
    );
  }

  Future<void> _showStatusBottomSheet(Map<String, dynamic> item) async {
    String selectedStatus = (item["status"] ?? "").toString().trim();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setBottomState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Update DSR Status",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
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
                        onChanged: isUpdatingStatus
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
                        onPressed: isUpdatingStatus
                            ? null
                            : () async {
                                Navigator.pop(sheetContext);
                                await updateDsrStatus(
                                    item["id"], selectedStatus);
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isUpdatingStatus
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
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> updateDsrStatus(int id, String status) async {
    try {
      setState(() {
        isUpdatingStatus = true;
      });

      final token = await gettokenFromPrefs();

      final response = await http.patch(
        Uri.parse('$api/api/sales/team/member/daily/report/status/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "status": status,
        }),
      );

      print("PATCH STATUS CODE: ${response.statusCode}");
      print("PATCH STATUS BODY: ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200 ||
          response.statusCode == 202 ||
          response.statusCode == 204) {
        await fetchDsrList(isRefresh: true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("Status updated successfully"),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Failed: ${response.body}"),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error: $e"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUpdatingStatus = false;
        });
      }
    }
  }

  Widget _buildCard(Map<String, dynamic> item, int index) {
    final int itemId =
        item["id"] is int ? item["id"] : int.tryParse("${item["id"]}") ?? index;

    final Color callColor = getCallStatusColor(item["call_status"] ?? "");
    final Color dsrColor = getDsrStatusColor(item["status"] ?? "");

    final List<Map<String, dynamic>> products =
        (item["product_details"] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            [];

    return Container(
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        "${index + 1}",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (item["invoice_no"] ?? "").toString().trim().isEmpty
                              ? "No Invoice"
                              : item["invoice_no"].toString(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          (item["created_by_name"] ?? "")
                                  .toString()
                                  .trim()
                                  .isEmpty
                              ? "-"
                              : item["created_by_name"].toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.90),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showStatusBottomSheet(item),
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                    tooltip: "Edit Status",
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      buildChip(item["call_status"] ?? "", callColor),
                      // buildChip(
                      //   item["status"] ?? "",
                      //   dsrColor,
                      //   onTap: () => _showStatusBottomSheet(item),
                      // ),
                      buildChip(
                        item["status"] ?? "",
                        dsrColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  buildSectionTitle("Record Details", Icons.info_outline),
                  const SizedBox(height: 12),
                  buildInfoRow(
                    "Division",
                    item["division_name"] ?? "",
                    icon: Icons.account_tree_outlined,
                  ),
                  buildInfoRow(
                    "Team",
                    item["team_name"] ?? "",
                    icon: Icons.groups_outlined,
                  ),
                  buildInfoRow(
                    "Staff",
                    item["created_by_name"] ?? "",
                    icon: Icons.badge_outlined,
                  ),
                  buildInfoRow(
                    "Customer",
                    item["customer_name"] ?? "",
                    icon: Icons.person_outline,
                    valueWeight: FontWeight.w600,
                  ),
                  buildInfoRow(
                    "Phone",
                    item["phone"] ?? "",
                    icon: Icons.call_outlined,
                  ),
                  buildInfoRow(
                    "Invoice No",
                    item["invoice_no"] ?? "",
                    icon: Icons.receipt_long_outlined,
                  ),
                  buildInfoRow(
                    "State",
                    item["state_name"] ?? "",
                    icon: Icons.map_outlined,
                  ),
                  buildInfoRow(
                    "District",
                    item["district_name"] ?? "",
                    icon: Icons.location_city_outlined,
                  ),
                  buildInfoRow(
                    "Duration",
                    item["call_duration"] ?? "",
                    icon: Icons.timer_outlined,
                    valueColor: const Color(0xff7C3AED),
                    valueWeight: FontWeight.w700,
                  ),
                  buildInfoRow(
                    "Duration % 8hrs",
                    "${(double.tryParse((item["call_duration_percentage_8hrs"] ?? 0).toString()) ?? 0).toStringAsFixed(2)}%",
                    icon: Icons.pie_chart_outline,
                  ),
                  buildInfoRow(
                    "Invoice Amount",
                    "₹${_formatAmount(item["invoice_amount"])}",
                    icon: Icons.currency_rupee_outlined,
                    valueColor: Colors.green.shade700,
                    valueWeight: FontWeight.w700,
                  ),
                  buildInfoRow(
                    "Payment",
                    item["invoice_payment_status"] ?? "",
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  // buildInfoRow(
                  //   "Invoice Status",
                  //   item["invoice_status"] ?? "",
                  //   icon: Icons.inventory_2_outlined,
                  // ),
                  buildInfoRow(
                    "Order Date",
                    item["order_date"] ?? "",
                    icon: Icons.calendar_today_outlined,
                  ),
                  buildInfoRow(
                    "Created At",
                    formatDateTime(item["created_at"] ?? ""),
                    icon: Icons.access_time_outlined,
                  ),
                  if ((item["note"] ?? "").toString().trim().isNotEmpty)
                    buildInfoRow(
                      "Note",
                      item["note"] ?? "",
                      icon: Icons.sticky_note_2_outlined,
                    ),
                  buildInfoRow(
                    "Total Qty",
                    item["total_quantity"] ?? "",
                    icon: Icons.shopping_bag_outlined,
                  ),
                  // buildInfoRow(
                  //   "Total Items",
                  //   item["total_items_count"] ?? "",
                  //   icon: Icons.format_list_bulleted_outlined,
                  // ),
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
          // _buildSearchBar(),
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
        // _buildSearchBar(),
        Expanded(
          child: filteredDsrList.isEmpty
              ? RefreshIndicator(
                  onRefresh: () => fetchDsrList(isRefresh: true),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _buildTopSummary(),
                      const SizedBox(height: 120),
                      Center(
                        child: Column(
                          children: const [
                            Icon(
                              Icons.inbox_outlined,
                              size: 54,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              "No DSR records found",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => fetchDsrList(isRefresh: true),
                  child: ListView.builder(
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
        ),
      ],
    );
  }
Future<void> exportToExcel() async {
  try {
    if (filteredDsrList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text("No data available to export"),
        ),
      );
      return;
    }

    setState(() {
      isExporting = true;
    });

    final ex.Excel excel = ex.Excel.createExcel();
    final String sheetName = "Approve BDO Duration";
    final ex.Sheet sheet = excel[sheetName];

    final ex.CellStyle titleStyle = ex.CellStyle(
      bold: true,
      fontSize: 16,
      horizontalAlign: ex.HorizontalAlign.Center,
      verticalAlign: ex.VerticalAlign.Center,
      backgroundColorHex: "#1F4E78",
      fontColorHex: "#FFFFFF",
    );

    final ex.CellStyle infoStyle = ex.CellStyle(
      bold: true,
      fontSize: 10,
      horizontalAlign: ex.HorizontalAlign.Left,
      verticalAlign: ex.VerticalAlign.Center,
      backgroundColorHex: "#D9EAF7",
    );

    final ex.CellStyle headerStyle = ex.CellStyle(
      bold: true,
      fontSize: 10,
      horizontalAlign: ex.HorizontalAlign.Center,
      verticalAlign: ex.VerticalAlign.Center,
      backgroundColorHex: "#DCE6F1",
      fontColorHex: "#C00000",
      leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
    );

    final ex.CellStyle textCellStyle = ex.CellStyle(
      fontSize: 10,
      horizontalAlign: ex.HorizontalAlign.Left,
      verticalAlign: ex.VerticalAlign.Center,
      leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
    );

    final ex.CellStyle centerCellStyle = ex.CellStyle(
      fontSize: 10,
      horizontalAlign: ex.HorizontalAlign.Center,
      verticalAlign: ex.VerticalAlign.Center,
      leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
    );

    final ex.CellStyle amountCellStyle = ex.CellStyle(
      fontSize: 10,
      horizontalAlign: ex.HorizontalAlign.Right,
      verticalAlign: ex.VerticalAlign.Center,
      leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
    );

    final ex.CellStyle summaryTitleStyle = ex.CellStyle(
      bold: true,
      fontSize: 13,
      horizontalAlign: ex.HorizontalAlign.Center,
      verticalAlign: ex.VerticalAlign.Center,
      backgroundColorHex: "#1F4E78",
      fontColorHex: "#FFFFFF",
      leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
    );

    final ex.CellStyle summaryHeaderStyle = ex.CellStyle(
      bold: true,
      fontSize: 10,
      horizontalAlign: ex.HorizontalAlign.Center,
      verticalAlign: ex.VerticalAlign.Center,
      backgroundColorHex: "#D9E2F3",
      leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
    );

    final ex.CellStyle summaryLabelStyle = ex.CellStyle(
      bold: true,
      fontSize: 10,
      horizontalAlign: ex.HorizontalAlign.Left,
      verticalAlign: ex.VerticalAlign.Center,
      leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
    );

    final ex.CellStyle summaryValueStyle = ex.CellStyle(
      fontSize: 10,
      horizontalAlign: ex.HorizontalAlign.Center,
      verticalAlign: ex.VerticalAlign.Center,
      leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
      bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
    );

    ex.CellStyle getCallStatusStyle(String status) {
      final s = status.toLowerCase().trim();

      if (s == "productive") {
        return ex.CellStyle(
          bold: true,
          fontSize: 10,
          horizontalAlign: ex.HorizontalAlign.Center,
          verticalAlign: ex.VerticalAlign.Center,
          fontColorHex: "#008000",
          leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
        );
      } else if (s == "active") {
        return ex.CellStyle(
          bold: true,
          fontSize: 10,
          horizontalAlign: ex.HorizontalAlign.Center,
          verticalAlign: ex.VerticalAlign.Center,
          fontColorHex: "#FF8C00",
          leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
        );
      }

      return centerCellStyle;
    }

    ex.CellStyle getDsrStatusStyle(String status) {
      final s = status.toLowerCase().trim();

      if (s == "dsr approved") {
        return ex.CellStyle(
          bold: true,
          fontSize: 10,
          horizontalAlign: ex.HorizontalAlign.Center,
          verticalAlign: ex.VerticalAlign.Center,
          fontColorHex: "#008000",
          leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
        );
      } else if (s == "dsr rejected") {
        return ex.CellStyle(
          bold: true,
          fontSize: 10,
          horizontalAlign: ex.HorizontalAlign.Center,
          verticalAlign: ex.VerticalAlign.Center,
          fontColorHex: "#C00000",
          leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
        );
      } else if (s == "dsr created") {
        return ex.CellStyle(
          bold: true,
          fontSize: 10,
          horizontalAlign: ex.HorizontalAlign.Center,
          verticalAlign: ex.VerticalAlign.Center,
          fontColorHex: "#1F4E78",
          leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
        );
      } else if (s == "dsr confirmed") {
        return ex.CellStyle(
          bold: true,
          fontSize: 10,
          horizontalAlign: ex.HorizontalAlign.Center,
          verticalAlign: ex.VerticalAlign.Center,
          fontColorHex: "#FF8C00",
          leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
          bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin),
        );
      }

      return centerCellStyle;
    }

    final Map<int, int> columnWidths = {};

    void updateColumnWidth(int col, String text) {
      final int length = text.length;
      if (!columnWidths.containsKey(col) || length > columnWidths[col]!) {
        columnWidths[col] = length;
      }
    }

    void setCell(
      int col,
      int row,
      dynamic value,
      ex.CellStyle style,
    ) {
      final String text = value?.toString() ?? "";
      final cell = sheet.cell(
        ex.CellIndex.indexByColumnRow(
          columnIndex: col,
          rowIndex: row,
        ),
      );
      cell.value = text;
      cell.cellStyle = style;
      updateColumnWidth(col, text);
    }

    String safeValue(dynamic value) {
      if (value == null) return "-";
      final String text = value.toString().trim();
      return text.isEmpty ? "-" : text;
    }

    final String teamName = filteredDsrList.isNotEmpty
        ? safeValue(filteredDsrList.first["team_name"])
        : "-";

    final String dateRangeText = _buildExcelDateRangeLabel();

    sheet.merge(
      ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      ex.CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: 0),
    );
    setCell(0, 0, "APPROVE BDO DURATION REPORT", titleStyle);

    sheet.merge(
      ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      ex.CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: 1),
    );
    setCell(
      0,
      1,
      "Team Name: $teamName   |   Data Shown From: $dateRangeText",
      infoStyle,
    );

    final List<String> headers = [
      "SNO",
      "TEAM NAME",
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
      setCell(i, 2, headers[i], headerStyle);
    }

    int excelRow = 3;

    for (int i = 0; i < filteredDsrList.length; i++) {
      final item = filteredDsrList[i];

      final String createdAt = item["created_at"] != null &&
              item["created_at"].toString().isNotEmpty
          ? formatDateTime(item["created_at"].toString())
          : "-";

      setCell(0, excelRow, (i + 1).toString(), centerCellStyle);
      setCell(1, excelRow, safeValue(item["team_name"]), textCellStyle);
      setCell(2, excelRow, safeValue(item["created_by_name"]), textCellStyle);

      setCell(
        3,
        excelRow,
        (item["invoice_no"] ?? "").toString().trim().isNotEmpty
            ? item["invoice_no"]
            : "-",
        centerCellStyle,
      );

      setCell(4, excelRow, safeValue(item["customer_name"]), textCellStyle);

      setCell(
        5,
        excelRow,
        safeValue(item["call_status"]),
        getCallStatusStyle((item["call_status"] ?? "").toString()),
      );

      setCell(
        6,
        excelRow,
        safeValue(item["status"]),
        getDsrStatusStyle((item["status"] ?? "").toString()),
      );

      setCell(
        7,
        excelRow,
        safeValue(item["call_duration"]),
        centerCellStyle,
      );
      setCell(8, excelRow, safeValue(item["state_name"]), textCellStyle);
      setCell(9, excelRow, safeValue(item["district_name"]), textCellStyle);
      setCell(
        10,
        excelRow,
        _formatAmount(item["invoice_amount"]),
        amountCellStyle,
      );
      setCell(11, excelRow, createdAt, centerCellStyle);
      setCell(12, excelRow, safeValue(item["note"]), textCellStyle);

      excelRow++;
    }

    final int dsrCreatedCount = filteredDsrList
        .where(
          (e) =>
              (e["status"] ?? "").toString().toLowerCase().trim() ==
              "dsr created",
        )
        .length;

    final int dsrApprovedCount = filteredDsrList
        .where(
          (e) =>
              (e["status"] ?? "").toString().toLowerCase().trim() ==
              "dsr approved",
        )
        .length;

    final int dsrRejectedCount = filteredDsrList
        .where(
          (e) =>
              (e["status"] ?? "").toString().toLowerCase().trim() ==
              "dsr rejected",
        )
        .length;

    final List<String> hourlyHeaders = summaryHourlyDurations.isNotEmpty
        ? summaryHourlyDurations.keys.map((e) => e.toString()).toList()
        : [
            "09:00-10:00",
            "10:00-11:00",
            "11:00-12:00",
            "12:00-01:00",
            "01:00-02:00",
            "02:00-03:00",
            "03:00-04:00",
            "04:00-05:00",
            "05:00-06:00",
            "06:00-07:00",
          ];

    int hourlyTableStartRow = excelRow + 1;

    if (staffHourlySummaryList.isNotEmpty) {
      final int hourlyTableLastColumn = hourlyHeaders.length + 4;

      sheet.merge(
        ex.CellIndex.indexByColumnRow(
          columnIndex: 0,
          rowIndex: hourlyTableStartRow,
        ),
        ex.CellIndex.indexByColumnRow(
          columnIndex: hourlyTableLastColumn,
          rowIndex: hourlyTableStartRow,
        ),
      );
      setCell(
        0,
        hourlyTableStartRow,
        "STAFF HOURLY DURATION SUMMARY",
        summaryTitleStyle,
      );

      setCell(0, hourlyTableStartRow + 1, "SNO", summaryHeaderStyle);
      setCell(1, hourlyTableStartRow + 1, "STAFF NAME", summaryHeaderStyle);

      for (int i = 0; i < hourlyHeaders.length; i++) {
        setCell(
          i + 2,
          hourlyTableStartRow + 1,
          hourlyHeaders[i],
          summaryHeaderStyle,
        );
      }

      setCell(
        hourlyHeaders.length + 2,
        hourlyTableStartRow + 1,
        "TOTAL CALL DURATION",
        summaryHeaderStyle,
      );
      setCell(
        hourlyHeaders.length + 3,
        hourlyTableStartRow + 1,
        "CALL DURATION AVERAGE",
        summaryHeaderStyle,
      );
      setCell(
        hourlyHeaders.length + 4,
        hourlyTableStartRow + 1,
        "CALL DURATION % 8HRS",
        summaryHeaderStyle,
      );

      int hourlyDataRow = hourlyTableStartRow + 2;

      for (int i = 0; i < staffHourlySummaryList.length; i++) {
        final staffItem = staffHourlySummaryList[i];
        final Map<String, dynamic> hourlyMap =
            staffItem["hourly_durations"] is Map
                ? Map<String, dynamic>.from(staffItem["hourly_durations"])
                : {};

        setCell(0, hourlyDataRow, (i + 1).toString(), centerCellStyle);
        setCell(
          1,
          hourlyDataRow,
          safeValue(staffItem["staff_name"]),
          textCellStyle,
        );

        for (int j = 0; j < hourlyHeaders.length; j++) {
          final dynamic value = hourlyMap[hourlyHeaders[j]] ?? 0;
          final double numberValue = value is num
              ? value.toDouble()
              : double.tryParse(value.toString()) ?? 0.0;

          setCell(
            j + 2,
            hourlyDataRow,
            numberValue.toStringAsFixed(2),
            summaryValueStyle,
          );
        }

        final dynamic totalCallDurationValue =
            staffItem["total_call_duration"] ?? 0;
        final double totalCallDurationNumber = totalCallDurationValue is num
            ? totalCallDurationValue.toDouble()
            : double.tryParse(totalCallDurationValue.toString()) ?? 0.0;

        final dynamic callDurationAverageValue =
            staffItem["call_duration_average"] ?? 0;
        final double callDurationAverageNumber = callDurationAverageValue is num
            ? callDurationAverageValue.toDouble()
            : double.tryParse(callDurationAverageValue.toString()) ?? 0.0;

        final dynamic callDurationPercentValue =
            staffItem["call_duration_percentage_8hrs"] ?? 0;
        final double callDurationPercentNumber = callDurationPercentValue is num
            ? callDurationPercentValue.toDouble()
            : double.tryParse(callDurationPercentValue.toString()) ?? 0.0;

        setCell(
          hourlyHeaders.length + 2,
          hourlyDataRow,
          totalCallDurationNumber.toStringAsFixed(2),
          summaryValueStyle,
        );
        setCell(
          hourlyHeaders.length + 3,
          hourlyDataRow,
          callDurationAverageNumber.toStringAsFixed(2),
          summaryValueStyle,
        );
        setCell(
          hourlyHeaders.length + 4,
          hourlyDataRow,
          callDurationPercentNumber.toStringAsFixed(2),
          summaryValueStyle,
        );

        hourlyDataRow++;
      }

      hourlyTableStartRow = hourlyDataRow + 1;
    }

    final int summaryStartRow = hourlyTableStartRow;

    sheet.merge(
      ex.CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: summaryStartRow,
      ),
      ex.CellIndex.indexByColumnRow(
        columnIndex: 3,
        rowIndex: summaryStartRow,
      ),
    );
    setCell(0, summaryStartRow, "SUMMARY", summaryTitleStyle);

    setCell(0, summaryStartRow + 1, "TeamName", summaryLabelStyle);
    setCell(1, summaryStartRow + 1, teamName, summaryValueStyle);
    setCell(2, summaryStartRow + 1, "", summaryValueStyle);
    setCell(3, summaryStartRow + 1, "", summaryValueStyle);

    setCell(0, summaryStartRow + 2, "METRIC", summaryHeaderStyle);
    setCell(1, summaryStartRow + 2, "VALUE", summaryHeaderStyle);
    setCell(2, summaryStartRow + 2, "METRIC", summaryHeaderStyle);
    setCell(3, summaryStartRow + 2, "VALUE", summaryHeaderStyle);

    setCell(0, summaryStartRow + 3, "Total Bills", summaryLabelStyle);
    setCell(
      1,
      summaryStartRow + 3,
      excelSummaryBilling.toString(),
      summaryValueStyle,
    );
    setCell(2, summaryStartRow + 3, "Total Volume", summaryLabelStyle);
    setCell(
      3,
      summaryStartRow + 3,
      excelSummaryTotalVolume.toStringAsFixed(2),
      summaryValueStyle,
    );

    setCell(
      0,
      summaryStartRow + 4,
      "Total Call Duration",
      summaryLabelStyle,
    );
    setCell(
      1,
      summaryStartRow + 4,
      excelSummaryTotalCallDuration.toStringAsFixed(2),
      summaryValueStyle,
    );
    setCell(
      2,
      summaryStartRow + 4,
      "Call Duration Average",
      summaryLabelStyle,
    );
    setCell(
      3,
      summaryStartRow + 4,
      excelSummaryCallDurationAverage.toStringAsFixed(2),
      summaryValueStyle,
    );

    setCell(
      0,
      summaryStartRow + 5,
      "Call Duration % 8hrs",
      summaryLabelStyle,
    );
    setCell(
      1,
      summaryStartRow + 5,
      excelSummaryCallDuration8hrs.toStringAsFixed(2),
      summaryValueStyle,
    );
    setCell(2, summaryStartRow + 5, "DSR Created", summaryLabelStyle);
    setCell(
      3,
      summaryStartRow + 5,
      dsrCreatedCount.toString(),
      summaryValueStyle,
    );

    setCell(0, summaryStartRow + 6, "DSR Approved", summaryLabelStyle);
    setCell(
      1,
      summaryStartRow + 6,
      dsrApprovedCount.toString(),
      summaryValueStyle,
    );
    setCell(2, summaryStartRow + 6, "DSR Rejected", summaryLabelStyle);
    setCell(
      3,
      summaryStartRow + 6,
      dsrRejectedCount.toString(),
      summaryValueStyle,
    );

    for (final entry in columnWidths.entries) {
      int width = entry.value + 2;

      if (width < 10) width = 10;
      if (width > 35) width = 35;

      if (entry.key == 1 && width < 18) width = 18;
      if (entry.key == 2 && width < 14) width = 14;
      if (entry.key == 3 && width < 12) width = 12;
      if (entry.key == 4 && width < 16) width = 16;
      if (entry.key == 5 && width < 12) width = 12;
      if (entry.key == 6 && width < 12) width = 12;
      if (entry.key == 7 && width < 12) width = 12;
      if (entry.key == 8 && width < 12) width = 12;
      if (entry.key == 9 && width < 12) width = 12;
      if (entry.key == 10 && width < 12) width = 12;
      if (entry.key == 11 && width < 18) width = 18;
      if (entry.key == 12 && width < 12) width = 12;

      sheet.setColWidth(entry.key, width.toDouble());
    }

    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath =
        "${directory.path}/approve_bdo_duration_${DateTime.now().millisecondsSinceEpoch}.xlsx";

    final List<int>? fileBytes = excel.encode();
    if (fileBytes == null) {
      throw Exception("Failed to generate Excel file");
    }

    final File file = File(filePath);
    await file.writeAsBytes(fileBytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: "Approve BDO Duration Report",
    );
  } catch (e) {
    print("EXCEL EXPORT ERROR: $e");

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text("Excel export failed: $e"),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        isExporting = false;
      });
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _navigateBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xffF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            onPressed: _navigateBack,
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          ),
          title: const Text(
            "Approve BDO Call Duration",
            style: TextStyle(
              color: Colors.black87,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _openFilterBottomSheet,
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xff2196F3).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.filter_alt_outlined,
                  color: Color(0xff2196F3),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 2),
            IconButton(
              onPressed: isExporting ? null : exportToExcel,
              icon: isExporting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.download_outlined,
                        color: Colors.black87,
                        size: 20,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }
}
