import 'dart:convert';
import 'package:beposoft/pages/api.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StaffAttendanceTeamMemberScreen extends StatefulWidget {
  const StaffAttendanceTeamMemberScreen({super.key});

  @override
  State<StaffAttendanceTeamMemberScreen> createState() =>
      _StaffAttendanceTeamMemberScreenState();
}

class _StaffAttendanceTeamMemberScreenState
    extends State<StaffAttendanceTeamMemberScreen> {
  List<Map<String, dynamic>> teams = [];
  List<Map<String, dynamic>> sta = [];
  List<Map<String, dynamic>> myTeams = [];

  int? selectedTeamId;
  int? selectedMemberId;
  int? editingId;

  bool isLoading = false;
  bool isSaving = false;
  bool isStaffLoading = false;

  final TextEditingController staffSearchController = TextEditingController();

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  void initState() {
    super.initState();
    getTeams();
    getstaff(isInitial: true);
    getMyTeamDetails();
  }

  Future<void> getTeams() async {
    try {
      final token = await gettokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/staff/attendance/teams/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final List data = parsed is List ? parsed : parsed['data'] ?? [];

        setState(() {
          teams = data.map<Map<String, dynamic>>((item) {
            return {
              'id': item['id'],
              'team_name': item['team_name'] ?? '',
              'team_leader': item['team_leader'],
              'team_leader_name': item['team_leader_name'] ??
                  item['leader_name'] ??
                  item['team_leader_name_display'] ??
                  '',
            };
          }).toList();
        });
      }
    } catch (error) {
      debugPrint("Team fetch error: $error");
    }
  }

  Uri _buildStaffUri({int page = 1}) {
    final Map<String, String> params = {'page': page.toString()};

    if (staffSearchController.text.trim().isNotEmpty) {
      params['search'] = staffSearchController.text.trim();
    }

    return Uri.parse('$api/api/get/staffs/').replace(queryParameters: params);
  }

  Future<void> getstaff({bool isInitial = false}) async {
    try {
      setState(() {
        isStaffLoading = true;
      });

      final token = await gettokenFromPrefs();

      final response = await http.get(
        _buildStaffUri(page: 1),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final results = parsed['results'];
        final List staffData = results != null ? results['data'] ?? [] : [];

        setState(() {
          sta = staffData.map<Map<String, dynamic>>((staff) {
            return {
              'id': staff['id'],
              'eid': staff['eid'],
              'name': staff['name'] ?? '',
              'email': staff['email'],
              'phone': staff['phone'],
              'designation': staff['designation'],
              'department_name': staff['department_name'],
            };
          }).toList();
        });
      }
    } catch (error) {
      debugPrint("Staff fetch error: $error");
    } finally {
      if (mounted) {
        setState(() {
          isStaffLoading = false;
        });
      }
    }
  }

  Future<void> getMyTeamDetails() async {
    try {
      setState(() => isLoading = true);

      final token = await gettokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/staff/attendance/my/team/details/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("MY TEAM DETAILS STATUS: ${response.statusCode}");
      debugPrint("MY TEAM DETAILS RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final List data = List.from(parsed['data'] ?? []);

        setState(() {
          myTeams = data.map<Map<String, dynamic>>((team) {
            return {
              'team_id': team['team_id'],
              'team_name': team['team_name'] ?? '',
              'team_leader': team['team_leader'],
              'team_leader_name': team['team_leader_name'] ?? '',
              'is_team_leader': team['is_team_leader'] ?? false,
              'members_count': team['members_count'] ?? 0,
              'members': List<Map<String, dynamic>>.from(
                (team['members'] ?? []).map((member) {
                  return {
                    'id': member['id'],
                    'team': team['team_id'],
                    'team_name': team['team_name'] ?? '',
                    'member': member['member'],
                    'member_name': member['member_name'] ?? '',
                  };
                }),
              ),
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("My team details fetch error: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> saveTeamMember() async {
    if (selectedTeamId == null) {
      showMsg("Select team");
      return;
    }

    if (selectedMemberId == null) {
      showMsg("Select member");
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      final token = await gettokenFromPrefs();

      final body = {
        "team": selectedTeamId,
        "member": selectedMemberId,
      };

      final url = editingId == null
          ? '$api/api/staff/attendance/team/members/'
          : '$api/api/staff/attendance/team/members/edit/$editingId/';

      final response = editingId == null
          ? await http.post(
              Uri.parse(url),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(body),
            )
          : await http.put(
              Uri.parse(url),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(body),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        showMsg(
          editingId == null
              ? "Team member added successfully"
              : "Team member updated successfully",
        );

        clearForm();
        await getMyTeamDetails();
      } else {
        showMsg("Failed: ${response.body}");
      }
    } catch (e) {
      debugPrint("Save team member error: $e");
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void editTeamMember(Map<String, dynamic> item) {
    setState(() {
      editingId = item['id'];
      selectedTeamId = item['team'];
      selectedMemberId = item['member'];
    });
  }

  void clearForm() {
    setState(() {
      editingId = null;
      selectedTeamId = null;
      selectedMemberId = null;
    });
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  int get totalMembers {
    int total = 0;
    for (var team in myTeams) {
      total += (team['members'] as List).length;
    }
    return total;
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
          "Team Members",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: getMyTeamDetails,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: getMyTeamDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormCard(),
              const SizedBox(height: 22),
              _buildListHeader(),
              const SizedBox(height: 12),
              _buildTeamCards(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListHeader() {
    return Row(
      children: [
        const Text(
          "Team Member List",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xff111827),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xffdbeafe),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "$totalMembers Members",
            style: const TextStyle(
              color: Color(0xff1d4ed8),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xffeff6ff),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  editingId == null ? Icons.person_add_alt_1 : Icons.edit,
                  color: const Color(0xff2563eb),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                editingId == null ? "Add Team Member" : "Edit Team Member",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownSearch<Map<String, dynamic>>(
            selectedItem: selectedTeamId == null
                ? null
                : teams.firstWhere(
                    (team) => team['id'] == selectedTeamId,
                    orElse: () => {},
                  ),
            items: teams,
            itemAsString: (team) =>
                team.isEmpty ? "" : "${team['team_name']}",
            popupProps: PopupProps.menu(
              showSearchBox: true,
              menuProps: MenuProps(
                borderRadius: BorderRadius.circular(14),
              ),
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: "Search team",
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: const Color(0xfff8fafc),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                labelText: "Team",
                prefixIcon: const Icon(Icons.groups_outlined),
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
                selectedTeamId = value?['id'];
              });
            },
          ),
          const SizedBox(height: 10),
          DropdownSearch<Map<String, dynamic>>(
            selectedItem: selectedMemberId == null
                ? null
                : sta.firstWhere(
                    (staff) => staff['id'] == selectedMemberId,
                    orElse: () => {},
                  ),
            items: sta,
            itemAsString: (staff) => staff.isEmpty ? "" : "${staff['name']}",
            popupProps: PopupProps.menu(
              showSearchBox: true,
              menuProps: MenuProps(
                borderRadius: BorderRadius.circular(14),
              ),
              searchFieldProps: TextFieldProps(
                controller: staffSearchController,
                decoration: InputDecoration(
                  hintText: "Search member",
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: getstaff,
                  ),
                  filled: true,
                  fillColor: const Color(0xfff8fafc),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                labelText: "Member",
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
                selectedMemberId = value?['id'];
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : saveTeamMember,
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
                          editingId == null
                              ? Icons.add_circle_outline
                              : Icons.check_circle_outline,
                          size: 18,
                        ),
                  label: Text(
                    editingId == null ? "Add Member" : "Update",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2563eb),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (editingId != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: clearForm,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text("Cancel"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xffef4444),
                      side: const BorderSide(color: Color(0xfffecaca)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCards() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (myTeams.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 45,
              color: Colors.grey,
            ),
            SizedBox(height: 10),
            Text(
              "No team members found",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: myTeams.map<Widget>((team) {
        final List members = team['members'] ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
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
                        fontWeight: FontWeight.w800,
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
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
              const Text(
                "Members",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff111827),
                ),
              ),
              const SizedBox(height: 8),
              members.isEmpty
                  ? const Text(
                      "No members found",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : Column(
                      children: members.map<Widget>((member) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xffe5e7eb),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 17,
                                backgroundColor: Color(0xfff1f5f9),
                                child: Icon(
                                  Icons.person_outline,
                                  size: 18,
                                  color: Color(0xff475569),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  member['member_name'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xff111827),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => editTeamMember(
                                  Map<String, dynamic>.from(member),
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  color: Color(0xff2563eb),
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        );
      }).toList(),
    );
  }
}