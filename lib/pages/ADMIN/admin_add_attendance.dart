import 'dart:convert';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AllAttendanceAddPage extends StatefulWidget {
  const AllAttendanceAddPage({super.key});

  @override
  State<AllAttendanceAddPage> createState() => _AllAttendanceAddPageState();
}

class _AllAttendanceAddPageState extends State<AllAttendanceAddPage> {
  final String baseUrl = "$api/api/";

  bool loading = false;
  bool submitLoading = false;
  bool editLoading = false;

  List<dynamic> teams = [];
  List<dynamic> staffs = [];
  List<dynamic> attendanceData = [];

  String? selectedTeam;

  late String todayDate;
  DateTime? startDate;
  DateTime? endDate;

  String teamName = "All Teams";
  String teamLeaderName = "All Team Leaders";

  final addFormKey = GlobalKey<FormState>();
  final editFormKey = GlobalKey<FormState>();

  String? addStaff;
  String? addStatus;
  TimeOfDay? addTime;

  int? selectedAttendanceId;
  String? editStaff;
  String? editStatus;
  String? editDate;
  TimeOfDay? editTime;

  final List<Map<String, String>> statusOptions = const [
    {"value": "present", "label": "Present"},
    {"value": "absent", "label": "Absent"},
    {"value": "half_day", "label": "Half Day"},
  ];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    todayDate = formatDate(now);
    startDate = now;
    endDate = now;

    initPage();
  }

  Future<void> initPage() async {
    setState(() => loading = true);

    await Future.wait([
      fetchTeams(),
      fetchAttendance(),
    ]);

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  Map<String, String> authHeaders(String token) {
    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
  }

  String formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  String formatTime(TimeOfDay time) {
    return "${time.hour.toString().padLeft(2, '0')}:"
        "${time.minute.toString().padLeft(2, '0')}";
  }

  TimeOfDay? parseTime(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final parts = value.split(":");
    if (parts.length < 2) return null;

    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  Future<void> fetchTeams() async {
    try {
      final token = await getToken();
      if (token == null) throw Exception("Token missing");

      final response = await http.get(
        Uri.parse("${baseUrl}staff/attendance/teams/"),
        headers: authHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);

        if (!mounted) return;
        setState(() {
          teams = body["data"] ?? [];
        });
      } else {
        throw Exception("Failed to load teams");
      }
    } catch (_) {
      showError("Failed to load teams");
    }
  }

  Future<void> fetchStaffs(dynamic teamId) async {
    if (teamId == null || teamId.toString().isEmpty) {
      if (!mounted) return;
      setState(() => staffs = []);
      return;
    }

    try {
      final token = await getToken();
      if (token == null) throw Exception("Token missing");

      final response = await http.get(
        Uri.parse("${baseUrl}staff/attendance/team/members/$teamId/"),
        headers: authHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        final members = body["data"]?["members"] ?? [];

        if (!mounted) return;
        setState(() {
          staffs = members.map((item) {
            return {
              "id": item["member"],
              "name": item["member_name"],
              "team_id": item["team"],
              "team_name": item["team_name"],
            };
          }).toList();
        });
      } else {
        throw Exception("Failed to load team members");
      }
    } catch (_) {
      showError("Failed to load team members");
    }
  }

  Future<void> fetchAttendance() async {
    try {
      final token = await getToken();
      if (token == null) throw Exception("Token missing");

      final uri = Uri.parse("${baseUrl}staff/attendance/").replace(
        queryParameters: {
          if (startDate != null) "start_date": formatDate(startDate!),
          if (endDate != null) "end_date": formatDate(endDate!),
        },
      );

      final response = await http.get(
        uri,
        headers: authHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);

        if (!mounted) return;
        setState(() {
          attendanceData = body["results"]?["data"] ?? [];
          teamName = "All Teams";
          teamLeaderName = "All Team Leaders";
        });
      } else {
        throw Exception("Failed to load attendance");
      }
    } catch (_) {
      showError("Failed to load attendance");
    }
  }

  Future<void> addAttendance() async {
    if (!addFormKey.currentState!.validate()) return;

    if (addTime == null) {
      showError("Select reporting time");
      return;
    }

    try {
      setState(() => submitLoading = true);

      final token = await getToken();
      if (token == null) throw Exception("Token missing");

      final payload = {
        "staff": int.tryParse(addStaff.toString()),
        "attendance_date": todayDate,
        "attendance_time": formatTime(addTime!),
        "status": addStatus,
      };

      final response = await http.post(
        Uri.parse("${baseUrl}staff/attendance/"),
        headers: authHeaders(token),
        body: jsonEncode(payload),
      );

      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode >= 200 && response.statusCode < 300) {
        showSuccess("Attendance added successfully");

        if (!mounted) return;
        Navigator.pop(context);

        setState(() {
          selectedTeam = null;
          addStaff = null;
          addStatus = null;
          addTime = null;
          staffs = [];
        });

        await fetchAttendance();
      } else {
        final message = body["message"] ??
            body["errors"]?["staff"]?[0] ??
            body["errors"]?["attendance_date"]?[0] ??
            "Failed to add attendance";

        showError(message.toString());
      }
    } catch (_) {
      showError("Failed to add attendance");
    } finally {
      if (mounted) {
        setState(() => submitLoading = false);
      }
    }
  }

  Future<void> openEditModal(dynamic id) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception("Token missing");

      final response = await http.get(
        Uri.parse("${baseUrl}staff/attendance/edit/$id/"),
        headers: authHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        final data = body["data"];

        final staffId = data["staff"]?.toString();

        String? resolvedTeamId;

        for (final team in attendanceData) {
          final rows = buildTeamRows(team);

          final found = rows.any(
            (row) => row["staff"]?.toString() == staffId,
          );

          if (found) {
            resolvedTeamId = team["team_id"]?.toString();
            break;
          }
        }

        resolvedTeamId ??= data["team"]?.toString();

        setState(() {
          selectedAttendanceId = id is int ? id : int.tryParse(id.toString());
          selectedTeam = resolvedTeamId;
          editStaff = staffId;
          editDate = data["attendance_date"]?.toString();
          editTime = parseTime(data["attendance_time"]?.toString());
          editStatus = data["status"]?.toString();
          staffs = [];
        });

        if (resolvedTeamId != null && resolvedTeamId.isNotEmpty) {
          await fetchStaffs(resolvedTeamId);
        }

        if (!mounted) return;
        showEditAttendanceDialog();
      } else {
        throw Exception("Failed to load attendance");
      }
    } catch (_) {
      showError("Failed to load attendance");
    }
  }

  Future<void> updateAttendance() async {
    if (!editFormKey.currentState!.validate()) return;

    if (selectedAttendanceId == null) {
      showError("Invalid attendance record");
      return;
    }

    if (editTime == null) {
      showError("Select reporting time");
      return;
    }

    try {
      setState(() => editLoading = true);

      final token = await getToken();
      if (token == null) throw Exception("Token missing");

      final payload = {
        "staff": int.tryParse(editStaff.toString()),
        "attendance_date": editDate,
        "attendance_time": formatTime(editTime!),
        "status": editStatus,
      };

      final response = await http.put(
        Uri.parse("${baseUrl}staff/attendance/edit/$selectedAttendanceId/"),
        headers: authHeaders(token),
        body: jsonEncode(payload),
      );

      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode >= 200 && response.statusCode < 300) {
        showSuccess("Attendance updated");

        if (!mounted) return;
        Navigator.pop(context);

        await fetchAttendance();
      } else {
        showError(body["message"]?.toString() ?? "Update failed");
      }
    } catch (_) {
      showError("Update failed");
    } finally {
      if (mounted) {
        setState(() => editLoading = false);
      }
    }
  }

  void resetFilters() {
    final now = DateTime.now();

    setState(() {
      startDate = now;
      endDate = now;
    });

    fetchAttendance();
  }

  List<dynamic> buildTeamRows(dynamic team) {
    final List<dynamic> rows = [];
    final dateWiseAttendance = team["date_wise_attendance"] ?? [];

    for (final dateGroup in dateWiseAttendance) {
      final attendance = dateGroup["attendance"] ?? [];

      for (final item in attendance) {
        rows.add({
          ...item,
          "attendance_date":
              item["attendance_date"] ?? dateGroup["attendance_date"] ?? "-",
        });
      }
    }

    return rows;
  }

  int countByStatus(List<dynamic> rows, String status) {
    return rows.where((item) => item["status"] == status).length;
  }

  Future<void> pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => startDate = picked);
    }
  }

  Future<void> pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => endDate = picked);
    }
  }

  Future<TimeOfDay?> pickTime(TimeOfDay? initialTime) async {
    return showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
    );
  }

  void showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
    );
  }

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.08),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

 Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();
   if(dep=="BDO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => bdo_dashbord()), // Replace AnotherPage with your target page
            );

}
else if(dep=="BDM" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => bdm_dashbord()), // Replace AnotherPage with your target page
            );
}
else if(dep=="warehouse" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => WarehouseDashboard()), // Replace AnotherPage with your target page
            );
}
else if(dep=="CEO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ceo_dashboard()), // Replace AnotherPage with your target page
            );
}
else if(dep=="COO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ceo_dashboard()), // Replace AnotherPage with your target page
            );
}


else if(dep=="Warehouse Admin" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => WarehouseAdmin()), // Replace AnotherPage with your target page
            );
}else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => dashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      
      appBar: AppBar(
          leading: IconButton(
    icon: const Icon(Icons.arrow_back_rounded),
    onPressed: _navigateBack,
  ),
        title: const Text(
          "Daily Attendance",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchAttendance,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    buildHeaderCard(),
                    const SizedBox(height: 18),
                    buildFilterCard(),
                    const SizedBox(height: 18),
                    buildAttendanceListCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF111827),
            Color(0xFF334155),
            Color(0xFF0F172A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.22),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Daily Attendance",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Manage attendance, review team records, and update daily status.",
                      style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              buildHeaderBadge(
                icon: Icons.today_rounded,
                text: "Today: $todayDate",
                bg: const Color(0xFF22C55E).withOpacity(0.18),
                fg: const Color(0xFFBBF7D0),
              ),
              buildHeaderBadge(
                icon: Icons.groups_rounded,
                text: "Teams: ${attendanceData.length}",
                bg: const Color(0xFF3B82F6).withOpacity(0.18),
                fg: const Color(0xFFBFDBFE),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildHeaderBadge({
    required IconData icon,
    required String text,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFilterCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Filters",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Filter attendance by date range.",
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: resetFilters,
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text("Reset"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 720;

              if (isWide) {
                return Row(
                  children: [
                    Expanded(
                      child: buildDateField(
                        label: "Start Date",
                        value: startDate == null ? "" : formatDate(startDate!),
                        onTap: pickStartDate,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: buildDateField(
                        label: "End Date",
                        value: endDate == null ? "" : formatDate(endDate!),
                        onTap: pickEndDate,
                      ),
                    ),
                    const SizedBox(width: 14),
                    SizedBox(
                      width: 180,
                      height: 50,
                      child: buildSearchButton(),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  buildDateField(
                    label: "Start Date",
                    value: startDate == null ? "" : formatDate(startDate!),
                    onTap: pickStartDate,
                  ),
                  const SizedBox(height: 14),
                  buildDateField(
                    label: "End Date",
                    value: endDate == null ? "" : formatDate(endDate!),
                    onTap: pickEndDate,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: buildSearchButton(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildSearchButton() {
    return ElevatedButton.icon(
      onPressed: fetchAttendance,
      icon: const Icon(Icons.search_rounded),
      label: const Text("Search"),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget buildDateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildAttendanceListCard() {
    return Container(
      decoration: cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Attendance List",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$teamName - Team Leader: $teamLeaderName",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: showAddAttendanceDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text("Add"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: attendanceData.isEmpty
                ? buildEmptyState()
                : Column(
                    children: attendanceData.map((team) {
                      final rows = buildTeamRows(team);
                      return buildTeamAttendanceCard(team, rows);
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget buildTeamAttendanceCard(dynamic team, List<dynamic> rows) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFF8FAFC),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team["team_name"]?.toString() ?? "-",
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Team Leader: ${team["team_leader_name"] ?? "-"}",
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    smallCountBadge(
                      "Present: ${countByStatus(rows, "present")}",
                      const Color(0xFF16A34A),
                    ),
                    smallCountBadge(
                      "Half Day: ${countByStatus(rows, "half_day")}",
                      const Color(0xFFF59E0B),
                    ),
                    smallCountBadge(
                      "Absent: ${countByStatus(rows, "absent")}",
                      const Color(0xFFDC2626),
                    ),
                    smallCountBadge(
                      "Total: ${rows.length}",
                      const Color(0xFF2563EB),
                    ),
                  ],
                ),
              ],
            ),
          ),
          rows.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(28),
                  child: Text(
                    "No attendance added for this team.",
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                )
              : ListView.separated(
                  itemCount: rows.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return buildAttendanceRow(rows[index], index);
                  },
                ),
        ],
      ),
    );
  }

  Widget buildAttendanceRow(dynamic item, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFFEFF6FF),
                child: Text(
                  "${index + 1}",
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item["staff_name"]?.toString() ?? "-",
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              buildStatusBadge(item["status"]?.toString()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 17,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                item["attendance_time"]?.toString() ?? "--:--",
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.event_rounded,
                size: 17,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item["attendance_date"]?.toString() ?? "-",
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF334155)),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  selectedTeam = null;
                  editStaff = null;
                  editStatus = null;
                  editDate = null;
                  editTime = null;
                  openEditModal(item["id"]);
                },
                icon: const Icon(Icons.edit_rounded, size: 17),
                label: const Text("Edit"),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFB45309),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildStatusBadge(String? status) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    if (status == "present") {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF15803D);
      icon = Icons.check_rounded;
      label = "Present";
    } else if (status == "absent") {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
      icon = Icons.close_rounded;
      label = "Absent";
    } else {
      bg = const Color(0xFFFFEDD5);
      fg = const Color(0xFFC2410C);
      icon = Icons.access_time_rounded;
      label = "Half Day";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget smallCountBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 70, horizontal: 20),
      child: Column(
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 54,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(height: 14),
          Text(
            "No attendance records found",
            style: TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "No attendance data is available for the selected filters.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget buildTeamDropdown({
    required String? value,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: value,
      decoration: inputDecoration("Team"),
      items: teams.map((team) {
        final itemValue = (team["id"] ?? team["team_id"]).toString();
        final label = (team["team_name"] ?? team["name"] ?? "-").toString();

        return DropdownMenuItem<String>(
          value: itemValue,
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      selectedItemBuilder: (context) {
        return teams.map((team) {
          final label = (team["team_name"] ?? team["name"] ?? "-").toString();

          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList();
      },
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget buildStaffDropdown({
    required String? value,
    required ValueChanged<String?>? onChanged,
    String? Function(String?)? validator,
  }) {
    final validValue =
        staffs.any((staff) => staff["id"].toString() == value) ? value : null;

    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: validValue,
      decoration: inputDecoration("Staff"),
      items: staffs.map((staff) {
        final label = staff["name"]?.toString() ?? "-";

        return DropdownMenuItem<String>(
          value: staff["id"].toString(),
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      selectedItemBuilder: (context) {
        return staffs.map((staff) {
          final label = staff["name"]?.toString() ?? "-";

          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList();
      },
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget buildStatusDropdown({
    required String? value,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: value,
      decoration: inputDecoration("Status"),
      items: statusOptions.map((status) {
        return DropdownMenuItem<String>(
          value: status["value"],
          child: Text(
            status["label"]!,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      selectedItemBuilder: (context) {
        return statusOptions.map((status) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              status["label"]!,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList();
      },
      onChanged: onChanged,
      validator: validator,
    );
  }

  void showAddAttendanceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (dialogContext, dialogSetState) {
            return Dialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              backgroundColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 35,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Form(
                    key: addFormKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          buildProfessionalDialogHeader(
                            title: "Add Attendance",
                            subtitle:
                                "Mark today’s attendance with reporting time.",
                            icon: Icons.person_add_alt_1_rounded,
                            onClose: submitLoading
                                ? null
                                : () => Navigator.pop(dialogContext),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                            child: Column(
                              children: [
                                buildDateInfoBox("Attendance Date", todayDate),
                                const SizedBox(height: 18),
                                buildTeamDropdown(
                                  value: selectedTeam,
                                  validator: (value) =>
                                      value == null ? "Select Team" : null,
                                  onChanged: (value) async {
                                    dialogSetState(() {
                                      selectedTeam = value;
                                      addStaff = null;
                                      staffs = [];
                                    });

                                    await fetchStaffs(value);
                                    dialogSetState(() {});
                                  },
                                ),
                                const SizedBox(height: 14),
                                buildStaffDropdown(
                                  value: addStaff,
                                  onChanged: selectedTeam == null
                                      ? null
                                      : (value) {
                                          dialogSetState(
                                              () => addStaff = value);
                                        },
                                  validator: (value) =>
                                      value == null ? "Select Staff" : null,
                                ),
                                const SizedBox(height: 14),
                                buildTimeField(
                                  label: "Reporting Time",
                                  value: addTime == null
                                      ? "Select reporting time"
                                      : formatTime(addTime!),
                                  onTap: () async {
                                    final picked = await pickTime(addTime);
                                    if (picked != null) {
                                      setState(() => addTime = picked);
                                      dialogSetState(() {});
                                    }
                                  },
                                ),
                                const SizedBox(height: 14),
                                buildStatusDropdown(
                                  value: addStatus,
                                  onChanged: (value) {
                                    dialogSetState(() => addStatus = value);
                                  },
                                  validator: (value) =>
                                      value == null ? "Select Status" : null,
                                ),
                                const SizedBox(height: 24),
                                buildDialogActions(
                                  cancelText: "Cancel",
                                  submitText: "Add Attendance",
                                  loading: submitLoading,
                                  onCancel: () => Navigator.pop(dialogContext),
                                  onSubmit: addAttendance,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void showEditAttendanceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (dialogContext, dialogSetState) {
            return Dialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              backgroundColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 35,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Form(
                    key: editFormKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          buildProfessionalDialogHeader(
                            title: "Edit Attendance",
                            subtitle:
                                "Update staff attendance details carefully.",
                            icon: Icons.edit_calendar_rounded,
                            onClose: editLoading
                                ? null
                                : () => Navigator.pop(dialogContext),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                            child: Column(
                              children: [
                                if (editDate != null)
                                  buildDateInfoBox(
                                      "Attendance Date", editDate!),
                                const SizedBox(height: 18),
                                buildTeamDropdown(
                                  value: selectedTeam,
                                  onChanged: (value) async {
                                    dialogSetState(() {
                                      selectedTeam = value;
                                      editStaff = null;
                                      staffs = [];
                                    });

                                    await fetchStaffs(value);
                                    dialogSetState(() {});
                                  },
                                ),
                                const SizedBox(height: 14),
                                buildStaffDropdown(
                                  value: editStaff,
                                  onChanged: selectedTeam == null
                                      ? null
                                      : (value) {
                                          dialogSetState(
                                              () => editStaff = value);
                                        },
                                  validator: (value) =>
                                      value == null ? "Select Staff" : null,
                                ),
                                const SizedBox(height: 14),
                                buildTimeField(
                                  label: "Reporting Time",
                                  value: editTime == null
                                      ? "Select reporting time"
                                      : formatTime(editTime!),
                                  onTap: () async {
                                    final picked = await pickTime(editTime);
                                    if (picked != null) {
                                      setState(() => editTime = picked);
                                      dialogSetState(() {});
                                    }
                                  },
                                ),
                                const SizedBox(height: 14),
                                buildStatusDropdown(
                                  value: editStatus,
                                  onChanged: (value) {
                                    dialogSetState(() => editStatus = value);
                                  },
                                  validator: (value) =>
                                      value == null ? "Select Status" : null,
                                ),
                                const SizedBox(height: 24),
                                buildDialogActions(
                                  cancelText: "Cancel",
                                  submitText: "Update Attendance",
                                  loading: editLoading,
                                  onCancel: () => Navigator.pop(dialogContext),
                                  onSubmit: updateAttendance,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildProfessionalDialogHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback? onClose,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 14, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF111827),
            Color(0xFF1E293B),
            Color(0xFF312E81),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget buildDateInfoBox(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: Color(0xFF4F46E5),
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTimeField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: inputDecoration(label),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.access_time_rounded,
              size: 20,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDialogTitle({
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.calendar_month_rounded,
            color: Color(0xFF4F46E5),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildDialogActions({
    required String cancelText,
    required String submitText,
    required bool loading,
    required VoidCallback onCancel,
    required VoidCallback onSubmit,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: loading ? null : onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            child: Text(cancelText),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: loading ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
            child: loading
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    submitText,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ),
      ],
    );
  }
}
