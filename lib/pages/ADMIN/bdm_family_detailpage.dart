import 'dart:convert';
import 'dart:ui';

import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BdmFamilyDetailsPage extends StatefulWidget {
  final Map<String, dynamic> familyData;
  final DateTime? startDate;
  final DateTime? endDate;

  const BdmFamilyDetailsPage({
    super.key,
    required this.familyData,
    this.startDate,
    this.endDate,
  });

  @override
  State<BdmFamilyDetailsPage> createState() => _BdmFamilyDetailsPageState();
}

class _BdmFamilyDetailsPageState extends State<BdmFamilyDetailsPage> {
  List<Map<String, dynamic>> bdmList = [];
  bool isLoading = false;
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  bool showAllStaff = false;

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  void initState() {
    super.initState();
    selectedStartDate = widget.startDate ?? DateTime.now();
    selectedEndDate = widget.endDate ?? DateTime.now();
    bdmList =
        List<Map<String, dynamic>>.from(widget.familyData['bdm_data'] ?? []);
    fetchStaffData();
  }

  Future<void> fetchBdmFamilyDetails() async {
    final token = await getTokenFromPrefs();
    if (token == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final String start = DateFormat('yyyy-MM-dd').format(selectedStartDate!);
      final String end = DateFormat('yyyy-MM-dd').format(selectedEndDate!);

      final uri = Uri.parse('$api/api/bdm/daily/overall/report/').replace(
        queryParameters: {
          'start_date': start,
          'end_date': end,
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List reportDates = decoded['results']?['data'] ?? [];

        Map<String, dynamic>? matchedFamily;

        for (final report in reportDates) {
          if (report is Map<String, dynamic>) {
            final List families = report['family_data'] ?? [];
            for (final family in families) {
              if ((family['family_id'] ?? 0) ==
                  (widget.familyData['family_id'] ?? 0)) {
                matchedFamily = Map<String, dynamic>.from(family);
                break;
              }
            }
          }
          if (matchedFamily != null) break;
        }

        setState(() {
          bdmList = matchedFamily != null
              ? List<Map<String, dynamic>>.from(
                  (matchedFamily!['bdm_data'] ?? [])
                      .map((e) => Map<String, dynamic>.from(e)),
                )
              : [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  DateTime selectedStaffDate = DateTime.now();

  List<Map<String, dynamic>> staffList = [];
  bool isStaffLoading = false;

  Future<void> fetchStaffData() async {
    try {
      setState(() {
        isStaffLoading = true;
      });

      final token = await getTokenFromPrefs();
      final familyId = widget.familyData['family_id'];
      final date = DateFormat('yyyy-MM-dd').format(selectedStaffDate);

      final url =
          "$api/api/bdm/order/analysis/staff/filter/?start_date=$date&end_date=$date&family_id=$familyId";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("STAFF STATUS: ${response.statusCode}");
      print("STAFF BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final List data = decoded["data"] ?? [];


        final todayData = data; 

        final Map<int, Map<String, dynamic>> uniqueStaff = {};

        for (var item in todayData) {
          uniqueStaff[item["staff_id"]] = item;
        }

        final staffFinalList = uniqueStaff.values.toList();

        setState(() {
          staffList = staffFinalList;
          isStaffLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isStaffLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get presentStaff => staffList.where((e) {
        final status = (e["status"] ?? "").toString().toLowerCase();
        return status == "present" || status == "half_day";
      }).toList();

  List<Map<String, dynamic>> get absentStaff => staffList.where((e) {
        final status = (e["status"] ?? "").toString().toLowerCase();
        return status == "absent";
      }).toList();

  Widget _buildStaffAttendanceCard() {
    int maxLength = presentStaff.length > absentStaff.length
        ? presentStaff.length
        : absentStaff.length;

    int visibleLength =
        showAllStaff ? maxLength : (maxLength > 3 ? 3 : maxLength);

    List<TableRow> rows = [];

    rows.add(
      const TableRow(
        decoration: BoxDecoration(color: Color(0xFFF2F2F2)),
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              "Active BDO",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              "Non Active BDO",
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
              style: const TextStyle(color: Colors.green),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              "${absentStaff.length}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    for (int i = 0; i < visibleLength; i++) {
      final activeName =
          i < presentStaff.length ? presentStaff[i]["staff_name"] ?? "" : "";
      final absentName =
          i < absentStaff.length ? absentStaff[i]["staff_name"] ?? "" : "";

      rows.add(
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: i < presentStaff.length
                  ? Row(
                      children: [
                        Expanded(
                          child: Text(
                            activeName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (presentStaff[i]["status"] == "half_day")
                                ? Colors.orange.withOpacity(0.15)
                                : Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (presentStaff[i]["status"] ?? "")
                                .toString()
                                .replaceAll("_", " ")
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: (presentStaff[i]["status"] == "half_day")
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox(),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(absentName),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
              gradient: LinearGradient(
                colors: [Color(0xFF1F4E8C), Color(0xFF4CD17B)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Staff Attendance",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedStaffDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );

                    if (picked != null) {
                      setState(() {
                        selectedStaffDate = picked;
                        showAllStaff = false; 
                      });

                      await fetchStaffData();
                    }
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('dd MMM').format(selectedStaffDate),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Table(
            border: TableBorder.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(2),
            },
            children: rows,
          ),

          if (maxLength > 3)
            InkWell(
              onTap: () {
                setState(() {
                  showAllStaff = !showAllStaff;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    showAllStaff ? "See Less" : "See More",
                    style: const TextStyle(
                      color: Color(0xFF1F4E8C),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> currentBdmList = bdmList;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text("${widget.familyData['family_name']} BDM List"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final pickedRange = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDateRange: DateTimeRange(
                  start: selectedStartDate ?? DateTime.now(),
                  end: selectedEndDate ?? DateTime.now(),
                ),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.light().copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF1F4E8C), 
                        onPrimary: Colors.white,
                        onSurface: Colors.black,
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (pickedRange != null) {
                setState(() {
                  selectedStartDate = pickedRange.start;
                  selectedEndDate = pickedRange.end;
                  showAllStaff = false; 
                });

                await fetchBdmFamilyDetails();
                await fetchStaffData();
              }
            },
          ),
        ],
      ),
      body: currentBdmList.isEmpty
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const Center(
                    child: Text("No BDM data available"),
                  ),
                  const SizedBox(height: 16),
                  _buildFamilySummaryCard(),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildStaffAttendanceCard(),
                ...currentBdmList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final bdm = entry.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(18),
                              topRight: Radius.circular(18),
                            ),
                            gradient: LinearGradient(
                              colors: [Color(0xFF1F4E8C), Color(0xFF4CD17B)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                          child: Text(
                            (bdm['bdm_name'] ?? '').toString().toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Table(
                          border: TableBorder.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                          columnWidths: const {
                            0: FlexColumnWidth(2.4),
                            1: FlexColumnWidth(1.6),
                          },
                          children: [
                            _tableRow(
                                "Total Bill", "${bdm['total_bill'] ?? 0}"),
                            _tableRow(
                              "Total Call Duration",
                              "${bdm['total_call_duration'] ?? '00:00:00'}",
                            ),
                            _tableRow(
                              "Average Call Duration Minutes",
                              "${bdm['average_call_duration_minutes'] ?? 0}",
                            ),
                            _tableRow(
                              "Percentage",
                              "${bdm['call_duration_average'] ?? 0}%",
                            ),
                            _tableRow(
                              "Total Volume",
                              "₹${bdm['total_volume'] ?? 0}",
                              isGreen: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 8),
                _buildFamilySummaryCard(),
              ],
            ),
    );
  }

  Widget _buildFamilySummaryCard() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
              gradient: LinearGradient(
                colors: [Color(0xFF02347C), Color(0xFF82E49D)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Text(
              "${widget.familyData['family_name']} SUMMARY",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                "${DateFormat('yyyy-MM-dd').format(selectedStartDate!)} to ${DateFormat('yyyy-MM-dd').format(selectedEndDate!)}",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
          Table(
            border: TableBorder.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
            columnWidths: const {
              0: FlexColumnWidth(2.4),
              1: FlexColumnWidth(1.6),
            },
            children: [
              _tableRow(
                "Active BDO",
                "${widget.familyData['bdo_present_count'] ?? 0}",
              ),
              _tableRow(
                "Non-Active BDO",
                "${widget.familyData['bdo_absent_count'] ?? 0}",
              ),
              _tableRow(
                "Total Bill",
                "${widget.familyData['total_bill'] ?? 0}",
              ),
              _tableRow(
                "Total Call Duration",
                "${widget.familyData['total_call_duration'] ?? '00:00:00'}",
              ),
              _tableRow(
                "Average Call Duration Minutes",
                "${widget.familyData['average_call_duration_minutes'] ?? 0}",
              ),
              _tableRow(
                "Percentage",
                "${widget.familyData['call_duration_average'] ?? 0}%",
              ),
              _tableRow(
                "Total Volume",
                "₹${widget.familyData['total_volume'] ?? 0}",
                isGreen: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _tableRow(String field, String value, {bool isGreen = false}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            field,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isGreen ? Colors.green : Colors.black87,
              fontWeight: isGreen ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
