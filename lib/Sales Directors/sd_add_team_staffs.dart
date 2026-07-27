import 'dart:convert';

import 'package:beposoft/Sales%20Directors/SD_dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
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

class SDAllMembersPage extends StatefulWidget {
  const SDAllMembersPage({super.key});

  @override
  State<SDAllMembersPage> createState() => _SDAllMembersPageState();
}

class _SDAllMembersPageState extends State<SDAllMembersPage> {
  final String baseUrl = "$api/api/";

  bool loading = false;
  bool submitLoading = false;
  bool editLoading = false;
  bool staffSearchLoading = false;

  List<Map<String, dynamic>> teams = [];
  List<Map<String, dynamic>> staffs = [];
  List<Map<String, dynamic>> addVisibleStaffs = [];
  List<Map<String, dynamic>> editVisibleStaffs = [];
  List<Map<String, dynamic>> membersData = [];

  final addFormKey = GlobalKey<FormState>();
  final editFormKey = GlobalKey<FormState>();

  String? addTeam;
  String? addMember;

  String? editTeam;
  String? editMember;
  int? selectedMemberId;

  final TextEditingController addStaffSearchController =
      TextEditingController();
  final TextEditingController editStaffSearchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    initPage();
  }

  @override
  void dispose() {
    addStaffSearchController.dispose();
    editStaffSearchController.dispose();
    super.dispose();
  }

  Future<void> initPage() async {
    setState(() => loading = true);

    await Future.wait([
      fetchTeams(),
      fetchStaffs(),
      fetchMembers(),
    ]);

    if (mounted) {
      setState(() {
        addVisibleStaffs = List<Map<String, dynamic>>.from(staffs);
        editVisibleStaffs = List<Map<String, dynamic>>.from(staffs);
        loading = false;
      });
    }
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

else if(dep=="SD" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SdDashboard()), // Replace AnotherPage with your target page
            );
}
else if(dep=="CSO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => cso_dashboard()), // Replace AnotherPage with your target page
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

  List<dynamic> toArray(dynamic payload) {
    if (payload is List) return payload;

    if (payload is Map && payload["data"] is List) {
      return payload["data"];
    }

    if (payload is Map &&
        payload["results"] is Map &&
        payload["results"]["data"] is List) {
      return payload["results"]["data"];
    }

    if (payload is Map && payload["results"] is List) {
      return payload["results"];
    }

    return [];
  }

  Future<void> deleteTeamMember(int memberId) async {
  final bool? confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Delete Member"),
      content: const Text(
        "Are you sure you want to remove this team member?",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Delete"),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  try {
    final token = await getToken();
    if (token == null) throw Exception("Token missing");

    final response = await http.delete(
      Uri.parse(
        "${baseUrl}staff/attendance/team/members/edit/$memberId/",
      ),
      headers: authHeaders(token),
    );

    final body =
        response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode == 200 ||
        response.statusCode == 204) {
      showSuccess("Member deleted successfully");
      await fetchMembers();
    } else {
      showError(
        body["message"]?.toString() ?? "Failed to delete member",
      );
    }
  } catch (_) {
    showError("Failed to delete member");
  }
}

  Map<String, dynamic> mapTeamItem(dynamic item) {
    return {
      "id": item["id"],
      "team_name": item["team_name"] ?? "",
      "team_leader": item["team_leader"],
      "team_leader_name": item["team_leader_name"] ??
          item["leader_name"] ??
          item["team_leader_name_display"] ??
          "",
    };
  }

bool isAllowedSalesTeam(dynamic team) {
  final name = (team["team_name"] ?? team["name"] ?? "")
      .toString()
      .trim()
      .toUpperCase();

  return name.contains("SALES");
}
  Map<String, dynamic> mapStaffItem(dynamic item) {
    return {
      "id": item["id"],
      "eid": item["eid"] ?? "",
      "name": item["name"] ?? "",
      "email": item["email"] ?? "",
      "phone": item["phone"] ?? "",
      "designation": item["designation"] ?? "",
      "department_name": item["department_name"] ?? "",
      "approval_status": item["approval_status"] ?? "",
    };
  }

  Map<String, dynamic> mapMemberTeam(dynamic team) {
    final rawMembers = team["members"] is List ? team["members"] : [];

    return {
      "team_id": team["team_id"] ?? team["id"] ?? "",
      "team_name": team["team_name"] ?? "",
      "team_leader": team["team_leader"],
      "team_leader_name": team["team_leader_name"] ?? "",
      "is_team_leader": team["is_team_leader"] ?? false,
      "members_count": team["members_count"] ?? rawMembers.length,
      "members": rawMembers.map<Map<String, dynamic>>((member) {
        return {
          "id": member["id"],
          "team": member["team"] ?? team["team_id"] ?? team["id"] ?? "",
          "team_name": member["team_name"] ?? team["team_name"] ?? "",
          "member": member["member"] ?? member["member_id"] ?? "",
          "member_name": member["member_name"] ?? "",
          "created_at": member["created_at"],
        };
      }).toList(),
    };
  }

  void mergeUniqueStaffs(List<Map<String, dynamic>> next) {
    final merged = [...staffs];

    for (final item in next) {
      final exists = merged.any(
        (staff) => staff["id"].toString() == item["id"].toString(),
      );

      if (!exists) {
        merged.add(item);
      }
    }

    staffs = merged;
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
final list = toArray(body)
    .map(mapTeamItem)
    .where(isAllowedSalesTeam)
    .toList();
        if (!mounted) return;

        setState(() {
          teams = list;
        });
      } else {
        throw Exception();
      }
    } catch (_) {
      showError("Failed to load teams");
    }
  }

  Future<void> fetchMembers() async {
    try {
      final token = await getToken();
      if (token == null) throw Exception("Token missing");

      final response = await http.get(
        Uri.parse("${baseUrl}staff/attendance/team/members/"),
        headers: authHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
final list = toArray(body)
    .map(mapMemberTeam)
    .where(isAllowedSalesTeam)
    .toList();
        if (!mounted) return;

        setState(() {
          membersData = list;
        });
      } else {
        throw Exception();
      }
    } catch (_) {
      showError("Failed to load members");
    }
  }

  Future<List<Map<String, dynamic>>> fetchStaffs([
    String searchText = "",
  ]) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception("Token missing");

      final uri = Uri.parse("${baseUrl}get/staffs/").replace(
        queryParameters: {
          "page": "1",
          if (searchText.trim().isNotEmpty) "search": searchText.trim(),
        },
      );

      final response = await http.get(
        uri,
        headers: authHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);

        final list = toArray(body)
            .where((item) => item["approval_status"] == "approved")
            .map<Map<String, dynamic>>(mapStaffItem)
            .toList();

        if (!mounted) return list;

        setState(() {
          mergeUniqueStaffs(list);

          if (searchText.trim().isEmpty) {
            addVisibleStaffs = List<Map<String, dynamic>>.from(list);
            editVisibleStaffs = List<Map<String, dynamic>>.from(list);
          }
        });

        return list;
      } else {
        throw Exception();
      }
    } catch (_) {
      showError("Failed to load staff");
      return [];
    }
  }

  Future<void> addTeamMember() async {
    if (!addFormKey.currentState!.validate()) return;

    try {
      setState(() => submitLoading = true);

      final token = await getToken();
      if (token == null) throw Exception("Token missing");

      final payload = {
        "team": int.tryParse(addTeam.toString()),
        "member": int.tryParse(addMember.toString()),
      };

      final response = await http.post(
        Uri.parse("${baseUrl}staff/attendance/team/members/"),
        headers: authHeaders(token),
        body: jsonEncode(payload),
      );

      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200 || response.statusCode == 201) {
        showSuccess("Team member added successfully");

        if (!mounted) return;

        Navigator.pop(context);

        setState(() {
          addTeam = null;
          addMember = null;
          addStaffSearchController.clear();
          addVisibleStaffs = List<Map<String, dynamic>>.from(staffs);
        });

        await fetchMembers();
      } else {
        showError(body["message"]?.toString() ?? "Failed to add member");
      }
    } catch (_) {
      showError("Failed to add member");
    } finally {
      if (mounted) {
        setState(() => submitLoading = false);
      }
    }
  }

  void openEditModal(Map<String, dynamic> memberRow) {
    setState(() {
      selectedMemberId = memberRow["id"] is int
          ? memberRow["id"]
          : int.tryParse(memberRow["id"].toString());

      editTeam = memberRow["team"]?.toString();
      editMember = memberRow["member"]?.toString();

      final selectedStaff = staffs.firstWhere(
        (staff) => staff["id"].toString() == editMember,
        orElse: () => {
          "name": memberRow["member_name"] ?? "",
        },
      );

      editStaffSearchController.text = selectedStaff["name"]?.toString() ?? "";
      editVisibleStaffs = List<Map<String, dynamic>>.from(staffs);
    });

    showEditMemberDialog();
  }

  Future<void> updateTeamMember() async {
    if (!editFormKey.currentState!.validate()) return;

    if (selectedMemberId == null) {
      showError("Member id missing");
      return;
    }

    try {
      setState(() => editLoading = true);

      final token = await getToken();
      if (token == null) throw Exception("Token missing");

      final payload = {
        "team": int.tryParse(editTeam.toString()),
        "member": int.tryParse(editMember.toString()),
      };

      final response = await http.put(
        Uri.parse(
          "${baseUrl}staff/attendance/team/members/edit/$selectedMemberId/",
        ),
        headers: authHeaders(token),
        body: jsonEncode(payload),
      );

      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200 || response.statusCode == 201) {
        showSuccess("Updated successfully");

        if (!mounted) return;

        Navigator.pop(context);

        setState(() {
          selectedMemberId = null;
          editTeam = null;
          editMember = null;
          editStaffSearchController.clear();
          editVisibleStaffs = List<Map<String, dynamic>>.from(staffs);
        });

        await fetchMembers();
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

  int get totalTeams => membersData.length;

  int get totalMembers {
    int count = 0;

    for (final team in membersData) {
      final members = team["members"] is List ? team["members"] : [];
      count += int.tryParse(
            (team["members_count"] ?? members.length).toString(),
          ) ??
          0;
    }

    return count;
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

  Future<void> handleStaffSearch({
    required String value,
    required Function(List<Map<String, dynamic>>) onListChanged,
    required VoidCallback dialogRefresh,
  }) async {
    setState(() => staffSearchLoading = true);
    dialogRefresh();

    final list = await fetchStaffs(value);

    onListChanged(list);

    if (mounted) {
      setState(() => staffSearchLoading = false);
    }

    dialogRefresh();
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
    "Team Members",
    style: TextStyle(fontWeight: FontWeight.w900),
  ),
  backgroundColor: Colors.white,
  foregroundColor: const Color(0xFF0F172A),
  elevation: 0,
  surfaceTintColor: Colors.white,
),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  fetchTeams(),
                  fetchStaffs(),
                  fetchMembers(),
                ]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    buildHeaderCard(),
                    const SizedBox(height: 18),
                    buildSummaryCards(),
                    const SizedBox(height: 18),
                    buildMembersListCard(),
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
                  Icons.groups_rounded,
                  color: Colors.white,
                  size: 31,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Team Members",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Manage team members assigned for attendance tracking.",
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: showAddMemberDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text("Add Team Member"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5667E8),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: buildSummaryCard(
            title: "Total Teams",
            value: totalTeams.toString(),
            icon: Icons.account_tree_rounded,
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: buildSummaryCard(
            title: "Total Members",
            value: totalMembers.toString(),
            icon: Icons.badge_rounded,
            color: const Color(0xFF4F46E5),
          ),
        ),
      ],
    );
  }

  Widget buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMembersListCard() {
    return Container(
      decoration: cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            color: Colors.white,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Members List",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Department-wise team member allocation.",
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: membersData.isEmpty
                ? buildEmptyState()
                : Column(
                    children: membersData.asMap().entries.map((entry) {
                      return buildTeamMemberCard(
                        team: entry.value,
                        teamIndex: entry.key,
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget buildTeamMemberCard({
    required Map<String, dynamic> team,
    required int teamIndex,
  }) {
    final members = team["members"] is List ? team["members"] : [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color.fromARGB(255, 233, 234, 235),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Text(
                    "${teamIndex + 1}",
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team["team_name"]?.toString() ?? "-",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Head: ${team["team_leader_name"]?.toString().isNotEmpty == true ? team["team_leader_name"] : "-"}",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                buildCountBadge("${team["members_count"] ?? members.length}"),
              ],
            ),
          ),
          members.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(26),
                  child: Text(
                    "No members in this team.",
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                )
              : ListView.separated(
                  itemCount: members.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final member = Map<String, dynamic>.from(members[index]);
                    return buildMemberRow(member, index);
                  },
                ),
        ],
      ),
    );
  }

Widget buildMemberRow(Map<String, dynamic> member, int index) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    child: Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFFF1F5F9),
          child: Text(
            "${index + 1}",
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            member["member_name"]?.toString() ?? "-",
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_vert_rounded,
            color: Color(0xFF475569),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          onSelected: (value) {
            if (value == "edit") {
              openEditModal(member);
            } else if (value == "delete") {
              final int? memberId = member["id"] is int
                  ? member["id"]
                  : int.tryParse(member["id"].toString());

              if (memberId != null) {
                deleteTeamMember(memberId);
              } else {
                showError("Member id missing");
              }
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem<String>(
              value: "edit",
              child: Row(
                children: [
                  Icon(
                    Icons.edit_rounded,
                    color: Color(0xFFB45309),
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Text("Edit"),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: "delete",
              child: Row(
                children: [
                  Icon(
                    Icons.delete_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Delete",
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget buildCountBadge(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Color(0xFF15803D),
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
            Icons.group_off_rounded,
            size: 54,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(height: 14),
          Text(
            "No members found",
            style: TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "No team members are currently assigned.",
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
    final validValue = teams.any((team) => team["id"].toString() == value)
        ? value
        : null;

    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: validValue,
      decoration: inputDecoration("Team"),
      items: teams.map((team) {
        final label = team["team_name"]?.toString() ?? "-";

        return DropdownMenuItem<String>(
          value: team["id"].toString(),
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      selectedItemBuilder: (context) {
        return teams.map((team) {
          final label = team["team_name"]?.toString() ?? "-";

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

  Widget buildStaffSearchDropdown({
    required TextEditingController controller,
    required String? selectedValue,
    required ValueChanged<String?> onSelected,
    required List<Map<String, dynamic>> visibleStaffs,
    required Function(List<Map<String, dynamic>>) onListChanged,
    required VoidCallback dialogRefresh,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: inputDecoration("Search Member").copyWith(
            suffixIcon: staffSearchLoading
                ? const Padding(
                    padding: EdgeInsets.all(13),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : controller.text.trim().isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () async {
                          controller.clear();
                          onSelected(null);

                          await handleStaffSearch(
                            value: "",
                            onListChanged: onListChanged,
                            dialogRefresh: dialogRefresh,
                          );
                        },
                      )
                    : const Icon(Icons.search_rounded),
          ),
          onChanged: (value) async {
            onSelected(null);

            await handleStaffSearch(
              value: value,
              onListChanged: onListChanged,
              dialogRefresh: dialogRefresh,
            );
          },
          validator: (_) {
            if (selectedValue == null || selectedValue.isEmpty) {
              return "Select Member";
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 230),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: visibleStaffs.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    "No members found",
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: visibleStaffs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final staff = visibleStaffs[index];

                    final isSelected =
                        staff["id"].toString() == selectedValue?.toString();

                    return ListTile(
                      dense: true,
                      selected: isSelected,
                      selectedTileColor: const Color(0xFFEEF2FF),
                      title: Text(
                        staff["name"]?.toString() ?? "-",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        staff["department_name"]?.toString() ?? "",
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF4F46E5),
                            )
                          : null,
                      onTap: () {
                        controller.text = staff["name"]?.toString() ?? "";
                        onSelected(staff["id"].toString());
                        dialogRefresh();
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  void showAddMemberDialog() {
    setState(() {
      addTeam = null;
      addMember = null;
      addStaffSearchController.clear();
      addVisibleStaffs = List<Map<String, dynamic>>.from(staffs);
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (dialogContext, dialogSetState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
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
                            title: "Add Team Member",
                            subtitle:
                                "Assign an approved staff member to an attendance team.",
                            icon: Icons.person_add_alt_1_rounded,
                            onClose: submitLoading
                                ? null
                                : () => Navigator.pop(dialogContext),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                            child: Column(
                              children: [
                                buildTeamDropdown(
                                  value: addTeam,
                                  onChanged: (value) {
                                    dialogSetState(() {
                                      addTeam = value;
                                    });
                                  },
                                  validator: (value) =>
                                      value == null ? "Select Team" : null,
                                ),
                                const SizedBox(height: 14),
                                buildStaffSearchDropdown(
                                  controller: addStaffSearchController,
                                  selectedValue: addMember,
                                  visibleStaffs: addVisibleStaffs,
                                  onSelected: (value) {
                                    addMember = value;
                                  },
                                  onListChanged: (list) {
                                    addVisibleStaffs =
                                        List<Map<String, dynamic>>.from(list);
                                  },
                                  dialogRefresh: () {
                                    dialogSetState(() {});
                                  },
                                ),
                                const SizedBox(height: 24),
                                buildDialogActions(
                                  cancelText: "Cancel",
                                  submitText: "Add Member",
                                  loading: submitLoading,
                                  onCancel: () => Navigator.pop(dialogContext),
                                  onSubmit: addTeamMember,
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

  void showEditMemberDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (dialogContext, dialogSetState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
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
                            title: "Edit Member",
                            subtitle:
                                "Update the team or assigned staff member.",
                            icon: Icons.edit_rounded,
                            onClose: editLoading
                                ? null
                                : () => Navigator.pop(dialogContext),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                            child: Column(
                              children: [
                                buildTeamDropdown(
                                  value: editTeam,
                                  onChanged: (value) {
                                    dialogSetState(() {
                                      editTeam = value;
                                    });
                                  },
                                  validator: (value) =>
                                      value == null ? "Select Team" : null,
                                ),
                                const SizedBox(height: 14),
                                buildStaffSearchDropdown(
                                  controller: editStaffSearchController,
                                  selectedValue: editMember,
                                  visibleStaffs: editVisibleStaffs,
                                  onSelected: (value) {
                                    editMember = value;
                                  },
                                  onListChanged: (list) {
                                    editVisibleStaffs =
                                        List<Map<String, dynamic>>.from(list);
                                  },
                                  dialogRefresh: () {
                                    dialogSetState(() {});
                                  },
                                ),
                                const SizedBox(height: 24),
                                buildDialogActions(
                                  cancelText: "Cancel",
                                  submitText: "Update",
                                  loading: editLoading,
                                  onCancel: () => Navigator.pop(dialogContext),
                                  onSubmit: updateTeamMember,
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
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
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
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
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