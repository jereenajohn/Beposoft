import 'dart:convert';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HrTeamAttendanceScreen extends StatefulWidget {
  const HrTeamAttendanceScreen({super.key});

  @override
  State<HrTeamAttendanceScreen> createState() => _HrTeamAttendanceScreenState();
}

class _HrTeamAttendanceScreenState extends State<HrTeamAttendanceScreen> {
  List<Map<String, dynamic>> teams = [];

  bool isLoading = false;

  DateTime selectedDate = DateTime.now();

  String get formattedSelectedDate {
    return selectedDate.toIso8601String().split('T').first;
  }

  Future<String?> getTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  void initState() {
    super.initState();
    getAllAttendance();
  }

  Future<void> getAllAttendance() async {
    try {
      setState(() {
        isLoading = true;
      });

      final token = await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/staff/attendance/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("HR ATTENDANCE STATUS: ${response.statusCode}");
      debugPrint("HR ATTENDANCE RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final results = parsed['results'];
        final List data =
            results != null ? List.from(results['data'] ?? []) : [];

        setState(() {
          teams = data.map<Map<String, dynamic>>((team) {
            return {
              'team_id': team['team_id'],
              'team_name': team['team_name'] ?? '',
              'team_leader': team['team_leader'],
              'team_leader_name': team['team_leader_name'] ?? '',
              'members_count': team['members_count'] ?? 0,
              'date_wise_attendance':
                  List.from(team['date_wise_attendance'] ?? []),
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("HR attendance fetch error: $e");
      showMsg("Failed to fetch attendance");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic>? getSelectedDateAttendance(Map<String, dynamic> team) {
    final List dateWiseAttendance =
        List.from(team['date_wise_attendance'] ?? []);

    try {
      return dateWiseAttendance.firstWhere(
        (dateItem) => dateItem['attendance_date'] == formattedSelectedDate,
        orElse: () => null,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> pickAttendanceDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  String getStatusLabel(String status) {
    switch (status) {
      case 'present':
        return 'Present';
      case 'absent':
        return 'Absent';
      case 'half_day':
        return 'Half Day';
      default:
        return status;
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'present':
        return const Color(0xff16a34a);
      case 'absent':
        return const Color(0xffdc2626);
      case 'half_day':
        return const Color(0xfff59e0b);
      default:
        return const Color(0xff64748b);
    }
  }

  int get totalPresent {
    int count = 0;

    for (final team in teams) {
      final selected = getSelectedDateAttendance(team);
      count += int.tryParse('${selected?['present_count'] ?? 0}') ?? 0;
    }

    return count;
  }

  int get totalAbsent {
    int count = 0;

    for (final team in teams) {
      final selected = getSelectedDateAttendance(team);
      count += int.tryParse('${selected?['absent_count'] ?? 0}') ?? 0;
    }

    return count;
  }

  int get totalHalfDay {
    int count = 0;

    for (final team in teams) {
      final selected = getSelectedDateAttendance(team);
      count += int.tryParse('${selected?['half_day_count'] ?? 0}') ?? 0;
    }

    return count;
  }

  int get totalMarked {
    int count = 0;

    for (final team in teams) {
      final selected = getSelectedDateAttendance(team);
      count += int.tryParse('${selected?['total_count'] ?? 0}') ?? 0;
    }

    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef3f9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          "HR Attendance",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: pickAttendanceDate,
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          IconButton(
            onPressed: getAllAttendance,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: getAllAttendance,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // _buildSummaryCard(),
              const SizedBox(height: 14),
              isLoading
                  ? const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : teams.isEmpty
                      ? _buildEmptyCard("No attendance data found")
                      : Column(
                          children: teams.map<Widget>((team) {
                            return _buildTeamAttendanceCard(team);
                          }).toList(),
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xff2563eb),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Attendance Summary",
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: Colors.white70,
                size: 17,
              ),
              const SizedBox(width: 6),
              Text(
                formattedSelectedDate,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildSummaryTile("Marked", "$totalMarked"),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryTile("Present", "$totalPresent"),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSummaryTile("Absent", "$totalAbsent"),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryTile("Half Day", "$totalHalfDay"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamAttendanceCard(Map<String, dynamic> team) {
    final selectedAttendance = getSelectedDateAttendance(team);

    final List attendanceList = selectedAttendance == null
        ? []
        : List.from(selectedAttendance['attendance'] ?? []);

    final int presentCount =
        int.tryParse('${selectedAttendance?['present_count'] ?? 0}') ?? 0;
    final int absentCount =
        int.tryParse('${selectedAttendance?['absent_count'] ?? 0}') ?? 0;
    final int halfDayCount =
        int.tryParse('${selectedAttendance?['half_day_count'] ?? 0}') ?? 0;
    final int totalCount =
        int.tryParse('${selectedAttendance?['total_count'] ?? 0}') ?? 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xffeff6ff),
                child: Icon(
                  Icons.groups_outlined,
                  color: Color(0xff2563eb),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  team['team_name'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xff111827),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffdbeafe),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${team['members_count']} Members",
                  style: const TextStyle(
                    color: Color(0xff1d4ed8),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xfff8fafc),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_pin_outlined,
                  size: 18,
                  color: Color(0xff64748b),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Leader: ${team['team_leader_name'] ?? ''}",
                    style: const TextStyle(
                      color: Color(0xff334155),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildCountChip("Present", presentCount)),
              const SizedBox(width: 6),
              Expanded(child: _buildCountChip("Absent", absentCount)),
              const SizedBox(width: 6),
              Expanded(child: _buildCountChip("Half", halfDayCount)),
              const SizedBox(width: 6),
              Expanded(child: _buildCountChip("Total", totalCount)),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Members Attendance",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xff111827),
            ),
          ),
          const SizedBox(height: 8),
          attendanceList.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    "No attendance found for selected date",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : Column(
                  children: attendanceList.map<Widget>((attendance) {
                    return _buildMemberAttendanceTile(attendance);
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildCountChip(String title, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: Column(
        children: [
          Text(
            "$count",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xff111827),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xff64748b),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberAttendanceTile(Map<String, dynamic> attendance) {
    final status = attendance['status'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 17,
            backgroundColor: Color(0xffeff6ff),
            child: Icon(
              Icons.person_outline,
              size: 18,
              color: Color(0xff2563eb),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attendance['staff_name'] ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff111827),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Time: ${attendance['attendance_time'] ?? '-'}",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff64748b),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: getStatusColor(status).withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              getStatusLabel(status),
              style: TextStyle(
                color: getStatusColor(status),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_busy_outlined,
            color: Colors.grey,
            size: 46,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
