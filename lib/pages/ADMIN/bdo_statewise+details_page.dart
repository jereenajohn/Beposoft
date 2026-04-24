import 'dart:convert';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as ex;
import 'package:share_plus/share_plus.dart';

// keep your own imports here
// import 'package:your_project/api.dart';
// import 'package:your_project/loginpage.dart';

class bdostatewisedetailspage extends StatefulWidget {
  final String title;
  final String familyName;
  final List<Map<String, dynamic>> states;
  final double familyTotal;
  final int familyBillTotal;
  final bool isDaily;
  final String dateLabel;

  const bdostatewisedetailspage({
    super.key,
    required this.title,
    required this.familyName,
    required this.states,
    required this.familyTotal,
    required this.familyBillTotal,
    required this.isDaily,
    required this.dateLabel,
  });

  @override
  State<bdostatewisedetailspage> createState() =>
      _bdostatewisedetailspageState();
}

class _bdostatewisedetailspageState extends State<bdostatewisedetailspage> {
  late List<Map<String, dynamic>> currentStates;
  late double currentFamilyTotal;
  late int currentFamilyBillTotal;
  late String currentDateLabel;

  bool loading = false;

  DateTimeRange? selectedRange;

  @override
  void initState() {
    super.initState();
    currentStates = widget.states;
    currentFamilyTotal = widget.familyTotal;
    currentFamilyBillTotal = widget.familyBillTotal;
    currentDateLabel = widget.dateLabel;
  }

  Color _groupColor(int index) {
    return index.isEven ? const Color(0xFFE6C1A4) : const Color(0xFFE7E7E7);
  }

  String formatAmount(dynamic value) {
    final amount = (value as num?)?.toDouble() ?? 0.0;
    return amount.toStringAsFixed(0);
  }

  String formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> pickDateRange() async {
    final now = DateTime.now();

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: selectedRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: now,
          ),
    );

    if (picked != null) {
      setState(() {
        selectedRange = picked;
      });

      await fetchFamilyDataByDateRange(
        startDate: picked.start,
        endDate: picked.end,
      );
    }
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchFamilyDataByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      setState(() {
        loading = true;
      });

      final token = await getTokenFromPrefs();

      final start = formatDate(startDate);
      final end = formatDate(endDate);

      final response = await http.get(
        Uri.parse(
          '$api/api/reports/state/wise/bdo/?start_date=$start&end_date=$end',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        if (parsed['status'] == 'success') {
          final List<dynamic> data = parsed['data'] ?? [];

          Map<String, dynamic>? matchedFamily;

          for (final item in data) {
            final mapItem = Map<String, dynamic>.from(item);
            final family =
                (mapItem['family'] ?? '').toString().toLowerCase().trim();

            if (family == widget.familyName.toLowerCase().trim()) {
              matchedFamily = mapItem;
              break;
            }
          }

          if (matchedFamily != null) {
            setState(() {
              currentStates = List<Map<String, dynamic>>.from(
                matchedFamily!['states'] ?? [],
              );
              currentFamilyTotal =
                  (matchedFamily['family_total'] as num?)?.toDouble() ?? 0.0;
              currentFamilyBillTotal =
                  (matchedFamily['family_bill_total'] as num?)?.toInt() ?? 0;
              currentDateLabel = "$start to $end";
            });
          } else {
            setState(() {
              currentStates = [];
              currentFamilyTotal = 0.0;
              currentFamilyBillTotal = 0;
              currentDateLabel = "$start to $end";
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching BDO statewise detail: $e");
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> exportToExcel() async {
    try {
      if (currentStates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("No data available to export"),
          ),
        );
        return;
      }

      var excel = ex.Excel.createExcel();
      ex.Sheet sheet = excel["BDO Statewise Report"];

      // ================= COLUMN WIDTHS =================
      // Adjusted for readable, professional layout
      sheet.setColWidth(0, 8); // #NO
      sheet.setColWidth(1, 24); // STATE
      sheet.setColWidth(2, 22); // BDO
      sheet.setColWidth(3, 10); // BILL
      sheet.setColWidth(4, 14); // AMOUNT
      sheet.setColWidth(5, 18); // STATE WISE TOTAL

      // ================= BORDER =================
      final ex.Border thinBorder = ex.Border(borderStyle: ex.BorderStyle.Thin);

      // ================= STYLES =================
      final ex.CellStyle titleStyle = ex.CellStyle(
        backgroundColorHex: "#B7DEE8",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        fontSize: 20,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle billedStyle = ex.CellStyle(
        backgroundColorHex: "#EDEDED",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        fontSize: 16,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle infoStyle = ex.CellStyle(
        backgroundColorHex: "#FFFFFF",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        fontSize: 12,
        horizontalAlign: ex.HorizontalAlign.Left,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle headerStyle = ex.CellStyle(
        backgroundColorHex: "#D9D9D9",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        fontSize: 12,
        fontColorHex: "#C00000",
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle peachCenterStyle = ex.CellStyle(
        backgroundColorHex: "#E8C4A8",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        fontSize: 11,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle peachLeftStyle = ex.CellStyle(
        backgroundColorHex: "#E8C4A8",
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

      final ex.CellStyle grayCenterStyle = ex.CellStyle(
        backgroundColorHex: "#E7E7E7",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        fontSize: 11,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle grayLeftStyle = ex.CellStyle(
        backgroundColorHex: "#E7E7E7",
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

      final ex.CellStyle amountStyle = ex.CellStyle(
        backgroundColorHex: "#FFF200",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        fontSize: 11,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle totalLabelStyle = ex.CellStyle(
        backgroundColorHex: "#F2F2F2",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        fontSize: 12,
        fontColorHex: "#C00000",
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      final ex.CellStyle totalValueStyle = ex.CellStyle(
        backgroundColorHex: "#F2F2F2",
        fontFamily: ex.getFontFamily(ex.FontFamily.Calibri),
        bold: true,
        fontSize: 12,
        fontColorHex: "#C00000",
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      int rowIndex = 0;

      // ================= TITLE =================
      sheet.merge(
        ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        ex.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
      );

      final titleCell = sheet.cell(
        ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
      );
      titleCell.value = widget.familyName.toUpperCase();
      titleCell.cellStyle = titleStyle;

      rowIndex++;

      // ================= SUB TITLE =================
      sheet.merge(
        ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        ex.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
      );

      final billedCell = sheet.cell(
        ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
      );
      billedCell.value = "BILLED";
      billedCell.cellStyle = billedStyle;

      rowIndex++;

      // ================= REPORT INFO =================
      sheet.merge(
        ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        ex.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
      );

      final infoCell = sheet.cell(
        ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
      );
      infoCell.value = "${widget.title} | $currentDateLabel";
      infoCell.cellStyle = infoStyle;

      rowIndex++;

      // ================= HEADER =================
      List<String> headers = [
        "#NO",
        "STATE",
        "BDO",
        "BILL",
        "AMOUNT",
        "STATE WISE TOTAL",
      ];

      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex),
        );
        cell.value = headers[i];
        cell.cellStyle = headerStyle;
      }

      rowIndex++;

      // ================= DATA =================
      int serialNo = 1;

      for (int i = 0; i < currentStates.length; i++) {
        final stateItem = currentStates[i];
        final String stateName = stateItem['state']?.toString() ?? '';
        final double stateTotal =
            (stateItem['state_total'] as num?)?.toDouble() ?? 0.0;
        final List<dynamic> bdoDetails = stateItem['bdo_details'] ?? [];

        final bool isPeach = i.isEven;

        final ex.CellStyle centerStyle =
            isPeach ? peachCenterStyle : grayCenterStyle;
        final ex.CellStyle leftStyle = isPeach ? peachLeftStyle : grayLeftStyle;

        final int blockStartRow = rowIndex;

        if (bdoDetails.isNotEmpty) {
          for (int j = 0; j < bdoDetails.length; j++) {
            final bdo = Map<String, dynamic>.from(bdoDetails[j]);
            final String name = bdo['name']?.toString() ?? '';
            final int bills = (bdo['bills'] as num?)?.toInt() ?? 0;
            final double amount = (bdo['amount'] as num?)?.toDouble() ?? 0.0;

            final slCell = sheet.cell(
              ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
            );
            slCell.value = j == 0 ? serialNo : "";
            slCell.cellStyle = centerStyle;

            final stateCell = sheet.cell(
              ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
            );
            stateCell.value = j == 0 ? stateName : "";
            stateCell.cellStyle = leftStyle;

            final nameCell = sheet.cell(
              ex.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
            );
            nameCell.value = name;
            nameCell.cellStyle = leftStyle;

            final billCell = sheet.cell(
              ex.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
            );
            billCell.value = bills;
            billCell.cellStyle = centerStyle;

            final amountCell = sheet.cell(
              ex.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
            );
            amountCell.value = amount.toStringAsFixed(0);
            amountCell.cellStyle = amountStyle;

            final totalCell = sheet.cell(
              ex.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
            );
            totalCell.value = j == 0 ? stateTotal.toStringAsFixed(0) : "";
            totalCell.cellStyle = centerStyle;

            rowIndex++;
          }
        } else {
          final slCell = sheet.cell(
            ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
          );
          slCell.value = serialNo;
          slCell.cellStyle = centerStyle;

          final stateCell = sheet.cell(
            ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
          );
          stateCell.value = stateName;
          stateCell.cellStyle = leftStyle;

          final nameCell = sheet.cell(
            ex.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
          );
          nameCell.value = "-";
          nameCell.cellStyle = leftStyle;

          final billCell = sheet.cell(
            ex.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
          );
          billCell.value = 0;
          billCell.cellStyle = centerStyle;

          final amountCell = sheet.cell(
            ex.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
          );
          amountCell.value = "0";
          amountCell.cellStyle = amountStyle;

          final totalCell = sheet.cell(
            ex.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
          );
          totalCell.value = stateTotal.toStringAsFixed(0);
          totalCell.cellStyle = centerStyle;

          rowIndex++;
        }

        final int blockEndRow = rowIndex - 1;

        if (blockEndRow > blockStartRow) {
          sheet.merge(
            ex.CellIndex.indexByColumnRow(
                columnIndex: 0, rowIndex: blockStartRow),
            ex.CellIndex.indexByColumnRow(
                columnIndex: 0, rowIndex: blockEndRow),
          );
          sheet.merge(
            ex.CellIndex.indexByColumnRow(
                columnIndex: 1, rowIndex: blockStartRow),
            ex.CellIndex.indexByColumnRow(
                columnIndex: 1, rowIndex: blockEndRow),
          );
          sheet.merge(
            ex.CellIndex.indexByColumnRow(
                columnIndex: 5, rowIndex: blockStartRow),
            ex.CellIndex.indexByColumnRow(
                columnIndex: 5, rowIndex: blockEndRow),
          );
        }

        serialNo++;
      }

      // ================= TOTAL =================
      final totalA = sheet.cell(
        ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
      );
      totalA.value = "";
      totalA.cellStyle = totalLabelStyle;

      final totalB = sheet.cell(
        ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
      );
      totalB.value = "TOTAL";
      totalB.cellStyle = totalLabelStyle;

      final totalC = sheet.cell(
        ex.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
      );
      totalC.value = "";
      totalC.cellStyle = totalLabelStyle;

      final totalD = sheet.cell(
        ex.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
      );
      totalD.value = currentFamilyBillTotal;
      totalD.cellStyle = totalValueStyle;

      final totalE = sheet.cell(
        ex.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
      );
      totalE.value = currentFamilyTotal.toStringAsFixed(0);
      totalE.cellStyle = totalValueStyle;

      final totalF = sheet.cell(
        ex.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
      );
      totalF.value = currentFamilyTotal.toStringAsFixed(0);
      totalF.cellStyle = totalValueStyle;

      // ================= SAVE & SHARE =================
      final fileBytes = excel.encode();
      final tempDir = await getTemporaryDirectory();

      final filePath =
          '${tempDir.path}/BDO_Statewise_Report_${widget.familyName}_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      final file = File(filePath);
      await file.writeAsBytes(fileBytes!);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: "BDO Statewise Report - ${widget.familyName}",
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

  @override
  Widget build(BuildContext context) {
    final familyUpper = widget.familyName.toUpperCase();
    List<TableRow> rows = [];

    rows.add(
      const TableRow(
        decoration: BoxDecoration(color: Color(0xFFD9D9D9)),
        children: [
          HeaderCell("#NO"),
          HeaderCell("STATE"),
          HeaderCell("BDO"),
          HeaderCell("BILL"),
          HeaderCell("AMOUNT"),
          HeaderCell("STATE WISE TOTAL"),
        ],
      ),
    );

    int serialNo = 1;

    for (int i = 0; i < currentStates.length; i++) {
      final stateItem = currentStates[i];
      final stateName = stateItem['state']?.toString() ?? '';
      final stateTotal = stateItem['state_total'] ?? 0;
      final List<dynamic> bdoDetails = stateItem['bdo_details'] ?? [];
      final bgColor = _groupColor(i);

      for (int j = 0; j < bdoDetails.length; j++) {
        final bdo = Map<String, dynamic>.from(bdoDetails[j]);
        final name = bdo['name']?.toString() ?? '';
        final bills = (bdo['bills'] as num?)?.toInt() ?? 0;
        final amount = bdo['amount'] ?? 0;

        rows.add(
          TableRow(
            decoration: BoxDecoration(color: bgColor),
            children: [
              BodyCell(j == 0 ? serialNo.toString() : ""),
              BodyCell(j == 0 ? stateName : ""),
              BodyCell(name),
              BodyCell(bills.toString()),
              BodyCell(formatAmount(amount), amountCell: true),
              BodyCell(j == 0 ? formatAmount(stateTotal) : "", bold: true),
            ],
          ),
        );
      }

      if (bdoDetails.isEmpty) {
        rows.add(
          TableRow(
            decoration: BoxDecoration(color: bgColor),
            children: [
              BodyCell(serialNo.toString()),
              BodyCell(stateName),
              const BodyCell("-"),
              const BodyCell("0"),
              const BodyCell("0", amountCell: true),
              BodyCell(formatAmount(stateTotal), bold: true),
            ],
          ),
        );
      }

      serialNo++;
    }

    rows.add(
      TableRow(
        decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
        children: [
          const BodyCell(""),
          const BodyCell("TOTAL", bold: true, red: true),
          const BodyCell(""),
          BodyCell(
            currentFamilyBillTotal.toString(),
            bold: true,
            red: true,
          ),
          BodyCell(
            currentFamilyTotal.toStringAsFixed(0),
            bold: true,
            red: true,
          ),
          BodyCell(
            currentFamilyTotal.toStringAsFixed(0),
            bold: true,
            red: true,
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 12, 170, 222),
        title: Text(
          "$familyUpper - ${widget.isDaily ? "Daily" : "Monthly"} Reportt",
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: pickDateRange,
            icon: const Icon(Icons.calendar_month, color: Colors.white),
          ),
          IconButton(
            onPressed: exportToExcel,
            icon: const Icon(Icons.download, color: Colors.white),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 900,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black54, width: 0.8),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            color: const Color(0xFFB8EAF0),
                            child: Center(
                              child: Text(
                                familyUpper,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            color: const Color(0xFFF0F0F0),
                            child: const Center(
                              child: Text(
                                "BILLED",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            color: Colors.white,
                            child: Text(
                              "${widget.title}  |  $currentDateLabel",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Table(
                            border: TableBorder.all(
                              color: Colors.black54,
                              width: 0.8,
                            ),
                            columnWidths: const {
                              0: FixedColumnWidth(55),
                              1: FixedColumnWidth(240),
                              2: FixedColumnWidth(170),
                              3: FixedColumnWidth(95),
                              4: FixedColumnWidth(120),
                              5: FixedColumnWidth(190),
                            },
                            children: rows,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class HeaderCell extends StatelessWidget {
  final String text;
  const HeaderCell(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class BodyCell extends StatelessWidget {
  final String text;
  final bool bold;
  final bool red;
  final bool amountCell;

  const BodyCell(
    this.text, {
    super.key,
    this.bold = false,
    this.red = false,
    this.amountCell = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: amountCell && text.isNotEmpty ? const Color(0xFFFFFF00) : null,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          color: red ? Colors.red : Colors.black,
        ),
      ),
    );
  }
}
