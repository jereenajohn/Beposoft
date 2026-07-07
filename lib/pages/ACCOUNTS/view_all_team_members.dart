import 'dart:convert';

import 'package:beposoft/Sales%20Directors/SD_dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ViewAllTeamMembers extends StatefulWidget {
  const ViewAllTeamMembers({super.key});

  @override
  State<ViewAllTeamMembers> createState() => _ViewAllTeamMembersState();
}

class _ViewAllTeamMembersState extends State<ViewAllTeamMembers> {
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> teams = [];
  List<Map<String, dynamic>> staffs = [];
  List<Map<String, dynamic>> members = [];
  List<Map<String, dynamic>> filteredMembers = [];

  Map<String, dynamic>? selectedTeamMap;
  Map<String, dynamic>? selectedStaffMap;

  int? selectedTeamId;
  int? selectedStaffId;

  bool isLoading = false;
  bool isLoadingTeams = false;
  bool isLoadingStaff = false;
  bool isSubmitting = false;

  String searchText = "";

  @override
  void initState() {
    super.initState();
    initializePage();
  }

  Future<void> initializePage() async {
    await Future.wait([
      getTeams(),
      getStaffs(),
      getAllTeamMembers(),
    ]);
  }

  Future<String?> getTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<void> getTeams() async {
    try {
      setState(() => isLoadingTeams = true);

      final token = await getTokenFromPrefs();
      if (token == null) throw Exception("Token missing");

      final response = await http.get(
        Uri.parse('$api/api/sales/teams/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("GET TEAMS RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final List data = parsed["data"] ?? [];

        setState(() {
          teams = data.map<Map<String, dynamic>>((item) {
            return {
              "id": item["id"],
              "name": item["name"]?.toString() ?? "",
              "team_leader": item["team_leader"],
              "team_leader_name": item["team_leader_name"]?.toString() ?? "",
              "division": item["division"],
              "division_name": item["division_name"]?.toString() ?? "",
              "created_by": item["created_by"],
              "created_by_name": item["created_by_name"]?.toString() ?? "",
            };
          }).toList();
        });
      } else {
        setState(() => teams = []);
      }
    } catch (e) {
      debugPrint("Get teams error: $e");
      setState(() => teams = []);
    } finally {
      if (mounted) setState(() => isLoadingTeams = false);
    }
  }

  Future<void> getStaffs() async {
    try {
      setState(() => isLoadingStaff = true);

      final token = await getTokenFromPrefs();
      if (token == null) throw Exception("Token missing");

      final response = await http.get(
        Uri.parse('$api/api/staffs/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("GET STAFF RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final List data = parsed["data"] ?? [];

        setState(() {
          staffs = data.where((item) {
            final dept =
                item["department_name"]?.toString().trim().toUpperCase() ?? "";
            return dept == "BDO" || dept == "BDM";
          }).map<Map<String, dynamic>>((item) {
            return {
              "id": item["id"],
              "name": item["name"]?.toString() ?? "",
              "email": item["email"]?.toString() ?? "",
              "designation": item["designation"]?.toString() ?? "",
              "department_name": item["department_name"]?.toString() ?? "",
            };
          }).toList();
        });
      } else {
        setState(() => staffs = []);
      }
    } catch (e) {
      debugPrint("Get staffs error: $e");
      setState(() => staffs = []);
    } finally {
      if (mounted) setState(() => isLoadingStaff = false);
    }
  }

  Future<void> getAllTeamMembers() async {
    try {
      setState(() => isLoading = true);

      final token = await getTokenFromPrefs();
      if (token == null) throw Exception("Token missing");

      final response = await http.get(
        Uri.parse('$api/api/sales/team/members/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("ALL TEAM MEMBERS RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final List data = parsed["data"] ?? [];

        members = data.map<Map<String, dynamic>>((item) {
          return {
            "id": item["id"],
            "team": item["team"],
            "team_name": item["team_name"]?.toString() ?? "-",
            "user": item["user"],
            "user_name": item["user_name"]?.toString() ?? "-",
            "created_by": item["created_by"],
            "created_by_name": item["created_by_name"]?.toString() ?? "-",
            "joined_at": item["joined_at"]?.toString() ?? "-",
            "updated_at": item["updated_at"]?.toString() ?? "-",
          };
        }).toList();

        applySearch();
      } else {
        setState(() {
          members = [];
          filteredMembers = [];
        });
      }
    } catch (e) {
      debugPrint("All team members error: $e");
      showMsg("Failed to fetch team members", Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void applySearch() {
    final query = searchText.trim().toLowerCase();

    setState(() {
      filteredMembers = members.where((item) {
        final staff = item["user_name"].toString().toLowerCase();
        final team = item["team_name"].toString().toLowerCase();
        final createdBy = item["created_by_name"].toString().toLowerCase();

        return staff.contains(query) ||
            team.contains(query) ||
            createdBy.contains(query);
      }).toList();
    });
  }

  Future<void> addMember() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => isSubmitting = true);

      final token = await getTokenFromPrefs();
      if (token == null) throw Exception("Token missing");

      final response = await http.post(
        Uri.parse('$api/api/sales/team/members/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "team": selectedTeamId,
          "user": selectedStaffId,
        }),
      );

      final parsed = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        Navigator.pop(context);
        showMsg(parsed["message"] ?? "Team member added successfully", Colors.green);
        await getAllTeamMembers();
      } else {
        showMsg(
          parsed["message"] ??
              parsed["detail"] ??
              parsed["error"] ??
              "Failed to add team member",
          Colors.red,
        );
      }
    } catch (e) {
      debugPrint("Add member error: $e");
      showMsg("Something went wrong", Colors.red);
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Future<void> updateMember(int memberId) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => isSubmitting = true);

      final token = await getTokenFromPrefs();
      if (token == null) throw Exception("Token missing");

      final response = await http.put(
        Uri.parse('$api/api/sales/team/members/edit/$memberId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "team": selectedTeamId,
          "user": selectedStaffId,
        }),
      );

      final parsed = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context);
        showMsg(parsed["message"] ?? "Team member updated successfully", Colors.green);
        await getAllTeamMembers();
      } else {
        showMsg(
          parsed["message"] ??
              parsed["detail"] ??
              parsed["error"] ??
              "Failed to update team member",
          Colors.red,
        );
      }
    } catch (e) {
      debugPrint("Update member error: $e");
      showMsg("Something went wrong", Colors.red);
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Future<void> deleteMember(int memberId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Team Member"),
        content: const Text("Are you sure you want to delete this team member?"),
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
      final token = await getTokenFromPrefs();
      if (token == null) throw Exception("Token missing");

      final response = await http.delete(
        Uri.parse('$api/api/sales/team/members/edit/$memberId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final parsed = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200 || response.statusCode == 204) {
        showMsg(parsed["message"] ?? "Team member deleted successfully", Colors.green);
        await getAllTeamMembers();
      } else {
        showMsg(
          parsed["message"] ??
              parsed["detail"] ??
              parsed["error"] ??
              "Failed to delete team member",
          Colors.red,
        );
      }
    } catch (e) {
      debugPrint("Delete member error: $e");
      showMsg("Something went wrong", Colors.red);
    }
  }

  void openMemberDialog({Map<String, dynamic>? member}) {
    final isEdit = member != null;

    if (isEdit) {
      final teamId = member["team"];
      final userId = member["user"];

      selectedTeamId = teamId is int ? teamId : int.tryParse(teamId.toString());
      selectedStaffId = userId is int ? userId : int.tryParse(userId.toString());

      try {
        selectedTeamMap = teams.firstWhere((item) => item["id"] == selectedTeamId);
      } catch (_) {
        selectedTeamMap = null;
      }

      try {
        selectedStaffMap = staffs.firstWhere((item) => item["id"] == selectedStaffId);
      } catch (_) {
        selectedStaffMap = null;
      }
    } else {
      selectedTeamMap = null;
      selectedStaffMap = null;
      selectedTeamId = null;
      selectedStaffId = null;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (dialogContext, dialogSetState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              backgroundColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isEdit ? "Edit Team Member" : "Add Team Member",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () => Navigator.pop(dialogContext),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildLabel("Select Team *"),
                          isLoadingTeams
                              ? const Center(child: CircularProgressIndicator())
                              : _buildDropdownSearchField<Map<String, dynamic>>(
                                  hintText: "Choose team",
                                  selectedItem: selectedTeamMap,
                                  items: teams,
                                  itemAsString: (item) =>
                                      item["name"]?.toString() ?? "",
                                  onChanged: (value) {
                                    dialogSetState(() {
                                      selectedTeamMap = value;
                                      selectedTeamId = value?["id"];
                                    });
                                  },
                                  validator: (value) =>
                                      value == null ? "Please select team" : null,
                                ),
                          const SizedBox(height: 16),
                          _buildLabel("Select Staff *"),
                          isLoadingStaff
                              ? const Center(child: CircularProgressIndicator())
                              : _buildDropdownSearchField<Map<String, dynamic>>(
                                  hintText: "Choose staff",
                                  selectedItem: selectedStaffMap,
                                  items: staffs,
                                  itemAsString: (item) =>
                                      item["name"]?.toString() ?? "",
                                  onChanged: (value) {
                                    dialogSetState(() {
                                      selectedStaffMap = value;
                                      selectedStaffId = value?["id"];
                                    });
                                  },
                                  validator: (value) =>
                                      value == null ? "Please select staff" : null,
                                ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () {
                                      if (isEdit) {
                                        updateMember(member["id"]);
                                      } else {
                                        addMember();
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: isSubmitting
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      isEdit ? "Update Team Member" : "Add Team Member",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
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

  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();
    if (!mounted) return;

    if (dep == "BDO") {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => bdo_dashbord()));
    } else if (dep == "SD") {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SdDashboard()));
    } else if (dep == "CEO") {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ceo_dashboard()));
    } else if (dep == "ADMIN") {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => admin_dashboard()));
    } else if (dep == "COO") {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ceo_dashboard()));
    } else if (dep == "CSO") {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => cso_dashboard()));
    } else if (dep == "BDM") {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => bdm_dashbord()));
    } else if (dep == "warehouse") {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WarehouseDashboard()));
    } else if (dep == "Warehouse Admin") {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WarehouseAdmin()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => dashboard()));
    }
  }

  void showMsg(String msg, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String formatDate(String value) {
    if (value == "-" || value.trim().isEmpty) return "-";

    try {
      final date = DateTime.parse(value);
      return "${date.day.toString().padLeft(2, '0')}-"
          "${date.month.toString().padLeft(2, '0')}-"
          "${date.year}";
    } catch (_) {
      return value;
    }
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Widget _buildDropdownSearchField<T>({
    required String hintText,
    required T? selectedItem,
    required List<T> items,
    required String Function(T) itemAsString,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownSearch<T>(
      selectedItem: selectedItem,
      items: items,
      itemAsString: itemAsString,
      onChanged: onChanged,
      validator: validator,
      popupProps: PopupProps.menu(
        showSearchBox: true,
        fit: FlexFit.loose,
        searchFieldProps: TextFieldProps(
          decoration: _inputDecoration("Search here"),
        ),
        menuProps: MenuProps(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: _inputDecoration(hintText),
      ),
    );
  }

  Widget _buildLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _summaryCard() {
    final uniqueTeams = members.map((item) => item["team"]).toSet().length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
            Color(0xFF2563EB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.groups_2_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "All Team Members",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "${members.length} members • $uniqueTeams teams",
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return TextField(
      onChanged: (value) {
        searchText = value;
        applySearch();
      },
      decoration: InputDecoration(
        hintText: "Search staff, team, or created by",
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _memberCard(Map<String, dynamic> member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: const Color(0xFFEFF6FF),
                child: Text(
                  member["user_name"].toString().isNotEmpty
                      ? member["user_name"].toString()[0].toUpperCase()
                      : "?",
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
                      member["user_name"]?.toString() ?? "-",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member["team_name"]?.toString() ?? "-",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) {
                  if (value == "edit") {
                    openMemberDialog(member: member);
                  } else if (value == "delete") {
                    deleteMember(member["id"]);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: "edit",
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 10),
                        Text("Edit"),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: "delete",
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 10),
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
          const SizedBox(height: 14),
          _infoRow("Created By", member["created_by_name"]?.toString() ?? "-"),
          const SizedBox(height: 8),
          _infoRow("Joined At", formatDate(member["joined_at"]?.toString() ?? "-")),
          const SizedBox(height: 8),
          _infoRow("Updated At", formatDate(member["updated_at"]?.toString() ?? "-")),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.group_off_rounded,
            size: 46,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(height: 10),
          Text(
            "No team members found",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _navigateBack,
        ),
        title: const Text(
          "All Team Members",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: initializePage,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openMemberDialog(),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text("Add Member"),
      ),
      body: RefreshIndicator(
        onRefresh: initializePage,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _summaryCard(),
              const SizedBox(height: 16),
              _searchBox(),
              const SizedBox(height: 16),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 70),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (filteredMembers.isEmpty)
                _emptyState()
              else
                Column(
                  children: filteredMembers.map(_memberCard).toList(),
                ),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }
}