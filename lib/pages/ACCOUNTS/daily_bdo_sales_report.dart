import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:beposoft/pages/api.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class DailySalesReportViewPage extends StatefulWidget {
  const DailySalesReportViewPage({super.key});

  @override
  State<DailySalesReportViewPage> createState() =>
      _DailySalesReportViewPageState();
}

class _DailySalesReportViewPageState extends State<DailySalesReportViewPage> {
  // ================= DROPDOWN LISTS =================
  List<Map<String, dynamic>> states = [];

  // ================= SELECTED FILTERS =================
  int? selectedStateId;
  int? selectedMonth;
  int? selectedYear;
  bool isSearchMode = false;

  // ================= REPORT DATA =================
  bool loading = false;

  String userName = "";
  String stateName = "";
  String monthName = "";

  List<int> dates = [];
  List<Map<String, dynamic>> districtsReport = [];
  Map<String, dynamic> columnTotals = {};
  int grandTotal = 0;
  bool searched = false;
  List<Map<String, dynamic>> allocatedStateList = [];

  bool profileLoading = false;
  List<Map<String, dynamic>> allStatesReport = [];

  // ================= TOKEN =================
  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
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

        // print("========== STATE REPORT URL: $url");

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
          });
        }
      }

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      // print("========== ALL STATES REPORT: $allStatesReport");
    } catch (e) {
      // print("========== ALL STATES REPORT ERROR: $e");

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

//       print("========== PROFILE STATUS: ${response.statusCode}");
//       print("========== PROFILE BODY: ${response.body}");
// // 
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List allocatedStates = parsed["data"]["allocated_states"] ?? [];

        // default current month/year
        selectedMonth = DateTime.now().month;
        selectedYear = DateTime.now().year;

// Fetch all allocated state reports automatically
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

            // auto select first state (optional but best)
          });

          // print("========== FINAL STATES LIST: $states");
        }
      }
    } catch (e) {
      // print("========== PROFILE ERROR: $e");
    }

    if (!mounted) return;

    setState(() {
      profileLoading = false;
    });
  }

  // ================= GET STATES =================
  Future<void> getStates() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/states/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // print("========== STATES STATUS: ${response.statusCode}");
      // print("========== STATES BODY: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List<Map<String, dynamic>> list = [];

        for (var item in parsed["data"]) {
          list.add({
            "id": item["id"],
            "name": item["name"],
          });
        }

        if (!mounted) return;

        setState(() {
          states = list;
        });

        // print("========== STATES LIST: $states");
      }
    } catch (e) {
      // print("========== STATES ERROR: $e");
    }
  }

  // ================= FETCH REPORT =================
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

      // print("========== REPORT URL: $url");

      var response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // print("========== REPORT STATUS: ${response.statusCode}");
      // print("========== REPORT BODY: ${response.body}");

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
            }
          ];
        });
      }
    } catch (e) {
      // print("========== REPORT ERROR: $e");
    }

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

      var excel = Excel.createExcel();
      Sheet sheet = excel["All States Daily Sales"];

      // ================= STYLES =================
      final headerStyle = CellStyle(
        backgroundColorHex: "#40B0FB",
        fontFamily: getFontFamily(FontFamily.Calibri),
        bold: true,
        fontColorHex: "#FFFFFF",
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final districtStyle = CellStyle(
        backgroundColorHex: "#E8E8E8",
        fontFamily: getFontFamily(FontFamily.Calibri),
        bold: true,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
      );

      final yellowStyle = CellStyle(
        backgroundColorHex: "#FFFF00",
        fontFamily: getFontFamily(FontFamily.Calibri),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final redStyle = CellStyle(
        backgroundColorHex: "#FF0000",
        fontFamily: getFontFamily(FontFamily.Calibri),
        fontColorHex: "#FFFFFF",
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final totalColStyle = CellStyle(
        backgroundColorHex: "#00FF00",
        fontFamily: getFontFamily(FontFamily.Calibri),
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final bottomTotalStyle = CellStyle(
        backgroundColorHex: "#FFA500",
        fontFamily: getFontFamily(FontFamily.Calibri),
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      int rowIndex = 0;

      // ================= LOOP EACH STATE =================
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
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
          CellIndex.indexByColumnRow(
              columnIndex: dates.length + 2, rowIndex: rowIndex),
        );

        final titleCell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
        titleCell.value = "DAILY SALES REPORT - $state ($month)";
        titleCell.cellStyle = CellStyle(
          fontFamily: getFontFamily(FontFamily.Calibri),
          bold: true,
          fontSize: 16,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );

        rowIndex++;

        // ================= HEADER =================
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .value = "Sl No";
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .cellStyle = headerStyle;

        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = "District";
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .cellStyle = headerStyle;

        int colIndex = 2;
        for (var d in dates) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(
              columnIndex: colIndex, rowIndex: rowIndex));
          cell.value = d.toString();
          cell.cellStyle = headerStyle;
          colIndex++;
        }

        final totalHeader = sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: colIndex, rowIndex: rowIndex));
        totalHeader.value = "TOTAL";
        totalHeader.cellStyle = headerStyle;

        rowIndex++;

        // ================= DATA =================
        for (int i = 0; i < districts.length; i++) {
          final district = districts[i];
          final dailyCounts =
              Map<String, dynamic>.from(district["daily_counts"]);

          final sNoCell = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
          sNoCell.value = (i + 1);
          sNoCell.cellStyle = districtStyle;

          final districtCell = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
          districtCell.value = district["district"].toString();
          districtCell.cellStyle = districtStyle;

          int dayCol = 2;
          for (final day in dates) {
            final val =
                int.tryParse((dailyCounts[day.toString()] ?? 0).toString()) ??
                    0;

            final cell = sheet.cell(CellIndex.indexByColumnRow(
                columnIndex: dayCol, rowIndex: rowIndex));
            cell.value = val;
            cell.cellStyle = val == 0 ? redStyle : yellowStyle;

            dayCol++;
          }

          final totalVal =
              int.tryParse((district["total"] ?? 0).toString()) ?? 0;
          final totalCell = sheet.cell(CellIndex.indexByColumnRow(
              columnIndex: dayCol, rowIndex: rowIndex));
          totalCell.value = totalVal;
          totalCell.cellStyle = totalColStyle;

          rowIndex++;
        }

        // ================= BOTTOM TOTAL =================
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = "TOTAL";
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .cellStyle = bottomTotalStyle;

        int totalDayCol = 2;
        for (final day in dates) {
          final totalVal =
              int.tryParse((columnTotals[day.toString()] ?? 0).toString()) ?? 0;

          final cell = sheet.cell(CellIndex.indexByColumnRow(
              columnIndex: totalDayCol, rowIndex: rowIndex));
          cell.value = totalVal;
          cell.cellStyle = bottomTotalStyle;

          totalDayCol++;
        }

        final grandCell = sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: totalDayCol, rowIndex: rowIndex));
        grandCell.value = grandTotal;
        grandCell.cellStyle = bottomTotalStyle;

        rowIndex += 2; // add gap between states
      }

      // ================= SAVE & SHARE =================
     final fileBytes = excel.encode();
if (fileBytes == null) return;

String exportName = "AllStates";

if (isSearchMode && allStatesReport.isNotEmpty) {
  exportName = allStatesReport[0]["state"].toString();
}

final dir = await getApplicationDocumentsDirectory();

final filePath =
    '${dir.path}/DailySalesReport_${exportName}_${DateTime.now().millisecondsSinceEpoch}.xlsx';

final file = File(filePath);
await file.writeAsBytes(fileBytes, flush: true);

await Future.delayed(const Duration(milliseconds: 300));

await Share.shareXFiles(
  [
    XFile(
      file.path,
      mimeType:
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    )
  ],
  text: "📊 Daily Sales Report - $exportName",
);

    } catch (e) {
      // print("========== EXPORT ERROR: $e");

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

    // keep only first state report
    allStatesReport = [backup[0]];

    await exportAllStatesDailySalesExcel();

    // restore
    allStatesReport = backup;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(242, 255, 255, 255),
      appBar: AppBar(
        title: const Text(
          "Daily Sales Report",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
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
                        exportSelectedStateExcel(); // single state
                      } else {
                        exportAllStatesDailySalesExcel(); // all states
                      }
                    },
                    icon: const Icon(Icons.download, color: Colors.white),
                    label: const Text(
                      "Export Excel",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 34, 165, 246),
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
                  padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "State: ${allStatesReport[s]["state"]}",
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
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
                                    allStatesReport[s]["districts"][i]["total"]
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
                                  style: TextStyle(fontWeight: FontWeight.bold),
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
                                  allStatesReport[s]["grand_total"].toString(),
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
    );
  }
}
