import 'dart:convert';
import 'dart:io';

import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:beposoft/pages/api.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart' as ex;

class BDODailySalesReportViewPage extends StatefulWidget {
  const BDODailySalesReportViewPage({super.key});

  @override
  State<BDODailySalesReportViewPage> createState() =>
      _BDODailySalesReportViewPageState();
}

class _BDODailySalesReportViewPageState
    extends State<BDODailySalesReportViewPage> {
  // ================= DROPDOWN LISTS =================
  List<Map<String, dynamic>> states = [];

  // ================= SELECTED FILTERS =================
  int? selectedStateId;
  int? selectedMonth;
  int? selectedYear;
  bool isSearchMode = false;

  // ================= REPORT DATA =================
  bool loading = false;

  List<int> dates = [];
  List<Map<String, dynamic>> districtsReport = [];
  Map<String, dynamic> columnTotals = {};
  int grandTotal = 0;
  bool searched = false;

  bool profileLoading = false;
  List<Map<String, dynamic>> allStatesReport = [];

  // ================= TOKEN =================
  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  @override
  void initState() {
    super.initState();
    getProfileAllocatedStates();
  }

  Future<void> fetchAllAllocatedStatesReport(List allocatedStates) async {
    try {
      setState(() {
        loading = true;
        searched = true;
        allStatesReport = [];
      });

      final token = await gettokenFromPrefs();

      for (var stateId in allocatedStates) {
        final url =
            "$api/api/daily/sales/report/my/?month=${selectedMonth ?? DateTime.now().month}&year=${selectedYear ?? DateTime.now().year}&state_id=$stateId";

        var response = await http.get(
          Uri.parse(url),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        );

        if (response.statusCode == 200) {
          final parsed = jsonDecode(response.body);

          allStatesReport.add({
            "state": parsed["state"],
            "month": parsed["month"],
            "user": parsed["user"],
            "dates": parsed["dates"],
            "districts": parsed["districts"],
            "column_totals": parsed["column_totals"],
            "grand_total": parsed["grand_total"],
            "state_summary": parsed["state_summary"],
          });
        }
      }

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> getProfileAllocatedStates() async {
    try {
      setState(() {
        profileLoading = true;
      });

      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse("$api/api/profile/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List allocatedStates = parsed["data"]["allocated_states"] ?? [];

        selectedMonth = DateTime.now().month;
        selectedYear = DateTime.now().year;

        await fetchAllAllocatedStatesReport(allocatedStates);

        var stateRes = await http.get(
          Uri.parse("$api/api/states/"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        );

        if (stateRes.statusCode == 200) {
          final stateParsed = jsonDecode(stateRes.body);

          List<Map<String, dynamic>> filteredStates = [];

          for (var item in stateParsed["data"]) {
            if (allocatedStates.contains(item["id"])) {
              filteredStates.add({
                "id": item["id"],
                "name": item["name"],
              });
            }
          }

          if (!mounted) return;

          setState(() {
            states = filteredStates;
          });
        }
      }
    } catch (e) {}

    if (!mounted) return;

    setState(() {
      profileLoading = false;
    });
  }

  Future<void> fetchDailySalesReport() async {
    if (selectedStateId == null ||
        selectedMonth == null ||
        selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Please select State, Month and Year"),
        ),
      );
      return;
    }

    setState(() {
      searched = true;
      loading = true;
      dates = [];
      districtsReport = [];
      columnTotals = {};
      grandTotal = 0;
      allStatesReport = [];
    });

    try {
      final token = await gettokenFromPrefs();

      final url =
          "$api/api/daily/sales/report/my/?month=$selectedMonth&year=$selectedYear&state_id=$selectedStateId";

      var response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        if (!mounted) return;

        setState(() {
          isSearchMode = true;

          allStatesReport = [
            {
              "state": parsed["state"],
              "month": parsed["month"],
              "user": parsed["user"],
              "dates": parsed["dates"],
              "districts": parsed["districts"],
              "column_totals": parsed["column_totals"],
              "grand_total": parsed["grand_total"],
              "state_summary": parsed["state_summary"],
            }
          ];
        });
      }
    } catch (e) {}

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  // ================= MONTH LIST =================
  List<Map<String, dynamic>> monthList = [
    {"id": 1, "name": "January"},
    {"id": 2, "name": "February"},
    {"id": 3, "name": "March"},
    {"id": 4, "name": "April"},
    {"id": 5, "name": "May"},
    {"id": 6, "name": "June"},
    {"id": 7, "name": "July"},
    {"id": 8, "name": "August"},
    {"id": 9, "name": "September"},
    {"id": 10, "name": "October"},
    {"id": 11, "name": "November"},
    {"id": 12, "name": "December"},
  ];

  // ================= YEAR LIST =================
  List<int> yearList() {
    int currentYear = DateTime.now().year;
    return List.generate(10, (index) => currentYear - 5 + index);
  }

  // ================= EXPORT EXCEL (FULL) =================
  Future<void> exportAllStatesDailySalesExcel() async {
    try {
      if (allStatesReport.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("No data available to export"),
          ),
        );
        return;
      }

      var excel = ex.Excel.createExcel();
      ex.Sheet sheet = excel["All States Daily Sales"];

      // ================= BORDER STYLE =================
      final ex.Border thinBorder = ex.Border(borderStyle: ex.BorderStyle.Thin);

      // ================= STYLES =================
      final ex.CellStyle headerStyle = ex.CellStyle(
        backgroundColorHex: "#40B0FB",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        fontColorHex: "#FFFFFF",
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle districtStyle = ex.CellStyle(
        backgroundColorHex: "#E8E8E8",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        horizontalAlign: ex.HorizontalAlign.Left,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle yellowStyle = ex.CellStyle(
        backgroundColorHex: "#FFFF00",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle redStyle = ex.CellStyle(
        backgroundColorHex: "#FF0000",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        fontColorHex: "#FFFFFF",
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle totalColStyle = ex.CellStyle(
        backgroundColorHex: "#00FF00",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle bottomTotalStyle = ex.CellStyle(
        backgroundColorHex: "#FFA500",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      // ================= SUMMARY TABLE STYLE =================
      final ex.CellStyle summaryHeaderStyle = ex.CellStyle(
        backgroundColorHex: "#1F4E79",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        fontColorHex: "#FFFFFF",
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle summaryRowStyle = ex.CellStyle(
        backgroundColorHex: "#FFFFFF",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle summaryStateStyle = ex.CellStyle(
        backgroundColorHex: "#D9E1F2",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        horizontalAlign: ex.HorizontalAlign.Left,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle titleStyle = ex.CellStyle(
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        fontSize: 16,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
      );

      int rowIndex = 0;

      // ================= LOOP EACH STATE FULL REPORT =================
      for (int s = 0; s < allStatesReport.length; s++) {
        String state = allStatesReport[s]["state"].toString();
        String month = allStatesReport[s]["month"].toString();

        List<int> dates = List<int>.from(allStatesReport[s]["dates"]);
        List districts = List.from(allStatesReport[s]["districts"]);

        Map<String, dynamic> columnTotals =
            Map<String, dynamic>.from(allStatesReport[s]["column_totals"]);

        int grandTotal = allStatesReport[s]["grand_total"] ?? 0;

        // ================= TITLE =================
        sheet.merge(
          ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
          ex.CellIndex.indexByColumnRow(
            columnIndex: dates.length + 2,
            rowIndex: rowIndex,
          ),
        );

        final titleCell = sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        );

        titleCell.value =
            "DAILY SALES REPORT - $state ($month)  (Total: $grandTotal)";
        titleCell.cellStyle = titleStyle;

        rowIndex += 2;

        // ================= HEADER =================
        final slHeader = sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        );
        slHeader.value = "Sl No";
        slHeader.cellStyle = headerStyle;

        final districtHeader = sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
        );
        districtHeader.value = "District";
        districtHeader.cellStyle = headerStyle;

        int colIndex = 2;
        for (var d in dates) {
          final cell = sheet.cell(
            ex.CellIndex.indexByColumnRow(
              columnIndex: colIndex,
              rowIndex: rowIndex,
            ),
          );
          cell.value = d.toString();
          cell.cellStyle = headerStyle;
          colIndex++;
        }

        final totalHeader = sheet.cell(
          ex.CellIndex.indexByColumnRow(
              columnIndex: colIndex, rowIndex: rowIndex),
        );
        totalHeader.value = "TOTAL";
        totalHeader.cellStyle = headerStyle;

        rowIndex++;

        // ================= DATA ROWS =================
        for (int i = 0; i < districts.length; i++) {
          final district = districts[i];
          final dailyCounts =
              Map<String, dynamic>.from(district["daily_counts"]);

          final slCell = sheet.cell(
            ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
          );
          slCell.value = (i + 1);
          slCell.cellStyle = districtStyle;

          final districtCell = sheet.cell(
            ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
          );
          districtCell.value = district["district"].toString();
          districtCell.cellStyle = districtStyle;

          int dayCol = 2;
          for (final day in dates) {
            final val =
                int.tryParse((dailyCounts[day.toString()] ?? 0).toString()) ??
                    0;

            final cell = sheet.cell(
              ex.CellIndex.indexByColumnRow(
                columnIndex: dayCol,
                rowIndex: rowIndex,
              ),
            );

            cell.value = val;
            cell.cellStyle = val == 0 ? redStyle : yellowStyle;

            dayCol++;
          }

          final totalVal =
              int.tryParse((district["total"] ?? 0).toString()) ?? 0;

          final totalCell = sheet.cell(
            ex.CellIndex.indexByColumnRow(
                columnIndex: dayCol, rowIndex: rowIndex),
          );

          totalCell.value = totalVal;
          totalCell.cellStyle = totalColStyle;

          rowIndex++;
        }

        // ================= BOTTOM TOTAL =================
        final emptyCell = sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        );
        emptyCell.value = "";
        emptyCell.cellStyle = bottomTotalStyle;

        final totalTextCell = sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
        );
        totalTextCell.value = "TOTAL";
        totalTextCell.cellStyle = bottomTotalStyle;

        int totalDayCol = 2;
        for (final day in dates) {
          final totalVal =
              int.tryParse((columnTotals[day.toString()] ?? 0).toString()) ?? 0;

          final cell = sheet.cell(
            ex.CellIndex.indexByColumnRow(
              columnIndex: totalDayCol,
              rowIndex: rowIndex,
            ),
          );

          cell.value = totalVal;
          cell.cellStyle = bottomTotalStyle;

          totalDayCol++;
        }

        final grandCell = sheet.cell(
          ex.CellIndex.indexByColumnRow(
            columnIndex: totalDayCol,
            rowIndex: rowIndex,
          ),
        );

        grandCell.value = grandTotal;
        grandCell.cellStyle = bottomTotalStyle;

        rowIndex += 4;
      }

      // ================= FINAL COMBINED SUMMARY TABLE =================
      rowIndex += 2;

      sheet.merge(
        ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        ex.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
      );

      final combinedTitle = sheet.cell(
        ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
      );

      combinedTitle.value = "ALL STATES SUMMARY";
      combinedTitle.cellStyle = titleStyle;

      rowIndex += 2;

      // ================= SUMMARY HEADER =================
      List<String> summaryHeaders = [
        "Sl",
        "State",
        "Total Invoices",
        "Average",
        "Grand Total"
      ];

      for (int i = 0; i < summaryHeaders.length; i++) {
        final cell = sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex),
        );
        cell.value = summaryHeaders[i];
        cell.cellStyle = summaryHeaderStyle;
      }

      rowIndex++;

      // ================= SUMMARY ROWS =================
      int combinedGrandTotal = 0;

      for (int s = 0; s < allStatesReport.length; s++) {
        String state = allStatesReport[s]["state"].toString();
        int grandTotal = allStatesReport[s]["grand_total"] ?? 0;

        Map<String, dynamic> summary = Map<String, dynamic>.from(
            allStatesReport[s]["state_summary"] ?? {});

        int totalInvoices = summary["total_invoices"] ?? 0;

        double avgPerDay =
            double.tryParse((summary["average_per_day"] ?? 0).toString()) ??
                0.0;

        combinedGrandTotal += grandTotal;

        // Sl
        final slCell = sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        );
        slCell.value = (s + 1);
        slCell.cellStyle = summaryRowStyle;

        // State
        final stateCell = sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
        );
        stateCell.value = state;
        stateCell.cellStyle = summaryStateStyle;

        // Total Invoices
        final invCell = sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
        );
        invCell.value = totalInvoices;
        invCell.cellStyle = summaryRowStyle;

        // Avg/Day
        final avgCell = sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
        );
        avgCell.value = avgPerDay.toStringAsFixed(2);
        avgCell.cellStyle = summaryRowStyle;

        // Grand Total
        final totalCell = sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
        );
        totalCell.value = grandTotal;
        totalCell.cellStyle = totalColStyle;

        rowIndex++;
      }

      // ================= FINAL TOTAL ROW =================
      sheet.merge(
        ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        ex.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
      );

      final totalLabelCell = sheet.cell(
        ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
      );
      totalLabelCell.value = "ALL STATES GRAND TOTAL";
      totalLabelCell.cellStyle = bottomTotalStyle;

      final totalValueCell = sheet.cell(
        ex.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
      );
      totalValueCell.value = combinedGrandTotal;
      totalValueCell.cellStyle = bottomTotalStyle;

      // ================= SAVE & SHARE =================
      final fileBytes = excel.encode();
      final tempDir = await getTemporaryDirectory();

      String exportName = "AllStates";

      final filePath =
          '${tempDir.path}/DailySalesReport_${exportName}_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      final file = File(filePath);
      await file.writeAsBytes(fileBytes!);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: "📊 Daily Sales Report - $exportName",
      );
    } catch (e) {
      print("========== EXPORT ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Excel Export Failed: $e"),
        ),
      );
    }
  }

  Future<void> exportSelectedStateExcel() async {
    if (allStatesReport.isEmpty) return;

    List<Map<String, dynamic>> backup = List.from(allStatesReport);

    allStatesReport = [backup[0]];

    await exportAllStatesDailySalesExcel();

    allStatesReport = backup;
  }

  drower d = drower();

  Widget _buildDropdownTile(
      BuildContext context, String title, List<String> options) {
    return ExpansionTile(
      title: Text(title),
      children: options.map((option) {
        return ListTile(
          title: Text(option),
          onTap: () {
            Navigator.pop(context);
            d.navigateToSelectedPage2(context, option);
          },
        );
      }).toList(),
    );
  }

  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();

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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _navigateBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(242, 255, 255, 255),
        appBar: AppBar(
          title: const Text(
            "Daily Sales Report",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _navigateBack();
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 15),

              // ================= HEADER =================
              Padding(
                padding: const EdgeInsets.only(right: 10, top: 10, left: 10),
                child: Container(
                  width: 600,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 34, 165, 246),
                    border: Border.all(
                        color: const Color.fromARGB(255, 202, 202, 202)),
                  ),
                  child: const Column(
                    children: [
                      SizedBox(height: 10),
                      Text(
                        " DAILY SALES REPORT ",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      SizedBox(height: 13),
                    ],
                  ),
                ),
              ),

              // ================= FILTER CARD =================
              Padding(
                padding: const EdgeInsets.only(top: 20, left: 15, right: 15),
                child: Container(
                  width: 700,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                        color: const Color.fromARGB(255, 202, 202, 202)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "State",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<int>(
                          value: selectedStateId,
                          decoration: InputDecoration(
                            labelText: "Select State",
                            labelStyle: const TextStyle(fontSize: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: states.map((item) {
                            return DropdownMenuItem<int>(
                              value: item["id"],
                              child: Text(item["name"]),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedStateId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Month",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<int>(
                          value: selectedMonth,
                          decoration: InputDecoration(
                            labelText: "Select Month",
                            labelStyle: const TextStyle(fontSize: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: monthList.map((item) {
                            return DropdownMenuItem<int>(
                              value: item["id"],
                              child: Text(item["name"]),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedMonth = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Year",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<int>(
                          value: selectedYear,
                          decoration: InputDecoration(
                            labelText: "Select Year",
                            labelStyle: const TextStyle(fontSize: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: yearList().map((y) {
                            return DropdownMenuItem<int>(
                              value: y,
                              child: Text(y.toString()),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedYear = value;
                            });
                          },
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 250,
                              child: ElevatedButton(
                                onPressed: () {
                                  fetchDailySalesReport();
                                },
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                    const Color.fromARGB(255, 64, 176, 251),
                                  ),
                                  shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  "Search Report",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        if (isSearchMode) {
                          exportSelectedStateExcel();
                        } else {
                          exportAllStatesDailySalesExcel();
                        }
                      },
                      icon: const Icon(Icons.download, color: Colors.white),
                      label: const Text(
                        "Export Excel",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 34, 165, 246),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (!loading && allStatesReport.isNotEmpty) ...[
                for (int s = 0; s < allStatesReport.length; s++) ...[
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 15, right: 15, top: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "State: ${allStatesReport[s]["state"]}  (Total: ${allStatesReport[s]["grand_total"]})",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          allStatesReport[s]["month"].toString(),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 10, right: 10, bottom: 30),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        color: Colors.white,
                        child: Table(
                          border: TableBorder.all(
                              color: const Color.fromARGB(255, 214, 213, 213)),
                          defaultColumnWidth: const FixedColumnWidth(55),
                          children: [
                            TableRow(
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(255, 64, 176, 251),
                              ),
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(6.0),
                                  child: Text(
                                    "Sl",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.all(6.0),
                                  child: Text(
                                    "District",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                                ...List<int>.from(allStatesReport[s]["dates"])
                                    .map((d) {
                                  return Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Text(
                                      d.toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                  );
                                }).toList(),
                                const Padding(
                                  padding: EdgeInsets.all(6.0),
                                  child: Text(
                                    "Total",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            for (int i = 0;
                                i <
                                    List.from(allStatesReport[s]["districts"])
                                        .length;
                                i++)
                              TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Text((i + 1).toString()),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Text(
                                      allStatesReport[s]["districts"][i]
                                              ["district"]
                                          .toString(),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  ...List<int>.from(allStatesReport[s]["dates"])
                                      .map((day) {
                                    Map<String, dynamic> dailyCounts =
                                        Map<String, dynamic>.from(
                                            allStatesReport[s]["districts"][i]
                                                ["daily_counts"]);

                                    int value = int.tryParse(
                                            (dailyCounts[day.toString()] ?? 0)
                                                .toString()) ??
                                        0;

                                    return Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Text(
                                        value.toString(),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  }).toList(),
                                  Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Text(
                                      allStatesReport[s]["districts"][i]
                                              ["total"]
                                          .toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            TableRow(
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(255, 235, 235, 235),
                              ),
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(6.0),
                                  child: Text(""),
                                ),
                                const Padding(
                                  padding: EdgeInsets.all(6.0),
                                  child: Text(
                                    "TOTAL",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                ...List<int>.from(allStatesReport[s]["dates"])
                                    .map((day) {
                                  return Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Text(
                                      allStatesReport[s]["column_totals"]
                                              [day.toString()]
                                          .toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                }).toList(),
                                Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Text(
                                    allStatesReport[s]["grand_total"]
                                        .toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]
              ],

              if (searched && !loading && allStatesReport.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "No report data found",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
