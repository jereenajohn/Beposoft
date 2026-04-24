import 'dart:convert';
import 'dart:io';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/BDO/update_dsr_call_status.dart';
import 'package:beposoft/pages/BDO/update_dsr_status.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:excel/excel.dart' as ex;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BdoViewCallduration extends StatefulWidget {
  const BdoViewCallduration({super.key});

  @override
  State<BdoViewCallduration> createState() => _BdoViewCalldurationState();
}

class _BdoViewCalldurationState extends State<BdoViewCallduration> {
  List<dynamic> reportsList = [];
  bool isLoading = true;
  bool isLoadingMore = false;

  int currentPage = 1;
  int totalCount = 0;
  int totalPages = 0;
  String? nextPageUrl;
  String? previousPageUrl;
  bool hasMore = true;
Map<String, dynamic> apiSummary = {};
  final int itemsPerPage = 50;

  String selectedSummaryFilter = "all";
  final Set<int> expandedItemCards = {};

  DateTime? startDate;
  DateTime? endDate;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<void> _openEditPage(Map<String, dynamic> item) async {
    int? selectedInvoiceId;
    int? selectedCustomerId;

    if (item["invoice"] != null) {
      selectedInvoiceId = item["invoice"] is int
          ? item["invoice"]
          : int.tryParse(item["invoice"].toString());
    }

    if (item["customer"] != null) {
      selectedCustomerId = item["customer"] is int
          ? item["customer"]
          : int.tryParse(item["customer"].toString());
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateDsrPagee(
          dsrId: item["id"],
          selectedCustomerId: selectedCustomerId,
          selectedInvoiceId: selectedInvoiceId,
          selectedCallStatus:
              (item["call_status"]?.toString().toLowerCase().trim() ??
                  "active"),
        ),
      ),
    );

    if (result == true) {
      refreshReports();
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

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

Future<Map<String, dynamic>> getCallDurationReports({
  DateTime? startDate,
  DateTime? endDate,
  int page = 1,
  String? search,
}) async {
  try {
    final token = await gettokenFromPrefs();

    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': itemsPerPage.toString(),
    };

    if (startDate != null) {
      queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(startDate);
    }
    if (endDate != null) {
      queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(endDate);
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final url = Uri.parse("$api/api/sales/team/member/daily/report/add/")
        .replace(queryParameters: queryParams);

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print("DSR LIST STATUS: ${response.statusCode}");
    print("DSR LIST BODY: ${response.body}");

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      final results = jsonData['results'] ?? {};
      final List<dynamic> rawList = results['data'] ?? [];
      final Map<String, dynamic> summary =
          Map<String, dynamic>.from(results['summary'] ?? {});

      final count = jsonData['count'] ?? 0;
      final next = jsonData['next'];
      final previous = jsonData['previous'];

      List<Map<String, dynamic>> reportList = [];

      for (var item in rawList) {
        final Map<String, dynamic>? invoiceDetails =
            item["invoice_details"] != null
                ? Map<String, dynamic>.from(item["invoice_details"])
                : null;

        reportList.add({
          "id": item["id"],
          "invoice": item["invoice"],
          "invoice_details": item["invoice_details"],
          "customer": item["customer"],
          "team": item["team"],
          "team_name": item["team_name"]?.toString() ?? "",
          "state": item["state"],
          "state_name": item["state_name"]?.toString() ?? "",
          "district": item["district"],
          "district_name": item["district_name"]?.toString() ?? "",
          "created_by": item["created_by"],
          "created_by_name": item["created_by_name"]?.toString() ?? "",
          "invoice_number": item["invoice_number"]?.toString() ?? "",
          "phone": item["phone"]?.toString() ?? "",
          "customer_name": item["customer_name"]?.toString() ?? "",
          "call_status": item["call_status"]?.toString() ?? "",
          "status": item["status"]?.toString() ?? "",
          "call_duration": item["call_duration"]?.toString() ?? "",
          "note": item["note"]?.toString() ?? "",
          "created_at": item["created_at"]?.toString() ?? "",
          "invoice_amount":
              invoiceDetails?["total_amount"]?.toString() ?? "0",
        });
      }

      return {
        'data': reportList,
        'count': count,
        'next': next,
        'previous': previous,
        'summary': summary,
      };
    } else {
      return {
        'data': <Map<String, dynamic>>[],
        'count': 0,
        'next': null,
        'previous': null,
        'summary': <String, dynamic>{},
      };
    }
  } catch (e) {
    print("❌ EXCEPTION: $e");
    return {
      'data': <Map<String, dynamic>>[],
      'count': 0,
      'next': null,
      'previous': null,
      'summary': <String, dynamic>{},
    };
  }
}

Future<void> loadPage(int page) async {
  setState(() {
    isLoading = true;
    currentPage = page;
  });

  if (_scrollController.hasClients) {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  final result = await getCallDurationReports(
    startDate: startDate,
    endDate: endDate,
    page: page,
    search: searchQuery,
  );

  final newReports = result['data'] as List<dynamic>;
  totalCount = result['count'] ?? 0;
  nextPageUrl = result['next'];
  previousPageUrl = result['previous'];
  apiSummary = Map<String, dynamic>.from(result['summary'] ?? {});
  totalPages = totalCount > 0 ? (totalCount / itemsPerPage).ceil() : 1;
  hasMore = nextPageUrl != null;

  setState(() {
    reportsList = newReports;
    isLoading = false;
  });
}

  Future<void> loadReports({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        currentPage = 1;
        reportsList.clear();
        isLoading = true;
        hasMore = true;
      });
    }

    await loadPage(currentPage);
  }

  Future<void> refreshReports() async {
    setState(() {
      currentPage = 1;
      hasMore = true;
      selectedSummaryFilter = "all";
    });
    await loadReports(isRefresh: true);
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xff2196F3),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
        currentPage = 1;
        hasMore = true;
      });
      await refreshReports();
    }
  }

  Future<void> _clearDateFilter() async {
    setState(() {
      startDate = null;
      endDate = null;
      currentPage = 1;
      hasMore = true;
    });
    await refreshReports();
  }

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  String formatValue(dynamic value) {
    if (value == null) return "-";
    if (value.toString().trim().isEmpty) return "-";
    return value.toString();
  }

  String formatDateTime(String? value) {
    if (value == null || value.isEmpty) return "-";
    try {
      final parsed = DateTime.parse(value);
      return DateFormat('dd-MM-yyyy  HH:mm').format(parsed);
    } catch (e) {
      return value;
    }
  }

  int _parseDurationToSeconds(String duration) {
    try {
      final parts = duration.split(':');
      if (parts.length != 3) return 0;
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final s = int.tryParse(parts[2]) ?? 0;
      return h * 3600 + m * 60 + s;
    } catch (e) {
      return 0;
    }
  }

  String _secondsToHms(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  String _secondsToReadableMinutes(int totalSeconds) {
    final minutes = totalSeconds / 60;
    return "${minutes.toStringAsFixed(1)} mins";
  }

  Color getCallStatusColor(String? status) {
    if (status == null) return const Color(0xffF59E0B);
    switch (status.toLowerCase()) {
      case 'productive':
        return const Color(0xff4CAF50);
      case 'active':
        return const Color(0xffF59E0B);
      default:
        return const Color(0xffF59E0B);
    }
  }

  Color getCallStatusBgColor(String? status) {
    if (status == null) return const Color(0xffFFF8EC);
    switch (status.toLowerCase()) {
      case 'productive':
        return const Color(0xffEFFAF0);
      case 'active':
        return const Color(0xffFFF8EC);
      default:
        return const Color(0xffFFF8EC);
    }
  }

  Color getCallStatusBorderColor(String? status) {
    if (status == null) return const Color(0xffF5D9A7);
    switch (status.toLowerCase()) {
      case 'productive':
        return const Color(0xffCBE9CF);
      case 'active':
        return const Color(0xffF5D9A7);
      default:
        return const Color(0xffF5D9A7);
    }
  }

  Color getDsrStatusColor(String? status) {
    if (status == null) return const Color(0xff64B5F6);
    switch (status.toLowerCase()) {
      case 'dsr approved':
        return const Color(0xff4CAF50);
      case 'dsr created':
        return const Color(0xff64B5F6);
      case 'dsr confirmed':
        return const Color(0xffF59E0B);
      case 'dsr rejected':
        return const Color(0xffEF5350);
      default:
        return const Color(0xff64B5F6);
    }
  }

  Color getDsrStatusBgColor(String? status) {
    if (status == null) return const Color(0xffEEF7FF);
    switch (status.toLowerCase()) {
      case 'dsr approved':
        return const Color(0xffEFFAF0);
      case 'dsr created':
        return const Color(0xffEEF7FF);
      case 'dsr confirmed':
        return const Color(0xffFFF8EC);
      case 'dsr rejected':
        return const Color(0xffFFF1F1);
      default:
        return const Color(0xffEEF7FF);
    }
  }

  Color getDsrStatusBorderColor(String? status) {
    if (status == null) return const Color(0xffBFDEFF);
    switch (status.toLowerCase()) {
      case 'dsr approved':
        return const Color(0xffCBE9CF);
      case 'dsr created':
        return const Color(0xffBFDEFF);
      case 'dsr confirmed':
        return const Color(0xffF5D9A7);
      case 'dsr rejected':
        return const Color(0xffF3CACA);
      default:
        return const Color(0xffBFDEFF);
    }
  }

  List<dynamic> get filteredReportsList {
    if (selectedSummaryFilter == "all") return reportsList;

    return reportsList.where((item) {
      final callStatus = formatValue(item['call_status']).toLowerCase().trim();
      final dsrStatus = formatValue(item['status']).toLowerCase().trim();

      switch (selectedSummaryFilter) {
        case "active":
          return callStatus == "active";
        case "productive":
          return callStatus == "productive";
        case "created":
          return dsrStatus == "dsr created";
        case "approved":
          return dsrStatus == "dsr approved";
        case "confirmed":
          return dsrStatus == "dsr confirmed";
        case "rejected":
          return dsrStatus == "dsr rejected";
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildPaginationBar() {
    if (totalCount == 0) return const SizedBox.shrink();

    List<int> visiblePages = [];
    if (totalPages <= 7) {
      visiblePages = List.generate(totalPages, (i) => i + 1);
    } else {
      visiblePages.add(1);
      if (currentPage > 3) visiblePages.add(-1);
      for (int i = currentPage - 1; i <= currentPage + 1; i++) {
        if (i > 1 && i < totalPages) visiblePages.add(i);
      }
      if (currentPage < totalPages - 2) visiblePages.add(-2);
      visiblePages.add(totalPages);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: totalPages > 1 ? 8 : 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total: $totalCount records",
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "Page $currentPage / $totalPages",
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xff2196F3),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (totalPages > 1)
            Row(
              children: [
                _buildNavButton(
                  icon: Icons.chevron_left,
                  enabled: currentPage > 1,
                  onTap: () => loadPage(currentPage - 1),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: visiblePages.map((page) {
                        if (page < 0) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              "...",
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }

                        final isActive = page == currentPage;

                        return GestureDetector(
                          onTap: isActive ? null : () => loadPage(page),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xff2196F3)
                                  : const Color(0xffF2F5FA),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                "$page",
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _buildNavButton(
                  icon: Icons.chevron_right,
                  enabled: currentPage < totalPages,
                  onTap: () => loadPage(currentPage + 1),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xff2196F3) : const Color(0xffE9EDF3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : Colors.grey.shade500,
          size: 15,
        ),
      ),
    );
  }

  Future<bool> deleteReport(int reportId) async {
    try {
      final token = await gettokenFromPrefs();
      final url =
          Uri.parse("$api/api/sales/team/member/daily/report/edit/$reportId/");

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("DELETE STATUS: ${response.statusCode}");
      print("DELETE BODY: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("❌ EXCEPTION in deleteReport: $e");
      return false;
    }
  }

  void showDeleteDialog(Map<String, dynamic> report) {
    final outerContext = context;
    final messenger = ScaffoldMessenger.of(context);
    final int reportId = report['id'] as int;

    showDialog(
      context: outerContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text("Delete Report"),
            ],
          ),
          content: Text(
            "Are you sure you want to delete this report?\n\n"
            "Invoice: ${formatValue(report['invoice_number'])}\n"
            "Customer: ${formatValue(report['customer_name'])}\n"
            "Status: ${formatValue(report['status'])}",
            style: const TextStyle(fontSize: 12.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                showDialog(
                  context: outerContext,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );

                final bool success = await deleteReport(reportId);

                Navigator.of(outerContext, rootNavigator: true).pop();

                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.green,
                      content: Text("Report deleted successfully"),
                    ),
                  );
                  refreshReports();
                } else {
                  messenger.showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.red,
                      content: Text("Failed to delete report"),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Future<void> downloadExcelReport() async {
    try {
      if (reportsList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("No data available to export"),
          ),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text("Generating Excel file..."),
                ],
              ),
            ),
          ),
        ),
      );

      var excel = ex.Excel.createExcel();
      final defaultSheet = excel.getDefaultSheet();
      if (defaultSheet != null) {
        excel.delete(defaultSheet);
      }

      ex.Sheet sheet = excel["Call Duration Report"];

      sheet.setColWidth(0, 8);
      sheet.setColWidth(1, 10);
      sheet.setColWidth(2, 18);
      sheet.setColWidth(3, 16);
      sheet.setColWidth(4, 18);
      sheet.setColWidth(5, 18);
      sheet.setColWidth(6, 14);
      sheet.setColWidth(7, 18);
      sheet.setColWidth(8, 16);
      sheet.setColWidth(9, 18);
      sheet.setColWidth(10, 16);
      sheet.setColWidth(11, 16);
      sheet.setColWidth(12, 14);
      sheet.setColWidth(13, 28);
      sheet.setColWidth(14, 20);

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
        14,
        rowIndex,
        titleStyle,
        firstValue: "CALL DURATION REPORT",
      );
      sheet.merge(
        ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        ex.CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: rowIndex),
      );

      rowIndex++;

      String dateText = "All Dates";
      if (startDate != null && endDate != null) {
        dateText =
            "${DateFormat('dd-MM-yyyy').format(startDate!)} to ${DateFormat('dd-MM-yyyy').format(endDate!)}";
      }

      fillRangeStyle(
        0,
        14,
        rowIndex,
        dateInfoStyle,
        firstValue: "Data Shown From: $dateText",
      );
      sheet.merge(
        ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        ex.CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: rowIndex),
      );

      rowIndex++;

      final headers = [
        "#NO",
        "ID",
        "TEAM",
        "STATE",
        "DISTRICT",
        "CREATED BY",
        "INVOICE",
        "INVOICE NO",
        "PHONE",
        "CUSTOMER",
        "CALL STATUS",
        "DSR STATUS",
        "DURATION",
        "NOTE",
        "CREATED AT",
      ];

      for (int i = 0; i < headers.length; i++) {
        setCellValueStyle(i, rowIndex, headers[i], headerStyle);
      }

      rowIndex++;

      for (int i = 0; i < reportsList.length; i++) {
        final item = reportsList[i];
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

        final invoiceAmountText = item["invoice_amount"] != null &&
                item["invoice_amount"].toString().trim().isNotEmpty
            ? item["invoice_amount"].toString()
            : "0";

        final values = [
          "${i + 1}",
          formatValue(item["id"]),
          formatValue(item["team_name"]),
          formatValue(item["state_name"]),
          formatValue(item["district_name"]),
          formatValue(item["created_by_name"]),
          formatValue(item["invoice"]),
          formatValue(item["invoice_number"]),
          formatValue(item["phone"]),
          formatValue(item["customer_name"]),
          formatValue(item["call_status"]),
          formatValue(item["status"]),
          formatValue(item["call_duration"]),
          formatValue(item["note"]),
          formatDateTime(item["created_at"] ?? ""),
        ];

        for (int col = 0; col < values.length; col++) {
          final cell = sheet.cell(
            ex.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex),
          );
          cell.value = values[col];

          if (col == 2 ||
              col == 3 ||
              col == 4 ||
              col == 5 ||
              col == 9 ||
              col == 13 ||
              col == 14) {
            cell.cellStyle = leftStyle;
          } else if (col == 10) {
            cell.cellStyle = callStatusCellStyle;
          } else if (col == 11) {
            cell.cellStyle = dsrStatusCellStyle;
          } else if (col == 6) {
            cell.value = invoiceAmountText;
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

      int activeCount = reportsList
          .where((e) => formatValue(e['call_status']).toLowerCase() == 'active')
          .length;

      int productiveCount = reportsList
          .where((e) =>
              formatValue(e['call_status']).toLowerCase() == 'productive')
          .length;

      int createdCount = reportsList
          .where((e) => formatValue(e['status']).toLowerCase() == 'dsr created')
          .length;

      int approvedCount = reportsList
          .where(
              (e) => formatValue(e['status']).toLowerCase() == 'dsr approved')
          .length;

      int confirmedCount = reportsList
          .where(
              (e) => formatValue(e['status']).toLowerCase() == 'dsr confirmed')
          .length;

      int rejectedCount = reportsList
          .where(
              (e) => formatValue(e['status']).toLowerCase() == 'dsr rejected')
          .length;

      int totalSeconds = 0;
      double totalInvoiceAmount = 0.0;

      for (final item in reportsList) {
        totalSeconds +=
            _parseDurationToSeconds(formatValue(item['call_duration']));
        if (item['invoice_amount'] != null) {
          totalInvoiceAmount +=
              double.tryParse(item['invoice_amount'].toString()) ?? 0.0;
        }
      }

      String totalCallDuration = _secondsToHms(totalSeconds);
      String avgDuration = reportsList.isEmpty
          ? "0.0 min"
          : _secondsToReadableMinutes(totalSeconds ~/ reportsList.length);

      String durationPercent = (((totalSeconds / 28800) * 100)).isFinite
          ? ((totalSeconds / 28800) * 100).toStringAsFixed(2)
          : "0.00";

      final summaryData = [
        ["TOTAL REPORTS", reportsList.length.toString()],
        ["TOTAL ACTIVE CALLS", activeCount.toString()],
        ["TOTAL PRODUCTIVE CALLS", productiveCount.toString()],
        ["TOTAL DSR CREATED", createdCount.toString()],
        ["TOTAL DSR APPROVED", approvedCount.toString()],
        ["TOTAL DSR CONFIRMED", confirmedCount.toString()],
        ["TOTAL DSR REJECTED", rejectedCount.toString()],
        ["TOTAL CALL DURATION", totalCallDuration],
        ["TOTAL INVOICE AMOUNT", "₹${totalInvoiceAmount.toStringAsFixed(2)}"],
        ["AVG DURATION (8 HRS)", avgDuration],
        ["DURATION % (8 HRS)", "$durationPercent%"],
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
          "${tempDir.path}/Call_Duration_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx";

      final file = File(filePath);
      await file.writeAsBytes(fileBytes!, flush: true);

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Excel exported successfully"),
        ),
      );

      await Share.shareXFiles(
        [XFile(file.path)],
        text: "Call Duration Report",
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Excel Export Failed: $e"),
        ),
      );
    }
  }

  Widget _buildMetricBox({
    required IconData icon,
    required String title,
    required String value,
    required Color iconBg,
    required Color borderColor,
    required Color textColor,
    required Color cardBg,
    String? filterKey,
  }) {
    final bool isSelected =
        filterKey != null && selectedSummaryFilter == filterKey;

    return InkWell(
      onTap: filterKey == null
          ? null
          : () {
              setState(() {
                selectedSummaryFilter =
                    selectedSummaryFilter == filterKey ? "all" : filterKey;
              });
            },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? borderColor.withOpacity(0.18) : cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? textColor : borderColor,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: textColor, size: 15),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.1,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.0,
                      color: textColor,
                      fontWeight: FontWeight.bold,
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

Widget _buildSummarySection() {
  final List<dynamic> sourceList =
      selectedSummaryFilter == "all" ? reportsList : filteredReportsList;

  int activeCount = sourceList
      .where((e) =>
          (e['call_status']?.toString().toLowerCase().trim() ?? '') == 'active')
      .length;

  int productiveCount = sourceList
      .where((e) =>
          (e['call_status']?.toString().toLowerCase().trim() ?? '') ==
          'productive')
      .length;

  int createdCount = sourceList
      .where((e) =>
          (e['status']?.toString().toLowerCase().trim() ?? '') == 'dsr created')
      .length;

  int approvedCount = sourceList
      .where((e) =>
          (e['status']?.toString().toLowerCase().trim() ?? '') ==
          'dsr approved')
      .length;

  int confirmedCount = sourceList
      .where((e) =>
          (e['status']?.toString().toLowerCase().trim() ?? '') ==
          'dsr confirmed')
      .length;

  int rejectedCount = sourceList
      .where((e) =>
          (e['status']?.toString().toLowerCase().trim() ?? '') ==
          'dsr rejected')
      .length;

  int totalSeconds = 0;
  double totalAmount = 0.0;

  for (final item in sourceList) {
    final durationText = item['call_duration']?.toString().trim() ?? '';
    totalSeconds += _parseDurationToSeconds(
      durationText.isEmpty ? "00:00:00" : durationText,
    );

    final amountText = item['invoice_amount']?.toString().trim() ?? '0';
    totalAmount += double.tryParse(amountText) ?? 0.0;
  }

  String totalDuration = _secondsToHms(totalSeconds);

  String avgDuration = sourceList.isEmpty
      ? "0.0 mins"
      : _secondsToReadableMinutes(totalSeconds ~/ sourceList.length);

  String durationPercent = (((totalSeconds / 28800) * 100)).isFinite
      ? ((totalSeconds / 28800) * 100).toStringAsFixed(2)
      : "0.00";

  return Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff28A4F6), Color(0xff2E7BDB)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "DSR Summary",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      selectedSummaryFilter == "all"
                          ? "Overview of sales analysis records"
                          : "Filtered summary: ${selectedSummaryFilter.toUpperCase()}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Total ${sourceList.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.75,
            children: [
              _buildMetricBox(
                icon: Icons.wifi_calling_3_outlined,
                title: "Active",
                value: "$activeCount",
                iconBg: const Color(0xffFFF1D9),
                borderColor: const Color(0xffF4DEC0),
                textColor: const Color(0xffF39C12),
                cardBg: const Color(0xffFFF9F1),
                filterKey: "active",
              ),
              _buildMetricBox(
                icon: Icons.trending_up,
                title: "Productive",
                value: "$productiveCount",
                iconBg: const Color(0xffE7F6E8),
                borderColor: const Color(0xffCFE6D1),
                textColor: const Color(0xff4CAF50),
                cardBg: const Color(0xffF6FCF6),
                filterKey: "productive",
              ),
              _buildMetricBox(
                icon: Icons.edit_note_outlined,
                title: "Created",
                value: "$createdCount",
                iconBg: const Color(0xffE5F3FF),
                borderColor: const Color(0xffCDE3F7),
                textColor: const Color(0xff42A5F5),
                cardBg: const Color(0xffF4FAFF),
                filterKey: "created",
              ),
              _buildMetricBox(
                icon: Icons.verified_outlined,
                title: "Approved",
                value: "$approvedCount",
                iconBg: const Color(0xffE7F6E8),
                borderColor: const Color(0xffCFE6D1),
                textColor: const Color(0xff4CAF50),
                cardBg: const Color(0xffF6FCF6),
                filterKey: "approved",
              ),
              _buildMetricBox(
                icon: Icons.task_alt_outlined,
                title: "Confirmed",
                value: "$confirmedCount",
                iconBg: const Color(0xffFFF1D9),
                borderColor: const Color(0xffF4DEC0),
                textColor: const Color(0xffF39C12),
                cardBg: const Color(0xffFFF9F1),
                filterKey: "confirmed",
              ),
              _buildMetricBox(
                icon: Icons.cancel_outlined,
                title: "Rejected",
                value: "$rejectedCount",
                iconBg: const Color(0xffFFE7E7),
                borderColor: const Color(0xffF3D1D1),
                textColor: const Color(0xffEF5350),
                cardBg: const Color(0xffFFF7F7),
                filterKey: "rejected",
              ),
              _buildMetricBox(
                icon: Icons.access_time_outlined,
                title: "Total Duration",
                value: totalDuration,
                iconBg: const Color(0xffF1E1F7),
                borderColor: const Color(0xffE4CDEA),
                textColor: const Color(0xffAB47BC),
                cardBg: const Color(0xffFCF6FE),
              ),
              _buildMetricBox(
                icon: Icons.currency_rupee,
                title: "Total Amount",
                value: "₹${totalAmount.toStringAsFixed(2)}",
                iconBg: const Color(0xffDDF4EC),
                borderColor: const Color(0xffC7E3D9),
                textColor: const Color(0xff17A673),
                cardBg: const Color(0xffF5FCF9),
              ),
              _buildMetricBox(
                icon: Icons.av_timer_outlined,
                title: "Avg Duration (8h)",
                value: avgDuration,
                iconBg: const Color(0xffECEAF8),
                borderColor: const Color(0xffD9D5EE),
                textColor: const Color(0xff3F51B5),
                cardBg: const Color(0xffF8F8FE),
              ),
              _buildMetricBox(
                icon: Icons.pie_chart_outline,
                title: "Duration % (8h)",
                value: "$durationPercent%",
                iconBg: const Color(0xffDFF5F2),
                borderColor: const Color(0xffC6E5E0),
                textColor: const Color(0xff13A89E),
                cardBg: const Color(0xffF4FCFB),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildStatusChip({
    required String text,
    required Color textColor,
    required Color bgColor,
    required Color borderColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            ":",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11.8,
                color: Color(0xff222222),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> item, int index) {
    final callStatus = formatValue(item['call_status']).toLowerCase().trim();
    final dsrStatus = formatValue(item['status']).toLowerCase().trim();

    final bool isProductive = callStatus == "productive";
    final bool isActive = callStatus == "active";
    final bool enableEditIcon = isActive;
    final bool showDeleteIcon = dsrStatus == "dsr created";

    final invoiceDetails = item['invoice_details'] as Map<String, dynamic>?;
    final List<dynamic> invoiceItems =
        invoiceDetails?['items'] is List ? invoiceDetails!['items'] : [];

    final bool isExpanded = expandedItemCards.contains(item['id']);
    final List<dynamic> visibleItems = (invoiceItems.length > 1 && !isExpanded)
        ? [invoiceItems.first]
        : invoiceItems;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xff33A6F7), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff36A5F7), Color(0xff3696EA)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(17),
                topRight: Radius.circular(17),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      "${(currentPage - 1) * itemsPerPage + index + 1}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatValue(item['invoice_number']) == "-"
                            ? "No Invoice"
                            : formatValue(item['invoice_number']),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.2,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatValue(item['customer_name']) == "-"
                            ? formatValue(item['created_by_name'])
                            : formatValue(item['customer_name']),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.2,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: enableEditIcon
                          ? () {
                              _openEditPage(item);
                            }
                          : null,
                      child: Opacity(
                        opacity: enableEditIcon ? 1.0 : 0.45,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Edit",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (showDeleteIcon) const SizedBox(width: 8),
                    if (showDeleteIcon)
                      InkWell(
                        onTap: () {
                          showDeleteDialog(item);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Delete",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStatusChip(
                      text: formatValue(item['call_status']),
                      textColor: getCallStatusColor(item['call_status']),
                      bgColor: getCallStatusBgColor(item['call_status']),
                      borderColor:
                          getCallStatusBorderColor(item['call_status']),
                      icon: isProductive
                          ? Icons.trending_up
                          : Icons.wifi_calling_3_outlined,
                    ),
                    _buildStatusChip(
                      text: formatValue(item['status']),
                      textColor: getDsrStatusColor(item['status']),
                      bgColor: getDsrStatusBgColor(item['status']),
                      borderColor: getDsrStatusBorderColor(item['status']),
                      icon: dsrStatus == "dsr approved"
                          ? Icons.verified_outlined
                          : dsrStatus == "dsr rejected"
                              ? Icons.cancel_outlined
                              : dsrStatus == "dsr confirmed"
                                  ? Icons.task_alt_outlined
                                  : Icons.settings_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: const [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xff63B8F2),
                      size: 20,
                    ),
                    SizedBox(width: 7),
                    Text(
                      "Record Details",
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff1F2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _detailRow(
                  icon: Icons.person_outline,
                  label: "Customer",
                  value: formatValue(item['customer_name']) == "-"
                      ? formatValue(item['created_by_name'])
                      : formatValue(item['customer_name']),
                ),
                _detailRow(
                  icon: Icons.call_outlined,
                  label: "Phone",
                  value: formatValue(item['phone']),
                ),
                _detailRow(
                  icon: Icons.map_outlined,
                  label: "State",
                  value: formatValue(item['state_name']),
                ),
                _detailRow(
                  icon: Icons.location_city_outlined,
                  label: "District",
                  value: formatValue(item['district_name']),
                ),
                _detailRow(
                  icon: Icons.badge_outlined,
                  label: "Created By",
                  value: formatValue(item['created_by_name']),
                ),
                _detailRow(
                  icon: Icons.timer_outlined,
                  label: "Duration",
                  value: formatValue(item['call_duration']),
                ),
                _detailRow(
                  icon: Icons.currency_rupee,
                  label: "Invoice Amount",
                  value: formatValue(item['invoice_amount']),
                ),
                _detailRow(
                  icon: Icons.calendar_today_outlined,
                  label: "Created At",
                  value: formatDateTime(item['created_at']),
                ),
                if (formatValue(item['invoice_number']) != "-")
                  _detailRow(
                    icon: Icons.receipt_long_outlined,
                    label: "Invoice No",
                    value: formatValue(item['invoice_number']),
                  ),
                if (formatValue(item['team_name']) != "-")
                  _detailRow(
                    icon: Icons.groups_outlined,
                    label: "Team",
                    value: formatValue(item['team_name']),
                  ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xffF8F8FA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xffE9E9EE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.note_alt_outlined,
                            color: Color(0xff5F6368),
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "Note",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff333333),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatValue(item['note']),
                        style: const TextStyle(
                          fontSize: 11.8,
                          color: Color(0xff333333),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (invoiceItems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xffF5FBFF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xffD7ECFA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              color: Color(0xff2196F3),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              "Items",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff1F2937),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xffE8F4FD),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "${invoiceItems.length} item${invoiceItems.length > 1 ? 's' : ''}",
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xff1976D2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...List.generate(visibleItems.length, (itemIndex) {
                          final product =
                              visibleItems[itemIndex] as Map<String, dynamic>;
                          final productName = formatValue(product['name']);
                          final quantity = formatValue(product['quantity']);
                          final imageUrl = formatValue(product['image']);

                          return Container(
                            margin: EdgeInsets.only(
                              bottom:
                                  itemIndex == visibleItems.length - 1 ? 0 : 10,
                            ),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xffE3EEF8)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: imageUrl != "-"
                                      ? Image.network(
                                          imageUrl,
                                          width: 52,
                                          height: 52,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            width: 52,
                                            height: 52,
                                            color: const Color(0xffEEF3F8),
                                            child: const Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              color: Colors.grey,
                                              size: 20,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          width: 52,
                                          height: 52,
                                          color: const Color(0xffEEF3F8),
                                          child: const Icon(
                                            Icons.inventory_2_outlined,
                                            color: Colors.grey,
                                            size: 20,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        productName,
                                        style: const TextStyle(
                                          fontSize: 11.8,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xff222222),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        "Qty: $quantity",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (invoiceItems.length > 1) ...[
                          const SizedBox(height: 10),
                          Center(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  if (isExpanded) {
                                    expandedItemCards.remove(item['id']);
                                  } else {
                                    expandedItemCards.add(item['id']);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xffEAF4FF),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: const Color(0xffBFDEFF)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isExpanded ? "See less" : "See more",
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xff1976D2),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      size: 18,
                                      color: const Color(0xff1976D2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            InkWell(
              onTap: _navigateBack,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.arrow_back,
                  size: 26,
                  color: Color(0xff222222),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "DSR List",
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff202124),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Sales analysis records",
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Color(0xff9A9A9A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: _selectDateRange,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(6),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xff202124),
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      color: const Color(0xffF5F7FB),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: searchController,
          onChanged: (value) {
            setState(() {
              searchQuery = value;
              currentPage = 1;
            });
            refreshReports();
          },
          style: const TextStyle(fontSize: 12.5),
          decoration: InputDecoration(
            hintText: "Search invoice, customer, note...",
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: Color(0xff339AF0),
              size: 24,
            ),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                    onPressed: () {
                      setState(() {
                        searchController.clear();
                        searchQuery = "";
                        currentPage = 1;
                      });
                      refreshReports();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          ),
        ),
      ),
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
        backgroundColor: const Color(0xffF5F7FB),
        body: Column(
          children: [
            _buildAppBarHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: refreshReports,
                child: isLoading && reportsList.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        controller: _scrollController,
                        padding: EdgeInsets.zero,
                        children: [
                          _buildSearchSection(),
                          if (startDate != null || endDate != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xffEEF7FF),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xffCDE4F8)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.filter_alt_outlined,
                                      color: Color(0xff2196F3),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        startDate != null && endDate != null
                                            ? "${DateFormat('dd-MM-yyyy').format(startDate!)} to ${DateFormat('dd-MM-yyyy').format(endDate!)}"
                                            : "Date filter applied",
                                        style: const TextStyle(
                                          color: Color(0xff2196F3),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: _clearDateFilter,
                                      child: const Icon(
                                        Icons.close,
                                        color: Color(0xff2196F3),
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (reportsList.isNotEmpty) _buildSummarySection(),
                          if (selectedSummaryFilter != "all")
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffEAF4FF),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: const Color(0xffBFDEFF)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Filtered: ${selectedSummaryFilter[0].toUpperCase()}${selectedSummaryFilter.substring(1)}",
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xff1976D2),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              selectedSummaryFilter = "all";
                                            });
                                          },
                                          child: const Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Color(0xff1976D2),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (reportsList.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 80),
                              child: Center(
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.inbox_outlined,
                                      size: 52,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "No DSR records found",
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else if (filteredReportsList.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 80),
                              child: Center(
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.filter_alt_off_outlined,
                                      size: 52,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "No records found for selected filter",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...List.generate(filteredReportsList.length,
                                (index) {
                              final item = filteredReportsList[index];
                              return _buildRecordCard(item, index);
                            }),
                          if (isLoadingMore)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          if (reportsList.isNotEmpty) _buildPaginationBar(),
                          const SizedBox(height: 10),
                        ],
                      ),
              ),
            ),
          ],
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: FloatingActionButton(
                heroTag: "excel_btn",
                backgroundColor: const Color(0xff2196F3),
                onPressed: downloadExcelReport,
                child:
                    const Icon(Icons.download, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 48,
              height: 48,
              child: FloatingActionButton(
                heroTag: "refresh_btn",
                backgroundColor: const Color(0xff4CAF50),
                onPressed: refreshReports,
                child: const Icon(Icons.refresh, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
