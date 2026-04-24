import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:beposoft/pages/api.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart' hide Border;

class BDOCategorywiseSalesReport extends StatefulWidget {
  const BDOCategorywiseSalesReport({super.key});

  @override
  State<BDOCategorywiseSalesReport> createState() =>
      _BDOCategorywiseSalesReportState();
}

class _BDOCategorywiseSalesReportState extends State<BDOCategorywiseSalesReport> {
  bool loading = false;

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  List<String> categories = [];
  Map<String, dynamic> reportData = {};
  Map<String, dynamic> categoryTotals = {};

  // ================= TOKEN =================
  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  // ================= FETCH FUNCTION =================
  Future<void> fetchCategoryReport() async {
    try {
      setState(() {
        loading = true;
      });

      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse(
            "$api/api/monthly/category/report/?month=$selectedMonth&year=$selectedYear"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      // print("Category Report Status: ${response.statusCode}");
      // print("Category Report Body: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List<String> categoryList =
            List<String>.from(parsed["categories"] ?? []);

        // remove duplicates
        categoryList = categoryList.toSet().toList();

        setState(() {
          categories = categoryList;
          reportData = parsed["data"] ?? {};
          categoryTotals = parsed["category_totals"] ?? {};
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load report")),
        );
      }
    } catch (e) {
      setState(() {
        loading = false;
      });

      // print("Error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> exportCategorywiseExcel() async {
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

      var excel = Excel.createExcel();
      Sheet sheet = excel["Sheet1"];

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

      // ================= MAIN TITLE =================
      int maxCol =
          categories.length + 2; // SlNo + District + Categories + Total

      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        CellIndex.indexByColumnRow(columnIndex: maxCol, rowIndex: rowIndex),
      );

      final titleCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
      );

      titleCell.value =
          "CATEGORYWISE SALES REPORT - $selectedMonth/$selectedYear";

      titleCell.cellStyle = CellStyle(
        fontFamily: getFontFamily(FontFamily.Calibri),
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      rowIndex += 2;

      // ================= LOOP EACH STATE =================
      reportData.forEach((stateName, districtMap) {
        Map<String, dynamic> districts = districtMap as Map<String, dynamic>;

        // ================= CALCULATE STATE TOTALS =================
        Map<String, int> stateTotals = {};
        for (var cat in categories) {
          stateTotals[cat] = 0;
        }
        int grandTotal = 0;

        districts.forEach((districtName, districtData) {
          Map<String, dynamic> d = districtData as Map<String, dynamic>;

          for (var cat in categories) {
            stateTotals[cat] = (stateTotals[cat] ?? 0) + ((d[cat] ?? 0) as int);
          }

          grandTotal += (d["total"] ?? 0) as int;
        });

        // ================= STATE HEADER (MERGED) =================
        sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
          CellIndex.indexByColumnRow(columnIndex: maxCol, rowIndex: rowIndex),
        );

        final stateCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        );

        stateCell.value =
            "STATE: ${stateName.toString().toUpperCase()}  |  TOTAL: $grandTotal";
        stateCell.cellStyle = CellStyle(
          fontFamily: getFontFamily(FontFamily.Calibri),
          bold: true,
          fontSize: 14,
        );

        rowIndex++;

        // ================= HEADER ROW =================
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

        for (var cat in categories) {
          final c = sheet.cell(
            CellIndex.indexByColumnRow(
                columnIndex: colIndex, rowIndex: rowIndex),
          );
          c.value = cat;
          c.cellStyle = headerStyle;
          colIndex++;
        }

        final totalHeader = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex),
        );
        totalHeader.value = "TOTAL";
        totalHeader.cellStyle = headerStyle;

        rowIndex++;

        // ================= DISTRICT DATA ROWS =================
        int slNo = 1;

        districts.forEach((districtName, districtData) {
          Map<String, dynamic> d = districtData as Map<String, dynamic>;

          final sNoCell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
          );
          sNoCell.value = slNo;
          sNoCell.cellStyle = districtStyle;

          final districtCell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
          );
          districtCell.value = districtName.toString();
          districtCell.cellStyle = districtStyle;

          int dataCol = 2;
          for (var cat in categories) {
            int val = (d[cat] ?? 0) as int;

            final cell = sheet.cell(
              CellIndex.indexByColumnRow(
                  columnIndex: dataCol, rowIndex: rowIndex),
            );

            cell.value = val;
            cell.cellStyle = val == 0 ? redStyle : yellowStyle;

            dataCol++;
          }

          final totalVal = (d["total"] ?? 0) as int;
          final totalCell = sheet.cell(
            CellIndex.indexByColumnRow(
                columnIndex: dataCol, rowIndex: rowIndex),
          );
          totalCell.value = totalVal;
          totalCell.cellStyle = totalColStyle;

          rowIndex++;
          slNo++;
        });

        // ================= TOTAL ROW =================
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = "TOTAL";
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .cellStyle = bottomTotalStyle;

        int totalCol = 2;
        for (var cat in categories) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(
                columnIndex: totalCol, rowIndex: rowIndex),
          );

          cell.value = stateTotals[cat] ?? 0;
          cell.cellStyle = bottomTotalStyle;

          totalCol++;
        }

        final grandCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: totalCol, rowIndex: rowIndex),
        );
        grandCell.value = grandTotal;
        grandCell.cellStyle = bottomTotalStyle;

        rowIndex += 2;
      });

      final fileBytes = excel.encode();
      final tempDir = await getTemporaryDirectory();

      final filePath =
          '${tempDir.path}/CategorywiseSalesReport_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      final file = File(filePath);
      await file.writeAsBytes(fileBytes!);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: "📊 Categorywise Sales Report",
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

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    fetchCategoryReport();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Categorywise Sales Report",
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.file_download,
              color: Colors.green,
            ),
            tooltip: "Export Excel",
            onPressed: exportCategorywiseExcel,
          ),
        ],
      ),
      body: Column(
        children: [
          // ================= FILTER BAR =================
          // ================= FILTER BAR =================
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // MONTH DROPDOWN
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: selectedMonth,
                    decoration: InputDecoration(
                      labelText: "Month",
                      filled: true,
                      fillColor: Colors.blue.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: List.generate(12, (index) {
                      int month = index + 1;
                      return DropdownMenuItem(
                        value: month,
                        child: Text(month.toString()),
                      );
                    }),
                    onChanged: (val) {
                      setState(() {
                        selectedMonth = val!;
                      });
                    },
                  ),
                ),

                const SizedBox(width: 10),

                // YEAR DROPDOWN
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: selectedYear,
                    decoration: InputDecoration(
                      labelText: "Year",
                      filled: true,
                      fillColor: Colors.blue.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: List.generate(10, (index) {
                      int year = DateTime.now().year - index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (val) {
                      setState(() {
                        selectedYear = val!;
                      });
                    },
                  ),
                ),

                const SizedBox(width: 10),

                // SEARCH BUTTON
                Expanded(
                  child: ElevatedButton(
                    onPressed: fetchCategoryReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      "Search",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ================= REPORT TABLE =================
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : reportData.isEmpty
                    ? const Center(child: Text("No data found"))
                    : SingleChildScrollView(
                        child: Column(
                          children: reportData.entries.map((stateEntry) {
                            String stateName = stateEntry.key;
                            Map<String, dynamic> districts =
                                stateEntry.value as Map<String, dynamic>;

                            int slNo = 1;

                            // ================= CALCULATE STATE TOTALS =================
                            Map<String, int> stateTotals = {};
                            for (var cat in categories) {
                              stateTotals[cat] = 0;
                            }
                            int grandTotal = 0;

                            districts.forEach((districtName, districtData) {
                              Map<String, dynamic> d =
                                  districtData as Map<String, dynamic>;

                              for (var cat in categories) {
                                stateTotals[cat] = (stateTotals[cat] ?? 0) +
                                    ((d[cat] ?? 0) as int);
                              }

                              grandTotal += (d["total"] ?? 0) as int;
                            });

                            return Padding(
                              padding: const EdgeInsets.all(10),
                              child: Card(
                                color: Colors.white,
                                elevation: 4,
                                shadowColor: Colors.blue.shade100,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // ================= STATE HEADER =================
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              stateName.toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                "Total : $grandTotal",
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 10),

                                      // ================= TABLE =================
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: DataTable(
                                          border: TableBorder.all(
                                            color: Colors.blue.shade100,
                                          ),
                                          headingRowColor:
                                              MaterialStateProperty.all(
                                            Colors.blue.shade100,
                                          ),
                                          columns: [
                                            const DataColumn(
                                              label: Text(
                                                "Sl No",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0D47A1),
                                                ),
                                              ),
                                            ),
                                            const DataColumn(
                                              label: Text(
                                                "District",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0D47A1),
                                                ),
                                              ),
                                            ),
                                            ...categories.map((cat) {
                                              return DataColumn(
                                                label: Text(
                                                  cat,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF0D47A1),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                            const DataColumn(
                                              label: Text(
                                                "Total",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0D47A1),
                                                ),
                                              ),
                                            ),
                                          ],
                                          rows: [
                                            // ================= DISTRICT ROWS =================
                                            ...districts.entries
                                                .map((districtEntry) {
                                              String districtName =
                                                  districtEntry.key;
                                              Map<String, dynamic>
                                                  districtData =
                                                  districtEntry.value
                                                      as Map<String, dynamic>;

                                              return DataRow(
                                                cells: [
                                                  DataCell(Text(
                                                      (slNo++).toString())),
                                                  DataCell(Text(districtName)),
                                                  ...categories.map((cat) {
                                                    var value =
                                                        districtData[cat] ?? 0;
                                                    return DataCell(
                                                      Text(value.toString()),
                                                    );
                                                  }).toList(),
                                                  DataCell(
                                                    Text(
                                                      (districtData["total"] ??
                                                              0)
                                                          .toString(),
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }).toList(),

                                            // ================= STATE TOTAL ROW =================
                                            DataRow(
                                              color: MaterialStateProperty.all(
                                                  Colors.blue.shade50),
                                              cells: [
                                                const DataCell(Text("")),
                                                const DataCell(
                                                  Text(
                                                    "TOTAL",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF0D47A1),
                                                    ),
                                                  ),
                                                ),
                                                ...categories.map((cat) {
                                                  return DataCell(
                                                    Text(
                                                      (stateTotals[cat] ?? 0)
                                                          .toString(),
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Color(0xFF0D47A1),
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                                DataCell(
                                                  Text(
                                                    grandTotal.toString(),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF0D47A1),
                                                    ),
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
                              ),
                            );
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
