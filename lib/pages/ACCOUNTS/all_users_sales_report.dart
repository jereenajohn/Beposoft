import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:beposoft/pages/api.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:share_plus/share_plus.dart';
import 'package:dropdown_search/dropdown_search.dart';

class AllUsersDailySalesReportPage extends StatefulWidget {
  const AllUsersDailySalesReportPage({super.key});

  @override
  State<AllUsersDailySalesReportPage> createState() =>
      _AllUsersDailySalesReportPageState();
}

class _AllUsersDailySalesReportPageState
    extends State<AllUsersDailySalesReportPage> {
  // ================= SELECTED FILTERS =================
  int? selectedMonth;
  int? selectedYear;
  int? selectedUserId;
  int? selectedStateId;
  List<Map<String, dynamic>> stateList = [];

  // ================= LOADING =================
  bool loading = false;
  bool profileLoading = false;
  bool searched = false;

  // ================= STAFF (USER DROPDOWN) =================
  List<Map<String, dynamic>> staffList = [];

  // ================= GROUPED REPORT (USER -> STATES -> DATA) =================
  List<Map<String, dynamic>> groupedReport = [];

  // ================= TOKEN =================
  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime.now().month;
    selectedYear = DateTime.now().year;
    getstaff();
    // getProfileAllocatedStatesAndLoad();
  }

  // ================= GET STAFFS (USER DROPDOWN) =================
  Future<void> getstaff() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/staffs/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var staffData = parsed['data'];

        List<Map<String, dynamic>> stafflist = [];

        for (var staff in staffData) {
          stafflist.add({
            'id': staff['id'],
            'name': staff['name'],
            'email': staff['email'],
            'department_name': staff['department_name'],
            'designation': staff['designation'],
            'allocated_states': staff['allocated_states'],
            'allocated_states_names': staff['allocated_states_names'],
          });
        }

        if (!mounted) return;

        setState(() {
          staffList = stafflist;
        });
      }
    } catch (e) {
      // print("========== STAFF ERROR: $e");
    }
  }

  // ================= PROFILE -> allocated_states -> load all reports =================
  Future<void> getProfileAllocatedStatesAndLoad() async {
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

        await fetchAndGroupAllAllocatedStatesReport(allocatedStates);
      }
    } catch (e) {
      // print("========== PROFILE ERROR: $e");
    }

    if (!mounted) return;

    setState(() {
      profileLoading = false;
    });
  }

  // ================= FETCH USER FULL REPORT =================
  Future<void> fetchUserFullReport(int userId) async {
    if (selectedMonth == null || selectedYear == null) return;

    try {
      setState(() {
        loading = true;
        searched = true;
        groupedReport = [];
      });

      final token = await gettokenFromPrefs();

      final url =
          "$api/api/daily/sales/report/all/users/?month=$selectedMonth&year=$selectedYear&user_id=$userId";

      var response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        final List<int> dates = List<int>.from(parsed["dates"] ?? []);
        final List users = List.from(parsed["users"] ?? []);

        if (users.isEmpty) {
          setState(() {
            loading = false;
          });
          return;
        }

        final userObj = users[0];

        final int uid = int.tryParse((userObj["user_id"] ?? 0).toString()) ?? 0;
        final String uname = (userObj["user_name"] ?? "").toString();

        List districtsStateWise = List.from(userObj["districts"] ?? []);

        List<Map<String, dynamic>> stateBlocks = [];

        for (final st in districtsStateWise) {
          String stateName = (st["state"] ?? "").toString();
          List districtList = List.from(st["districts"] ?? []);

          // calculate grand total for this state
          int stateGrandTotal = 0;
          Map<String, dynamic> stateColumnTotals = {};

          for (final day in dates) {
            stateColumnTotals[day.toString()] = 0;
          }

          for (final dist in districtList) {
            final Map<String, dynamic> dailyCounts =
                Map<String, dynamic>.from(dist["daily_counts"] ?? {});

            for (final day in dates) {
              int val =
                  int.tryParse((dailyCounts[day.toString()] ?? 0).toString()) ??
                      0;
              stateColumnTotals[day.toString()] =
                  (stateColumnTotals[day.toString()] ?? 0) + val;
            }

            stateGrandTotal +=
                int.tryParse((dist["total"] ?? 0).toString()) ?? 0;
          }

          // create userData structure same as buildUserTable expects
          Map<String, dynamic> userDataForState = {
            "user_id": uid,
            "user_name": uname,
            "districts": [
              {
                "state": stateName,
                "districts": districtList,
              }
            ],
            "column_totals": stateColumnTotals,
            "grand_total": stateGrandTotal,
            "state_summary": List.from(userObj["state_summary"] ?? []),
          };

          // ================= FIX STATE ID MATCH =================
          int stateIdMatch = 0;

          for (final stItem in stateList) {
            if (stItem["name"].toString().toLowerCase() ==
                stateName.toLowerCase()) {
              stateIdMatch = int.tryParse((stItem["id"] ?? 0).toString()) ?? 0;
              break;
            }
          }

          stateBlocks.add({
            "state_id": stateIdMatch,
            "state": stateName,
            "month": parsed["month"] ?? "",
            "dates": dates,
            "userData": userDataForState,
          });
        }

        setState(() {
          groupedReport = [
            {
              "user_id": uid,
              "user_name": uname,
              "states": stateBlocks,
            }
          ];
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

  // ================= FETCH ALL STATES REPORTS & GROUP BY USER =================
  Future<void> fetchAndGroupAllAllocatedStatesReport(
      List allocatedStates) async {
    if (selectedMonth == null || selectedYear == null) return;

    try {
      setState(() {
        loading = true;
        searched = true;
        groupedReport = [];
      });

      final token = await gettokenFromPrefs();

      final Map<int, Map<String, dynamic>> userMap = {};

      for (var stateId in allocatedStates) {
        final url =
            "$api/api/daily/sales/report/all/users/?month=$selectedMonth&year=$selectedYear&state_id=$stateId";

        var response = await http.get(
          Uri.parse(url),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        );

        if (response.statusCode == 200) {
          final parsed = jsonDecode(response.body);

          final String stName = (parsed["state"] ?? "").toString();
          final String mnName = (parsed["month"] ?? "").toString();
          final List<int> stDates = List<int>.from(parsed["dates"] ?? []);
          final List users = List.from(parsed["users"] ?? []);

          for (final u in users) {
            final int uid = int.tryParse((u["user_id"] ?? 0).toString()) ?? 0;
            final String uname = (u["user_name"] ?? "").toString();

            if (uid == 0) continue;

            userMap.putIfAbsent(uid, () {
              return {
                "user_id": uid,
                "user_name": uname,
                "states": <Map<String, dynamic>>[],
              };
            });

            (userMap[uid]!["states"] as List).add({
              "state_id": stateId,
              "state": stName,
              "month": mnName,
              "dates": stDates,
              "userData": u,
            });
          }
        }
      }

      final List<Map<String, dynamic>> result =
          userMap.values.map((e) => Map<String, dynamic>.from(e)).toList();

      result.sort((a, b) => (a["user_name"] ?? "")
          .toString()
          .compareTo((b["user_name"] ?? "").toString()));

      for (final u in result) {
        final List st = List.from(u["states"] ?? []);
        st.sort((a, b) => (a["state"] ?? "")
            .toString()
            .compareTo((b["state"] ?? "").toString()));
        u["states"] = st;
      }

      if (!mounted) return;

      setState(() {
        groupedReport = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  // ================= MONTH LIST =================
  final List<Map<String, dynamic>> monthList = const [
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

  // ================= EXPORT EXCEL (CURRENT VIEW: all users grouped) =================
  Future<void> exportAllUsersExcel() async {
    try {
      List<Map<String, dynamic>> view = selectedUserId == null
          ? groupedReport
          : groupedReport.where((e) => e["user_id"] == selectedUserId).toList();

      if (selectedStateId != null) {
        view = view.map((user) {
          List states = List.from(user["states"] ?? []);

          List filteredStates = states.where((st) {
            return st["state_id"] == selectedStateId;
          }).toList();

          return {
            ...user,
            "states": filteredStates,
          };
        }).toList();
      }

      if (view.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("No data available to export"),
          ),
        );
        return;
      }

      var excel = Excel.createExcel();
      Sheet sheet = excel["All Users Sales Report"];

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

      final summaryHeaderStyle = CellStyle(
        backgroundColorHex: "#02347C",
        fontFamily: getFontFamily(FontFamily.Calibri),
        bold: true,
        fontColorHex: "#FFFFFF",
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final summaryValueStyle = CellStyle(
        backgroundColorHex: "#82E49D",
        fontFamily: getFontFamily(FontFamily.Calibri),
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      int rowIndex = 0;

      String monthText = monthList
          .firstWhere(
            (m) => m["id"] == selectedMonth,
            orElse: () => {"name": ""},
          )["name"]
          .toString();

      // ================= TITLE =================
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        CellIndex.indexByColumnRow(columnIndex: 20, rowIndex: rowIndex),
      );

      final titleCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
      );

      titleCell.value = "DAILY SALES REPORT (DSR) - $monthText $selectedYear";

      titleCell.cellStyle = CellStyle(
        fontFamily: getFontFamily(FontFamily.Calibri),
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      rowIndex += 2;

      // ================= LOOP USERS =================
      for (final user in view) {
        final String userName = (user["user_name"] ?? "").toString();
        final List states = List.from(user["states"] ?? []);

        // USER HEADER
        sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
          CellIndex.indexByColumnRow(columnIndex: 20, rowIndex: rowIndex),
        );

        final userCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        );

        userCell.value = "User: $userName";
        userCell.cellStyle = CellStyle(
          fontFamily: getFontFamily(FontFamily.Calibri),
          bold: true,
          fontSize: 14,
        );

        rowIndex++;

        int userGrandTotalInvoices = 0;
        double userAvgTotal = 0;
        int stateCount = 0;

        List<Map<String, dynamic>> userStateSummary = [];

        // ================= LOOP STATES =================
        for (final st in states) {
          final String stName = (st["state"] ?? "").toString();
          final List<int> dts = List<int>.from(st["dates"] ?? []);
          final Map<String, dynamic> userData =
              Map<String, dynamic>.from(st["userData"] ?? {});

          List summaryList = List.from(userData["state_summary"] ?? []);
          int totalInvoices = userData["grand_total"] ?? 0;

          double avgPerDay = 0;
          if (summaryList.isNotEmpty) {
            avgPerDay = double.tryParse(
                    (summaryList[0]["average_per_day"] ?? 0).toString()) ??
                0;
          }

          userGrandTotalInvoices += totalInvoices;
          userAvgTotal += avgPerDay;
          stateCount++;

          userStateSummary.add({
            "state": stName,
            "total_invoices": totalInvoices,
            "average_per_day": avgPerDay,
          });

          // ================= STATE HEADER =================
          sheet.merge(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
            CellIndex.indexByColumnRow(
                columnIndex: dts.length + 4, rowIndex: rowIndex),
          );

          final stCell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
          );

          stCell.value = "State: $stName";
          stCell.cellStyle = CellStyle(
            fontFamily: getFontFamily(FontFamily.Calibri),
            bold: true,
          );

          rowIndex++;

          List districts = [];
          if (userData["districts"] != null &&
              userData["districts"].length > 0 &&
              userData["districts"][0]["districts"] != null) {
            districts = List.from(userData["districts"][0]["districts"]);
          }

          Map<String, dynamic> columnTotals =
              Map<String, dynamic>.from(userData["column_totals"] ?? {});
          int grandTotal = userData["grand_total"] ?? 0;

          // ================= HEADER ROW =================
          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: 0, rowIndex: rowIndex))
              .value = "Sl No";
          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: 0, rowIndex: rowIndex))
              .cellStyle = headerStyle;

          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: 1, rowIndex: rowIndex))
              .value = "District";
          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: 1, rowIndex: rowIndex))
              .cellStyle = headerStyle;

          // ✅ TOTAL column after District
          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: 2, rowIndex: rowIndex))
              .value = "TOTAL";
          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: 2, rowIndex: rowIndex))
              .cellStyle = headerStyle;

          // Days start from col 3
          int colIndex = 3;
          for (var day in dts) {
            final c = sheet.cell(CellIndex.indexByColumnRow(
                columnIndex: colIndex, rowIndex: rowIndex));
            c.value = day.toString();
            c.cellStyle = headerStyle;
            colIndex++;
          }

          // TOTAL column at end
          final totalHeader = sheet.cell(CellIndex.indexByColumnRow(
              columnIndex: colIndex, rowIndex: rowIndex));
          totalHeader.value = "TOTAL";
          totalHeader.cellStyle = headerStyle;

          rowIndex++;

          // ================= DISTRICT DATA ROWS =================
          for (int i = 0; i < districts.length; i++) {
            final district = districts[i];
            final dailyCounts =
                Map<String, dynamic>.from(district["daily_counts"] ?? {});

            final sNoCell = sheet.cell(
                CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
            sNoCell.value = (i + 1);
            sNoCell.cellStyle = districtStyle;

            final districtCell = sheet.cell(
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
            districtCell.value = district["district"].toString();
            districtCell.cellStyle = districtStyle;

            final totalVal =
                int.tryParse((district["total"] ?? 0).toString()) ?? 0;

            // ✅ TOTAL after district column (0 should be RED)
            final totalAfterDistrictCell = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
            );
            totalAfterDistrictCell.value = totalVal;
            totalAfterDistrictCell.cellStyle =
                totalVal == 0 ? redStyle : totalColStyle;

            // Days start from col 3
            int dayCol = 3;
            for (final day in dts) {
              final val =
                  int.tryParse((dailyCounts[day.toString()] ?? 0).toString()) ??
                      0;

              final cell = sheet.cell(CellIndex.indexByColumnRow(
                  columnIndex: dayCol, rowIndex: rowIndex));
              cell.value = val;

              // ✅ Wherever 0 comes -> RED
              cell.cellStyle = val == 0 ? redStyle : yellowStyle;

              dayCol++;
            }

            // TOTAL at end (0 should be RED)
            final totalCell = sheet.cell(CellIndex.indexByColumnRow(
                columnIndex: dayCol, rowIndex: rowIndex));
            totalCell.value = totalVal;
            totalCell.cellStyle = totalVal == 0 ? redStyle : totalColStyle;

            rowIndex++;
          }

          // ================= TOTAL ROW =================
          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: 1, rowIndex: rowIndex))
              .value = "TOTAL";
          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: 1, rowIndex: rowIndex))
              .cellStyle = bottomTotalStyle;

          // ✅ TOTAL after district in total row (0 should be RED)
          final totalAfterDistrictGrandCell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
          );
          totalAfterDistrictGrandCell.value = grandTotal;
          totalAfterDistrictGrandCell.cellStyle =
              grandTotal == 0 ? redStyle : bottomTotalStyle;

          int totalDayCol = 3;
          for (final day in dts) {
            final totalVal =
                int.tryParse((columnTotals[day.toString()] ?? 0).toString()) ??
                    0;

            final cell = sheet.cell(CellIndex.indexByColumnRow(
                columnIndex: totalDayCol, rowIndex: rowIndex));
            cell.value = totalVal;

            // ✅ if zero -> red else orange
            cell.cellStyle = totalVal == 0 ? redStyle : bottomTotalStyle;

            totalDayCol++;
          }

          // Grand total at end (0 should be RED)
          final grandCell = sheet.cell(CellIndex.indexByColumnRow(
              columnIndex: totalDayCol, rowIndex: rowIndex));
          grandCell.value = grandTotal;
          grandCell.cellStyle = grandTotal == 0 ? redStyle : bottomTotalStyle;

          rowIndex += 2;
        }

        // ================= USER SUMMARY CARD =================
        if (userStateSummary.isNotEmpty) {
          int summaryStartCol = 4;
          int summaryEndCol = summaryStartCol + 3;

          sheet.merge(
            CellIndex.indexByColumnRow(
                columnIndex: summaryStartCol, rowIndex: rowIndex),
            CellIndex.indexByColumnRow(
                columnIndex: summaryEndCol, rowIndex: rowIndex),
          );

          final summaryTitle = sheet.cell(CellIndex.indexByColumnRow(
              columnIndex: summaryStartCol, rowIndex: rowIndex));
          summaryTitle.value = "STATEWISE SUMMARY - $userName";
          summaryTitle.cellStyle = summaryHeaderStyle;

          rowIndex++;

          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: summaryStartCol, rowIndex: rowIndex))
              .value = "State";
          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: summaryStartCol, rowIndex: rowIndex))
              .cellStyle = summaryHeaderStyle;

          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: summaryStartCol + 1, rowIndex: rowIndex))
              .value = "Total Invoices";
          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: summaryStartCol + 1, rowIndex: rowIndex))
              .cellStyle = summaryHeaderStyle;

          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: summaryStartCol + 2, rowIndex: rowIndex))
              .value = "Avg / Day";
          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: summaryStartCol + 2, rowIndex: rowIndex))
              .cellStyle = summaryHeaderStyle;

          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: summaryStartCol + 3, rowIndex: rowIndex))
              .value = "Grand Total";
          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: summaryStartCol + 3, rowIndex: rowIndex))
              .cellStyle = summaryHeaderStyle;

          rowIndex++;

          for (final st in userStateSummary) {
            sheet
                .cell(CellIndex.indexByColumnRow(
                    columnIndex: summaryStartCol, rowIndex: rowIndex))
                .value = st["state"].toString();
            sheet
                .cell(CellIndex.indexByColumnRow(
                    columnIndex: summaryStartCol, rowIndex: rowIndex))
                .cellStyle = summaryValueStyle;

            sheet
                .cell(CellIndex.indexByColumnRow(
                    columnIndex: summaryStartCol + 1, rowIndex: rowIndex))
                .value = st["total_invoices"];
            sheet
                .cell(CellIndex.indexByColumnRow(
                    columnIndex: summaryStartCol + 1, rowIndex: rowIndex))
                .cellStyle = summaryValueStyle;

            sheet
                    .cell(CellIndex.indexByColumnRow(
                        columnIndex: summaryStartCol + 2, rowIndex: rowIndex))
                    .value =
                double.tryParse((st["average_per_day"] ?? 0).toString())
                        ?.toStringAsFixed(2) ??
                    "0.00";
            sheet
                .cell(CellIndex.indexByColumnRow(
                    columnIndex: summaryStartCol + 2, rowIndex: rowIndex))
                .cellStyle = summaryValueStyle;

            sheet
                .cell(CellIndex.indexByColumnRow(
                    columnIndex: summaryStartCol + 3, rowIndex: rowIndex))
                .value = st["total_invoices"];
            sheet
                .cell(CellIndex.indexByColumnRow(
                    columnIndex: summaryStartCol + 3, rowIndex: rowIndex))
                .cellStyle = summaryValueStyle;

            rowIndex++;
          }

          double finalAvg = stateCount == 0 ? 0 : (userAvgTotal / stateCount);

          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: summaryStartCol, rowIndex: rowIndex))
              .value = "TOTAL";
          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: summaryStartCol, rowIndex: rowIndex))
              .cellStyle = bottomTotalStyle;

          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: summaryStartCol + 1, rowIndex: rowIndex))
              .value = userGrandTotalInvoices;
          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: summaryStartCol + 1, rowIndex: rowIndex))
              .cellStyle = bottomTotalStyle;

          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: summaryStartCol + 2, rowIndex: rowIndex))
              .value = finalAvg.toStringAsFixed(2);
          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: summaryStartCol + 2, rowIndex: rowIndex))
              .cellStyle = bottomTotalStyle;

          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: summaryStartCol + 3, rowIndex: rowIndex))
              .value = userGrandTotalInvoices;
          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: summaryStartCol + 3, rowIndex: rowIndex))
              .cellStyle = bottomTotalStyle;

          rowIndex += 3;
        }

        rowIndex += 1;
      }

      final fileBytes = excel.encode();
      if (fileBytes == null) return;

      final dir = await getApplicationDocumentsDirectory();

      final filePath =
          '${dir.path}/AllUsersDailySalesReport_${DateTime.now().millisecondsSinceEpoch}.xlsx';

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
        text: "📊 User Daily Sales Report",
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

  // ================= UI TABLE WIDGET (STATE-LEVEL: MUST PASS dates) =================
  Widget buildUserTable(Map<String, dynamic> userData, List<int> localDates) {
    List districts = [];

    if (userData["districts"] != null &&
        userData["districts"].length > 0 &&
        userData["districts"][0]["districts"] != null) {
      districts = List.from(userData["districts"][0]["districts"]);
    }

    Map<String, dynamic> columnTotals =
        Map<String, dynamic>.from(userData["column_totals"] ?? {});
    int grandTotal = userData["grand_total"] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          color: Colors.white,
          child: Table(
            border: TableBorder.all(
              color: const Color.fromARGB(255, 214, 213, 213),
            ),
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
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(6.0),
                    child: Text(
                      "District",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  ...localDates.map((d) {
                    return Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        d.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    );
                  }).toList(),
                  const Padding(
                    padding: EdgeInsets.all(6.0),
                    child: Text(
                      "Total",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
              for (int i = 0; i < districts.length; i++)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text((i + 1).toString()),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        districts[i]["district"].toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    ...localDates.map((day) {
                      Map<String, dynamic> dailyCounts =
                          Map<String, dynamic>.from(
                              districts[i]["daily_counts"] ?? {});

                      int value = int.tryParse(
                              (dailyCounts[day.toString()] ?? 0).toString()) ??
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
                        districts[i]["total"].toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
                  ...localDates.map((day) {
                    return Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        (columnTotals[day.toString()] ?? 0).toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }).toList(),
                  Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Text(
                      grandTotal.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> viewList = selectedUserId == null
        ? groupedReport
        : groupedReport.where((e) => e["user_id"] == selectedUserId).toList();

    if (selectedStateId != null) {
      viewList = viewList.map((user) {
        List states = List.from(user["states"] ?? []);

        List filteredStates = states.where((st) {
          return st["state_id"] == selectedStateId;
        }).toList();

        return {
          ...user,
          "states": filteredStates,
        };
      }).toList();
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(242, 255, 255, 255),
      appBar: AppBar(
        title: const Text(
          "All Users Daily Sales Report",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.only(right: 10, top: 10, left: 10),
              child: Container(
                width: 600,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 34, 165, 246),
                  border: Border.all(
                      color: const Color.fromARGB(255, 202, 202, 202)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      "ALL USERS DAILY SALES REPORT",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "${monthList.firstWhere((m) => m["id"] == selectedMonth, orElse: () => {
                            "name": ""
                          })["name"]} - $selectedYear",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 13),
                  ],
                ),
              ),
            ),
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
                      DropdownSearch<Map<String, dynamic>>(
                        items: staffList,
                        itemAsString: (item) => item?["name"] ?? "",
                        selectedItem: selectedUserId == null
                            ? null
                            : staffList.firstWhere(
                                (e) => e["id"] == selectedUserId,
                                orElse: () => {},
                              ),
                        popupProps: const PopupProps.menu(
                          showSearchBox: true,
                          searchFieldProps: TextFieldProps(
                            decoration: InputDecoration(
                              hintText: "Search user...",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            labelText: "Select User",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            selectedUserId = value?["id"];
                            selectedStateId = null;
                            stateList = [];
                          });

                          if (value != null) {
                            List allocatedIds =
                                List.from(value["allocated_states"] ?? []);
                            List allocatedNames = List.from(
                                value["allocated_states_names"] ?? []);

                            List<Map<String, dynamic>> filteredStates = [];

                            for (int i = 0; i < allocatedIds.length; i++) {
                              filteredStates.add({
                                "id": allocatedIds[i],
                                "name": allocatedNames.length > i
                                    ? allocatedNames[i]
                                    : allocatedIds[i].toString(),
                              });
                            }

                            setState(() {
                              stateList = filteredStates;
                            });
                          }
                        },
                        clearButtonProps:
                            const ClearButtonProps(isVisible: true),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: selectedStateId,
                        decoration: InputDecoration(
                          labelText: "Select State",
                          labelStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: stateList.map((item) {
                          return DropdownMenuItem<int>(
                            value: item["id"],
                            child: Text(item["name"].toString()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedStateId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
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
                            value: item["id"] as int,
                            child: Text(item["name"].toString()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedMonth = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
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
                              onPressed: () async {
                                if (selectedUserId != null) {
                                  await fetchUserFullReport(selectedUserId!);
                                } else {
                                  await getProfileAllocatedStatesAndLoad();
                                }
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
            if (profileLoading || loading)
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
                    onPressed: exportAllUsersExcel,
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
            if (!loading && viewList.isNotEmpty) ...[
              for (final user in viewList) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 15, right: 15, top: 12),
                  child: Text(
                    "User: ${user["user_name"]}",
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 6),
                for (final st in List.from(user["states"] ?? [])) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 15, right: 15, top: 8),
                    child: Text(
                      "${st["state"] ?? ""}  (Total: ${(st["userData"]?["grand_total"] ?? 0)})",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  buildUserTable(
                    Map<String, dynamic>.from(st["userData"] ?? {}),
                    List<int>.from(st["dates"] ?? []),
                  ),
                ],
                const Divider(thickness: 1),
                const SizedBox(height: 10),
              ]
            ],
            if (searched && !loading && viewList.isEmpty)
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
