import 'dart:convert';
import 'package:beposoft/pages/api.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StaffAttendanceTeamScreen extends StatefulWidget {
  const StaffAttendanceTeamScreen({super.key});

  @override
  State<StaffAttendanceTeamScreen> createState() =>
      _StaffAttendanceTeamScreenState();
}

class _StaffAttendanceTeamScreenState extends State<StaffAttendanceTeamScreen> {
  final TextEditingController teamNameController = TextEditingController();

  List<Map<String, dynamic>> sta = [];
  List<Map<String, dynamic>> teams = [];

  int? selectedTeamLeader;
  int? editingTeamId;

  bool isLoading = false;
  bool isSaving = false;



 Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  void initState() {
    super.initState();
    getstaff();
    getTeams();
  }

  Future<void> getstaff() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/staff/managers/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> stafflist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          stafflist.add({
            'id': productData['id'],
            'name': productData['name'],
            'email': productData['email'],
          });
        }

        setState(() {
          sta = stafflist;
        });
      }
    } catch (error) {
      debugPrint("Staff fetch error: $error");
    }
  }

  Future<void> getTeams() async {
    try {
      setState(() {
        isLoading = true;
      });

      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/staff/attendance/teams/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List data = parsed is List ? parsed : parsed['data'];

        setState(() {
          teams = data.map<Map<String, dynamic>>((item) {
  return {
    'id': item['id'],
    'team_name': item['team_name'],
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
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> saveTeam() async {
    if (teamNameController.text.trim().isEmpty) {
      showMsg("Enter team name");
      return;
    }

    if (selectedTeamLeader == null) {
      showMsg("Select team Manager");
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      final token = await gettokenFromPrefs();

      final body = {
        "team_name": teamNameController.text.trim(),
        "team_leader": selectedTeamLeader,
      };

      final url = editingTeamId == null
          ? '$api/api/staff/attendance/teams/'
          : '$api/api/staff/attendance/teams/edit/$editingTeamId/';

      final response = editingTeamId == null
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
        showMsg(editingTeamId == null
            ? "Team added successfully"
            : "Team updated successfully");

        clearForm();
        getTeams();
      } else {
        showMsg("Failed: ${response.body}");
      }
    } catch (error) {
      debugPrint("Save team error: $error");
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  void editTeam(Map<String, dynamic> team) {
    setState(() {
      editingTeamId = team['id'];
      teamNameController.text = team['team_name'] ?? '';
      selectedTeamLeader = team['team_leader'];
    });
  }

  void clearForm() {
    setState(() {
      editingTeamId = null;
      teamNameController.clear();
      selectedTeamLeader = null;
    });
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
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
        "Attendance Teams",
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      actions: [
        IconButton(
          onPressed: getTeams,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: getTeams,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Container(
            //   width: double.infinity,
            //   padding: const EdgeInsets.all(18),
            //   decoration: BoxDecoration(
            //     gradient: const LinearGradient(
            //       colors: [
            //         Color(0xff1e3a8a),
            //         Color(0xff2563eb),
            //       ],
            //     ),
            //     borderRadius: BorderRadius.circular(20),
            //     boxShadow: [
            //       BoxShadow(
            //         color: Colors.blue.withOpacity(0.25),
            //         blurRadius: 18,
            //         offset: const Offset(0, 8),
            //       ),
            //     ],
            //   ),
            //   child: Row(
            //     children: [
            //       Container(
            //         padding: const EdgeInsets.all(14),
            //         decoration: BoxDecoration(
            //           color: Colors.white.withOpacity(0.18),
            //           borderRadius: BorderRadius.circular(16),
            //         ),
            //         child: const Icon(
            //           Icons.groups_rounded,
            //           color: Colors.white,
            //           size: 34,
            //         ),
            //       ),
            //       const SizedBox(width: 14),
            //       Expanded(
            //         child: Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             Text(
            //               editingTeamId == null
            //                   ? "Create Attendance Team"
            //                   : "Update Attendance Team",
            //               style: const TextStyle(
            //                 color: Colors.white,
            //                 fontSize: 18,
            //                 fontWeight: FontWeight.w800,
            //               ),
            //             ),
            //             const SizedBox(height: 4),
            //             Text(
            //               "Manage team name and team leader",
            //               style: TextStyle(
            //                 color: Colors.white.withOpacity(0.85),
            //                 fontSize: 13,
            //               ),
            //             ),
            //           ],
            //         ),
            //       ),
            //     ],
            //   ),
            // ),

         const SizedBox(height: 10),

Container(
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
    crossAxisAlignment: CrossAxisAlignment.start,
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
              editingTeamId == null ? Icons.add_rounded : Icons.edit_rounded,
              color: const Color(0xff2563eb),
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            editingTeamId == null ? "Add Team" : "Edit Team",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xff111827),
            ),
          ),
        ],
      ),

      const SizedBox(height: 10),

      TextField(
        controller: teamNameController,
        decoration: InputDecoration(
          labelText: "Team Name",
          labelStyle: const TextStyle(fontSize: 13),
          hintText: "Enter team name",
          hintStyle: const TextStyle(fontSize: 13),
          prefixIcon: const Icon(Icons.badge_outlined, size: 20),
          filled: true,
          fillColor: const Color(0xfff8fafc),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xffe5e7eb)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xff2563eb),
              width: 1.3,
            ),
          ),
        ),
      ),

      const SizedBox(height: 10),

      DropdownSearch<Map<String, dynamic>>(
        selectedItem: selectedTeamLeader == null
            ? null
            : sta.firstWhere(
                (staff) => staff['id'] == selectedTeamLeader,
                orElse: () => {},
              ),
        items: sta,
        itemAsString: (staff) =>
            staff.isEmpty ? "" : "${staff['name']}",
        popupProps: PopupProps.menu(
          showSearchBox: true,
          menuProps: MenuProps(
            borderRadius: BorderRadius.circular(14),
          ),
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: "Search team manager",
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: const Color(0xfff8fafc),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            labelText: "Team Manager",
            labelStyle: const TextStyle(fontSize: 13),
            prefixIcon: const Icon(Icons.person_search_outlined, size: 20),
            filled: true,
            fillColor: const Color(0xfff8fafc),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xffe5e7eb)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xff2563eb),
                width: 1.3,
              ),
            ),
          ),
        ),
        onChanged: (value) {
          setState(() {
            selectedTeamLeader = value?['id'];
          });
        },
      ),

      const SizedBox(height: 12),

      Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : saveTeam,
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
                      editingTeamId == null
                          ? Icons.add_circle_outline
                          : Icons.check_circle_outline,
                      size: 18,
                    ),
              label: Text(
                editingTeamId == null ? "Add Team" : "Update Team",
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
          if (editingTeamId != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: clearForm,
                icon: const Icon(Icons.close, size: 18),
                label: const Text(
                  "Cancel",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
),

const SizedBox(height: 22),

            Row(
              children: [
                const Text(
                  "Team List",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff111827),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffdbeafe),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${teams.length} Teams",
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

            isLoading
                ? const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : teams.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.groups_2_outlined,
                              size: 45,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 10),
                            Text(
                              "No teams found",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: teams.length,
                        itemBuilder: (context, index) {
                          final team = teams[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
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
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xffeff6ff),
                                child: Text(
                                  "${index + 1}",
                                  style: const TextStyle(
                                    color: Color(0xff2563eb),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              title: Text(
                                team['team_name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xff111827),
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.person_outline,
                                      size: 16,
                                      color: Color(0xff64748b),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        "Team Manager: ${team['team_leader_name']}",
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xff64748b),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: InkWell(
                                onTap: () => editTeam(team),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffeff6ff),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.edit_outlined,
                                    color: Color(0xff2563eb),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    ),
  );
}

}