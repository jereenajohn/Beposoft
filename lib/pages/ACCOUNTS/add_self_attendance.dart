import 'dart:convert';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StaffSelfAttendanceScreen extends StatefulWidget {
  const StaffSelfAttendanceScreen({super.key});

  @override
  State<StaffSelfAttendanceScreen> createState() =>
      _StaffSelfAttendanceScreenState();
}

class _StaffSelfAttendanceScreenState extends State<StaffSelfAttendanceScreen> {
  List<Map<String, dynamic>> selectedDateAttendance = [];

  String? currentStaffId;
  String currentStaffName = '';
  String currentTeamName = '';
  String currentTeamLeaderName = '';

  String selectedStatus = 'present';
  int? editingAttendanceId;

  bool isLoading = false;
  bool isSaving = false;
  bool isProfileLoading = false;

  final TextEditingController attendanceTimeController =
      TextEditingController();

  DateTime attendanceViewDate = DateTime.now();

  String get todayDate => DateTime.now().toIso8601String().split('T').first;

  String get formattedAttendanceViewDate =>
      attendanceViewDate.toIso8601String().split('T').first;

  Future<String?> getTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  void initState() {
    super.initState();
    refreshAll();
  }

  @override
  void dispose() {
    attendanceTimeController.dispose();
    super.dispose();
  }

  Future<void> refreshAll() async {
    await getProfile();
    await getMyAttendance();
  }

  Future<void> getProfile() async {
    try {
      setState(() => isProfileLoading = true);

      final token = await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("PROFILE STATUS: ${response.statusCode}");
      debugPrint("PROFILE RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final data = parsed['data'] ?? {};

        final rawStaffId = data['id'];

        if (rawStaffId == null || int.tryParse(rawStaffId.toString()) == null) {
          showMsg("Valid staff id not found in profile");
          return;
        }

        setState(() {
          currentStaffId = rawStaffId.toString();

          currentStaffName = data['name']?.toString() ??
              data['staff_name']?.toString() ??
              data['username']?.toString() ??
              '';

          currentTeamName = data['team_name']?.toString() ?? '';
          currentTeamLeaderName = data['team_leader_name']?.toString() ?? '';
        });

        debugPrint("CURRENT STAFF ID: $currentStaffId");
      } else {
        showMsg("Failed to fetch profile");
      }
    } catch (e) {
      debugPrint("PROFILE ERROR: $e");
      showMsg("Failed to fetch profile");
    } finally {
      if (mounted) {
        setState(() => isProfileLoading = false);
      }
    }
  }

  Future<void> getMyAttendance() async {
    try {
      setState(() => isLoading = true);

      final token = await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/staff/attendance/my/details/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("MY ATTENDANCE STATUS: ${response.statusCode}");
      debugPrint("MY ATTENDANCE RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        final List data = List.from(parsed['data'] ?? []);

        final List<Map<String, dynamic>> attendanceList = [];

        for (final attendance in data) {
          if (attendance['attendance_date'] == formattedAttendanceViewDate) {
            attendanceList.add({
              'id': attendance['id'],
              'staff': attendance['staff'],
              'staff_name': attendance['staff_name'] ?? '',
              'attendance_date': attendance['attendance_date'],
              'attendance_time': attendance['attendance_time'],
              'status': attendance['status'],
              'approval_status': attendance['approval_status'],
              'submitted_by': attendance['submitted_by'],
              'submitted_by_name': attendance['submitted_by_name'],
              'approved_by': attendance['approved_by'],
              'approved_by_name': attendance['approved_by_name'],
              'manager_note': attendance['manager_note'],
              'team_id': null,
              'team_name': '',
              'team_leader_name': '',
            });
          }
        }

        setState(() {
          selectedDateAttendance = attendanceList;

          if (selectedDateAttendance.isNotEmpty) {
            currentStaffName =
                selectedDateAttendance.first['staff_name']?.toString() ?? '';
          }
        });
      } else {
        showMsg("Failed to fetch attendance");
      }
    } catch (e) {
      debugPrint("Fetch self attendance error: $e");
      showMsg("Failed to fetch attendance");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> markAttendance() async {
    if (currentStaffId == null) {
      showMsg("Profile staff id not found");
      return;
    }

    if (attendanceTimeController.text.trim().isEmpty) {
      showMsg("Choose reporting time");
      return;
    }

    final alreadyMarked = selectedDateAttendance.any(
      (attendance) =>
          attendance['staff'].toString() == currentStaffId &&
          attendance['attendance_date'] == todayDate,
    );

    if (alreadyMarked) {
      showMsg("Your attendance is already marked for today");
      return;
    }

    try {
      setState(() => isSaving = true);

      final token = await getTokenFromPrefs();

      final body = {
        "staff": currentStaffId,
        "attendance_date": todayDate,
        "attendance_time": attendanceTimeController.text.trim(),
        "status": selectedStatus,
      };

      final response = await http.post(
        Uri.parse('$api/api/staff/attendance/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint("MARK ATTENDANCE STATUS: ${response.statusCode}");
      debugPrint("MARK ATTENDANCE RESPONSE: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        showMsg("Attendance marked successfully");

        setState(() {
          selectedStatus = 'present';
          editingAttendanceId = null;
          attendanceViewDate = DateTime.now();
          attendanceTimeController.clear();
        });

        await getMyAttendance();
      } else if (response.statusCode == 400) {
        final parsed = jsonDecode(response.body);

        showMsg(
          parsed['message']?.toString() ??
              parsed['errors']?.toString() ??
              "Attendance already marked",
        );
      } else {
        showMsg("Failed: ${response.body}");
      }
    } catch (e) {
      debugPrint("Mark attendance error: $e");
      showMsg("Failed to mark attendance");
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> updateAttendance() async {
    if (editingAttendanceId == null) {
      showMsg("Select attendance to update");
      return;
    }

    if (currentStaffId == null) {
      showMsg("Profile staff id not found");
      return;
    }

    if (attendanceTimeController.text.trim().isEmpty) {
      showMsg("Choose reporting time");
      return;
    }

    try {
      setState(() => isSaving = true);

      final token = await getTokenFromPrefs();

      final body = {
        "staff": currentStaffId,
        "attendance_date": todayDate,
        "attendance_time": attendanceTimeController.text.trim(),
        "status": selectedStatus,
      };

      final response = await http.put(
        Uri.parse('$api/api/staff/attendance/edit/$editingAttendanceId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint("UPDATE ATTENDANCE STATUS: ${response.statusCode}");
      debugPrint("UPDATE ATTENDANCE RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        showMsg("Attendance updated successfully");

        setState(() {
          selectedStatus = 'present';
          editingAttendanceId = null;
          attendanceViewDate = DateTime.now();
          attendanceTimeController.clear();
        });

        await getMyAttendance();
      } else {
        showMsg("Failed: ${response.body}");
      }
    } catch (e) {
      debugPrint("Update attendance error: $e");
      showMsg("Failed to update attendance");
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> pickAttendanceViewDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: attendanceViewDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (pickedDate != null) {
      setState(() {
        attendanceViewDate = pickedDate;
      });

      await getMyAttendance();
    }
  }

  Future<void> pickAttendanceTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        attendanceTimeController.text =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  void cancelEdit() {
    setState(() {
      selectedStatus = 'present';
      editingAttendanceId = null;
      attendanceTimeController.clear();
    });
  }

  void startEditAttendance(Map<String, dynamic> item) {
    final approvalStatus = item['approval_status']?.toString() ?? 'pending';

    if (approvalStatus == 'approved') {
      showMsg("Approved attendance cannot be edited");
      return;
    }

    setState(() {
      editingAttendanceId = item['id'];
      selectedStatus = item['status'] ?? 'present';
      attendanceTimeController.text = item['attendance_time']?.toString() ?? '';
    });
  }

  void showMsg(String msg) {
    if (!mounted) return;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef3f9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          "My Attendance",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: pickAttendanceViewDate,
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          IconButton(
            onPressed: refreshAll,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              _buildAttendanceCard(),
              const SizedBox(height: 18),
              _buildSelectedDateAttendanceCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isProfileLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(22),
                child: CircularProgressIndicator(),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  editingAttendanceId == null
                      ? "Mark My Attendance"
                      : "Update My Attendance",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff111827),
                  ),
                ),
                const SizedBox(height: 14),
                _buildProfileInfoCard(),
                const SizedBox(height: 12),
                _buildDateInfoCard(),
                const SizedBox(height: 14),
                const Text(
                  "Attendance Status",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff111827),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusOption(
                        'present',
                        Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatusOption(
                        'absent',
                        Icons.cancel,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatusOption(
                        'half_day',
                        Icons.timelapse_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  "Reporting Time",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff111827),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: attendanceTimeController,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: "Choose reporting time",
                    prefixIcon: const Icon(Icons.access_time),
                    filled: true,
                    fillColor: const Color(0xfff8fafc),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onTap: pickAttendanceTime,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isSaving
                        ? null
                        : editingAttendanceId == null
                            ? markAttendance
                            : updateAttendance,
                    icon: isSaving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            editingAttendanceId == null
                                ? Icons.save_outlined
                                : Icons.check_circle_outline,
                            size: 18,
                          ),
                    label: Text(
                      isSaving
                          ? "Saving..."
                          : editingAttendanceId == null
                              ? "Submit Attendance"
                              : "Update Attendance",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2563eb),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (editingAttendanceId != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: cancelEdit,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text("Cancel Edit"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xffef4444),
                        side: const BorderSide(color: Color(0xfffecaca)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildProfileInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xffeff6ff),
            child: Icon(
              Icons.person_outline,
              color: Color(0xff2563eb),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentStaffName.isEmpty
                      ? "Logged-in Staff"
                      : currentStaffName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff111827),
                  ),
                ),
                if (currentTeamName.isNotEmpty)
                  Text(
                    currentTeamName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff64748b),
                    ),
                  ),
                if (currentTeamLeaderName.isNotEmpty)
                  Text(
                    "Leader: $currentTeamLeaderName",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff64748b),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: Color(0xff64748b),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Posting Date: $todayDate",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xff334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption(String value, IconData icon) {
    final bool isSelected = selectedStatus == value;

    return InkWell(
      onTap: () {
        setState(() {
          selectedStatus = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xffdbeafe) : const Color(0xfff8fafc),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? const Color(0xff2563eb) : const Color(0xffe5e7eb),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? const Color(0xff2563eb)
                  : const Color(0xff64748b),
            ),
            const SizedBox(height: 5),
            Text(
              getStatusLabel(value),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? const Color(0xff1d4ed8)
                    : const Color(0xff475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDateAttendanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "My Attendance - $formattedAttendanceViewDate",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xff111827),
            ),
          ),
          const SizedBox(height: 12),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : selectedDateAttendance.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text(
                          "No attendance found for selected date",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: selectedDateAttendance.map<Widget>((item) {
                        final approvalStatus =
                            item['approval_status']?.toString() ?? 'pending';
                        final canEdit = approvalStatus == 'pending' ||
                            approvalStatus == 'rejected';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xfff8fafc),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xffe5e7eb),
                            ),
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
                                      item['staff_name'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xff111827),
                                      ),
                                    ),
                                    Text(
                                      item['team_name'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xff64748b),
                                      ),
                                    ),
                                    Text(
                                      "Time: ${item['attendance_time'] ?? '-'}",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xff64748b),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    getStatusLabel(item['status']),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: getStatusColor(item['status']),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Status: ${approvalStatus.toUpperCase()}",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: approvalStatus == 'approved'
                                          ? Colors.green
                                          : approvalStatus == 'rejected'
                                              ? Colors.red
                                              : Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () => startEditAttendance(item),
                                    child: const Icon(
                                      Icons.edit_outlined,
                                      color: Color(0xff2563eb),
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
        ],
      ),
    );
  }
}
