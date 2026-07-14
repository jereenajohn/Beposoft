import 'dart:convert';
import 'package:beposoft/pages/api.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StaffMarkAttendanceScreen extends StatefulWidget {
  const StaffMarkAttendanceScreen({super.key});

  @override
  State<StaffMarkAttendanceScreen> createState() =>
      _StaffMarkAttendanceScreenState();
}

class _StaffMarkAttendanceScreenState extends State<StaffMarkAttendanceScreen> {
  List<Map<String, dynamic>> teamMembers = [];
  List<Map<String, dynamic>> selectedDateAttendance = [];

  Map<String, dynamic>? selectedMember;

  String selectedStatus = 'present';

  int? editingAttendanceId;
  int? loggedInUserId;
  bool isManager = false;

  bool isLoading = false;
  bool isMemberLoading = false;
  bool isSaving = false;
  bool isProfileLoading = false;

  final TextEditingController attendanceTimeController =
      TextEditingController();

  DateTime attendanceViewDate = DateTime.now();

  String get todayDate => DateTime.now().toIso8601String().split('T').first;

  String get formattedAttendanceViewDate =>
      attendanceViewDate.toIso8601String().split('T').first;

  Future<String?> gettokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  void initState() {
    super.initState();
    attendanceTimeController.clear();
    refreshAll();
  }

  @override
  void dispose() {
    attendanceTimeController.dispose();
    super.dispose();
  }

  Future<void> refreshAll() async {
    await getProfile();
    await getMembersForDropdown();
    await getMyTeamAttendance();
  }

  Future<void> getProfile() async {
    try {
      setState(() => isProfileLoading = true);

      final token = await gettokenFromPrefs();

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

        setState(() {
          loggedInUserId = int.tryParse('${data['id']}');
          isManager = data['is_manager'] ?? false;
        });

        debugPrint("LOGGED USER ID: $loggedInUserId");
        debugPrint("IS MANAGER: $isManager");
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

  Future<void> getMembersForDropdown() async {
    try {
      setState(() => isMemberLoading = true);

      final token = await gettokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/staff/attendance/my/team/details/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final List data = List.from(parsed['data'] ?? []);

        final List<Map<String, dynamic>> membersList = [];

        for (var team in data) {
          final List members = List.from(team['members'] ?? []);

          for (var member in members) {
            membersList.add({
              'id': member['id'],
              'member': member['member'],
              'member_name': member['member_name'] ?? '',
              'team_id': team['team_id'],
              'team_name': team['team_name'] ?? '',
              'team_leader_name': team['team_leader_name'] ?? '',
            });
          }
        }

        setState(() {
          teamMembers = membersList;
        });

        debugPrint("DROPDOWN MEMBERS COUNT: ${teamMembers.length}");
      }
    } catch (e) {
      debugPrint("Fetch members dropdown error: $e");
      showMsg("Failed to fetch members");
    } finally {
      if (mounted) {
        setState(() => isMemberLoading = false);
      }
    }
  }

  Future<void> getMyTeamAttendance() async {
    try {
      setState(() => isLoading = true);

      final token = await gettokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/staff/attendance/my/team/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("TEAM ATTENDANCE STATUS: ${response.statusCode}");
      debugPrint("TEAM ATTENDANCE RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final results = parsed['results'];
        final List data =
            results != null ? List.from(results['data'] ?? []) : [];

        final List<Map<String, dynamic>> dateAttendanceList = [];

        for (var team in data) {
          final List dateWiseAttendance =
              List.from(team['date_wise_attendance'] ?? []);

          for (var dateItem in dateWiseAttendance) {
            if (dateItem['attendance_date'] == formattedAttendanceViewDate) {
              final List attendanceList =
                  List.from(dateItem['attendance'] ?? []);

              for (var attendance in attendanceList) {
                dateAttendanceList.add({
                  'id': attendance['id'],
                  'staff': attendance['staff'],
                  'staff_name': attendance['staff_name'] ?? '',
                  'attendance_date': attendance['attendance_date'],
                  'status': attendance['status'],
                  'team_id': team['team_id'],
                  'team_name': team['team_name'] ?? '',
                  'team_leader_name': team['team_leader_name'] ?? '',
                  'attendance_time': attendance['attendance_time'],
                  'approval_status':
                      attendance['approval_status'] ?? 'pending',
                  'approved_by': attendance['approved_by'],
                  'approved_by_name': attendance['approved_by_name'],
                  'approved_at': attendance['approved_at'],
                });
              }
            }
          }
        }

        setState(() {
          selectedDateAttendance = dateAttendanceList;
        });
      } else {
        showMsg("Failed to fetch attendance");
      }
    } catch (e) {
      debugPrint("Fetch team attendance error: $e");
      showMsg("Failed to fetch attendance");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> markAttendance() async {
    if (selectedMember == null) {
      showMsg("Select member");
      return;
    }

 if (selectedStatus != 'absent' &&
    attendanceTimeController.text.trim().isEmpty) {
  showMsg("Choose reporting time");
  return;
}

    final alreadyMarked = selectedDateAttendance.any(
      (attendance) =>
          attendance['staff'] == selectedMember!['member'] &&
          attendance['attendance_date'] == todayDate,
    );

    if (alreadyMarked) {
      showMsg(
        "${selectedMember!['member_name']} attendance is already marked for today",
      );
      return;
    }

    try {
      setState(() => isSaving = true);

      final token = await gettokenFromPrefs();

  final body = {
  "staff": selectedMember!['member'],
  "attendance_date": todayDate,
  "attendance_time": selectedStatus == 'absent'
      ? null
      : attendanceTimeController.text.trim(),
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
          selectedMember = null;
          selectedStatus = 'present';
          editingAttendanceId = null;
          attendanceViewDate = DateTime.now();
          attendanceTimeController.clear();
        });

        await refreshAll();
      } else if (response.statusCode == 400) {
        final parsed = jsonDecode(response.body);

        showMsg(
          parsed['message']?.toString() ??
              parsed['errors']?.toString() ??
              "Attendance already marked for this member",
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

    if (selectedMember == null) {
      showMsg("Select member");
      return;
    }
if (selectedStatus != 'absent' &&
    attendanceTimeController.text.trim().isEmpty) {
  showMsg("Choose reporting time");
  return;
}

    try {
      setState(() => isSaving = true);

      final token = await gettokenFromPrefs();

   final body = {
  "staff": selectedMember!['member'],
  "attendance_date": todayDate,
  "attendance_time": selectedStatus == 'absent'
      ? null
      : attendanceTimeController.text.trim(),
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
          selectedMember = null;
          selectedStatus = 'present';
          editingAttendanceId = null;
          attendanceViewDate = DateTime.now();
          attendanceTimeController.clear();
        });

        await refreshAll();
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

  Future<void> updateApprovalStatus(
    Map<String, dynamic> item,
    String approvalStatus,
  ) async {
    if (loggedInUserId == null) {
      showMsg("Logged-in user id not found");
      return;
    }

    if (item['id'] == null) {
      showMsg("Attendance id not found");
      return;
    }

    try {
      setState(() => isSaving = true);

      final token = await gettokenFromPrefs();

      final body = {
        "staff": item['staff'],
        "attendance_date": item['attendance_date'],
        "attendance_time": item['attendance_time'],
        "status": item['status'],
        "approval_status": approvalStatus,
        "approved_by": loggedInUserId,
        "approved_at": DateTime.now().toIso8601String(),
      };

      final response = await http.put(
        Uri.parse('$api/api/staff/attendance/edit/${item['id']}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint("APPROVAL UPDATE STATUS: ${response.statusCode}");
      debugPrint("APPROVAL UPDATE RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        showMsg("Attendance $approvalStatus successfully");
        await refreshAll();
      } else {
        showMsg("Failed: ${response.body}");
      }
    } catch (e) {
      debugPrint("Approval update error: $e");
      showMsg("Failed to update approval status");
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

      await getMyTeamAttendance();
    }
  }

  void cancelEdit() {
    setState(() {
      selectedMember = null;
      selectedStatus = 'present';
      editingAttendanceId = null;
      attendanceTimeController.clear();
    });
  }

  void startEditAttendance(Map<String, dynamic> item) {
    final member = teamMembers.firstWhere(
      (member) => member['member'] == item['staff'],
      orElse: () => {},
    );

    if (member.isEmpty) {
      showMsg("Member not found in dropdown list");
      return;
    }

    setState(() {
      editingAttendanceId = item['id'];
      selectedMember = member;
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

  String getApprovalLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'pending':
        return 'Pending';
      default:
        return 'Pending';
    }
  }

  Color getApprovalColor(String status) {
    switch (status) {
      case 'approved':
        return const Color.fromARGB(255, 44, 168, 235);
      case 'rejected':
        return const Color(0xffdc2626);
      case 'pending':
        return const Color(0xfff59e0b);
      default:
        return const Color(0xfff59e0b);
    }
  }

  IconData getApprovalIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.verified;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.hourglass_top_rounded;
      default:
        return Icons.hourglass_top_rounded;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef3f9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          "Mark Attendance",
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
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  editingAttendanceId == null
                      ? "Mark Team Attendance"
                      : "Update Team Attendance",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff111827),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
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
                ),
                const SizedBox(height: 12),
                isMemberLoading
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownSearch<Map<String, dynamic>>(
                        selectedItem: selectedMember,
                        items: teamMembers,
                        compareFn: (item, selectedItem) {
                          return item['member'] == selectedItem['member'];
                        },
                        filterFn: (member, filter) {
                          final name = (member['member_name'] ?? '')
                              .toString()
                              .toLowerCase();
                          final team = (member['team_name'] ?? '')
                              .toString()
                              .toLowerCase();
                          final search = filter.toLowerCase();

                          return name.contains(search) ||
                              team.contains(search);
                        },
                        itemAsString: (member) {
                          if (member.isEmpty) return "";
                          return "${member['member_name']} - ${member['team_name']}";
                        },
                        popupProps: PopupProps.menu(
                          showSearchBox: true,
                          constraints: const BoxConstraints(maxHeight: 420),
                          menuProps: MenuProps(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          searchFieldProps: TextFieldProps(
                            decoration: InputDecoration(
                              hintText: "Search member",
                              prefixIcon: const Icon(Icons.search, size: 20),
                              filled: true,
                              fillColor: const Color(0xfff8fafc),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          itemBuilder: (context, member, isSelected) {
                            return ListTile(
                              dense: true,
                              leading: const CircleAvatar(
                                radius: 16,
                                backgroundColor: Color(0xffeff6ff),
                                child: Icon(
                                  Icons.person_outline,
                                  size: 17,
                                  color: Color(0xff2563eb),
                                ),
                              ),
                              title: Text(
                                member['member_name'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                member['team_name'] ?? '',
                                style: const TextStyle(fontSize: 11),
                              ),
                            );
                          },
                        ),
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            labelText: "Select Member",
                            prefixIcon: const Icon(Icons.person_outline),
                            filled: true,
                            fillColor: const Color(0xfff8fafc),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            selectedMember = value;
                          });
                        },
                      ),
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
                const SizedBox(height: 10),
                Text(
                  "${teamMembers.length} members available",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff64748b),
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

    if (value == 'absent') {
      attendanceTimeController.clear();
    }
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

  Widget _buildApprovalChip(String approvalStatus) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: getApprovalColor(approvalStatus).withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        getApprovalLabel(approvalStatus),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: getApprovalColor(approvalStatus),
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
            "Attendance - $formattedAttendanceViewDate",
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
                            item['approval_status'] ?? 'pending';

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
                                    const SizedBox(height: 4),
                                    _buildApprovalChip(approvalStatus),
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
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () => startEditAttendance(item),
                                        child: const Icon(
                                          Icons.edit_outlined,
                                          color: Color(0xff2563eb),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                    PopupMenuButton<String>(
  enabled: !isSaving,
  onSelected: (value) {
    updateApprovalStatus(item, value);
  },
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  ),
  itemBuilder: (_) => const [
    PopupMenuItem(
      value: "approved",
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 10),
          Text("Approve"),
        ],
      ),
    ),
    PopupMenuItem(
      value: "rejected",
      child: Row(
        children: [
          Icon(Icons.cancel, color: Colors.red),
          SizedBox(width: 10),
          Text("Reject"),
        ],
      ),
    ),
    PopupMenuItem(
      value: "pending",
      child: Row(
        children: [
          Icon(Icons.hourglass_empty, color: Colors.orange),
          SizedBox(width: 10),
          Text("Pending"),
        ],
      ),
    ),
  ],
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: getApprovalColor(approvalStatus).withOpacity(0.10),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: getApprovalColor(approvalStatus).withOpacity(0.45),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.admin_panel_settings_rounded,
          size: 16,
          color: getApprovalColor(approvalStatus),
        ),
        const SizedBox(width: 4),
        Text(
          "Approval",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: getApprovalColor(approvalStatus),
          ),
        ),
        Icon(
          Icons.arrow_drop_down,
          size: 16,
          color: getApprovalColor(approvalStatus),
        ),
      ],
    ),
  ),
),
                                    ],
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