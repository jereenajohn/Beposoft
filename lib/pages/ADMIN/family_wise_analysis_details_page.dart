import 'dart:convert';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FamilyWiseAnalysisDetailsPage extends StatefulWidget {
  final int familyId;
  final String familyName;
  final DateTime? startDate;
  final DateTime? endDate;

  const FamilyWiseAnalysisDetailsPage({
    super.key,
    required this.familyId,
    required this.familyName,
    this.startDate,
    this.endDate,
  });

  @override
  State<FamilyWiseAnalysisDetailsPage> createState() =>
      _FamilyWiseAnalysisDetailsPageState();
}

class _FamilyWiseAnalysisDetailsPageState
    extends State<FamilyWiseAnalysisDetailsPage> {
  List<Map<String, dynamic>> staffList = [];
  bool isStaffLoading = false;
  bool showAllStaff = false;
  DateTime selectedStaffDate = DateTime.now();

  List<Map<String, dynamic>> staffSummaryList = [];
  Map<String, dynamic> familySummary = {};
  bool isSummaryLoading = false;
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  Future<String?> getTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  void initState() {
    super.initState();
    selectedStartDate = widget.startDate ?? DateTime.now();
    selectedEndDate = widget.endDate ?? DateTime.now();
    selectedStaffDate = widget.startDate ?? DateTime.now();
    fetchFamilyStaffSummary();
    fetchStaffAttendance();
  }

  Future<void> fetchFamilyStaffSummary() async {
    final token = await getTokenFromPrefs();
    if (token == null) return;

    setState(() {
      isSummaryLoading = true;
    });

    try {
      final Map<String, String> queryParams = {};

      if (selectedStartDate != null) {
        queryParams['from_date'] =
            DateFormat('yyyy-MM-dd').format(selectedStartDate!);
      }
      if (selectedEndDate != null) {
        queryParams['to_date'] =
            DateFormat('yyyy-MM-dd').format(selectedEndDate!);
      }

      final uri = Uri.parse(
              '$api/api/family/analysis/staff/summary/${widget.familyId}/')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("FAMILY STAFF SUMMARY URL: $uri");
      print("FAMILY STAFF SUMMARY STATUS: ${response.statusCode}");
      print("FAMILY STAFF SUMMARY BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        setState(() {
          familySummary = Map<String, dynamic>.from(decoded['summary'] ?? {});
          staffSummaryList = List<Map<String, dynamic>>.from(
            (decoded['results'] ?? []).map((e) => Map<String, dynamic>.from(e)),
          );
          isSummaryLoading = false;
        });
      } else {
        setState(() {
          familySummary = {};
          staffSummaryList = [];
          isSummaryLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        familySummary = {};
        staffSummaryList = [];
        isSummaryLoading = false;
      });
      print("FAMILY STAFF SUMMARY ERROR: $e");
    }
  }

  Future<void> fetchStaffAttendance() async {
    try {
      setState(() {
        isStaffLoading = true;
      });

      final token = await getTokenFromPrefs();
      if (token == null) {
        setState(() {
          isStaffLoading = false;
        });
        return;
      }

      final date = DateFormat('yyyy-MM-dd').format(selectedStaffDate);

      final uri = Uri.parse(
        '$api/api/bdm/order/analysis/staff/filter/?start_date=$date&end_date=$date&family_id=${widget.familyId}',
      );

      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("FAMILY STAFF ATTENDANCE URL: $uri");
      print("FAMILY STAFF ATTENDANCE STATUS: ${response.statusCode}");
      print("FAMILY STAFF ATTENDANCE BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List data = decoded["data"] ?? [];

        final Map<int, Map<String, dynamic>> uniqueStaff = {};
        for (final item in data) {
          uniqueStaff[item["staff_id"]] = Map<String, dynamic>.from(item);
        }

        setState(() {
          staffList = uniqueStaff.values.toList();
          isStaffLoading = false;
        });
      } else {
        setState(() {
          staffList = [];
          isStaffLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        staffList = [];
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

  Widget _summaryTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
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

  Widget _buildTopSummaryCard() {
    final dateText =
        "${DateFormat('yyyy-MM-dd').format(selectedStartDate ?? DateTime.now())} to ${DateFormat('yyyy-MM-dd').format(selectedEndDate ?? DateTime.now())}";

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
            child: Text(
              "${widget.familyName.toUpperCase()} SUMMARY",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                dateText,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
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
                      child: _summaryTile(
                        "Present",
                        "${familySummary['present'] ?? 0}",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _summaryTile(
                        "Absent",
                        "${familySummary['absent'] ?? 0}",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _summaryTile(
                        "Half Day",
                        "${familySummary['half_day'] ?? 0}",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _summaryTile(
                        "Amount",
                        "₹${familySummary['total_amount'] ?? 0}",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _summaryTile(
                        "Invoices",
                        "${familySummary['total_invoices'] ?? 0}",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _summaryTile(
                        "Total Calls",
                        "${familySummary['total_call_count'] ?? 0}",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _summaryTile(
                        "Call Duration",
                        "${familySummary['total_call_duration'] ?? 0}",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _summaryTile(
                        "Avg Duration",
                        "${familySummary['call_duration_average_minutes'] ?? 0}",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _summaryTile(
                        "8hr %",
                        "${familySummary['call_duration_average_percentage_8hrs'] ?? 0}%",
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffAttendanceCard() {
    final maxLength = presentStaff.length > absentStaff.length
        ? presentStaff.length
        : absentStaff.length;

    final visibleLength =
        showAllStaff ? maxLength : (maxLength > 3 ? 3 : maxLength);

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
                Text(
                  "${widget.familyName.toUpperCase()} Staff Attendance",
                  style: const TextStyle(
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
                      await fetchStaffAttendance();
                    }
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('dd MMM yyyy').format(selectedStaffDate),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isStaffLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            )
          else
            Column(
              children: [
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
        ],
      ),
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> staff) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (staff['staff_name'] ?? '').toString().toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (staff['department'] ?? '').toString(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
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
              0: FlexColumnWidth(2.2),
              1: FlexColumnWidth(1.4),
            },
            children: [
              _tableRow("Present", "${staff['present'] ?? 0}"),
              _tableRow("Absent", "${staff['absent'] ?? 0}"),
              _tableRow("Half Day", "${staff['half_day'] ?? 0}"),
              _tableRow("Amount", "₹${staff['total_amount'] ?? 0}"),
              _tableRow("Invoices", "${staff['total_invoices'] ?? 0}"),
              _tableRow("Total Calls", "${staff['total_call_count'] ?? 0}"),
              _tableRow(
                  "Call Duration", "${staff['total_call_duration'] ?? 0}"),
              _tableRow(
                "Avg Duration",
                "${staff['call_duration_average_minutes'] ?? 0}",
              ),
              _tableRow(
                "8hr %",
                "${staff['call_duration_average_percentage_8hrs'] ?? 0}%",
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text("${widget.familyName} Details"),
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
              );

              if (pickedRange != null) {
                setState(() {
                  selectedStartDate = pickedRange.start;
                  selectedEndDate = pickedRange.end;
                });

                await fetchFamilyStaffSummary();
              }
            },
          ),
        ],
      ),
      body: isSummaryLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildStaffAttendanceCard(),
                _buildTopSummaryCard(),
                
                ...staffSummaryList.map((staff) => _buildStaffCard(staff)),
              ],
            ),
    );
  }
}
