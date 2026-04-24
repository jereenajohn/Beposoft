import 'dart:convert';
import 'package:beposoft/Sales%20Directors/SD_dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BdmOverallReportPage extends StatefulWidget {
  const BdmOverallReportPage({super.key});

  @override
  State<BdmOverallReportPage> createState() => _BdmOverallReportPageState();
}

class _BdmOverallReportPageState extends State<BdmOverallReportPage>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;
  bool isRefreshing = false;
  bool isPageChanging = false;

  String? selectedBdmId;
  List<Map<String, dynamic>> bdmDropdownList = [];
  List<Map<String, dynamic>> masterBdmDropdownList = [];

  late AnimationController _shimmerController;

  int overallPresent = 0;
  int overallAbsent = 0;
  int overallHalfDay = 0;
  int overallTotalBill = 0;
  double overallTotalVolume = 0.0;

  String createdDate = "";
  int bdoPresentCount = 0;
  int bdoAbsentCount = 0;
  int bdoHalfDayCount = 0;
  int totalBillCount = 0;
  double totalVolume = 0.0;
  String totalCallDuration = "00:00:00";
  double callDurationAverage = 0.0;
  double averageCallDurationMinutes = 0.0;

  List<Map<String, dynamic>> bdmList = [];

  String? nextPageUrl;
  String? previousPageUrl;
  int totalCount = 0;
  int currentPage = 1;
  int totalPages = 1;
  int pageSize = 1;

  DateTime? startDate;
  DateTime? endDate;

  String family = "";
  int? familyId;
  List<dynamic> allocatedstates = [];

  bool get hasCustomDateFilter {
    if (startDate == null || endDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return !(startDate!.year == today.year &&
        startDate!.month == today.month &&
        startDate!.day == today.day &&
        endDate!.year == today.year &&
        endDate!.month == today.month &&
        endDate!.day == today.day);
  }

  String get selectedDateText {
    if (startDate == null || endDate == null) return "Today";

    if (startDate!.year == endDate!.year &&
        startDate!.month == endDate!.month &&
        startDate!.day == endDate!.day) {
      return formatDateDisplay(startDate!.toIso8601String());
    }

    return "${formatDateDisplay(startDate!.toIso8601String())} - ${formatDateDisplay(endDate!.toIso8601String())}";
  }

  Future<void> _pickDateRange() async {
    DateTime now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        startDate =
            DateTime(picked.start.year, picked.start.month, picked.start.day);
        endDate = DateTime(picked.end.year, picked.end.month, picked.end.day);
        selectedBdmId = null;
        createdDate = selectedDateText;
      });

      await fetchOverallSummary();
      await fetchOverallReport(showRefresh: true);
    }
  }

  Future<void> clearDateFilter() async {
    final now = DateTime.now();

    setState(() {
      startDate = DateTime(now.year, now.month, now.day);
      endDate = DateTime(now.year, now.month, now.day);
      selectedBdmId = null;
      createdDate = selectedDateText;
    });

    await fetchOverallSummary();
    await fetchOverallReport(showRefresh: true);
  }

  Future<void> refreshPageData() async {
    setState(() {
      selectedBdmId = null;
    });

    await getstaff();
    await fetchOverallSummary();
    await fetchOverallReport(showRefresh: true);
  }

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();

    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, now.day);
    endDate = DateTime(now.year, now.month, now.day);
    createdDate = selectedDateText;

    getprofiledata();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<String?> gettokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
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

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  String formatAmount(double amount) {
    return "₹${amount.toStringAsFixed(0)}";
  }

  String formatDateDisplay(String value) {
    if (value.trim().isEmpty) return "-";
    try {
      final date = DateTime.parse(value);
      return "${date.day.toString().padLeft(2, '0')}-"
          "${date.month.toString().padLeft(2, '0')}-"
          "${date.year}";
    } catch (e) {
      return value;
    }
  }

  int _extractPageNumber(String? url) {
    if (url == null || url.trim().isEmpty) return 1;
    try {
      final uri = Uri.parse(url);
      final page = int.tryParse(uri.queryParameters["page"] ?? "");
      return page ?? 1;
    } catch (e) {
      return 1;
    }
  }

  Future<void> getprofiledata() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse("$api/api/profile/"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("PROFILE STATUS: ${response.statusCode}");
      print("PROFILE BODY: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        if (!mounted) return;

        setState(() {
          allocatedstates = productsData['allocated_states'] ?? [];

          if (productsData['family'] is int) {
            familyId = productsData['family'];
          } else {
            familyId = int.tryParse(productsData['family']?.toString() ?? "");
          }

          family = productsData['family_name']?.toString().trim().isNotEmpty ==
                  true
              ? productsData['family_name'].toString().trim()
              : productsData['family_display']?.toString().trim().isNotEmpty ==
                      true
                  ? productsData['family_display'].toString().trim()
                  : productsData['family']?.toString().trim() ?? "";
        });

        await getstaff();
        await fetchOverallSummary();
        await fetchOverallReport();
      }
    } catch (error) {
      print("PROFILE ERROR: $error");
      if (!mounted) return;

      setState(() {
        isLoading = false;
        isRefreshing = false;
        isPageChanging = false;
      });
    }
  }

  Future<void> getstaff() async {
    try {
      final token = await gettokenFromPrefs();

      if (familyId == null) {
        print("FAMILY ID IS NULL");
        return;
      }

      var response = await http.get(
        Uri.parse("$api/api/users/family/$familyId/"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("STAFF STATUS: ${response.statusCode}");
      print("STAFF BODY: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List staffData = [];
        if (parsed is Map && parsed['data'] is List) {
          staffData = parsed['data'];
        }

        List<Map<String, dynamic>> tempStaffList = [];

        for (var item in staffData) {
          tempStaffList.add({
            "id": item["id"]?.toString() ?? "",
            "name": item["name"]?.toString() ?? "",
            "department_name": item["department_name"]?.toString() ?? "",
            "username": item["username"]?.toString() ?? "",
          });
        }

        tempStaffList.sort(
          (a, b) => a["name"]
              .toString()
              .toLowerCase()
              .compareTo(b["name"].toString().toLowerCase()),
        );

        if (!mounted) return;

        setState(() {
          masterBdmDropdownList = tempStaffList;
          bdmDropdownList = tempStaffList;
        });
      }
    } catch (error) {
      print("GET STAFF ERROR: $error");
    }
  }

  Future<void> fetchOverallReport({
    bool showRefresh = false,
    String? pageUrl,
  }) async {
    try {
      if (showRefresh) {
        setState(() {
          isRefreshing = true;
        });
      } else if (pageUrl != null) {
        setState(() {
          isPageChanging = true;
        });
      } else {
        setState(() {
          isLoading = true;
        });
      }

      final token = await gettokenFromPrefs();
      String baseUrl = '$api/api/bdm/daily/created/report/';

      List<String> queryParams = [];

      if (startDate != null && endDate != null) {
        String start = "${startDate!.toIso8601String().split('T')[0]}";
        String end = "${endDate!.toIso8601String().split('T')[0]}";

        queryParams.add("start_date=$start");
        queryParams.add("end_date=$end");
      }

      if (selectedBdmId != null && selectedBdmId!.isNotEmpty) {
        queryParams.add("bdm=$selectedBdmId");
      }

      if (queryParams.isNotEmpty) {
        baseUrl += "?${queryParams.join("&")}";
      }

      final response = await http.get(
        pageUrl != null && pageUrl.trim().isNotEmpty
            ? Uri.parse(pageUrl)
            : Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("BDM OVERALL STATUS: ${response.statusCode}");
      print("BDM OVERALL BODY: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        final int parsedCount = _parseInt(parsed["count"]);
        final String? parsedNext = parsed["next"]?.toString();
        final String? parsedPrevious = parsed["previous"]?.toString();

        final results = parsed["results"] ?? {};
        final List data = results["data"] ?? [];

        int currentFetchedPage = 1;
        if (pageUrl != null && pageUrl.trim().isNotEmpty) {
          currentFetchedPage = _extractPageNumber(pageUrl);
        } else if (parsedPrevious != null && parsedPrevious.isNotEmpty) {
          currentFetchedPage = _extractPageNumber(parsedPrevious) + 1;
        }

        final int currentPageSize = data.isEmpty ? 1 : data.length;
        final int computedTotalPages =
            (parsedCount / currentPageSize).ceil() == 0
                ? 1
                : (parsedCount / currentPageSize).ceil();

        if (data.isNotEmpty) {
          double totalCallAvg = 0.0;
          double totalAvgMinutes = 0.0;

          for (var item in data) {
            totalCallAvg += _parseDouble(item["call_duration_average"]);
            totalAvgMinutes +=
                _parseDouble(item["average_call_duration_minutes"]);
          }

          final first = data.first;
          final List<Map<String, dynamic>> parsedBdmList = [];

          for (var item in data) {
            final List rawFamilies = item["family_data"] ?? [];

            for (final fam in rawFamilies) {
              final String familyName = fam["family_name"]?.toString() ?? "";
              final List rawBdmList = fam["bdm_data"] ?? [];

              for (final bdm in rawBdmList) {
                parsedBdmList.add({
                  "family_name": familyName,
                  "bdm_id": bdm["bdm_id"],
                  "bdm_name": bdm["bdm_name"]?.toString() ?? "",
                  "total_bill": _parseInt(bdm["total_bill"]),
                  "total_order_count": _parseInt(bdm["total_order_count"]),
                  "total_volume": _parseDouble(bdm["total_volume"]),
                  "total_call_duration":
                      bdm["total_call_duration"]?.toString() ?? "00:00:00",
                  "call_duration_average":
                      _parseDouble(bdm["call_duration_average"]),
                  "average_call_duration_minutes":
                      _parseDouble(bdm["average_call_duration_minutes"]),
                });
              }
            }
          }

          if (!mounted) return;

          setState(() {
            createdDate = selectedDateText;
            bdmList = parsedBdmList;
            callDurationAverage = totalCallAvg;
            averageCallDurationMinutes = totalAvgMinutes;
            totalCallDuration =
                first["total_call_duration"]?.toString() ?? "00:00:00";

            nextPageUrl = parsedNext;
            previousPageUrl = parsedPrevious;
            totalCount = parsedCount;
            currentPage = currentFetchedPage;
            pageSize = currentPageSize;
            totalPages = computedTotalPages;

            isLoading = false;
            isRefreshing = false;
            isPageChanging = false;
          });
        } else {
          if (!mounted) return;
          setState(() {
            createdDate = selectedDateText;
            bdoPresentCount = 0;
            bdoAbsentCount = 0;
            bdoHalfDayCount = 0;
            totalBillCount = 0;
            totalVolume = 0.0;
            totalCallDuration = "00:00:00";
            callDurationAverage = 0.0;
            averageCallDurationMinutes = 0.0;
            bdmList = [];
            nextPageUrl = parsedNext;
            previousPageUrl = parsedPrevious;
            totalCount = parsedCount;
            currentPage = currentFetchedPage;
            pageSize = currentPageSize;
            totalPages = computedTotalPages;
            isLoading = false;
            isRefreshing = false;
            isPageChanging = false;
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          isRefreshing = false;
          isPageChanging = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Failed to load report: ${response.body}"),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        isRefreshing = false;
        isPageChanging = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error: $e"),
        ),
      );
    }
  }

  Future<void> fetchOverallSummary() async {
    try {
      final token = await gettokenFromPrefs();

      String url = '$api/api/bdm/daily/created/report/';

      List<String> queryParams = [];

      if (startDate != null && endDate != null) {
        String start = "${startDate!.toIso8601String().split('T')[0]}";
        String end = "${endDate!.toIso8601String().split('T')[0]}";

        queryParams.add("start_date=$start");
        queryParams.add("end_date=$end");
      }

      if (queryParams.isNotEmpty) {
        url += "?${queryParams.join("&")}";
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final results = parsed["results"] ?? {};
        final List data = results["data"] ?? [];

        int present = 0;
        int absent = 0;
        int halfDay = 0;
        int totalBill = 0;
        double volume = 0.0;

        for (var item in data) {
          present += _parseInt(item["bdo_present_count"]);
          absent += _parseInt(item["bdo_absent_count"]);
          halfDay += _parseInt(item["bdo_half_day_count"]);
          totalBill += _parseInt(item["total_bill"]);
          volume += _parseDouble(item["total_volume"]);
        }

        if (!mounted) return;

        setState(() {
          bdoPresentCount = present;
          bdoAbsentCount = absent;
          bdoHalfDayCount = halfDay;
          totalBillCount = totalBill;
          totalVolume = volume;
        });
      }
    } catch (e) {
      print("Summary error: $e");
    }
  }

  Widget buildSkeletonLine({
    double width = double.infinity,
    double height = 12,
    double radius = 8,
  }) {
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
                Colors.grey.shade300,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              buildSkeletonLine(width: 160, height: 16),
              const SizedBox(height: 12),
              buildSkeletonLine(height: 12),
              const SizedBox(height: 10),
              buildSkeletonLine(height: 12),
              const SizedBox(height: 10),
              buildSkeletonLine(width: 220, height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSummaryStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget buildTopSummaryCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.analytics_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "BDM Overall Report",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Report Date: $selectedDateText",
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white.withOpacity(0.88),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      "${bdmList.length} BDM",
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
                        child: buildSummaryStatCard(
                          title: "BDO Present",
                          value: "$bdoPresentCount",
                          icon: Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: buildSummaryStatCard(
                          title: "BDO Absent",
                          value: "$bdoAbsentCount",
                          icon: Icons.cancel_outlined,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: buildSummaryStatCard(
                          title: "Half Day",
                          value: "$bdoHalfDayCount",
                          icon: Icons.timelapse_outlined,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: buildSummaryStatCard(
                          title: "Total Bill",
                          value: "$totalBillCount",
                          icon: Icons.receipt_long_outlined,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: buildSummaryStatCard(
                          title: "Total Volume",
                          value: formatAmount(totalVolume),
                          icon: Icons.currency_rupee_outlined,
                          color: const Color(0xff0F9D58),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: buildSummaryStatCard(
                          title: "Total CD",
                          value: totalCallDuration,
                          icon: Icons.access_time,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: buildSummaryStatCard(
                          title: "Avg Call Min",
                          value:
                              "${averageCallDurationMinutes.toStringAsFixed(2)} min",
                          icon: Icons.timer_outlined,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: buildSummaryStatCard(
                          title: "Avg CD %",
                          value:
                              "${callDurationAverage.toStringAsFixed(2)} min",
                          icon: Icons.av_timer_outlined,
                          color: Colors.indigo,
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
    );
  }

  Widget buildBdmCard(Map<String, dynamic> bdm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: const Color(0xff2196F3).withOpacity(0.12),
                child: const Icon(
                  Icons.person,
                  color: Color(0xff2196F3),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bdm["bdm_name"]?.toString().isNotEmpty == true
                          ? bdm["bdm_name"].toString()
                          : "Unnamed BDM",
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "BDM ID: ${bdm["bdm_id"] ?? "-"}",
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "${bdm["total_bill"] ?? 0} Bills",
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Family: ${bdm["family_name"]?.toString().isNotEmpty == true ? bdm["family_name"] : "-"}",
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: buildSmallInfoBox(
                  title: "Total Volume",
                  value: formatAmount(_parseDouble(bdm["total_volume"])),
                  color: const Color(0xff0F9D58),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: buildSmallInfoBox(
                  title: "Total Duration",
                  value: bdm["total_call_duration"]?.toString() ?? "00:00:00",
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: buildSmallInfoBox(
                  title: "Avg CD %",
                  value:
                      "${_parseDouble(bdm["call_duration_average"]).toStringAsFixed(2)} min",
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: buildSmallInfoBox(
                  title: "Avg Call Minutes",
                  value:
                      "${_parseDouble(bdm["average_call_duration_minutes"]).toStringAsFixed(2)} min",
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSmallInfoBox({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPaginationBar() {
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: previousPageUrl == null || isPageChanging
                  ? null
                  : () => fetchOverallReport(pageUrl: previousPageUrl),
              icon: const Icon(Icons.chevron_left),
              label: const Text("Previous"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Text(
                  "Page $currentPage / $totalPages",
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Total: $totalCount",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: nextPageUrl == null || isPageChanging
                  ? null
                  : () => fetchOverallReport(pageUrl: nextPageUrl),
              icon: const Icon(Icons.chevron_right),
              label: const Text("Next"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2196F3),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLoadingView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        buildSkeletonCard(),
        buildSkeletonCard(),
        buildSkeletonCard(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? selectedDropdownItem = selectedBdmId == null
        ? null
        : bdmDropdownList.cast<Map<String, dynamic>?>().firstWhere(
              (item) => item?["id"]?.toString() == selectedBdmId,
              orElse: () => null,
            );

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () async {
            await _navigateBack();
          },
        ),
        titleSpacing: 8,
        title: Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "BDM Overall Report",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      selectedDateText,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (hasCustomDateFilter) ...[
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: isRefreshing ? null : clearDateFilter,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: isRefreshing ? null : _pickDateRange,
            icon: const Icon(Icons.calendar_today, color: Colors.black87),
          ),
          IconButton(
            onPressed: isRefreshing ? null : refreshPageData,
            icon: isRefreshing
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, color: Colors.black87),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refreshPageData,
        child: isLoading
            ? buildLoadingView()
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                children: [
                  buildTopSummaryCard(),
                  buildPaginationBar(),
                  if (isPageChanging)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 14),
                      child: Center(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.groups_outlined,
                              size: 18,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "BDM Details",
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownSearch<Map<String, dynamic>>(
                            items: bdmDropdownList,
                            selectedItem: selectedDropdownItem,
                            itemAsString: (item) =>
                                item["name"]?.toString() ?? "",
                            compareFn: (a, b) =>
                                a["id"]?.toString() == b["id"]?.toString(),
                            popupProps: PopupProps.menu(
                              showSearchBox: true,
                              fit: FlexFit.loose,
                              searchFieldProps: TextFieldProps(
                                decoration: InputDecoration(
                                  hintText: "Search staff...",
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              itemBuilder: (context, item, isSelected) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  child: Text(
                                    item["name"]?.toString() ?? "",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                );
                              },
                              emptyBuilder: (context, searchEntry) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: Text(
                                      "No staff found",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            dropdownDecoratorProps: DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                hintText: "Select BDM",
                                prefixIcon: const Icon(Icons.search),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                              ),
                            ),
                            clearButtonProps: ClearButtonProps(
                              isVisible: selectedBdmId != null,
                              onPressed: () {
                                setState(() {
                                  selectedBdmId = null;
                                });
                                fetchOverallReport(showRefresh: true);
                              },
                            ),
                            dropdownButtonProps: const DropdownButtonProps(
                              icon: Icon(Icons.arrow_drop_down),
                            ),
                            onChanged: (value) {
                              setState(() {
                                selectedBdmId = value?["id"]?.toString();
                              });
                              fetchOverallReport(showRefresh: true);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (bdmList.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.10),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            size: 52,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            "No report data found",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...bdmList.map((bdm) => buildBdmCard(bdm)),
                ],
              ),
      ),
    );
  }
}
