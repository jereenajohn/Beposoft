import 'dart:convert';
import 'dart:io';
import 'package:beposoft/pages/ACCOUNTS/report_folder_page.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:beposoft/pages/api.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class BdmDsrList extends StatefulWidget {
  const BdmDsrList({super.key});

  @override
  State<BdmDsrList> createState() => _BdmDsrListState();
}

class _BdmDsrListState extends State<BdmDsrList> {
  bool loading = false;

  List<Map<String, dynamic>> reportList = [];

  // ================= SUMMARY VARIABLES =================
  double totalVolume = 0;
  int totalReports = 0;
  int totalNewCoach = 0;
  int totalMicroDealer = 0;
  double avgAverage = 0;
  String reportsFolderPath = "";

  // ================= TOKEN =================
  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  @override
  void initState() {
    super.initState();
    fetchBDMBDOReportList();
  }

  // ================= FETCH LIST =================
  Future<void> fetchBDMBDOReportList() async {
    try {
      setState(() {
        loading = true;
        reportList = [];
      });

      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse("$api/api/monthly/sales/report/bdm/bdo/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("=========== REPORT LIST STATUS CODE ===========");
      print(response.statusCode);

      print("=========== REPORT LIST BODY ===========");
      print(response.body);

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List data = List.from(parsed["data"] ?? []);

        List<Map<String, dynamic>> reports = [];

        for (var item in data) {
          reports.add({
            "id": item["id"],
            "bdm_name": item["bdm_name"] ?? "",
            "bdo_name": item["bdo_name"] ?? "",
            "invoice_no": item["invoice_no"] ?? "",
            "volume": item["volume"] ?? "",
            "state_name": item["state_name"] ?? "",
            "new_coach": item["new_coach"] ?? "",
            "micro_dealer": item["micro_dealer"] ?? "",
            "note": item["note"] ?? "",
            "call_duration": item["call_duration"] ?? "",
            "average": item["average"] ?? "",
            "created_at": item["created_at"] ?? "",
          });
        }

        // ================= CALCULATE SUMMARY =================
        totalReports = reports.length;

        totalVolume = 0;
        totalNewCoach = 0;
        totalMicroDealer = 0;
        avgAverage = 0;

        double sumAverage = 0;
        int avgCount = 0;

        for (var r in reports) {
          totalVolume += double.tryParse(r["volume"].toString()) ?? 0;

          if (r["new_coach"].toString().toLowerCase() == "yes") {
            totalNewCoach++;
          }

          if (r["micro_dealer"].toString().toLowerCase() == "yes") {
            totalMicroDealer++;
          }

          double avgVal = double.tryParse(r["average"].toString()) ?? 0;
          if (avgVal > 0) {
            sumAverage += avgVal;
            avgCount++;
          }
        }

        avgAverage = avgCount > 0 ? (sumAverage / avgCount) : 0;

        if (!mounted) return;

        setState(() {
          reportList = reports;
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Failed to load report (${response.statusCode})"),
          ),
        );
      }
    } catch (e) {
      print("=========== REPORT LIST ERROR ===========");
      print(e);

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error: $e"),
        ),
      );
    }
  }

  // ================= EXPORT EXCEL WITH FULL SUMMARY COLOR =================
  Future<void> exportExcel() async {
    try {
      if (reportList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("No data available to export"),
          ),
        );
        return;
      }

      var excel = Excel.createExcel();
      Sheet sheet = excel["BDO_SALES_REPORT"];

      // ================= STYLES =================
      final headingStyle = CellStyle(
        backgroundColorHex: "#1565C0",
        fontFamily: getFontFamily(FontFamily.Calibri),
        bold: true,
        fontColorHex: "#FFFFFF",
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final headerStyle = CellStyle(
        backgroundColorHex: "#40B0FB",
        fontFamily: getFontFamily(FontFamily.Calibri),
        bold: true,
        fontColorHex: "#FFFFFF",
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final normalStyle = CellStyle(
        backgroundColorHex: "#FFF9C4",
        fontFamily: getFontFamily(FontFamily.Calibri),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final noteStyle = CellStyle(
        backgroundColorHex: "#FFF9C4",
        fontFamily: getFontFamily(FontFamily.Calibri),
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
      );

      final summaryHeaderStyle = CellStyle(
        backgroundColorHex: "#2E7D32",
        fontFamily: getFontFamily(FontFamily.Calibri),
        bold: true,
        fontColorHex: "#FFFFFF",
        fontSize: 14,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final summaryRowStyle = CellStyle(
        backgroundColorHex: "#BBDEFB",
        fontFamily: getFontFamily(FontFamily.Calibri),
        bold: true,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
      );

      final summaryValueStyle = CellStyle(
        backgroundColorHex: "#BBDEFB",
        fontFamily: getFontFamily(FontFamily.Calibri),
        bold: true,
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );

      // ================= HEADING ROW =================
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: 0),
      );

      final headingCell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
      headingCell.value = "BDO SALES REPORT LIST";
      headingCell.cellStyle = headingStyle;

      // ================= HEADER ROW =================
      List<String> headers = [
        "Sl No",
        "BDM Name",
        "BDO Name",
        "Invoice No",
        "Volume",
        "State Name",
        "New Coach (1/0)",
        "Micro Dealer (1/0)",
        "Call Duration",
        "Average",
        "Note",
      ];

      for (int i = 0; i < headers.length; i++) {
        final cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1));
        cell.value = headers[i];
        cell.cellStyle = headerStyle;
      }

      // ================= DATA ROWS =================
      for (int i = 0; i < reportList.length; i++) {
        int rowIndex = i + 2;
        Map<String, dynamic> row = reportList[i];

        int newCoachVal =
            row["new_coach"].toString().toLowerCase() == "yes" ? 1 : 0;

        int microDealerVal =
            row["micro_dealer"].toString().toLowerCase() == "yes" ? 1 : 0;

        List<dynamic> rowData = [
          (i + 1),
          row["bdm_name"] ?? "",
          row["bdo_name"] ?? "",
          row["invoice_no"] ?? "",
          row["volume"] ?? "",
          row["state_name"] ?? "",
          newCoachVal,
          microDealerVal,
          row["call_duration"] ?? "",
          row["average"] ?? "",
          row["note"] ?? "",
        ];

        for (int col = 0; col < rowData.length; col++) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex),
          );

          cell.value = rowData[col].toString();

          if (col == 10) {
            cell.cellStyle = noteStyle;
          } else {
            cell.cellStyle = normalStyle;
          }
        }
      }

      // ================= SUMMARY SECTION =================
      int summaryStartRow = reportList.length + 4;

      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryStartRow),
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: summaryStartRow),
      );

      final summaryTitleCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryStartRow),
      );

      summaryTitleCell.value = "FINAL SUMMARY";
      summaryTitleCell.cellStyle = summaryHeaderStyle;

      List<List<dynamic>> summaryRows = [
        ["Total Reports", totalReports],
        ["Total Volume", totalVolume.toStringAsFixed(2)],
        ["New Coach (YES Count)", totalNewCoach],
        ["Micro Dealer (YES Count)", totalMicroDealer],
        ["Average (Overall)", avgAverage.toStringAsFixed(2)],
      ];

      for (int i = 0; i < summaryRows.length; i++) {
        int row = summaryStartRow + 1 + i;

        sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
          CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row),
        );

        sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row),
          CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row),
        );

        final keyCell = sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
        keyCell.value = summaryRows[i][0].toString();
        keyCell.cellStyle = summaryRowStyle;

        final valueCell = sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row));
        valueCell.value = summaryRows[i][1].toString();
        valueCell.cellStyle = summaryValueStyle;

        for (int col = 0; col <= 5; col++) {
          final c = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
          );
          c.cellStyle = summaryRowStyle;
        }
      }

      // ================= COLUMN WIDTHS =================
      sheet.setColWidth(0, 8);
      sheet.setColWidth(1, 20);
      sheet.setColWidth(2, 20);
      sheet.setColWidth(3, 18);
      sheet.setColWidth(4, 12);
      sheet.setColWidth(5, 16);
      sheet.setColWidth(6, 14);
      sheet.setColWidth(7, 16);
      sheet.setColWidth(8, 14);
      sheet.setColWidth(9, 12);
      sheet.setColWidth(10, 25);

      final fileBytes = excel.encode();
      if (fileBytes == null) return;

      // ================= SAVE IN APP EXTERNAL DIRECTORY =================
      final dir = await getExternalStorageDirectory();
      if (dir == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("Storage not available"),
          ),
        );
        return;
      }

      final reportsDir = Directory("${dir.path}/reports");
      if (!reportsDir.existsSync()) {
        reportsDir.createSync(recursive: true);
      }

      setState(() {
        reportsFolderPath = reportsDir.path;
      });

      String fileName =
          "BDO_SALES_REPORT_${DateTime.now().millisecondsSinceEpoch}.xlsx";

      String filePath = "${reportsDir.path}/$fileName";

      final file = File(filePath);
      await file.writeAsBytes(fileBytes, flush: true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text("Excel saved successfully"),
        ),
      );

      // ================= OPEN FILE DIRECTLY =================
// ================= DO NOT AUTO OPEN =================
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text("Excel saved successfully in: $filePath"),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Excel Export Failed: $e"),
        ),
      );
    }
  }

  // ================= SUMMARY CARD UI =================
  Widget summaryCard() {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 15),
      child: Container(
        width: 900,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color.fromARGB(255, 202, 202, 202)),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(30, 0, 0, 0),
              blurRadius: 6,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Final Summary",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 10),
              summaryRow("Total Reports", totalReports.toString(),
                  valueColor: Colors.black),
              summaryRow("Total Volume", totalVolume.toStringAsFixed(2),
                  valueColor: Colors.green),
              summaryRow("New Coach (YES Count)", totalNewCoach.toString(),
                  valueColor: Colors.blue),
              summaryRow(
                  "Micro Dealer (YES Count)", totalMicroDealer.toString(),
                  valueColor: Colors.blue),
              summaryRow("Average (Overall)", avgAverage.toStringAsFixed(2),
                  valueColor: Colors.deepPurple),
            ],
          ),
        ),
      ),
    );
  }

  Widget summaryRow(String title, String value,
      {Color valueColor = Colors.black}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }

  // ================= TABLE UI =================
  Widget buildReportTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        color: Colors.white,
        child: Table(
          border: TableBorder.all(
            color: const Color.fromARGB(255, 214, 213, 213),
          ),
          defaultColumnWidth: const FixedColumnWidth(140),
          children: [
            TableRow(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 64, 176, 251),
              ),
              children: const [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Sl No",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "BDM",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "BDO",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Invoice No",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Volume",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "State",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "New Coach",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Micro Dealer",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Call Duration",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Average",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Note",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
            for (int i = 0; i < reportList.length; i++)
              TableRow(
                decoration: BoxDecoration(
                  color: i % 2 == 0
                      ? Colors.white
                      : const Color.fromARGB(255, 245, 245, 245),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text((i + 1).toString()),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(reportList[i]["bdm_name"].toString()),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(reportList[i]["bdo_name"].toString()),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(reportList[i]["invoice_no"].toString()),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(reportList[i]["volume"].toString()),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(reportList[i]["state_name"].toString()),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(reportList[i]["new_coach"].toString()),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(reportList[i]["micro_dealer"].toString()),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(reportList[i]["call_duration"].toString()),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(reportList[i]["average"].toString()),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(reportList[i]["note"].toString()),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(242, 255, 255, 255),
      appBar: AppBar(
        title: const Text(
          "BDM BDO Report List",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => bdm_dashbord()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchBDMBDOReportList,
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ReportsFolderPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 15),

            // ================= BLUE HEADER =================
            Padding(
              padding: const EdgeInsets.only(right: 10, top: 10, left: 10),
              child: Container(
                width: 600,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 34, 165, 246),
                  border: Border.all(
                      color: const Color.fromARGB(255, 202, 202, 202)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          children: [
                            SizedBox(height: 10),
                            Text(
                              "BDM - BDO REPORT LIST",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              "Monthly Sales Report Details",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 13),
                          ],
                        ),
                      ),

                      // Excel Export Icon
                      IconButton(
                        onPressed: exportExcel,
                        icon: const Icon(
                          Icons.download,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ================= TABLE CARD =================
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Container(
                width: 900,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                      color: const Color.fromARGB(255, 202, 202, 202)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: loading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(25),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : reportList.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  "No report data found",
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            )
                          : buildReportTable(),
                ),
              ),
            ),

            // ================= FINAL SUMMARY CARD =================
            if (!loading && reportList.isNotEmpty) summaryCard(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
