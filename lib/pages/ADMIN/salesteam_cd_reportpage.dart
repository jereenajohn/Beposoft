import 'dart:convert';
import 'dart:io';

import 'package:beposoft/Sales%20Directors/SD_dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:excel/excel.dart' as ex;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalesTeamCdReportPage extends StatefulWidget {
  const SalesTeamCdReportPage({super.key});

  @override
  State<SalesTeamCdReportPage> createState() => _SalesTeamCdReportPageState();
}

class _SalesTeamCdReportPageState extends State<SalesTeamCdReportPage> {
  bool isLoading = true;
  String errorMessage = '';

  List<Map<String, dynamic>> reportData = [];
  Map<String, dynamic> totals = {};
  Map<String, dynamic> filters = {};

  final TextEditingController searchController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();

  String selectedStatus = '';
  String selectedTeam = '';
  String selectedCreatedBy = '';

  List<Map<String, dynamic>> teamOptions = [];
  List<Map<String, dynamic>> createdByOptions = [];

  bool isExporting = false;

  DateTime selectedDate = DateTime.now();
  final double teamColWidth = 110;
  final double staffColWidth = 150;

  Future<String?> getTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? prefs.getString('access');
  }

  String formatNumber(dynamic value) {
    if (value == null) return '0';
    final number = double.tryParse(value.toString()) ?? 0;
    if (number == number.toInt()) return number.toInt().toString();
    return number.toStringAsFixed(2);
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
      searchController.clear();
      startDateController.clear();
      endDateController.clear();
    });
    fetchCdReport();
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
    }
     else if (dep == "CEO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ceo_dashboard()),
      );
    }

     else if (dep == "COO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ceo_dashboard()),
      );
    }

      else if (dep == "ADMIN") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => admin_dashboard()),
      );
    }
     else if (dep == "BDM") {
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

  Future<void> fetchCdReport() async {
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
        'search': searchController.text.trim(),
      };

      queryParams.removeWhere((key, value) => value.isEmpty);

      final uri = Uri.parse('$api/api/sales/team/cd/report/')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("CD REPORT URL    : $uri");
      debugPrint("CD REPORT STATUS : ${response.statusCode}");
      debugPrint("CD REPORT BODY   : ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final data = List<Map<String, dynamic>>.from(decoded['data'] ?? []);
        final totalMap = Map<String, dynamic>.from(decoded['totals'] ?? {});
        final filterMap = Map<String, dynamic>.from(decoded['filters'] ?? {});

        final Set<String> teamSet = {};
        final Set<String> staffSet = {};
        final List<Map<String, dynamic>> teams = [];
        final List<Map<String, dynamic>> staffs = [];

        for (final team in data) {
          final teamId = '${team['team_id'] ?? ''}';
          final teamName = '${team['team_name'] ?? ''}';

          if (teamId.isNotEmpty && !teamSet.contains(teamId)) {
            teamSet.add(teamId);
            teams.add({'id': teamId, 'name': teamName});
          }

          final members =
              List<Map<String, dynamic>>.from(team['members'] ?? []);
          for (final member in members) {
            final staffId = '${member['created_by_id'] ?? ''}';
            final staffName = '${member['created_by_name'] ?? ''}';

            if (staffId.isNotEmpty && !staffSet.contains(staffId)) {
              staffSet.add(staffId);
              staffs.add({'id': staffId, 'name': staffName});
            }
          }
        }

        setState(() {
          reportData = data;
          totals = totalMap;
          filters = filterMap;
          teamOptions = teams;
          createdByOptions = staffs;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed: ${response.statusCode}\n${response.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> exportCdReportExcel() async {
    try {
      if (reportData.isEmpty) {
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

      final excel = ex.Excel.createExcel();
      final defaultSheet = excel.getDefaultSheet();
      if (defaultSheet != null) excel.delete(defaultSheet);

      final sheet = excel["Daily Sales Report"];

      sheet.setColWidth(0, 16);
      sheet.setColWidth(1, 22);
      sheet.setColWidth(2, 8);
      sheet.setColWidth(3, 8);
      sheet.setColWidth(4, 10);
      sheet.setColWidth(5, 12);
      sheet.setColWidth(6, 16);
      sheet.setColWidth(7, 12);
      sheet.setColWidth(8, 14);

      final border = ex.Border(borderStyle: ex.BorderStyle.Thin);

      final normalStyle = ex.CellStyle(
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        fontSize: 11,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: border,
        rightBorder: border,
        topBorder: border,
        bottomBorder: border,
      );

      final leftStyle = ex.CellStyle(
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        fontSize: 11,
        horizontalAlign: ex.HorizontalAlign.Left,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: border,
        rightBorder: border,
        topBorder: border,
        bottomBorder: border,
      );

      final headerStyle = ex.CellStyle(
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        fontSize: 12,
        bold: true,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: border,
        rightBorder: border,
        topBorder: border,
        bottomBorder: border,
      );

      final teamStyle = ex.CellStyle(
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        fontSize: 11,
        bold: true,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: border,
        rightBorder: border,
        topBorder: border,
        bottomBorder: border,
      );

      final yellowTotalStyle = ex.CellStyle(
        backgroundColorHex: "#FFFF00",
        fontColorHex: "#FF0000",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        fontSize: 11,
        bold: true,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: border,
        rightBorder: border,
        topBorder: border,
        bottomBorder: border,
      );

      final grandTotalStyle = ex.CellStyle(
        backgroundColorHex: "#F8CBAD",
        fontColorHex: "#000000",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        fontSize: 11,
        bold: true,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: border,
        rightBorder: border,
        topBorder: border,
        bottomBorder: border,
      );

      void setCell(int col, int row, String value, ex.CellStyle style) {
        final cell = sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
        );
        cell.value = value;
        cell.cellStyle = style;
      }

      int row = 0;

      setCell(
        0,
        row,
        "DAILY SALES REPORT",
        headerStyle,
      );

      sheet.merge(
        ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        ex.CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row),
      );

      row++;

      final bool hasDateRange = startDateController.text.isNotEmpty &&
          endDateController.text.isNotEmpty;
      final reportDate = hasDateRange
          ? "${DateFormat('dd.MM.yyyy').format(DateTime.parse(startDateController.text))} to ${DateFormat('dd.MM.yyyy').format(DateTime.parse(endDateController.text))}"
          : startDateController.text.isNotEmpty
              ? DateFormat('dd.MM.yyyy').format(
                  DateTime.parse(startDateController.text),
                )
              : DateFormat('dd.MM.yyyy').format(selectedDate);

      final reportLabel = hasDateRange ? 'DATE RANGE: $reportDate' : reportDate;

      setCell(0, row, reportLabel, leftStyle);
      for (int c = 1; c <= 8; c++) {
        setCell(c, row, "", normalStyle);
      }

      row++;

      final headers = [
        "",
        "",
        "AC",
        "PC",
        "ACD",
        "AVG CD",
        "NEW LEADS",
        "BILL",
        "VOLUME",
      ];

      for (int c = 0; c < headers.length; c++) {
        setCell(c, row, headers[c], headerStyle);
      }

      row++;

      for (final team in reportData) {
        final teamName = team["team_name"]?.toString().toUpperCase() ?? "";
        final members = List<Map<String, dynamic>>.from(team["members"] ?? []);
        final teamTotal = Map<String, dynamic>.from(team["team_total"] ?? {});

        final teamStartRow = row;

        for (int i = 0; i < members.length; i++) {
          final member = members[i];

          setCell(0, row, teamName, teamStyle);
          setCell(
            1,
            row,
            member["created_by_name"]?.toString().toUpperCase() ?? "",
            leftStyle,
          );
          setCell(2, row, formatNumber(member["AC"]), normalStyle);
          setCell(3, row, formatNumber(member["PC"]), normalStyle);
          setCell(4, row, formatNumber(member["ACD"]), normalStyle);
          setCell(5, row, formatNumber(member["AVG_CD"]), normalStyle);
          setCell(6, row, formatNumber(member["new_deals"]), normalStyle);
          setCell(7, row, formatNumber(member["bill_count"]), normalStyle);
          setCell(8, row, formatNumber(member["volume"]), normalStyle);

          row++;
        }

        if (members.length > 1) {
          sheet.merge(
            ex.CellIndex.indexByColumnRow(
              columnIndex: 0,
              rowIndex: teamStartRow,
            ),
            ex.CellIndex.indexByColumnRow(
              columnIndex: 0,
              rowIndex: row - 1,
            ),
          );
        }

        setCell(0, row, "TOTAL", yellowTotalStyle);
        setCell(1, row, "", yellowTotalStyle);
        sheet.merge(
          ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
          ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
        );

        setCell(2, row, formatNumber(teamTotal["AC"]), yellowTotalStyle);
        setCell(3, row, formatNumber(teamTotal["PC"]), yellowTotalStyle);
        setCell(4, row, formatNumber(teamTotal["ACD"]), yellowTotalStyle);
        setCell(5, row, formatNumber(teamTotal["AVG_CD"]), yellowTotalStyle);
        setCell(6, row, formatNumber(teamTotal["new_deals"]), yellowTotalStyle);
        setCell(
            7, row, formatNumber(teamTotal["bill_count"]), yellowTotalStyle);
        setCell(8, row, formatNumber(teamTotal["volume"]), yellowTotalStyle);

        row++;
      }

      row++;

      setCell(0, row, "TOTAL", grandTotalStyle);
      setCell(1, row, "", grandTotalStyle);
      sheet.merge(
        ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
      );

      setCell(2, row, formatNumber(totals["AC"]), grandTotalStyle);
      setCell(3, row, formatNumber(totals["PC"]), grandTotalStyle);
      setCell(4, row, formatNumber(totals["ACD"]), grandTotalStyle);
      setCell(5, row, formatNumber(totals["AVG_CD"]), grandTotalStyle);
      setCell(6, row, formatNumber(totals["new_deals"]), grandTotalStyle);
      setCell(7, row, formatNumber(totals["bill_count"]), grandTotalStyle);
      setCell(8, row, formatNumber(totals["volume"]), grandTotalStyle);

      final fileBytes = excel.encode();
      final tempDir = await getTemporaryDirectory();

      final filePath =
          "${tempDir.path}/Sales_Team_CD_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx";

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
        text: "Sales Team CD Report",
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

  @override
  void initState() {
    super.initState();

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    startDateController.text = today;
    endDateController.text = today;

    fetchCdReport();
  }

  @override
  void dispose() {
    searchController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    super.dispose();
  }

  Widget buildFilters() {
    InputDecoration compactDecoration({
      required String label,
      IconData? icon,
    }) {
      return InputDecoration(
        isDense: true,
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11),
        prefixIcon: icon == null ? null : Icon(icon, size: 15),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 30,
          minHeight: 30,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue, width: 1),
        ),
      );
    }

    Widget fieldBox({required Widget child}) {
      return SizedBox(
        height: 38,
        child: child,
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          fieldBox(
            child: TextField(
              controller: searchController,
              style: const TextStyle(fontSize: 12),
              decoration: compactDecoration(
                label: 'Search',
                icon: Icons.search,
              ),
              onSubmitted: (_) => fetchCdReport(),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: fieldBox(
                  child: TextField(
                    controller: startDateController,
                    readOnly: true,
                    style: const TextStyle(fontSize: 12),
                    onTap: pickStartDate,
                    decoration: compactDecoration(
                      label: 'Start Date',
                      icon: Icons.calendar_today,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: fieldBox(
                  child: TextField(
                    controller: endDateController,
                    readOnly: true,
                    style: const TextStyle(fontSize: 12),
                    onTap: pickEndDate,
                    decoration: compactDecoration(
                      label: 'End Date',
                      icon: Icons.calendar_today,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: fieldBox(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedTeam.isEmpty ? null : selectedTeam,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                    decoration: compactDecoration(label: 'Team'),
                    items: teamOptions.map((team) {
                      return DropdownMenuItem<String>(
                        value: team['id'].toString(),
                        child: Text(
                          team['name'].toString(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedTeam = value ?? '';
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                flex: 3,
                child: fieldBox(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedCreatedBy.isEmpty ? null : selectedCreatedBy,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                    decoration: compactDecoration(label: 'Staff'),
                    items: createdByOptions.map((staff) {
                      return DropdownMenuItem<String>(
                        value: staff['id'].toString(),
                        child: Text(
                          staff['name'].toString(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCreatedBy = value ?? '';
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 5),
              SizedBox(
                width: 38,
                height: 38,
                child: ElevatedButton(
                  onPressed: fetchCdReport,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Icon(Icons.filter_alt, size: 16),
                ),
              ),
              const SizedBox(width: 5),
              SizedBox(
                width: 38,
                height: 38,
                child: OutlinedButton(
                  onPressed: clearFilters,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Icon(Icons.clear, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget tableCell(
    String text, {
    double width = 90,
    bool bold = false,
    Color bgColor = Colors.white,
    Color textColor = Colors.black,
    TextAlign align = TextAlign.center,
  }) {
    return Container(
      width: width,
      height: 30,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: Colors.black, width: 0.6),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: align,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Widget buildHeaderRow() {
    return Row(
      children: [
        tableCell('', width: teamColWidth),
        tableCell('', width: staffColWidth),
        tableCell('AC', width: 55),
        tableCell('PC', width: 55),
        tableCell('ACD', width: 85),
        tableCell('AVG CD', width: 95),
        tableCell('NEW LEADS', width: 120),
        tableCell('BILL', width: 95),
        tableCell('VOLUME', width: 110),
      ],
    );
  }

  Widget buildMemberRow({
    required String teamName,
    required String memberName,
    required Map<String, dynamic> member,
    required bool showTeamName,
  }) {
    return Row(
      children: [
        tableCell(showTeamName ? teamName : '',
            width: teamColWidth, bold: true),
        tableCell(memberName.toUpperCase(),
            width: staffColWidth, align: TextAlign.left),
        tableCell(formatNumber(member['AC']), width: 55),
        tableCell(formatNumber(member['PC']), width: 55),
        tableCell(formatNumber(member['ACD']), width: 85),
        tableCell(formatNumber(member['AVG_CD']), width: 95),
        tableCell(formatNumber(member['new_deals']), width: 120),
        tableCell(formatNumber(member['bill_count']), width: 95),
        tableCell(formatNumber(member['volume']), width: 110),
      ],
    );
  }

  Widget buildTotalRow(Map<String, dynamic> total, {bool grandTotal = false}) {
    final bgColor =
        grandTotal ? const Color(0xffF8CBAD) : const Color(0xffFFFF00);

    return Row(
      children: [
        tableCell('TOTAL', width: 260, bold: true, bgColor: bgColor),
        tableCell(formatNumber(total['AC']),
            width: 55,
            bold: true,
            bgColor: bgColor,
            textColor: grandTotal ? Colors.black : Colors.red),
        tableCell(formatNumber(total['PC']),
            width: 55,
            bold: true,
            bgColor: bgColor,
            textColor: grandTotal ? Colors.black : Colors.red),
        tableCell(formatNumber(total['ACD']),
            width: 85,
            bold: true,
            bgColor: bgColor,
            textColor: grandTotal ? Colors.black : Colors.red),
        tableCell(formatNumber(total['AVG_CD']),
            width: 95,
            bold: true,
            bgColor: bgColor,
            textColor: grandTotal ? Colors.black : Colors.red),
        tableCell(formatNumber(total['new_deals']),
            width: 120,
            bold: true,
            bgColor: bgColor,
            textColor: grandTotal ? Colors.black : Colors.red),
        tableCell(formatNumber(total['bill_count']),
            width: 95,
            bold: true,
            bgColor: bgColor,
            textColor: grandTotal ? Colors.black : Colors.red),
        tableCell(formatNumber(total['volume']),
            width: 110,
            bold: true,
            bgColor: bgColor,
            textColor: grandTotal ? Colors.black : Colors.red),
      ],
    );
  }

  Widget buildReportTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row(
          //   children: [
          //     tableCell(
          //       startDateController.text.isNotEmpty
          //           ? DateFormat('dd.MM.yyyy')
          //               .format(DateTime.parse(startDateController.text))
          //           : DateFormat('dd.MM.yyyy').format(selectedDate),
          //       width: teamColWidth,
          //       bold: true,
          //       align: TextAlign.left,
          //     ),
          //     tableCell(
          //       endDateController.text.isNotEmpty
          //           ? DateFormat('dd.MM.yyyy')
          //               .format(DateTime.parse(endDateController.text))
          //           : '',
          //       width: staffColWidth,
          //       bold: true,
          //       align: TextAlign.left,
          //     ),
          //     tableCell('', width: 55),
          //     tableCell('', width: 55),
          //     tableCell('', width: 85),
          //     tableCell('', width: 95),
          //     tableCell('', width: 120),
          //     tableCell('', width: 95),
          //     tableCell('', width: 110),
          //   ],
          // ),
          buildHeaderRow(),
          ...reportData.expand((team) {
            final members =
                List<Map<String, dynamic>>.from(team['members'] ?? []);
            final teamTotal =
                Map<String, dynamic>.from(team['team_total'] ?? {});
            final teamName = (team['team_name'] ?? '').toString();

            return [
              ...members.asMap().entries.map((entry) {
                return buildMemberRow(
                  teamName: teamName,
                  memberName: entry.value['created_by_name']?.toString() ?? '',
                  member: entry.value,
                  showTeamName: entry.key == 0,
                );
              }),
              buildTotalRow(teamTotal),
            ];
          }),
          const SizedBox(height: 28),
          buildTotalRow(totals, grandTotal: true),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F8FC),
      appBar: AppBar(
        title: const Text(
          'Sales Team CD Report',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () async {
            await _navigateBack();
          },
        ),
        actions: [
          IconButton(
            onPressed: isExporting ? null : exportCdReportExcel,
            icon: isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download_outlined),
            tooltip: 'Export Excel',
          ),
          IconButton(
            onPressed: fetchCdReport,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          buildFilters(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                    ? Center(child: Text(errorMessage))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(8),
                        child: buildReportTable(),
                      ),
          ),
        ],
      ),
    );
  }
}
