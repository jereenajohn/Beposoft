import 'dart:convert';
import 'dart:io';

import 'package:beposoft/Sales%20Directors/SD_dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:dropdown_search/dropdown_search.dart';
// import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:excel/excel.dart' as ex;
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeamWiseReport extends StatefulWidget {
  const TeamWiseReport({super.key});

  @override
  State<TeamWiseReport> createState() => _TeamWiseReportState();
}

class _TeamWiseReportState extends State<TeamWiseReport> {
  bool isLoading = true;
  String errorMessage = '';

  List<Map<String, dynamic>> reportData = [];
  Map<String, dynamic> totals = {};
  Map<String, dynamic> filters = {};

  final String apiBaseUrl = 'https://bepocart.in';

  final TextEditingController searchController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();

  String selectedStatus = '';
  String selectedTeam = '';
  String selectedCreatedBy = '';
  String selectedState = '';

  List<Map<String, dynamic>> teamOptions = [];
  List<Map<String, dynamic>> createdByOptions = [];
  List<Map<String, dynamic>> stateOptions = [];

  bool isLoadingStaff = false;
  List<Map<String, dynamic>> allStaff = [];

  List<Map<String, dynamic>> statess = [];

  final Color _pageBg = const Color(0xffF4F7FB);
  String expandedHourlyKey = '';
  String expandedMemberKey = '';

  bool _isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < 360;

  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600;

  String getDisplayStatus() {
    if (selectedStatus.trim().isNotEmpty) {
      return selectedStatus;
    }

    final apiStatus = (filters['status'] ?? '').toString().trim();
    if (apiStatus.isNotEmpty) {
      return apiStatus;
    }

    return 'dsr created';
  }

  Color getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'dsr approved':
        return const Color(0xff2E7D32);
      case 'dsr confirmed':
        return const Color(0xff1565C0);
      case 'dsr rejected':
        return const Color(0xffC62828);
      case 'dsr created':
      default:
        return const Color(0xffC47B15);
    }
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();
    if (dep == "BDO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                bdo_dashbord()), // Replace AnotherPage with your target page
      );
    } else if (dep == "BDM") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                bdm_dashbord()), // Replace AnotherPage with your target page
      );
    } else if (dep == "SD") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                SdDashboard()), // Replace AnotherPage with your target page
      );
    } else if (dep == "warehouse") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                WarehouseDashboard()), // Replace AnotherPage with your target page
      );
    } else if (dep == "CEO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ceo_dashboard()), // Replace AnotherPage with your target page
      );
    } else if (dep == "COO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ceo_dashboard()), // Replace AnotherPage with your target page
      );
    } else if (dep == "Warehouse Admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                WarehouseAdmin()), // Replace AnotherPage with your target page
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => dashboard()),
      );
    }
  }

  Color getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'dsr approved':
        return const Color(0xffEAF7EA);
      case 'dsr confirmed':
        return const Color(0xffEAF2FF);
      case 'dsr rejected':
        return const Color(0xffFDECEC);
      case 'dsr created':
      default:
        return const Color(0xffFFF4E2);
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'dsr approved':
        return Icons.verified_outlined;
      case 'dsr confirmed':
        return Icons.check_circle_outline;
      case 'dsr rejected':
        return Icons.cancel_outlined;
      case 'dsr created':
      default:
        return Icons.edit_note_outlined;
    }
  }

  @override
  void initState() {
    super.initState();
    getStaff();
    getstates();
    fetchTeamWiseReport();
  }

  @override
  void dispose() {
    searchController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    super.dispose();
  }

  Future<String?> getTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? prefs.getString('access');
  }

  Future<void> pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      startDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {});
    }
  }

  Future<void> pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      endDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {});
    }
  }

  void clearFilters() {
    setState(() {
      selectedStatus = '';
      selectedTeam = '';
      selectedCreatedBy = '';
      selectedState = '';
      searchController.clear();
      startDateController.clear();
      endDateController.clear();
    });
    fetchTeamWiseReport();
  }

  Future<void> fetchTeamWiseReport() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final token = await getTokenFromPrefs();

      if (token == null || token.isEmpty) {
        setState(() {
          errorMessage = 'Token not found. Please login again.';
          isLoading = false;
        });
        return;
      }

      final queryParams = <String, String>{
        'status': selectedStatus,
        'start_date': startDateController.text.trim(),
        'end_date': endDateController.text.trim(),
        'team': selectedTeam,
        'created_by': selectedCreatedBy,
        'state': selectedState,
        'search': searchController.text.trim(),
      };

      queryParams.removeWhere((key, value) => value.isEmpty);

      final uri = Uri.parse(
        '$apiBaseUrl/api/sales/team/summary/report/',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("TEAM REPORT URL    : $uri");
      debugPrint("TEAM REPORT STATUS : ${response.statusCode}");
      debugPrint("TEAM REPORT BODY   : ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final results = Map<String, dynamic>.from(decoded['results'] ?? {});

        final data = List<Map<String, dynamic>>.from(results['data'] ?? []);
        final totalMap = Map<String, dynamic>.from(results['totals'] ?? {});
        final filterMap = Map<String, dynamic>.from(results['filters'] ?? {});

        final Set<String> teamSet = {};
        final List<Map<String, dynamic>> teams = [];

        for (final team in data) {
          final teamId = "${team['team_id'] ?? ''}";
          final teamName = "${team['team_name'] ?? ''}";
          if (teamId.isNotEmpty && !teamSet.contains(teamId)) {
            teamSet.add(teamId);
            teams.add({'id': teamId, 'name': teamName});
          }
        }

        setState(() {
          reportData = data;
          totals = totalMap;
          filters = filterMap;
          teamOptions = teams;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'Failed to fetch report (${response.statusCode})\n${response.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("TEAM REPORT ERROR : $e");
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> getStaff() async {
    try {
      setState(() {
        isLoadingStaff = true;
      });

      final token = await getTokenFromPrefs();
      if (token == null) {
        throw Exception("Token not found");
      }

      final response = await http.get(
        Uri.parse('$api/api/staffs/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("GET STAFF RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final List data = parsed['data'] ?? [];

        setState(() {
          allStaff = data.where((item) {
            final dept =
                item['department_name']?.toString().trim().toUpperCase() ?? '';
            return dept == 'BDO' || dept == 'BDM';
          }).map<Map<String, dynamic>>((item) {
            return {
              'id': item['id'],
              'name': item['name']?.toString() ?? '',
              'email': item['email']?.toString() ?? '',
              'designation': item['designation']?.toString() ?? '',
              'image': item['image']?.toString() ?? '',
              'approval_status': item['approval_status']?.toString() ?? '',
              'family_name': item['family_name']?.toString() ?? '',
              'family_id':
                  item['family'] is Map ? item['family']['id'] : item['family'],
              'department_name': item['department_name']?.toString() ?? '',
            };
          }).toList();

          createdByOptions = List<Map<String, dynamic>>.from(allStaff);
        });
      }
    } catch (e) {
      debugPrint("Get staff error: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoadingStaff = false;
        });
      }
    }
  }

  Future<void> getstates() async {
    try {
      final token = await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/states/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("GET STATES RESPONSE: ${response.body}");

      final List<Map<String, dynamic>> stateslist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final statesData = parsed['data'] ?? [];

        for (final stateData in statesData) {
          stateslist.add({
            'id': stateData['id'],
            'name': stateData['name'],
          });
        }

        setState(() {
          statess = stateslist;
          stateOptions = stateslist;
        });
      }
    } catch (error) {
      debugPrint("Get states error: $error");
    }
  }

  Future<void> exportTeamReportExcel({bool shareFile = false}) async {
    try {
      if (reportData.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data available to export')),
        );
        return;
      }

      final ex.Excel excel = ex.Excel.createExcel();
      final String sheetName = excel.getDefaultSheet() ?? 'Sheet1';
      final ex.Sheet sheet = excel[sheetName];

      String safeString(dynamic value) {
        if (value == null) return '';
        return value.toString();
      }

      double toDouble(dynamic value) {
        if (value == null) return 0;
        if (value is int) return value.toDouble();
        if (value is double) return value;
        return double.tryParse(value.toString()) ?? 0;
      }

      dynamic numericCellValue(dynamic value) {
        final double number = toDouble(value);
        if (number == number.toInt()) {
          return number.toInt();
        }
        return double.parse(number.toStringAsFixed(2));
      }

      int getTeamRowCount(Map<String, dynamic> team) {
        int count = 0;
        final members = List<Map<String, dynamic>>.from(team['members'] ?? []);
        for (final member in members) {
          final states =
              List<Map<String, dynamic>>.from(member['states'] ?? []);
          count += states.isEmpty ? 1 : states.length;
        }
        return count == 0 ? 1 : count;
      }

      List<String> collectHourlyKeys() {
        final List<String> orderedKeys = [];

        void addKey(String key) {
          if (!orderedKeys.contains(key)) {
            orderedKeys.add(key);
          }
        }

        for (final team in reportData) {
          final members =
              List<Map<String, dynamic>>.from(team['members'] ?? []);
          for (final member in members) {
            final states =
                List<Map<String, dynamic>>.from(member['states'] ?? []);
            for (final state in states) {
              final hourly =
                  Map<String, dynamic>.from(state['hourly_durations'] ?? {});
              for (final key in hourly.keys) {
                addKey(key.toString());
              }
            }
          }
        }

        final totalHourly =
            Map<String, dynamic>.from(totals['hourly_durations'] ?? {});
        for (final key in totalHourly.keys) {
          addKey(key.toString());
        }

        return orderedKeys;
      }

      final ex.Border thinBorder = ex.Border(borderStyle: ex.BorderStyle.Thin);
      final ex.Border mediumBorder =
          ex.Border(borderStyle: ex.BorderStyle.Medium);

      final List<String> hourlyKeys = collectHourlyKeys();

      final List<String> headers = [
        'SL NO',
        'TEAM',
        'TEAM UNBILLED',
        'BDO',
        'STATE NO',
        'STATE',
        'DISTRICT',
        'TOTAL UNBILLED',
        'UNBILLED TO BILLED',
        'NEW CUSTOMER',
        'NEW CONVERSION',
        'BILLING',
        'VOLUME',
        'TOTAL CALL DURATION',
        ...hourlyKeys,
      ];

      final ex.CellStyle titleStyle = ex.CellStyle(
        bold: true,
        fontSize: 16,
        fontColorHex: '#FFFFFF',
        backgroundColorHex: '#0B5ED7',
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: mediumBorder,
        rightBorder: mediumBorder,
        topBorder: mediumBorder,
        bottomBorder: mediumBorder,
      );

      final ex.CellStyle headerStyle = ex.CellStyle(
        bold: true,
        fontColorHex: '#FFFFFF',
        backgroundColorHex: '#1E88E5',
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle teamBlockStyle1 = ex.CellStyle(
        backgroundColorHex: '#DCEAF7',
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle teamBlockStyle2 = ex.CellStyle(
        backgroundColorHex: '#E7F1FA',
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle teamBlockLeftStyle1 = ex.CellStyle(
        backgroundColorHex: '#DCEAF7',
        horizontalAlign: ex.HorizontalAlign.Left,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle teamBlockLeftStyle2 = ex.CellStyle(
        backgroundColorHex: '#E7F1FA',
        horizontalAlign: ex.HorizontalAlign.Left,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle teamMergedStyle1 = ex.CellStyle(
        bold: true,
        fontColorHex: '#1F1F1F',
        backgroundColorHex: '#E6D9F2',
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle teamMergedStyle2 = ex.CellStyle(
        bold: true,
        fontColorHex: '#1F1F1F',
        backgroundColorHex: '#DCCBED',
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );
      final ex.CellStyle memberMergedStyle1 = ex.CellStyle(
        bold: true,
        fontColorHex: '#000000',
        backgroundColorHex: '#FFF176', // ✅ light yellow
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle memberMergedStyle2 = ex.CellStyle(
        bold: true,
        fontColorHex: '#000000',
        backgroundColorHex: '#FFEE58', // ✅ slightly darker yellow
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle totalStyle = ex.CellStyle(
        bold: true,
        fontColorHex: '#FFFFFF',
        backgroundColorHex: '#198754',
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: mediumBorder,
        rightBorder: mediumBorder,
        topBorder: mediumBorder,
        bottomBorder: mediumBorder,
      );

      final ex.CellStyle summaryTitleStyle = ex.CellStyle(
        bold: true,
        fontSize: 13,
        fontColorHex: '#FFFFFF',
        backgroundColorHex: '#0A73FF',
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
      );

      final ex.CellStyle summaryHeaderStyle = ex.CellStyle(
        bold: true,
        fontColorHex: '#FFFFFF',
        backgroundColorHex: '#1E88E5',
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle summaryLabelStyle = ex.CellStyle(
        bold: true,
        fontColorHex: '#16324F',
        backgroundColorHex: '#EAF3FF',
        horizontalAlign: ex.HorizontalAlign.Left,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle summaryValueStyle = ex.CellStyle(
        bold: true,
        fontColorHex: '#0F5132',
        backgroundColorHex: '#F4FFF8',
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      void setTextCell(int row, int col, dynamic value, ex.CellStyle style) {
        final cell = sheet.cell(
          ex.CellIndex.indexByColumnRow(rowIndex: row, columnIndex: col),
        );
        cell.value = safeString(value);
        cell.cellStyle = style;
      }

      void setNumCell(int row, int col, dynamic value, ex.CellStyle style) {
        final cell = sheet.cell(
          ex.CellIndex.indexByColumnRow(rowIndex: row, columnIndex: col),
        );
        cell.value = numericCellValue(value);
        cell.cellStyle = style;
      }

      void setEmptyStyledCell(int row, int col, ex.CellStyle style) {
        final cell = sheet.cell(
          ex.CellIndex.indexByColumnRow(rowIndex: row, columnIndex: col),
        );
        cell.value = '';
        cell.cellStyle = style;
      }

      void fillStyledRange({
        required int startRow,
        required int endRow,
        required int startCol,
        required int endCol,
        required ex.CellStyle style,
      }) {
        for (int r = startRow; r <= endRow; r++) {
          for (int c = startCol; c <= endCol; c++) {
            setEmptyStyledCell(r, c, style);
          }
        }
      }

      void mergeRowTitle({
        required int row,
        required int startCol,
        required int endCol,
        required String text,
        required ex.CellStyle style,
      }) {
        for (int c = startCol; c <= endCol; c++) {
          setEmptyStyledCell(row, c, style);
        }
        sheet.merge(
          ex.CellIndex.indexByColumnRow(rowIndex: row, columnIndex: startCol),
          ex.CellIndex.indexByColumnRow(rowIndex: row, columnIndex: endCol),
        );
        setTextCell(row, startCol, text, style);
      }

      int maxLen(String s) => s.trim().length;

      final Map<int, int> maxColumnLengths = {};
      for (int i = 0; i < headers.length; i++) {
        maxColumnLengths[i] = maxLen(headers[i]);
      }

      void considerLength(int col, dynamic value) {
        final int len = maxLen(safeString(value));
        if (len > (maxColumnLengths[col] ?? 0)) {
          maxColumnLengths[col] = len;
        }
      }

      mergeRowTitle(
        row: 0,
        startCol: 0,
        endCol: headers.length - 1,
        text: 'TEAM WISE DSR REPORT',
        style: titleStyle,
      );

      const int headerRowIndex = 2;
      for (int col = 0; col < headers.length; col++) {
        setTextCell(headerRowIndex, col, headers[col], headerStyle);
      }

      int currentRow = headerRowIndex + 1;
      int teamSlNo = 1;

      for (int teamIndex = 0; teamIndex < reportData.length; teamIndex++) {
        final Map<String, dynamic> team = reportData[teamIndex];
        final List<Map<String, dynamic>> members =
            List<Map<String, dynamic>>.from(team['members'] ?? []);

        final String teamName = safeString(team['team_name']).trim().isEmpty
            ? 'No Team'
            : safeString(team['team_name']);
        final dynamic teamUnbilled = team['team_unbilled'] ?? 0;

        final bool evenBlock = teamIndex.isOdd;

        final ex.CellStyle rowCenterStyle =
            evenBlock ? teamBlockStyle2 : teamBlockStyle1;
        final ex.CellStyle rowLeftStyle =
            evenBlock ? teamBlockLeftStyle2 : teamBlockLeftStyle1;
        final ex.CellStyle teamMergedStyle =
            evenBlock ? teamMergedStyle2 : teamMergedStyle1;
        final ex.CellStyle memberMergedStyle =
            evenBlock ? memberMergedStyle2 : memberMergedStyle1;

        final int teamStartRow = currentRow;
        final int teamRowCount = getTeamRowCount(team);
        final int teamEndRow = teamStartRow + teamRowCount - 1;

        fillStyledRange(
          startRow: teamStartRow,
          endRow: teamEndRow,
          startCol: 0,
          endCol: headers.length - 1,
          style: rowCenterStyle,
        );

        for (int r = teamStartRow; r <= teamEndRow; r++) {
          setEmptyStyledCell(r, 6, rowLeftStyle);
        }

        setNumCell(teamStartRow, 0, teamSlNo, teamMergedStyle);
        setTextCell(teamStartRow, 1, teamName, teamMergedStyle);
        setNumCell(teamStartRow, 2, teamUnbilled, teamMergedStyle);

        considerLength(0, teamSlNo);
        considerLength(1, teamName);
        considerLength(2, teamUnbilled);

        if (teamRowCount > 1) {
          sheet.merge(
            ex.CellIndex.indexByColumnRow(
                rowIndex: teamStartRow, columnIndex: 0),
            ex.CellIndex.indexByColumnRow(rowIndex: teamEndRow, columnIndex: 0),
          );
          sheet.merge(
            ex.CellIndex.indexByColumnRow(
                rowIndex: teamStartRow, columnIndex: 1),
            ex.CellIndex.indexByColumnRow(rowIndex: teamEndRow, columnIndex: 1),
          );
          sheet.merge(
            ex.CellIndex.indexByColumnRow(
                rowIndex: teamStartRow, columnIndex: 2),
            ex.CellIndex.indexByColumnRow(rowIndex: teamEndRow, columnIndex: 2),
          );
        }

        if (members.isEmpty) {
          currentRow++;
        } else {
          for (final member in members) {
            final List<Map<String, dynamic>> states =
                List<Map<String, dynamic>>.from(member['states'] ?? []);
            final String memberName = safeString(member['created_by_name']);

            final int memberStartRow = currentRow;
            final int memberRowCount = states.isEmpty ? 1 : states.length;
            final int memberEndRow = memberStartRow + memberRowCount - 1;

            setTextCell(memberStartRow, 3, memberName, memberMergedStyle);
            considerLength(3, memberName);

            if (memberRowCount > 1) {
              sheet.merge(
                ex.CellIndex.indexByColumnRow(
                  rowIndex: memberStartRow,
                  columnIndex: 3,
                ),
                ex.CellIndex.indexByColumnRow(
                  rowIndex: memberEndRow,
                  columnIndex: 3,
                ),
              );
            }

            if (states.isEmpty) {
              currentRow++;
            } else {
              for (int stateIndex = 0;
                  stateIndex < states.length;
                  stateIndex++) {
                final Map<String, dynamic> state = states[stateIndex];
                final Map<String, dynamic> hourly =
                    Map<String, dynamic>.from(state['hourly_durations'] ?? {});

                setNumCell(currentRow, 4, stateIndex + 1, rowCenterStyle);
                setTextCell(
                  currentRow,
                  5,
                  state['state_name'] ?? '',
                  rowCenterStyle,
                );
                setTextCell(
                  currentRow,
                  6,
                  state['district_name'] ?? '',
                  rowLeftStyle,
                );
                setNumCell(
                  currentRow,
                  7,
                  state['total_unbilled'] ?? 0,
                  rowCenterStyle,
                );
                setNumCell(
                  currentRow,
                  8,
                  state['unbilled_to_billed'] ?? 0,
                  rowCenterStyle,
                );
                setNumCell(
                  currentRow,
                  9,
                  state['new_customer'] ?? 0,
                  rowCenterStyle,
                );
                setNumCell(
                  currentRow,
                  10,
                  state['new_conversion'] ?? 0,
                  rowCenterStyle,
                );
                setNumCell(
                  currentRow,
                  11,
                  state['billing'] ?? 0,
                  rowCenterStyle,
                );
                setNumCell(
                  currentRow,
                  12,
                  state['volume'] ?? 0,
                  rowCenterStyle,
                );
                setNumCell(
                  currentRow,
                  13,
                  state['total_call_duration'] ?? 0,
                  rowCenterStyle,
                );

                considerLength(4, stateIndex + 1);
                considerLength(5, state['state_name'] ?? '');
                considerLength(6, state['district_name'] ?? '');
                considerLength(7, state['total_unbilled'] ?? 0);
                considerLength(8, state['unbilled_to_billed'] ?? 0);
                considerLength(9, state['new_customer'] ?? 0);
                considerLength(10, state['new_conversion'] ?? 0);
                considerLength(11, state['billing'] ?? 0);
                considerLength(12, state['volume'] ?? 0);
                considerLength(13, state['total_call_duration'] ?? 0);

                for (int h = 0; h < hourlyKeys.length; h++) {
                  final dynamic value = hourly[hourlyKeys[h]] ?? 0;
                  setNumCell(currentRow, 14 + h, value, rowCenterStyle);
                  considerLength(14 + h, value);
                }

                currentRow++;
              }
            }
          }
        }

        teamSlNo++;
      }

      final Map<String, dynamic> totalHourly =
          Map<String, dynamic>.from(totals['hourly_durations'] ?? {});
      final int totalRow = currentRow;

      fillStyledRange(
        startRow: totalRow,
        endRow: totalRow,
        startCol: 0,
        endCol: headers.length - 1,
        style: totalStyle,
      );

      setTextCell(totalRow, 1, 'TOTAL', totalStyle);
      setNumCell(totalRow, 2, totals['team_unbilled'] ?? 0, totalStyle);
      setNumCell(
        totalRow,
        7,
        totals['total_unbilled'] ?? totals['team_unbilled'] ?? 0,
        totalStyle,
      );
      setNumCell(totalRow, 8, totals['unbilled_to_billed'] ?? 0, totalStyle);
      setNumCell(totalRow, 9, totals['new_customer'] ?? 0, totalStyle);
      setNumCell(totalRow, 10, totals['new_conversion'] ?? 0, totalStyle);
      setNumCell(totalRow, 11, totals['billing'] ?? 0, totalStyle);
      setNumCell(totalRow, 12, totals['volume'] ?? 0, totalStyle);
      setNumCell(totalRow, 13, totals['total_call_duration'] ?? 0, totalStyle);

      considerLength(2, totals['team_unbilled'] ?? 0);
      considerLength(
          7, totals['total_unbilled'] ?? totals['team_unbilled'] ?? 0);
      considerLength(8, totals['unbilled_to_billed'] ?? 0);
      considerLength(9, totals['new_customer'] ?? 0);
      considerLength(10, totals['new_conversion'] ?? 0);
      considerLength(11, totals['billing'] ?? 0);
      considerLength(12, totals['volume'] ?? 0);
      considerLength(13, totals['total_call_duration'] ?? 0);

      for (int h = 0; h < hourlyKeys.length; h++) {
        final dynamic value = totalHourly[hourlyKeys[h]] ?? 0;
        setNumCell(totalRow, 14 + h, value, totalStyle);
        considerLength(14 + h, value);
      }

      final int summaryStartRow = totalRow + 3;

      mergeRowTitle(
        row: summaryStartRow,
        startCol: 0,
        endCol: 3,
        text: 'OVERALL TOTALS SUMMARY',
        style: summaryTitleStyle,
      );

      setTextCell(summaryStartRow + 1, 0, 'METRIC', summaryHeaderStyle);
      setTextCell(summaryStartRow + 1, 1, 'VALUE', summaryHeaderStyle);
      setTextCell(summaryStartRow + 1, 2, 'METRIC', summaryHeaderStyle);
      setTextCell(summaryStartRow + 1, 3, 'VALUE', summaryHeaderStyle);

      final List<List<dynamic>> summaryRows = [
        [
          'Team Unbilled',
          totals['team_unbilled'] ?? 0,
          'Total Unbilled',
          totals['total_unbilled'] ?? totals['team_unbilled'] ?? 0,
        ],
        [
          'Unbilled To Billed',
          totals['unbilled_to_billed'] ?? 0,
          'New Customer',
          totals['new_customer'] ?? 0,
        ],
        [
          'New Conversion',
          totals['new_conversion'] ?? 0,
          'Billing',
          totals['billing'] ?? 0,
        ],
        [
          'Volume',
          totals['volume'] ?? 0,
          'Total Call Duration',
          totals['total_call_duration'] ?? 0,
        ],
        [
          'Avg Call Duration (Mins)',
          totals['call_duration_average_minutes'] ?? 0,
          'Avg Call Duration (%)',
          totals['call_duration_average_percentage'] ?? 0,
        ],
      ];

      int overallRowCursor = summaryStartRow + 2;
      for (final row in summaryRows) {
        setTextCell(overallRowCursor, 0, row[0], summaryLabelStyle);
        setNumCell(overallRowCursor, 1, row[1], summaryValueStyle);
        setTextCell(overallRowCursor, 2, row[2], summaryLabelStyle);
        setNumCell(overallRowCursor, 3, row[3], summaryValueStyle);
        overallRowCursor++;
      }

      const int hourlyStartCol = 5;

      mergeRowTitle(
        row: summaryStartRow,
        startCol: hourlyStartCol,
        endCol: hourlyStartCol + 1,
        text: 'HOURLY DURATIONS',
        style: summaryTitleStyle,
      );

      setTextCell(
        summaryStartRow + 1,
        hourlyStartCol,
        'TIME SLOT',
        summaryHeaderStyle,
      );
      setTextCell(
        summaryStartRow + 1,
        hourlyStartCol + 1,
        'MINUTES',
        summaryHeaderStyle,
      );

      int hourlySummaryRow = summaryStartRow + 2;
      for (final key in hourlyKeys) {
        setTextCell(hourlySummaryRow, hourlyStartCol, key, summaryLabelStyle);
        setNumCell(
          hourlySummaryRow,
          hourlyStartCol + 1,
          totalHourly[key] ?? 0,
          summaryValueStyle,
        );
        hourlySummaryRow++;
      }

      double widthFromLen(int len) {
        double w = len * 1.2 + 3;
        if (w < 10) w = 10;
        if (w > 40) w = 40;
        return w;
      }

      for (int col = 0; col < headers.length; col++) {
        double width =
            widthFromLen(maxColumnLengths[col] ?? headers[col].length);

        if (col == 1) width = width < 20 ? 20 : width;
        if (col == 2) width = width < 18 ? 18 : width;
        if (col == 3) width = width < 22 ? 22 : width;
        if (col == 5) width = width < 18 ? 18 : width;
        if (col == 6) width = width < 20 ? 20 : width;
        if (col == 13) width = width < 20 ? 20 : width;
        if (col >= 14) width = width < 14 ? 14 : width;

        sheet.setColWidth(col, width);
      }

      final Directory dir = await getApplicationDocumentsDirectory();
      final String timestamp =
          DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String filePath = '${dir.path}/team_wise_report_$timestamp.xlsx';

      final List<int>? bytes = excel.encode();
      if (bytes == null) {
        throw Exception('Excel generation failed');
      }

      final File file = File(filePath);
      await file.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);

      if (shareFile) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Team Wise DSR Report',
        );
      } else {
        final result = await OpenFilex.open(file.path);
        debugPrint('OPEN FILE RESULT: ${result.type} ${result.message}');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xff0A73FF),
          content: Text(
            shareFile
                ? 'Excel generated and ready to share'
                : 'Excel exported successfully',
          ),
        ),
      );
    } catch (e) {
      debugPrint('EXPORT EXCEL ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export excel: $e')),
      );
    }
  }

  String formatValue(dynamic value) {
    if (value == null) return '0';

    if (value is int) return value.toString();

    if (value is double) {
      if (value == value.toInt()) return value.toInt().toString();
      return value.toStringAsFixed(2);
    }

    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        if (parsed == parsed.toInt()) return parsed.toInt().toString();
        return parsed.toStringAsFixed(2);
      }
      return value;
    }

    return value.toString();
  }

  Widget buildTopSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color bgColor,
    required Color iconBg,
    required Color valueColor,
  }) {
    final isSmall = _isSmallScreen(context);
    final isTablet = _isTablet(context);

    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet
              ? 16
              : isSmall
                  ? 10
                  : 14,
          vertical: isTablet
              ? 16
              : isSmall
                  ? 10
                  : 14,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(isTablet ? 22 : 20),
          border: Border.all(color: Colors.black.withOpacity(0.04)),
        ),
        child: Row(
          children: [
            Container(
              height: isTablet
                  ? 46
                  : isSmall
                      ? 38
                      : 42,
              width: isTablet
                  ? 46
                  : isSmall
                      ? 38
                      : 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
              ),
              child: Icon(
                icon,
                color: valueColor,
                size: isTablet
                    ? 22
                    : isSmall
                        ? 18
                        : 20,
              ),
            ),
            SizedBox(width: isSmall ? 8 : 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: isTablet
                          ? 13.5
                          : isSmall
                              ? 11.5
                              : 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: isSmall ? 3 : 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: valueColor,
                      fontSize: isTablet
                          ? 19
                          : isSmall
                              ? 15
                              : 18,
                      fontWeight: FontWeight.w800,
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

  Widget buildStatusBadge({
    required String text,
    required Color textColor,
    required Color bgColor,
    required IconData icon,
  }) {
    final isSmall = _isSmallScreen(context);
    final isTablet = _isTablet(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet
            ? 13
            : isSmall
                ? 10
                : 12,
        vertical: isTablet
            ? 8
            : isSmall
                ? 6
                : 7,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: textColor.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isTablet
                ? 16
                : isSmall
                    ? 13
                    : 15,
            color: textColor,
          ),
          SizedBox(width: isSmall ? 4 : 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: isTablet
                    ? 13
                    : isSmall
                        ? 11
                        : 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isSmall = _isSmallScreen(context);
    final isTablet = _isTablet(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isSmall ? 10 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: isTablet
                ? 21
                : isSmall
                    ? 18
                    : 20,
            color: Colors.grey.shade600,
          ),
          SizedBox(width: isSmall ? 8 : 12),
          SizedBox(
            width: isTablet
                ? 120
                : isSmall
                    ? 82
                    : 105,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w700,
                fontSize: isTablet
                    ? 14.5
                    : isSmall
                        ? 12
                        : 14,
              ),
            ),
          ),
          Text(
            ":  ",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: isTablet
                  ? 14.5
                  : isSmall
                      ? 12
                      : 14,
              color: Colors.black54,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: isTablet
                    ? 14.5
                    : isSmall
                        ? 12.5
                        : 14.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMiniMetric(String title, dynamic value) {
    final isSmall = _isSmallScreen(context);
    final isTablet = _isTablet(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet
            ? 14
            : isSmall
                ? 10
                : 12,
        vertical: isTablet
            ? 14
            : isSmall
                ? 10
                : 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffF7FAFF),
        borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
        border: Border.all(color: const Color(0xffDDE8F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: isTablet
                  ? 13
                  : isSmall
                      ? 11
                      : 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            formatValue(value),
            style: TextStyle(
              color: const Color(0xff1565C0),
              fontSize: isTablet
                  ? 16
                  : isSmall
                      ? 13
                      : 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHourlyRows(Map<String, dynamic> hourlyDurations) {
    final isSmall = _isSmallScreen(context);
    final isTablet = _isTablet(context);

    if (hourlyDurations.isEmpty) {
      return Text(
        "No hourly duration data",
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: isTablet
              ? 13.5
              : isSmall
                  ? 11.5
                  : 13,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final entries = hourlyDurations.entries.toList();

    return Column(
      children: entries.map((entry) {
        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: isSmall ? 6 : 8),
          padding: EdgeInsets.symmetric(
            horizontal: isTablet
                ? 14
                : isSmall
                    ? 10
                    : 12,
            vertical: isTablet
                ? 12
                : isSmall
                    ? 8
                    : 10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xffEEF5FF),
            borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
            border: Border.all(color: const Color(0xffD8E8FF)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  entry.key,
                  style: TextStyle(
                    color: const Color(0xff245AA8),
                    fontWeight: FontWeight.w700,
                    fontSize: isTablet
                        ? 13
                        : isSmall
                            ? 11
                            : 12.5,
                  ),
                ),
              ),
              Text(
                "${formatValue(entry.value)} mins",
                style: TextStyle(
                  color: const Color(0xff245AA8),
                  fontWeight: FontWeight.w700,
                  fontSize: isTablet
                      ? 13
                      : isSmall
                          ? 11
                          : 12.5,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget buildStateCard(
    Map<String, dynamic> state, {
    required int stateIndex,
    required String expandKey,
  }) {
    final isSmall = _isSmallScreen(context);
    final isTablet = _isTablet(context);
    final hourlyDurations =
        Map<String, dynamic>.from(state['hourly_durations'] ?? {});

    return Container(
      margin: EdgeInsets.only(top: isSmall ? 10 : 14),
      padding: EdgeInsets.all(
        isTablet
            ? 18
            : isSmall
                ? 10
                : 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffFBFDFF),
        borderRadius: BorderRadius.circular(isTablet ? 20 : 18),
        border: Border.all(color: const Color(0xffD9E6F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: isTablet
                    ? 38
                    : isSmall
                        ? 30
                        : 34,
                width: isTablet
                    ? 38
                    : isSmall
                        ? 30
                        : 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xffE9F3FF),
                  borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                ),
                child: Text(
                  "$stateIndex",
                  style: TextStyle(
                    color: const Color(0xff1565C0),
                    fontWeight: FontWeight.w800,
                    fontSize: isTablet
                        ? 14
                        : isSmall
                            ? 11.5
                            : 13,
                  ),
                ),
              ),
              SizedBox(width: isSmall ? 8 : 10),
              Expanded(
                child: Text(
                  "${state['state_name'] ?? '-'} - ${state['district_name'] ?? '-'}",
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                    fontSize: isTablet
                        ? 16
                        : isSmall
                            ? 12.5
                            : 15,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmall ? 10 : 14),
          Wrap(
            spacing: isSmall ? 8 : 10,
            runSpacing: isSmall ? 8 : 10,
            children: [
              buildStatusBadge(
                text: "billing ${formatValue(state['billing'])}",
                textColor: const Color(0xffC47B15),
                bgColor: const Color(0xffFFF4E2),
                icon: Icons.receipt_long,
              ),
              buildStatusBadge(
                text: "volume ${formatValue(state['volume'])}",
                textColor: const Color(0xff2E7D32),
                bgColor: const Color(0xffEAF7EA),
                icon: Icons.person_add_alt_1,
              ),
            ],
          ),
          SizedBox(height: isSmall ? 12 : 16),
          Text(
            "Record Details",
            style: TextStyle(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w800,
              fontSize: isTablet
                  ? 18
                  : isSmall
                      ? 14
                      : 17,
            ),
          ),
          SizedBox(height: isSmall ? 10 : 14),
          buildDetailRow(
            icon: Icons.map_outlined,
            label: "State",
            value: "${state['state_name'] ?? '-'}",
          ),
          buildDetailRow(
            icon: Icons.location_city_outlined,
            label: "District",
            value: "${state['district_name'] ?? '-'}",
          ),
          buildDetailRow(
            icon: Icons.money_off_csred_outlined,
            label: "Total Unbilled",
            value: formatValue(state['total_unbilled']),
          ),
          buildDetailRow(
            icon: Icons.compare_arrows,
            label: "Unbilled to Billed",
            value: formatValue(state['unbilled_to_billed']),
          ),
          buildDetailRow(
            icon: Icons.person,
            label: "New Customer",
            value: formatValue(state['new_customer']),
          ),
          buildDetailRow(
            icon: Icons.autorenew,
            label: "New Conversion",
            value: formatValue(state['new_conversion']),
          ),
          buildDetailRow(
            icon: Icons.call_outlined,
            label: "Call Duration",
            value: formatValue(state['total_call_duration']),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xffF8FBFF),
              borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
              border: Border.all(color: const Color(0xffD9E6F5)),
            ),
            child: Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
                  onTap: () {
                    setState(() {
                      if (expandedHourlyKey == expandKey) {
                        expandedHourlyKey = '';
                      } else {
                        expandedHourlyKey = expandKey;
                      }
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.all(
                      isTablet
                          ? 16
                          : isSmall
                              ? 10
                              : 14,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: isTablet
                              ? 19
                              : isSmall
                                  ? 16
                                  : 18,
                          color: const Color(0xff245AA8),
                        ),
                        SizedBox(width: isSmall ? 6 : 8),
                        Expanded(
                          child: Text(
                            "Hourly Durations",
                            style: TextStyle(
                              color: const Color(0xff245AA8),
                              fontWeight: FontWeight.w800,
                              fontSize: isTablet
                                  ? 15
                                  : isSmall
                                      ? 12.5
                                      : 14.5,
                            ),
                          ),
                        ),
                        Text(
                          expandedHourlyKey == expandKey
                              ? "See Less"
                              : "See More",
                          style: TextStyle(
                            color: const Color(0xff245AA8),
                            fontWeight: FontWeight.w700,
                            fontSize: isTablet
                                ? 13
                                : isSmall
                                    ? 11
                                    : 12.5,
                          ),
                        ),
                        SizedBox(width: isSmall ? 4 : 6),
                        Icon(
                          expandedHourlyKey == expandKey
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xff245AA8),
                          size: isTablet ? 24 : 22,
                        ),
                      ],
                    ),
                  ),
                ),
                if (expandedHourlyKey == expandKey)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      isTablet
                          ? 16
                          : isSmall
                              ? 10
                              : 14,
                      0,
                      isTablet
                          ? 16
                          : isSmall
                              ? 10
                              : 14,
                      isTablet
                          ? 16
                          : isSmall
                              ? 10
                              : 14,
                    ),
                    child: buildHourlyRows(hourlyDurations),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMemberSection(
    Map<String, dynamic> member, {
    required int memberIndex,
  }) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final isSmall = width < 360;
    final isTablet = width >= 600;

    final states = List<Map<String, dynamic>>.from(member['states'] ?? []);
    final String memberKey =
        "${member['created_by_id'] ?? member['created_by_name'] ?? memberIndex}";
    final bool isExpanded = expandedMemberKey == memberKey;

    final String memberStatus =
        (member['status'] ?? member['approval_status'] ?? getDisplayStatus())
            .toString()
            .trim();

    return Container(
      margin: EdgeInsets.only(top: isSmall ? 12 : 16),
      padding: EdgeInsets.all(
        isTablet
            ? 18
            : isSmall
                ? 10
                : 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffF8FBFF),
        borderRadius: BorderRadius.circular(isTablet ? 20 : 18),
        border: Border.all(color: const Color(0xffD9E6F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
            onTap: () {
              setState(() {
                if (expandedMemberKey == memberKey) {
                  expandedMemberKey = '';
                } else {
                  expandedMemberKey = memberKey;
                }
              });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: isTablet
                          ? 48
                          : isSmall
                              ? 36
                              : 42,
                      width: isTablet
                          ? 48
                          : isSmall
                              ? 36
                              : 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xffE8F2FF),
                        borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
                      ),
                      child: Text(
                        "$memberIndex",
                        style: TextStyle(
                          color: const Color(0xff1565C0),
                          fontWeight: FontWeight.w800,
                          fontSize: isTablet
                              ? 17
                              : isSmall
                                  ? 13
                                  : 16,
                        ),
                      ),
                    ),
                    SizedBox(width: isSmall ? 8 : 10),
                    Expanded(
                      child: Text(
                        member['created_by_name'] ?? 'Unknown Member',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: isTablet
                              ? 18
                              : isSmall
                                  ? 14
                                  : 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      isExpanded ? "See Less" : "See More",
                      style: TextStyle(
                        color: const Color(0xff245AA8),
                        fontWeight: FontWeight.w700,
                        fontSize: isTablet
                            ? 13.5
                            : isSmall
                                ? 11
                                : 12.5,
                      ),
                    ),
                    SizedBox(width: isSmall ? 4 : 6),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xff245AA8),
                      size: isTablet ? 24 : 22,
                    ),
                  ],
                ),
                SizedBox(height: isSmall ? 10 : 12),
                buildStatusBadge(
                  text: memberStatus,
                  textColor: getStatusTextColor(memberStatus),
                  bgColor: getStatusBgColor(memberStatus),
                  icon: getStatusIcon(memberStatus),
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            SizedBox(height: isSmall ? 10 : 12),
            if (states.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(
                  isTablet
                      ? 16
                      : isSmall
                          ? 10
                          : 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
                ),
                child: Text(
                  "No state data available",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                    fontSize: isTablet
                        ? 14
                        : isSmall
                            ? 12
                            : 13,
                  ),
                ),
              )
            else
              ...List.generate(
                states.length,
                (index) => buildStateCard(
                  states[index],
                  stateIndex: index + 1,
                  expandKey:
                      "${member['created_by_id'] ?? memberIndex}_${states[index]['state_id'] ?? index}",
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget buildTeamCard(Map<String, dynamic> team, int teamIndex) {
    final isSmall = _isSmallScreen(context);
    final isTablet = _isTablet(context);
    final members = List<Map<String, dynamic>>.from(team['members'] ?? []);

    return Container(
      margin: EdgeInsets.only(bottom: isSmall ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 28 : 26),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xffDDE7F2)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              isTablet
                  ? 18
                  : isSmall
                      ? 12
                      : 16,
              isTablet
                  ? 18
                  : isSmall
                      ? 12
                      : 16,
              isTablet
                  ? 18
                  : isSmall
                      ? 12
                      : 16,
              isTablet
                  ? 18
                  : isSmall
                      ? 12
                      : 16,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff2EA8FF), Color(0xff0A73FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(26),
                topRight: Radius.circular(26),
              ),
            ),
            child: Row(
              children: [
                Container(
                  height: isTablet
                      ? 48
                      : isSmall
                          ? 38
                          : 44,
                  width: isTablet
                      ? 48
                      : isSmall
                          ? 38
                          : 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
                  ),
                  child: Text(
                    "$teamIndex",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet
                          ? 19
                          : isSmall
                              ? 15
                              : 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(width: isSmall ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team['team_name'] ?? 'No Team',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: isTablet
                              ? 24
                              : isSmall
                                  ? 16
                                  : 22,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet
                        ? 16
                        : isSmall
                            ? 10
                            : 14,
                    vertical: isTablet
                        ? 11
                        : isSmall
                            ? 8
                            : 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
                  ),
                  child: Text(
                    "Unbilled\n${formatValue(team['team_unbilled'])}",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: isTablet
                          ? 13.5
                          : isSmall
                              ? 11
                              : 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isTablet
                  ? 18
                  : isSmall
                      ? 12
                      : 16,
              isTablet
                  ? 18
                  : isSmall
                      ? 12
                      : 16,
              isTablet
                  ? 18
                  : isSmall
                      ? 12
                      : 16,
              isTablet
                  ? 20
                  : isSmall
                      ? 14
                      : 18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: isSmall ? 8 : 10,
                  runSpacing: isSmall ? 8 : 10,
                  children: [
                    buildStatusBadge(
                      text: "Total members ${members.length}",
                      textColor: const Color(0xffC47B15),
                      bgColor: const Color(0xffFFF4E2),
                      icon: Icons.groups_2_outlined,
                    ),
                  ],
                ),
                SizedBox(height: isSmall ? 12 : 16),
                Text(
                  "Team Details",
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: isTablet
                        ? 18
                        : isSmall
                            ? 14
                            : 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: isSmall ? 10 : 14),
                buildDetailRow(
                  icon: Icons.badge_outlined,
                  label: "Team Name",
                  value: "${team['team_name'] ?? '-'}",
                ),
                buildDetailRow(
                  icon: Icons.money_off_csred_outlined,
                  label: "Team Unbilled",
                  value: formatValue(team['team_unbilled']),
                ),
                if (members.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(
                      isTablet
                          ? 16
                          : isSmall
                              ? 10
                              : 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffF8FBFF),
                      borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
                    ),
                    child: Text(
                      "No members available",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                        fontSize: isTablet
                            ? 14
                            : isSmall
                                ? 12
                                : 13,
                      ),
                    ),
                  )
                else
                  ...List.generate(
                    members.length,
                    (index) => buildMemberSection(
                      members[index],
                      memberIndex: index + 1,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTotalsCard() {
    final isSmall = _isSmallScreen(context);
    final isTablet = _isTablet(context);
    final hourlyDurations =
        Map<String, dynamic>.from(totals['hourly_durations'] ?? {});
    const String totalsExpandKey = "totals_hourly";

    return Container(
      margin: EdgeInsets.only(bottom: isSmall ? 14 : 18),
      padding: EdgeInsets.all(
        isTablet
            ? 20
            : isSmall
                ? 12
                : 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 28 : 26),
        border: Border.all(color: const Color(0xffDDE7F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: const Color(0xff0A73FF),
                size: isTablet
                    ? 24
                    : isSmall
                        ? 20
                        : 22,
              ),
              SizedBox(width: isSmall ? 6 : 8),
              Text(
                "Overall Totals",
                style: TextStyle(
                  color: const Color(0xff0A73FF),
                  fontSize: isTablet
                      ? 21
                      : isSmall
                          ? 16
                          : 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmall ? 12 : 16),

          GridView.count(
            crossAxisCount: isTablet ? 3 : 2,
            childAspectRatio: isTablet
                ? 1.8
                : isSmall
                    ? 1.35
                    : 1.55,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: isSmall ? 8 : 10,
            mainAxisSpacing: isSmall ? 8 : 10,
            children: [
              buildMiniMetric("Team Unbilled", totals['team_unbilled']),
              // buildMiniMetric(
              //   "Total Unbilled",
              //   totals['total_unbilled'] ?? totals['team_unbilled'],
              // ),
              buildMiniMetric(
                  "Unbilled To Billed", totals['unbilled_to_billed']),
              buildMiniMetric("New Customer", totals['new_customer']),
              buildMiniMetric("New Conversion", totals['new_conversion']),
              buildMiniMetric("Billing", totals['billing']),
              buildMiniMetric("Volume", totals['volume']),
              buildMiniMetric(
                "Total Call Duration",
                "${formatValue(totals['total_call_duration'])} mins",
              ),
              buildMiniMetric(
                "Call Duration Average",
                "${formatValue(totals['call_duration_average_minutes'])} mins",
              ),
            ],
          ),

          // SizedBox(height: isSmall ? 12 : 16),

          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 16 : 14,
              vertical: isTablet ? 16 : 14,
            ),
            decoration: BoxDecoration(
              color: const Color(0xffF8FBFF),
              borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
              border: Border.all(color: const Color(0xffD9E6F5)),
            ),
            child: Row(
              children: [
                // Container(
                //   height: isTablet ? 42 : 38,
                //   width: isTablet ? 42 : 38,
                //   decoration: BoxDecoration(
                //     color: const Color(0xffEAF3FF),
                //     borderRadius: BorderRadius.circular(12),
                //   ),
                //   child: Icon(
                //     Icons.percent_rounded,
                //     color: const Color(0xff245AA8),
                //     size: isTablet ? 22 : 20,
                //   ),
                // ),
                // SizedBox(width: isSmall ? 10 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Call Duration Avg Percentage",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: isTablet
                              ? 13
                              : isSmall
                                  ? 11
                                  : 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "${formatValue(totals['call_duration_average_percentage'])} %",
                        style: TextStyle(
                          color: const Color(0xff1565C0),
                          fontSize: isTablet
                              ? 16
                              : isSmall
                                  ? 13
                                  : 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: isSmall ? 12 : 16),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xffF8FBFF),
              borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
              border: Border.all(color: const Color(0xffD9E6F5)),
            ),
            child: Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
                  onTap: () {
                    setState(() {
                      if (expandedHourlyKey == totalsExpandKey) {
                        expandedHourlyKey = '';
                      } else {
                        expandedHourlyKey = totalsExpandKey;
                      }
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.all(
                      isTablet
                          ? 16
                          : isSmall
                              ? 10
                              : 14,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: isTablet
                              ? 19
                              : isSmall
                                  ? 16
                                  : 18,
                          color: const Color(0xff245AA8),
                        ),
                        SizedBox(width: isSmall ? 6 : 8),
                        Expanded(
                          child: Text(
                            "Hourly Durations",
                            style: TextStyle(
                              color: const Color(0xff245AA8),
                              fontWeight: FontWeight.w800,
                              fontSize: isTablet
                                  ? 15
                                  : isSmall
                                      ? 12.5
                                      : 14.5,
                            ),
                          ),
                        ),
                        Text(
                          expandedHourlyKey == totalsExpandKey
                              ? "See Less"
                              : "See More",
                          style: TextStyle(
                            color: const Color(0xff245AA8),
                            fontWeight: FontWeight.w700,
                            fontSize: isTablet
                                ? 13
                                : isSmall
                                    ? 11
                                    : 12.5,
                          ),
                        ),
                        SizedBox(width: isSmall ? 4 : 6),
                        Icon(
                          expandedHourlyKey == totalsExpandKey
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xff245AA8),
                          size: isTablet ? 24 : 22,
                        ),
                      ],
                    ),
                  ),
                ),
                if (expandedHourlyKey == totalsExpandKey)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      isTablet
                          ? 16
                          : isSmall
                              ? 10
                              : 14,
                      0,
                      isTablet
                          ? 16
                          : isSmall
                              ? 10
                              : 14,
                      isTablet
                          ? 16
                          : isSmall
                              ? 10
                              : 14,
                    ),
                    child: buildHourlyRows(hourlyDurations),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> pickDateRange() async {
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: (startDateController.text.isNotEmpty &&
              endDateController.text.isNotEmpty)
          ? DateTimeRange(
              start: DateTime.parse(startDateController.text),
              end: DateTime.parse(endDateController.text),
            )
          : DateTimeRange(
              start: now,
              end: now,
            ),
    );

    if (picked != null) {
      setState(() {
        startDateController.text =
            DateFormat('yyyy-MM-dd').format(picked.start);
        endDateController.text = DateFormat('yyyy-MM-dd').format(picked.end);
      });

      fetchTeamWiseReport();
    }
  }

  Widget buildFiltersCard() {
    final isSmall = _isSmallScreen(context);
    final isTablet = _isTablet(context);

    final commonInputDecoration = InputDecoration(
      filled: true,
      fillColor: const Color(0xffF9FBFF),
      contentPadding: EdgeInsets.symmetric(
        horizontal: isTablet
            ? 16
            : isSmall
                ? 10
                : 14,
        vertical: isTablet
            ? 16
            : isSmall
                ? 12
                : 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
        borderSide: const BorderSide(color: Color(0xffD8E4F2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
        borderSide: const BorderSide(color: Color(0xffD8E4F2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
        borderSide: const BorderSide(color: Color(0xff0A73FF), width: 1.2),
      ),
      hintStyle: TextStyle(
        color: Colors.grey.shade500,
        fontSize: isTablet
            ? 14
            : isSmall
                ? 12
                : 13,
        fontWeight: FontWeight.w500,
      ),
      labelStyle: const TextStyle(
        color: Color(0xff4C5A6A),
        fontWeight: FontWeight.w600,
      ),
    );

    Widget sectionLabel(String text, IconData icon) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xff245AA8)),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: const Color(0xff425466),
                fontWeight: FontWeight.w700,
                fontSize: isTablet
                    ? 13.5
                    : isSmall
                        ? 11.5
                        : 12.5,
              ),
            ),
          ],
        ),
      );
    }

    Widget actionTile({
      required VoidCallback onTap,
      required IconData icon,
      required String text,
      required List<Color> colors,
      Color textColor = Colors.white,
      Color? borderColor,
    }) {
      final bool outlined = borderColor != null;

      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: isTablet ? 54 : 50,
          decoration: BoxDecoration(
            gradient: outlined
                ? null
                : LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: outlined ? Colors.white : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor ?? Colors.transparent,
            ),
            boxShadow: outlined
                ? []
                : [
                    BoxShadow(
                      color: colors.last.withOpacity(0.20),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 18),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: isTablet ? 14 : 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(bottom: isSmall ? 14 : 18),
      padding: EdgeInsets.all(
        isTablet
            ? 20
            : isSmall
                ? 12
                : 16,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffFFFFFF), Color(0xffF6FAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isTablet ? 28 : 24),
        border: Border.all(color: const Color(0xffDDE7F2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff0A73FF).withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Container(
          //   width: double.infinity,
          //   padding: EdgeInsets.symmetric(
          //     horizontal: isTablet ? 16 : 14,
          //     vertical: isTablet ? 16 : 14,
          //   ),
          //   decoration: BoxDecoration(
          //     gradient: const LinearGradient(
          //       colors: [Color(0xff2EA8FF), Color(0xff0A73FF)],
          //       begin: Alignment.topLeft,
          //       end: Alignment.bottomRight,
          //     ),
          //     borderRadius: BorderRadius.circular(20),
          //   ),
          //   child: Row(
          //     children: [
          //       Container(
          //         height: isTablet ? 46 : 40,
          //         width: isTablet ? 46 : 40,
          //         decoration: BoxDecoration(
          //           color: Colors.white.withOpacity(0.18),
          //           borderRadius: BorderRadius.circular(14),
          //         ),
          //         child: const Icon(
          //           Icons.tune_rounded,
          //           color: Colors.white,
          //           size: 22,
          //         ),
          //       ),
          //       const SizedBox(width: 12),
          //       Expanded(
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             Text(
          //               "Filters",
          //               style: TextStyle(
          //                 color: Colors.white,
          //                 fontSize: isTablet
          //                     ? 20
          //                     : isSmall
          //                         ? 16
          //                         : 18,
          //                 fontWeight: FontWeight.w800,
          //               ),
          //             ),
          //             const SizedBox(height: 2),
          //             Text(
          //               "Refine team report with search and quick filters",
          //               style: TextStyle(
          //                 color: Colors.white.withOpacity(0.88),
          //                 fontSize: isTablet
          //                     ? 13
          //                     : isSmall
          //                         ? 11
          //                         : 12,
          //                 fontWeight: FontWeight.w500,
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // SizedBox(height: isSmall ? 12 : 16),

          if (startDateController.text.isNotEmpty &&
              endDateController.text.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 14 : 12,
                vertical: isTablet ? 12 : 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xffEEF5FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xffD8E8FF)),
              ),
              child: Row(
                children: [
                  Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.date_range,
                      color: Color(0xff245AA8),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "${startDateController.text} to ${endDateController.text}",
                      style: TextStyle(
                        color: const Color(0xff245AA8),
                        fontWeight: FontWeight.w700,
                        fontSize: isTablet
                            ? 13.5
                            : isSmall
                                ? 11.5
                                : 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // sectionLabel("Search", Icons.search_rounded),
          TextField(
            controller: searchController,
            decoration: commonInputDecoration.copyWith(
              hintText: "Search team, member, district...",
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),

          SizedBox(height: isSmall ? 12 : 14),

          if (isSmall) ...[
            // sectionLabel("Team", Icons.groups_2_outlined),
            DropdownButtonFormField<String>(
              value: selectedTeam.isEmpty ? null : selectedTeam,
              isExpanded: true,
              decoration: commonInputDecoration.copyWith(
                hintText: "Select team",
                hintStyle: TextStyle(fontSize: 14),
              ),
              items: teamOptions.map((item) {
                return DropdownMenuItem<String>(
                  value: item['id'].toString(),
                  child: Text(
                    item['name'].toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedTeam = value ?? '';
                });
              },
            ),
            const SizedBox(height: 12),
            // sectionLabel("Created By", Icons.person_outline_rounded),
            DropdownSearch<Map<String, dynamic>>(
              items: createdByOptions,
              itemAsString: (item) => item['name']?.toString() ?? '',
              selectedItem: selectedCreatedBy.isEmpty
                  ? null
                  : createdByOptions.cast<Map<String, dynamic>?>().firstWhere(
                        (item) => item?['id'].toString() == selectedCreatedBy,
                        orElse: () => null,
                      ),
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: "Search Staff",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                emptyBuilder: (context, searchEntry) => const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text("No staff found"),
                ),
              ),
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: commonInputDecoration.copyWith(
                  hintText: "created by",
                  hintStyle:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  selectedCreatedBy = value?['id']?.toString() ?? '';
                });
              },
              clearButtonProps: const ClearButtonProps(isVisible: true),
              dropdownButtonProps: const DropdownButtonProps(),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // sectionLabel("Team", Icons.groups_2_outlined),
                      DropdownButtonFormField<String>(
                        value: selectedTeam.isEmpty ? null : selectedTeam,
                        isExpanded: true,
                        decoration: commonInputDecoration.copyWith(
                          hintText: "Select team",
                          hintStyle: TextStyle(fontSize: 14),
                        ),
                        items: teamOptions.map((item) {
                          return DropdownMenuItem<String>(
                            value: item['id'].toString(),
                            child: Text(
                              item['name'].toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedTeam = value ?? '';
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // sectionLabel("Created By", Icons.person_outline_rounded),
                      DropdownSearch<Map<String, dynamic>>(
                        items: createdByOptions,
                        itemAsString: (item) => item['name']?.toString() ?? '',
                        selectedItem: selectedCreatedBy.isEmpty
                            ? null
                            : createdByOptions
                                .cast<Map<String, dynamic>?>()
                                .firstWhere(
                                  (item) =>
                                      item?['id'].toString() ==
                                      selectedCreatedBy,
                                  orElse: () => null,
                                ),
                        popupProps: PopupProps.menu(
                          showSearchBox: true,
                          searchFieldProps: TextFieldProps(
                            decoration: InputDecoration(
                              hintText: "Search Staff",
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          emptyBuilder: (context, searchEntry) => const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text("No staff found"),
                          ),
                        ),
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration:
                              commonInputDecoration.copyWith(
                            hintText: "Created by",
                            hintStyle: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            selectedCreatedBy = value?['id']?.toString() ?? '';
                          });
                        },
                        clearButtonProps:
                            const ClearButtonProps(isVisible: true),
                        dropdownButtonProps: const DropdownButtonProps(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: isSmall ? 12 : 14),

          if (isSmall) ...[
            // sectionLabel("Status", Icons.verified_outlined),
            DropdownButtonFormField<String>(
              value: selectedStatus.isEmpty ? null : selectedStatus,
              isExpanded: true,
              decoration: commonInputDecoration.copyWith(
                  hintText: "Select status",
                  hintStyle: TextStyle(fontSize: 14)),
              items: const [
                DropdownMenuItem(
                  value: "dsr created",
                  child: Text("DSR Created",
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: "dsr approved",
                  child: Text("DSR Approved",
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: "dsr confirmed",
                  child: Text("DSR Confirmed",
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: "dsr rejected",
                  child: Text("DSR Rejected",
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedStatus = value ?? '';
                });
              },
            ),
            const SizedBox(height: 12),
            // sectionLabel("State", Icons.map_outlined),
            DropdownSearch<Map<String, dynamic>>(
              items: statess,
              itemAsString: (item) => item['name']?.toString() ?? '',
              selectedItem: selectedState.isEmpty
                  ? null
                  : statess.cast<Map<String, dynamic>?>().firstWhere(
                        (item) => item?['id'].toString() == selectedState,
                        orElse: () => null,
                      ),
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: "Search State",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                emptyBuilder: (context, searchEntry) => const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text("No state found"),
                ),
              ),
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: commonInputDecoration.copyWith(
                  hintText: "Select state",
                  hintStyle:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  selectedState = value?['id']?.toString() ?? '';
                });
              },
              clearButtonProps: const ClearButtonProps(isVisible: true),
              dropdownButtonProps: const DropdownButtonProps(),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // sectionLabel("Status", Icons.verified_outlined),
                      DropdownButtonFormField<String>(
                        value: selectedStatus.isEmpty ? null : selectedStatus,
                        isExpanded: true,
                        decoration: commonInputDecoration.copyWith(
                            hintText: "Select status",
                            hintStyle: TextStyle(fontSize: 14)),
                        items: const [
                          DropdownMenuItem(
                            value: "dsr created",
                            child: Text("DSR Created",
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem(
                            value: "dsr approved",
                            child: Text("DSR Approved",
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem(
                            value: "dsr confirmed",
                            child: Text("DSR Confirmed",
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem(
                            value: "dsr rejected",
                            child: Text("DSR Rejected",
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedStatus = value ?? '';
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // sectionLabel("State", Icons.map_outlined),
                      DropdownSearch<Map<String, dynamic>>(
                        items: statess,
                        itemAsString: (item) => item['name']?.toString() ?? '',
                        selectedItem: selectedState.isEmpty
                            ? null
                            : statess.cast<Map<String, dynamic>?>().firstWhere(
                                  (item) =>
                                      item?['id'].toString() == selectedState,
                                  orElse: () => null,
                                ),
                        popupProps: PopupProps.menu(
                          showSearchBox: true,
                          searchFieldProps: TextFieldProps(
                            decoration: InputDecoration(
                              hintText: "Search State",
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          emptyBuilder: (context, searchEntry) => const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text("No state found"),
                          ),
                        ),
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration:
                              commonInputDecoration.copyWith(
                            hintText: "Select state",
                            hintStyle: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            selectedState = value?['id']?.toString() ?? '';
                          });
                        },
                        clearButtonProps:
                            const ClearButtonProps(isVisible: true),
                        dropdownButtonProps: const DropdownButtonProps(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: isSmall ? 14 : 18),

          if (isSmall) ...[
            SizedBox(
              width: double.infinity,
              child: actionTile(
                onTap: fetchTeamWiseReport,
                icon: Icons.search_rounded,
                text: "Apply Filters",
                colors: const [Color(0xff2EA8FF), Color(0xff0A73FF)],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: actionTile(
                onTap: clearFilters,
                icon: Icons.clear_all_rounded,
                text: "Clear Filters",
                colors: const [Colors.white, Colors.white],
                textColor: const Color(0xff0A73FF),
                borderColor: const Color(0xff0A73FF),
              ),
            ),
            // const SizedBox(height: 10),
            // SizedBox(
            //   width: double.infinity,
            //   child: actionTile(
            //     onTap: () => exportTeamReportExcel(shareFile: false),
            //     icon: Icons.download_rounded,
            //     text: "Download Excel",
            //     colors: const [Color(0xff21A366), Color(0xff198754)],
            //   ),
            // ),
            // const SizedBox(height: 10),
            // SizedBox(
            //   width: double.infinity,
            //   child: actionTile(
            //     onTap: () => exportTeamReportExcel(shareFile: true),
            //     icon: Icons.share_rounded,
            //     text: "Share Excel",
            //     colors: const [Color(0xff8B5CF6), Color(0xff6F42C1)],
            //   ),
            // ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: actionTile(
                    onTap: fetchTeamWiseReport,
                    icon: Icons.search_rounded,
                    text: "Apply Filters",
                    colors: const [Color(0xff2EA8FF), Color(0xff0A73FF)],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: actionTile(
                    onTap: clearFilters,
                    icon: Icons.clear_all_rounded,
                    text: "Clear Filters",
                    colors: const [Colors.white, Colors.white],
                    textColor: const Color(0xff0A73FF),
                    borderColor: const Color(0xff0A73FF),
                  ),
                ),
              ],
            ),
            // const SizedBox(height: 12),
            // Row(
            //   children: [
            //     Expanded(
            //       child: actionTile(
            //         onTap: () => exportTeamReportExcel(shareFile: false),
            //         icon: Icons.download_rounded,
            //         text: "Download Excel",
            //         colors: const [Color(0xff21A366), Color(0xff198754)],
            //       ),
            //     ),
            //     const SizedBox(width: 12),
            //     Expanded(
            //       child: actionTile(
            //         onTap: () => exportTeamReportExcel(shareFile: true),
            //         icon: Icons.share_rounded,
            //         text: "Share Excel",
            //         colors: const [Color(0xff8B5CF6), Color(0xff6F42C1)],
            //       ),
            //     ),
            //   ],
            // ),
          ],
        ],
      ),
    );
  }

// Widget buildReportHero() {
//   final isSmall = _isSmallScreen(context);
//   final isTablet = _isTablet(context);

//   Widget summaryItem({
//     required String title,
//     required String value,
//     required IconData icon,
//     required Color iconBg,
//     required Color iconColor,
//   }) {
//     return Expanded(
//       child: Container(
//         padding: EdgeInsets.symmetric(
//           horizontal: isTablet
//               ? 16
//               : isSmall
//                   ? 10
//                   : 14,
//           vertical: isTablet
//               ? 16
//               : isSmall
//                   ? 12
//                   : 14,
//         ),
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.14),
//           borderRadius: BorderRadius.circular(isTablet ? 20 : 18),
//           border: Border.all(
//             color: Colors.white.withOpacity(0.16),
//           ),
//         ),
//         child: Row(
//           children: [
//             Container(
//               height: isTablet
//                   ? 48
//                   : isSmall
//                       ? 38
//                       : 42,
//               width: isTablet
//                   ? 48
//                   : isSmall
//                       ? 38
//                       : 42,
//               decoration: BoxDecoration(
//                 color: iconBg,
//                 borderRadius: BorderRadius.circular(isTablet ? 15 : 13),
//               ),
//               child: Icon(
//                 icon,
//                 color: iconColor,
//                 size: isTablet
//                     ? 22
//                     : isSmall
//                         ? 18
//                         : 20,
//               ),
//             ),
//             SizedBox(width: isSmall ? 8 : 10),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       color: Colors.white.withOpacity(0.88),
//                       fontWeight: FontWeight.w600,
//                       fontSize: isTablet
//                           ? 13
//                           : isSmall
//                               ? 11
//                               : 12,
//                     ),
//                   ),
//                   SizedBox(height: isSmall ? 4 : 6),
//                   Text(
//                     value,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.w800,
//                       fontSize: isTablet
//                           ? 20
//                           : isSmall
//                               ? 15
//                               : 18,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   return Container(
//     margin: EdgeInsets.only(bottom: isSmall ? 14 : 18),
//     padding: EdgeInsets.all(
//       isTablet
//           ? 20
//           : isSmall
//               ? 14
//               : 18,
//     ),
//     decoration: BoxDecoration(
//       gradient: const LinearGradient(
//         colors: [Color(0xff0A73FF), Color(0xff39A0FF)],
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//       ),
//       borderRadius: BorderRadius.circular(isTablet ? 30 : 26),
//       boxShadow: [
//         BoxShadow(
//           color: const Color(0xff0A73FF).withOpacity(0.22),
//           blurRadius: 20,
//           offset: const Offset(0, 10),
//         ),
//       ],
//     ),
//     child: Column(
//       children: [
//         Row(
//           children: [
//             summaryItem(
//               title: 'Teams',
//               value: formatValue(reportData.length),
//               icon: Icons.groups_2_rounded,
//               iconBg: const Color(0xffE8F1FF),
//               iconColor: const Color(0xff0A73FF),
//             ),
//             SizedBox(width: isSmall ? 8 : 10),
//             summaryItem(
//               title: 'Billing',
//               value: formatValue(totals['billing']),
//               icon: Icons.currency_rupee_rounded,
//               iconBg: const Color(0xffEAF7EA),
//               iconColor: const Color(0xff2E7D32),
//             ),
//           ],
//         ),
//         SizedBox(height: isSmall ? 8 : 10),
//         Row(
//           children: [
//             summaryItem(
//               title: 'Conversion',
//               value: formatValue(totals['new_conversion']),
//               icon: Icons.trending_up_rounded,
//               iconBg: const Color(0xffFFF4E2),
//               iconColor: const Color(0xffC47B15),
//             ),
//             SizedBox(width: isSmall ? 8 : 10),
//             summaryItem(
//               title: 'Volume',
//               value: formatValue(totals['volume']),
//               icon: Icons.inventory_2_rounded,
//               iconBg: const Color(0xffF2EFFF),
//               iconColor: const Color(0xff6F42C1),
//             ),
//           ],
//         ),
//       ],
//     ),
//   );
// }

  Widget buildErrorView() {
    final isSmall = _isSmallScreen(context);
    final isTablet = _isTablet(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          isTablet
              ? 26
              : isSmall
                  ? 16
                  : 22,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: isTablet
                  ? 50
                  : isSmall
                      ? 40
                      : 46,
            ),
            SizedBox(height: isSmall ? 10 : 12),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
                fontSize: isTablet
                    ? 14
                    : isSmall
                        ? 12
                        : 13,
              ),
            ),
            SizedBox(height: isSmall ? 12 : 14),
            ElevatedButton(
              onPressed: fetchTeamWiseReport,
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBody() {
    final isSmall = _isSmallScreen(context);
    final isTablet = _isTablet(context);
    final pagePadding = EdgeInsets.all(
      isTablet
          ? 20
          : isSmall
              ? 12
              : 16,
    );

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return buildErrorView();
    }

    if (reportData.isEmpty) {
      return RefreshIndicator(
        onRefresh: fetchTeamWiseReport,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: pagePadding,
          children: [
            // buildReportHero(),
            buildFiltersCard(),
            SizedBox(height: isSmall ? 28 : 40),
            Container(
              padding: EdgeInsets.all(isSmall ? 18 : 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xffDDE7F2)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    color: const Color(0xff0A73FF),
                    size: isTablet ? 52 : 44,
                  ),
                  SizedBox(height: isSmall ? 10 : 12),
                  Text(
                    'No report data found',
                    style: TextStyle(
                      fontSize: isTablet
                          ? 16
                          : isSmall
                              ? 13
                              : 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchTeamWiseReport,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: pagePadding,
        children: [
          // buildReportHero(),
          buildFiltersCard(),
          SizedBox(height: isSmall ? 14 : 18),
          buildTotalsCard(),
          ...List.generate(
            reportData.length,
            (index) => buildTeamCard(reportData[index], index + 1),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = _isSmallScreen(context);
    final isTablet = _isTablet(context);

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () async {
            await _navigateBack();
          },
        ),
        elevation: 0,
        backgroundColor: _pageBg,
        foregroundColor: Colors.black87,
        centerTitle: false,
        titleSpacing: isSmall ? 10 : 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Team Wise Report",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: isTablet
                    ? 24
                    : isSmall
                        ? 18
                        : 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "Sales team summary records",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: isTablet
                    ? 13.5
                    : isSmall
                        ? 11
                        : 13,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: isSmall ? 6 : 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(
                Icons.download_rounded,
                color: Colors.blue,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (value) {
                if (value == 'download') {
                  exportTeamReportExcel(shareFile: false);
                } else if (value == 'share') {
                  exportTeamReportExcel(shareFile: true);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'download',
                  child: Row(
                    children: [
                      Icon(Icons.download_rounded, size: 20),
                      SizedBox(width: 10),
                      Text('Open Excel'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share_rounded, size: 20),
                      SizedBox(width: 10),
                      Text('Share Excel'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: isSmall ? 6 : 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: IconButton(
              onPressed: pickDateRange,
              icon: Icon(
                Icons.date_range_rounded,
                color: Colors.blue,
                size: isTablet
                    ? 24
                    : isSmall
                        ? 20
                        : 22,
              ),
              tooltip: "Select Date Range",
            ),
          ),
          // Container(
          //   margin: const EdgeInsets.only(right: 12),
          //   decoration: BoxDecoration(
          //     gradient: const LinearGradient(
          //       colors: [Color(0xff14AE5C), Color(0xff0B8F4D)],
          //       begin: Alignment.topLeft,
          //       end: Alignment.bottomRight,
          //     ),
          //     borderRadius: BorderRadius.circular(14),
          //     boxShadow: [
          //       BoxShadow(
          //         color: const Color(0xff14AE5C).withOpacity(0.25),
          //         blurRadius: 10,
          //         offset: const Offset(0, 6),
          //       ),
          //     ],
          //   ),
          //   child: IconButton(
          //     onPressed: reportData.isEmpty ? null : exportTeamReportExcel,
          //     icon:
          //         const Icon(Icons.file_download_outlined, color: Colors.white),
          //     tooltip: "Export Colorful Excel",
          //   ),
          // ),
        ],
      ),
      body: buildBody(),
    );
  }
}
