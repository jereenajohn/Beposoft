import 'dart:convert';
import 'package:beposoft/pages/ADMIN/team_detailed_summary_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beposoft/pages/api.dart';

import 'dart:io';
import 'package:excel/excel.dart' as ex;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FamilyDetailedSummaryPage extends StatefulWidget {
  final int familyId;
  final String familyName;
  final DateTime startDate;
  final DateTime endDate;

  const FamilyDetailedSummaryPage({
    Key? key,
    required this.familyId,
    required this.familyName,
    required this.startDate,
    required this.endDate,
  }) : super(key: key);

  @override
  State<FamilyDetailedSummaryPage> createState() =>
      _FamilyDetailedSummaryPageState();
}

class _FamilyDetailedSummaryPageState extends State<FamilyDetailedSummaryPage> {
  bool isLoading = true;
  bool isTeamLoading = false;

  Map<String, dynamic> familyInfo = {};
  Map<String, dynamic> summary = {};
  List<Map<String, dynamic>> teams = [];

  List<Map<String, dynamic>> allTeamsDropdown = [];
  int? selectedTeamId;
  String selectedTeamName = "";

  DateTimeRange? selectedRange;
  String fromDate = "";
  String toDate = "";

  bool showFullHourlyFamily = false;
  Set<int> expandedTeamHourly = {};

  Map<String, dynamic> familyAttendanceDetails = {
    "present": <Map<String, dynamic>>[],
    "absent": <Map<String, dynamic>>[],
    "half_day": <Map<String, dynamic>>[],
  };

  bool isAttendanceLoading = false;

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  void initState() {
    super.initState();
    selectedRange = DateTimeRange(
      start: DateTime(
        widget.startDate.year,
        widget.startDate.month,
        widget.startDate.day,
      ),
      end: DateTime(
        widget.endDate.year,
        widget.endDate.month,
        widget.endDate.day,
      ),
    );
    fetchTeamsDropdown();
    fetchFamilyDetailedSummary();
    fetchFamilyAttendanceFromSummaryTeam();
  }

  Future<void> pickDateRange() async {
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(now.year + 1),
      initialDateRange: selectedRange,
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
        selectedRange = DateTimeRange(
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

      await fetchFamilyDetailedSummary();
      await fetchFamilyAttendanceFromSummaryTeam();
    }
  }

  Future<void> fetchTeamsDropdown() async {
    final token = await getTokenFromPrefs();
    if (token == null) return;

    setState(() {
      isTeamLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$api/api/sales/teams/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("TEAMS DROPDOWN STATUS: ${response.statusCode}");
      print("TEAMS DROPDOWN BODY: ${response.body}");
      print("CURRENT FAMILY ID: ${widget.familyId}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List data = decoded['data'] ?? [];

        final fetchedTeams = List<Map<String, dynamic>>.from(
          data.map((e) => {
                'id': e['id'],
                'name': (e['name'] ?? '').toString(),
                'team_leader': e['team_leader'],
                'team_leader_name': (e['team_leader_name'] ?? '').toString(),
                'division': e['division'],
                'division_name': (e['division_name'] ?? '').toString(),
                'created_by': e['created_by'],
                'created_by_name': (e['created_by_name'] ?? '').toString(),
              }),
        );

        final filteredTeams = fetchedTeams.where((team) {
          final divisionId = team['division'];
          return divisionId == widget.familyId;
        }).toList();

        print("ALL TEAM COUNT: ${fetchedTeams.length}");
        print("FILTERED TEAM COUNT: ${filteredTeams.length}");

        if (!mounted) return; 
        setState(() {
          allTeamsDropdown = filteredTeams;
          isTeamLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          allTeamsDropdown = [];
          isTeamLoading = false;
        });
      }
    } catch (e) {
      print("TEAMS DROPDOWN ERROR: $e");
      if (!mounted) return;
      setState(() {
        allTeamsDropdown = [];
        isTeamLoading = false;
      });
    }
  }

  Future<void> fetchFamilyDetailedSummary() async {
    final token = await getTokenFromPrefs();
    if (token == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final Map<String, String> queryParams = {};

      if (selectedRange != null) {
        queryParams['start_date'] =
            DateFormat('yyyy-MM-dd').format(selectedRange!.start);
        queryParams['end_date'] =
            DateFormat('yyyy-MM-dd').format(selectedRange!.end);
      } else {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        queryParams['start_date'] = today;
        queryParams['end_date'] = today;
      }

      if (selectedTeamId != null) {
        queryParams['team_id'] = selectedTeamId.toString();
      }

      final response = await http.get(
        Uri.parse(
          '$api/api/family/detailed/summary/${widget.familyId}/',
        ).replace(queryParameters: queryParams),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print(
        "FAMILY DETAILED URL: ${Uri.parse('$api/api/family/detailed/summary/${widget.familyId}/').replace(queryParameters: queryParams)}",
      );
      print("FAMILY DETAILED STATUS: ${response.statusCode}");
      print("FAMILY DETAILED BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final family = Map<String, dynamic>.from(decoded['family'] ?? {});
        final summ = Map<String, dynamic>.from(decoded['summary'] ?? {});
        final List teamList = decoded['teams'] ?? [];

        if (!mounted) return;
        setState(() {
          familyInfo = family;
          summary = summ;
          teams = List<Map<String, dynamic>>.from(
            teamList.map((e) => Map<String, dynamic>.from(e)),
          );
          fromDate = queryParams['start_date'] ?? "";
          toDate = queryParams['end_date'] ?? "";
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          familyInfo = {};
          summary = {};
          teams = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print("FAMILY DETAILED ERROR: $e");
      if (!mounted) return;
      setState(() {
        familyInfo = {};
        summary = {};
        teams = [];
        isLoading = false;
      });
    }
  }

  Future<void> fetchFamilyAttendanceFromSummaryTeam() async {
    final token = await getTokenFromPrefs();
    if (token == null) return;

    setState(() {
      isAttendanceLoading = true;
    });

    try {
      final Map<String, String> queryParams = {};

      if (selectedRange != null) {
        queryParams['start_date'] =
            DateFormat('yyyy-MM-dd').format(selectedRange!.start);
        queryParams['end_date'] =
            DateFormat('yyyy-MM-dd').format(selectedRange!.end);
      } else {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        queryParams['start_date'] = today;
        queryParams['end_date'] = today;
      }

      final uri = Uri.parse('$api/api/family/summary/team/').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("FAMILY ATTENDANCE URL: $uri");
      print("FAMILY ATTENDANCE STATUS: ${response.statusCode}");
      print("FAMILY ATTENDANCE BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List families = decoded['families'] ?? [];

        Map<String, dynamic> matchedAttendance = {
          "present": <Map<String, dynamic>>[],
          "absent": <Map<String, dynamic>>[],
          "half_day": <Map<String, dynamic>>[],
        };

        for (final item in families) {
          final family = Map<String, dynamic>.from(item);
          final int familyId = family['family_id'] ?? 0;

          if (familyId == widget.familyId) {
            final summaryMap =
                Map<String, dynamic>.from(family['summary'] ?? {});
            final attendance = Map<String, dynamic>.from(
              summaryMap['attendance_details'] ?? {},
            );

            matchedAttendance = {
              "present": List<Map<String, dynamic>>.from(
                (attendance['present'] ?? [])
                    .map((e) => Map<String, dynamic>.from(e)),
              ),
              "absent": List<Map<String, dynamic>>.from(
                (attendance['absent'] ?? [])
                    .map((e) => Map<String, dynamic>.from(e)),
              ),
              "half_day": List<Map<String, dynamic>>.from(
                (attendance['half_day'] ?? [])
                    .map((e) => Map<String, dynamic>.from(e)),
              ),
            };
            break;
          }
        }

        if (!mounted) return;
        setState(() {
          familyAttendanceDetails = matchedAttendance;
          isAttendanceLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          familyAttendanceDetails = {
            "present": <Map<String, dynamic>>[],
            "absent": <Map<String, dynamic>>[],
            "half_day": <Map<String, dynamic>>[],
          };
          isAttendanceLoading = false;
        });
      }
    } catch (e) {
      print("FAMILY ATTENDANCE ERROR: $e");
      if (!mounted) return;
      setState(() {
        familyAttendanceDetails = {
          "present": <Map<String, dynamic>>[],
          "absent": <Map<String, dynamic>>[],
          "half_day": <Map<String, dynamic>>[],
        };
        isAttendanceLoading = false;
      });
    }
  }

  Future<void> openTeamSearchBottomSheet() async {
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _TeamSearchBottomSheet(
          teams: allTeamsDropdown,
          selectedTeamId: selectedTeamId,
        );
      },
    );

    if (selected != null) {
      setState(() {
        selectedTeamId = selected['id'] as int?;
        selectedTeamName = (selected['name'] ?? '').toString();
      });
      await fetchFamilyDetailedSummary();
    }
  }

  Future<void> exportFamilyDetailedSummaryExcel(
      {bool shareFile = false}) async {
    try {
      if (summary.isEmpty && teams.isEmpty) {
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

      String formatDisplayDate(String date) {
        if (date.trim().isEmpty) return '';
        final parsedDate = DateTime.parse(date);
        return DateFormat('dd-MM-yyyy').format(parsedDate);
      }

      final displayFromDate = formatDisplayDate(fromDate);
      final displayToDate = formatDisplayDate(toDate);

      final ex.Border thinBorder = ex.Border(borderStyle: ex.BorderStyle.Thin);
      final ex.Border mediumBorder =
          ex.Border(borderStyle: ex.BorderStyle.Medium);

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

      final ex.CellStyle rowStyle1 = ex.CellStyle(
        backgroundColorHex: '#DCEAF7',
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle rowStyle2 = ex.CellStyle(
        backgroundColorHex: '#E7F1FA',
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle rowLeftStyle1 = ex.CellStyle(
        backgroundColorHex: '#DCEAF7',
        horizontalAlign: ex.HorizontalAlign.Left,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle rowLeftStyle2 = ex.CellStyle(
        backgroundColorHex: '#E7F1FA',
        horizontalAlign: ex.HorizontalAlign.Left,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle sectionTitleStyle = ex.CellStyle(
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

      final familyName = (familyInfo['family_name'] ?? widget.familyName)
          .toString()
          .toUpperCase();

      final Map<String, dynamic> hourlyDurations =
          Map<String, dynamic>.from(summary['hourly_durations'] ?? {});

      final List<String> hourlyKeys = hourlyDurations.keys.toList();

      final List<String> headers = [
        'SL NO',
        'TEAM NAME',
        'TOTAL UNBILLED',
        'TOTAL BILLED',
        'NEW CUSTOMERS',
        'NEW CONVERSIONS',
        'BILLING',
        'VOLUME',
        'TOTAL CALL DURATION',
        ...hourlyKeys,
      ];

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
        text:
            'FAMILY DETAILED SUMMARY - $familyName ($displayFromDate to $displayToDate)',
        style: titleStyle,
      );

      const int headerRowIndex = 2;
      for (int col = 0; col < headers.length; col++) {
        setTextCell(headerRowIndex, col, headers[col], headerStyle);
      }

      int currentRow = headerRowIndex + 1;

      for (int i = 0; i < teams.length; i++) {
        final Map<String, dynamic> team = teams[i];
        final Map<String, dynamic> teamSummary =
            Map<String, dynamic>.from(team['summary'] ?? {});

        final bool evenRow = i.isOdd;
        final ex.CellStyle rowCenterStyle = evenRow ? rowStyle2 : rowStyle1;
        final ex.CellStyle rowLeftStyle =
            evenRow ? rowLeftStyle2 : rowLeftStyle1;

        fillStyledRange(
          startRow: currentRow,
          endRow: currentRow,
          startCol: 0,
          endCol: headers.length - 1,
          style: rowCenterStyle,
        );
        setEmptyStyledCell(currentRow, 1, rowLeftStyle);

        setNumCell(currentRow, 0, i + 1, rowCenterStyle);
        setTextCell(currentRow, 1, team['team_name'] ?? '', rowLeftStyle);
        setNumCell(
            currentRow, 2, teamSummary['total_unbilled'] ?? 0, rowCenterStyle);
        setNumCell(
            currentRow, 3, teamSummary['total_bill'] ?? 0, rowCenterStyle);
        setNumCell(
            currentRow, 4, teamSummary['new_customers'] ?? 0, rowCenterStyle);
        setNumCell(
            currentRow, 5, teamSummary['new_conversions'] ?? 0, rowCenterStyle);
        setNumCell(currentRow, 6, teamSummary['billing'] ?? 0, rowCenterStyle);
        setNumCell(currentRow, 7, teamSummary['volume'] ?? 0, rowCenterStyle);
        setNumCell(currentRow, 8, teamSummary['total_call_duration'] ?? 0,
            rowCenterStyle);

        for (int h = 0; h < hourlyKeys.length; h++) {
          final key = hourlyKeys[h];
          final value = (teamSummary['hourly_durations'] ?? {})[key] ?? 0;
          setNumCell(currentRow, 9 + h, value, rowCenterStyle);
        }

        considerLength(0, i + 1);
        considerLength(1, team['team_name'] ?? '');
        considerLength(2, teamSummary['total_unbilled'] ?? 0);
        considerLength(3, teamSummary['total_bill'] ?? 0);
        considerLength(4, teamSummary['new_customers'] ?? 0);
        considerLength(5, teamSummary['new_conversions'] ?? 0);
        considerLength(6, teamSummary['billing'] ?? 0);
        considerLength(7, teamSummary['volume'] ?? 0);
        considerLength(8, teamSummary['total_call_duration'] ?? 0);

        for (int h = 0; h < hourlyKeys.length; h++) {
          final key = hourlyKeys[h];
          final value = (teamSummary['hourly_durations'] ?? {})[key] ?? 0;
          considerLength(9 + h, value);
        }

        currentRow++;
      }

      final int totalRow = currentRow;

      fillStyledRange(
        startRow: totalRow,
        endRow: totalRow,
        startCol: 0,
        endCol: headers.length - 1,
        style: totalStyle,
      );

      setTextCell(totalRow, 1, 'TOTAL', totalStyle);
      setNumCell(totalRow, 2, summary['total_unbilled'] ?? 0, totalStyle);
      setNumCell(totalRow, 3, summary['total_bill'] ?? 0, totalStyle);
      setNumCell(totalRow, 4, summary['new_customers'] ?? 0, totalStyle);
      setNumCell(totalRow, 5, summary['new_conversions'] ?? 0, totalStyle);
      setNumCell(totalRow, 6, summary['billing'] ?? 0, totalStyle);
      setNumCell(totalRow, 7, summary['volume'] ?? 0, totalStyle);
      setNumCell(totalRow, 8, summary['total_call_duration'] ?? 0, totalStyle);

      for (int h = 0; h < hourlyKeys.length; h++) {
        final key = hourlyKeys[h];
        setNumCell(totalRow, 9 + h, hourlyDurations[key] ?? 0, totalStyle);
      }

      final int summaryStartRow = totalRow + 3;

      mergeRowTitle(
        row: summaryStartRow,
        startCol: 0,
        endCol: 3,
        text: 'OVERALL TOTALS SUMMARY',
        style: sectionTitleStyle,
      );

      setTextCell(summaryStartRow + 1, 0, 'METRIC', summaryHeaderStyle);
      setTextCell(summaryStartRow + 1, 1, 'VALUE', summaryHeaderStyle);
      setTextCell(summaryStartRow + 1, 2, 'METRIC', summaryHeaderStyle);
      setTextCell(summaryStartRow + 1, 3, 'VALUE', summaryHeaderStyle);

      final List<List<dynamic>> summaryRows = [
        [
          'Total Unbilled',
          summary['total_unbilled'] ?? 0,
          'Total Billed',
          summary['total_bill'] ?? 0,
        ],
        [
          'New Customers',
          summary['new_customers'] ?? 0,
          'New Conversions',
          summary['new_conversions'] ?? 0,
        ],
        [
          'Billing',
          summary['billing'] ?? 0,
          'Volume',
          summary['volume'] ?? 0,
        ],
        [
          'Total Call Duration',
          summary['total_call_duration'] ?? 0,
          '',
          '',
        ],
      ];

      int overallRowCursor = summaryStartRow + 2;
      for (final row in summaryRows) {
        setTextCell(overallRowCursor, 0, row[0], summaryLabelStyle);
        if ((row[1] ?? '').toString().isNotEmpty) {
          setNumCell(overallRowCursor, 1, row[1], summaryValueStyle);
        } else {
          setTextCell(overallRowCursor, 1, '', summaryValueStyle);
        }

        setTextCell(overallRowCursor, 2, row[2], summaryLabelStyle);
        if ((row[3] ?? '').toString().isNotEmpty) {
          setNumCell(overallRowCursor, 3, row[3], summaryValueStyle);
        } else {
          setTextCell(overallRowCursor, 3, '', summaryValueStyle);
        }
        overallRowCursor++;
      }

      const int hourlyStartCol = 5;

      mergeRowTitle(
        row: summaryStartRow,
        startCol: hourlyStartCol,
        endCol: hourlyStartCol + 1,
        text: 'HOURLY DURATIONS',
        style: sectionTitleStyle,
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
      for (final entry in hourlyDurations.entries) {
        setTextCell(
            hourlySummaryRow, hourlyStartCol, entry.key, summaryLabelStyle);
        setNumCell(
          hourlySummaryRow,
          hourlyStartCol + 1,
          entry.value,
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

        if (col == 1) width = width < 22 ? 22 : width;
        if (col == 8) width = width < 20 ? 20 : width;
        if (col >= 9) width = width < 14 ? 14 : width;

        sheet.setColWidth(col, width);
      }

      final Directory dir = await getApplicationDocumentsDirectory();
      final String timestamp =
          DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String filePath =
          '${dir.path}/family_detailed_summary_${widget.familyId}_$timestamp.xlsx';

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
          text: 'Family Detailed Summary Report',
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
      debugPrint('EXPORT FAMILY EXCEL ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export excel: $e')),
      );
    }
  }

Widget buildAttendanceCard() {
  if (isAttendanceLoading) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  final List<Map<String, dynamic>> presentStaff =
      List<Map<String, dynamic>>.from(
    familyAttendanceDetails['present'] ?? [],
  );

  final List<Map<String, dynamic>> absentStaff =
      List<Map<String, dynamic>>.from(
    familyAttendanceDetails['absent'] ?? [],
  );

  final List<Map<String, dynamic>> halfDayStaff =
      List<Map<String, dynamic>>.from(
    familyAttendanceDetails['half_day'] ?? [],
  );

  if (presentStaff.isEmpty && absentStaff.isEmpty && halfDayStaff.isEmpty) {
    return const SizedBox();
  }

  final int maxRows = [
    presentStaff.length,
    absentStaff.length,
    halfDayStaff.length,
  ].reduce((a, b) => a > b ? a : b);

  final List<TableRow> rows = [];

  rows.add(
    const TableRow(
      decoration: BoxDecoration(color: Color(0xFFF2F2F2)),
      children: [
        Padding(
          padding: EdgeInsets.all(10),
          child: Text(
            "Present Staff",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(10),
          child: Text(
            "Absent Staff",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(10),
          child: Text(
            "Half Day Staff",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );

  rows.add(
    TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            "${presentStaff.length}",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            "${absentStaff.length}",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            "${halfDayStaff.length}",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  for (int i = 0; i < maxRows; i++) {
    final presentName = i < presentStaff.length
        ? (presentStaff[i]['staff_name'] ?? '').toString()
        : '';
    final absentName = i < absentStaff.length
        ? (absentStaff[i]['staff_name'] ?? '').toString()
        : '';
    final halfDayName = i < halfDayStaff.length
        ? (halfDayStaff[i]['staff_name'] ?? '').toString()
        : '';

    rows.add(
      TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              presentName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              absentName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              halfDayName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  return Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            gradient: LinearGradient(
              colors: [Color(0xFF02347C), Color(0xFF82E49D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Text(
            "Staff Attendance",
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Table(
            border: TableBorder.all(
              color: const Color(0xffD9E2F2),
              width: 1,
            ),
            columnWidths: const {
              0: FlexColumnWidth(),
              1: FlexColumnWidth(),
              2: FlexColumnWidth(),
            },
            children: rows,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildFamilyMetricTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xffE6ECF5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF02347C),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamFilterSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xffE6ECF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Team Filter",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF02347C),
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: isTeamLoading ? null : openTeamSearchBottomSheet,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xffF7F9FC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffD9E2F2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.groups_rounded,
                    color: Color(0xFF02347C),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isTeamLoading
                          ? "Loading teams..."
                          : (selectedTeamName.isNotEmpty
                              ? selectedTeamName
                              : "Select Team"),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: selectedTeamName.isNotEmpty
                            ? Colors.black87
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 28,
                    color: Color(0xFF02347C),
                  ),
                ],
              ),
            ),
          ),
          if (selectedTeamId != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Selected Team ID: $selectedTeamId",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    setState(() {
                      selectedTeamId = null;
                      selectedTeamName = "";
                    });
                    await fetchFamilyDetailedSummary();
                  },
                  child: const Text(
                    "Clear",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget buildTopSummaryCard() {
    final familyName = (familyInfo['family_name'] ?? widget.familyName)
        .toString()
        .toUpperCase();

    final totalUnbilled = summary['total_unbilled'] ?? 0;
    final totalBilled =
        double.tryParse(summary['total_bill'].toString()) ?? 0.0;
    final newCustomers = summary['new_customers'] ?? 0;
    final newConversions = summary['new_conversions'] ?? 0;
    final totalInvoices = summary['billing'] ?? 0;
    final totalAmount = double.tryParse(summary['volume'].toString()) ?? 0.0;
    final totalCallDuration =
        double.tryParse(summary['total_call_duration'].toString()) ?? 0.0;
    final callDurationAverage =
        double.tryParse(summary['call_duration_average'].toString()) ?? 0.0;
    final callDurationPercentage =
        double.tryParse(summary['call_duration_percentage_8hrs'].toString()) ??
            0.0;
    final activeCount = summary['active_count'] ?? 0;
    final productiveCount = summary['productive_count'] ?? 0;
    final presentCount = summary['present_count'] ?? 0;
    final absentCount = summary['absent_count'] ?? 0;
    final halfDayCount = summary['half_day_count'] ?? 0;

    final hourlyDurations =
        Map<String, dynamic>.from(summary['hourly_durations'] ?? {});

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              gradient: LinearGradient(
                colors: [Color(0xFF02347C), Color(0xFF82E49D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: familyName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: " ($fromDate to $toDate)",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: pickDateRange,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white24,
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
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "Total Unbilled",
                        "$totalUnbilled",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "Total Billed",
                        "₹${totalBilled.toStringAsFixed(1)}",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "New Customers",
                        "$newCustomers",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "New Conversion",
                        "$newConversions",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "Total Invoices",
                        "$totalInvoices",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "Total Amount",
                        "₹${totalAmount.toStringAsFixed(1)}",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "Total Call Duration",
                        "${totalCallDuration.toStringAsFixed(2)} min",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "Call Duration Avg",
                        "${callDurationAverage.toStringAsFixed(2)} min",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "Call Duration %",
                        "${callDurationPercentage.toStringAsFixed(2)}%",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "Active Count",
                        "$activeCount",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "Productive Count",
                        "$productiveCount",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "Present",
                        "$presentCount",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "Absent",
                        "$absentCount",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFamilyMetricTile(
                        "Half Day",
                        "$halfDayCount",
                      ),
                    ),
                  ],
                ),
                if (hourlyDurations.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xffF7F9FC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xffE6ECF5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Hourly Durations",
                          style: TextStyle(
                            color: Color(0xFF02347C),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...hourlyDurations.entries
                            .take(showFullHourlyFamily
                                ? hourlyDurations.length
                                : 2)
                            .map(
                              (entry) => Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xffE6ECF5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.key,
                                        style: const TextStyle(
                                          color: Color(0xFF02347C),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      "${(double.tryParse(entry.value.toString()) ?? 0).toStringAsFixed(2)} min",
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        if (hourlyDurations.length > 2)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  showFullHourlyFamily = !showFullHourlyFamily;
                                });
                              },
                              child: Center(
                                child: Text(
                                  showFullHourlyFamily
                                      ? "See Less"
                                      : "See More",
                                  style: const TextStyle(
                                    color: Color(0xFF02347C),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
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

  Widget buildTeamCard(Map<String, dynamic> team) {
    final int teamId = team['team_id'] ?? 0;
    final String teamName = (team['team_name'] ?? '').toString().toUpperCase();
    final Map<String, dynamic> teamSummary =
        Map<String, dynamic>.from(team['summary'] ?? {});

    final totalUnbilled = teamSummary['total_unbilled'] ?? 0;
    final totalBilled =
        double.tryParse(teamSummary['total_bill'].toString()) ?? 0.0;
    final newCustomers = teamSummary['new_customers'] ?? 0;
    final newConversions = teamSummary['new_conversions'] ?? 0;
    final totalInvoices = teamSummary['billing'] ?? 0;
    final totalAmount =
        double.tryParse(teamSummary['volume'].toString()) ?? 0.0;
    final totalCallDuration =
        double.tryParse(teamSummary['total_call_duration'].toString()) ?? 0.0;
    final callDurationAverage =
        double.tryParse(teamSummary['call_duration_average'].toString()) ?? 0.0;
    final callDurationPercentage = double.tryParse(
            teamSummary['call_duration_percentage_8hrs'].toString()) ??
        0.0;
    final activeCount = teamSummary['active_count'] ?? 0;
    final productiveCount = teamSummary['productive_count'] ?? 0;

    final hourlyDurations =
        Map<String, dynamic>.from(teamSummary['hourly_durations'] ?? {});

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeamDetailedSummaryPage(
              teamId: teamId,
              teamName: (team['team_name'] ?? '').toString(),
              startDate: selectedRange?.start ?? DateTime.now(),
              endDate: selectedRange?.end ?? DateTime.now(),
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF60A5FA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Text(
                teamName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildFamilyMetricTile(
                          "Total Unbilled",
                          "$totalUnbilled",
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFamilyMetricTile(
                          "Total Billed",
                          "₹${totalBilled.toStringAsFixed(1)}",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFamilyMetricTile(
                          "New Customers",
                          "$newCustomers",
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFamilyMetricTile(
                          "New Conversion",
                          "$newConversions",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFamilyMetricTile(
                          "Total Invoices",
                          "$totalInvoices",
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFamilyMetricTile(
                          "Total Amount",
                          "₹${totalAmount.toStringAsFixed(1)}",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFamilyMetricTile(
                          "Total Call Duration",
                          "${totalCallDuration.toStringAsFixed(2)} min",
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFamilyMetricTile(
                          "Call Duration Avg",
                          "${callDurationAverage.toStringAsFixed(2)} min",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFamilyMetricTile(
                          "Call Duration %",
                          "${callDurationPercentage.toStringAsFixed(2)}%",
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFamilyMetricTile(
                          "Active Count",
                          "$activeCount",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFamilyMetricTile(
                          "Productive Count",
                          "$productiveCount",
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                  if (hourlyDurations.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xffF7F9FC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xffE6ECF5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Hourly Durations",
                            style: TextStyle(
                              color: Color(0xFF02347C),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...hourlyDurations.entries
                              .take(
                                expandedTeamHourly.contains(teamId)
                                    ? hourlyDurations.length
                                    : 2,
                              )
                              .map(
                                (entry) => Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xffE6ECF5),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          entry.key,
                                          style: const TextStyle(
                                            color: Color(0xFF02347C),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        "${(double.tryParse(entry.value.toString()) ?? 0).toStringAsFixed(2)} min",
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          if (hourlyDurations.length > 2)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    if (expandedTeamHourly.contains(teamId)) {
                                      expandedTeamHourly.remove(teamId);
                                    } else {
                                      expandedTeamHourly.add(teamId);
                                    }
                                  });
                                },
                                child: Center(
                                  child: Text(
                                    expandedTeamHourly.contains(teamId)
                                        ? "See Less"
                                        : "See More",
                                    style: const TextStyle(
                                      color: Color(0xFF02347C),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text(
          "Family Detailed Summary",
          style: TextStyle(fontSize: 20),
        ),
        foregroundColor: Colors.black,
        // actions: [
        // PopupMenuButton<String>(
        //   icon: const Icon(Icons.download_rounded),
        //   onSelected: (value) {
        //     if (value == 'download') {
        //       exportFamilyDetailedSummaryExcel(shareFile: false);
        //     } else if (value == 'share') {
        //       exportFamilyDetailedSummaryExcel(shareFile: true);
        //     }
        //   },
        //   itemBuilder: (context) => const [
        //     PopupMenuItem(
        //       value: 'download',
        //       child: Row(
        //         children: [
        //           Icon(Icons.download_rounded, color: Colors.green),
        //           SizedBox(width: 8),
        //           Text('Download Excel'),
        //         ],
        //       ),
        //     ),
        //     PopupMenuItem(
        //       value: 'share',
        //       child: Row(
        //         children: [
        //           Icon(Icons.share_rounded, color: Colors.deepPurple),
        //           SizedBox(width: 8),
        //           Text('Share Excel'),
        //         ],
        //       ),
        //     ),
        //   ],
        // ),
        // ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await fetchFamilyDetailedSummary();
                await fetchFamilyAttendanceFromSummaryTeam();
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildTeamFilterSection(),
                  buildAttendanceCard(),
                  buildTopSummaryCard(),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(14, 8, 14, 4),
                    child: Text(
                      "Team Wise Summary",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  ...(selectedTeamId != null
                      ? teams
                          .where((team) =>
                              (team['team_id'] ?? 0) == selectedTeamId)
                          .map((team) => buildTeamCard(team))
                          .toList()
                      : teams.map((team) => buildTeamCard(team)).toList()),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}

class _TeamSearchBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> teams;
  final int? selectedTeamId;

  const _TeamSearchBottomSheet({
    Key? key,
    required this.teams,
    required this.selectedTeamId,
  }) : super(key: key);

  @override
  State<_TeamSearchBottomSheet> createState() => _TeamSearchBottomSheetState();
}

class _TeamSearchBottomSheetState extends State<_TeamSearchBottomSheet> {
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredTeams = [];

  @override
  void initState() {
    super.initState();
    filteredTeams = List<Map<String, dynamic>>.from(widget.teams);
    searchController.addListener(_filterTeams);
  }

  void _filterTeams() {
    final query = searchController.text.trim().toLowerCase();

    setState(() {
      filteredTeams = widget.teams.where((team) {
        final name = (team['name'] ?? '').toString().toLowerCase();
        final leaderName =
            (team['team_leader_name'] ?? '').toString().toLowerCase();
        final divisionName =
            (team['division_name'] ?? '').toString().toLowerCase();

        return name.contains(query) ||
            leaderName.contains(query) ||
            divisionName.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    searchController.removeListener(_filterTeams);
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xffF5F7FB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "Select Team",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF02347C),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search team",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            searchController.clear();
                          },
                          icon: const Icon(Icons.close),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xffD9E2F2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xffD9E2F2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF02347C),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filteredTeams.isEmpty
                  ? const Center(
                      child: Text(
                        "No team found",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                      itemCount: filteredTeams.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final team = filteredTeams[index];
                        final int teamId = team['id'] ?? 0;
                        final String teamName = (team['name'] ?? '').toString();
                        final String leaderName =
                            (team['team_leader_name'] ?? '').toString();
                        final String divisionName =
                            (team['division_name'] ?? '').toString();

                        final bool isSelected = widget.selectedTeamId == teamId;

                        return InkWell(
                          onTap: () {
                            Navigator.pop(context, team);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF02347C)
                                    : const Color(0xffE6ECF5),
                                width: isSelected ? 1.4 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF02347C)
                                        .withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.groups_rounded,
                                    color: Color(0xFF02347C),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        teamName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Leader: $leaderName",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Division: $divisionName",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Team ID: $teamId",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF02347C),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF02347C),
                                  ),
                              ],
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
}
