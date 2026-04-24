import 'dart:convert';

import 'package:beposoft/Sales%20Directors/SD_dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddTeamMembers extends StatefulWidget {
  final int? memberId;

  const AddTeamMembers({super.key, this.memberId});

  @override
  State<AddTeamMembers> createState() => _AddTeamMembersState();
}

class _AddTeamMembersState extends State<AddTeamMembers> {
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> teams = [];
  List<Map<String, dynamic>> allStaff = [];
  List<Map<String, dynamic>> members = [];

  Map<String, dynamic>? selectedTeamMap;
  Map<String, dynamic>? selectedStaffMap;

  int? selectedTeamId;
  int? selectedStaffId;
  int? loggedInUserId;

  bool isLoadingTeams = false;
  bool isLoadingStaff = false;
  bool isLoadingMembers = false;
  bool isLoadingEditDetails = false;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    initializePage();
  }

  Future<void> initializePage() async {
    await getLoggedInUserId();

    await Future.wait([
      getTeams(),
      getStaff(),
    ]);

    if (widget.memberId != null) {
      await getMemberDetails(widget.memberId!);
    }
  }

   Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }


   Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();
    if (!mounted) return;

    if (dep == "BDO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => bdo_dashbord()),
      );
    } else if (dep == "SD") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SdDashboard()),
      );
    } else if (dep == "BDM") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => bdm_dashbord()),
      );
    } else if (dep == "warehouse") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WarehouseDashboard()),
      );
    } else if (dep == "Warehouse Admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WarehouseAdmin()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => dashboard()),
      );
    }
  }


  Future<String?> gettokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> getLoggedInUserId() async {
    final prefs = await SharedPreferences.getInstance();

    final dynamic storedUserId = prefs.get('user_id');

    if (storedUserId is int) {
      loggedInUserId = storedUserId;
    } else if (storedUserId is String) {
      loggedInUserId = int.tryParse(storedUserId);
    }

    debugPrint("LOGGED IN USER ID: $loggedInUserId");
  }

  Future<void> getTeams() async {
    try {
      setState(() {
        isLoadingTeams = true;
      });

      final token = await gettokenFromPrefs();
      if (token == null) {
        throw Exception("Token not found");
      }

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

        final filteredTeams = data.where((item) {
          final dynamic rawLeaderId = item["team_leader"];
          final int? leaderId = rawLeaderId is int
              ? rawLeaderId
              : int.tryParse(rawLeaderId?.toString() ?? '');

          return leaderId == loggedInUserId;
        }).map<Map<String, dynamic>>((item) {
          return {
            "id": item["id"],
            "name": item["name"]?.toString() ?? "",
            "division_id": item["division"] is Map
                ? item["division"]["id"]
                : item["division"],
            "division_name": item["division_name"]?.toString() ??
                (item["division"] is Map
                    ? item["division"]["name"]?.toString() ?? ""
                    : ""),
            "team_leader": item["team_leader"],
            "team_leader_name": item["team_leader_name"]?.toString() ?? "",
          };
        }).toList();

        setState(() {
          teams = filteredTeams;

          if (widget.memberId == null && teams.isNotEmpty) {
            selectedTeamMap = teams.first;
            selectedTeamId = teams.first["id"];
          }
        });

        if (widget.memberId == null && selectedTeamId != null) {
          await getMembers();
        }
      } else {
        setState(() {
          teams = [];
          selectedTeamMap = null;
          selectedTeamId = null;
        });
      }
    } catch (e) {
      debugPrint("Get teams error: $e");
      setState(() {
        teams = [];
        selectedTeamMap = null;
        selectedTeamId = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoadingTeams = false;
        });
      }
    }
  }

  Future<void> getStaff() async {
    try {
      setState(() {
        isLoadingStaff = true;
      });

      final token = await gettokenFromPrefs();
      if (token == null) {
        throw Exception("Token not found");
      }

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
        final List data = parsed['data'] ?? [];

        setState(() {
          allStaff = data.where((item) {
            final dept =
                item['department_name']?.toString().trim().toUpperCase() ?? '';
            return dept == 'BDO' || dept == 'BDM';
          }).map<Map<String, dynamic>>((item) {
            return {
              'id': item['id'],
              'name': item['name']?.toString() ?? '',
              'email': item['email']?.toString() ?? '',
              'designation': item['designation']?.toString() ?? '',
              'image': item['image']?.toString() ?? '',
              'approval_status': item['approval_status']?.toString() ?? '',
              'family_name': item['family_name']?.toString() ?? '',
              'family_id':
                  item['family'] is Map ? item['family']['id'] : item['family'],
              'department_name': item['department_name']?.toString() ?? '',
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Get staff error: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoadingStaff = false;
        });
      }
    }
  }

  Future<void> getMembers() async {
    try {
      setState(() {
        isLoadingMembers = true;
      });

      final token = await gettokenFromPrefs();
      if (token == null) {
        throw Exception("Token not found");
      }

      final response = await http.get(
        Uri.parse('$api/api/sales/team/members/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("GET MEMBERS RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final List data = parsed['data'] ?? [];

        setState(() {
          members = data.where((item) {
            final dynamic rawTeamId = item["team"];
            final int? teamId = rawTeamId is int
                ? rawTeamId
                : int.tryParse(rawTeamId?.toString() ?? '');
            return teamId == selectedTeamId;
          }).map<Map<String, dynamic>>((item) {
            return {
              "id": item["id"],
              "team": item["team"],
              "team_name": item["team_name"]?.toString() ?? "",
              "user": item["user"],
              "user_name": item["user_name"]?.toString() ?? "",
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Get members error: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoadingMembers = false;
        });
      }
    }
  }

  Future<void> getMemberDetails(int memberId) async {
    try {
      setState(() {
        isLoadingEditDetails = true;
      });

      final token = await gettokenFromPrefs();
      if (token == null) {
        throw Exception("Token not found");
      }

      final response = await http.get(
        Uri.parse('$api/api/sales/team/members/edit/$memberId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("GET MEMBER DETAILS RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final data = parsed["data"] ?? parsed;

        final int? teamId =
            data["team"] is Map ? data["team"]["id"] : data["team"];
        final int? userId =
            data["user"] is Map ? data["user"]["id"] : data["user"];

        Map<String, dynamic>? teamMap;
        try {
          teamMap = teams.firstWhere((item) => item["id"] == teamId);
        } catch (_) {
          teamMap = null;
        }

        Map<String, dynamic>? userMap;
        try {
          userMap = allStaff.firstWhere((item) => item["id"] == userId);
        } catch (_) {
          userMap = null;
        }

        setState(() {
          selectedTeamId = teamMap?["id"] ?? teamId;
          selectedStaffId = userId;
          selectedTeamMap = teamMap;
          selectedStaffMap = userMap;
        });

        await getMembers();
      }
    } catch (e) {
      debugPrint("Get member details error: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoadingEditDetails = false;
        });
      }
    }
  }

  Future<void> addMember() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        isSubmitting = true;
      });

      final token = await gettokenFromPrefs();
      if (token == null) {
        throw Exception("Token not found");
      }

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


      final parsed = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          selectedStaffMap = null;
          selectedStaffId = null;
        });

        await getMembers();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(parsed["message"] ?? "Team member added successfully"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                parsed["message"] ??
                    parsed["detail"] ??
                    parsed["error"] ??
                    "Failed to add team member",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Add member error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Something went wrong"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  Future<void> updateMember(int memberId) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        isSubmitting = true;
      });

      final token = await gettokenFromPrefs();
      if (token == null) {
        throw Exception("Token not found");
      }

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

      final parsed = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await getMembers();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(parsed["message"] ?? "Team member updated successfully"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                parsed["message"] ??
                    parsed["detail"] ??
                    parsed["error"] ??
                    "Failed to update team member",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Update member error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Something went wrong"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
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

  Widget _buildLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
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

  Widget _buildInfoRow(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    if (isLoadingMembers) {
      return const Padding(
        padding: EdgeInsets.only(top: 18),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (selectedTeamId == null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "No team selected",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (members.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "No team members added yet",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Column(
      children: members.map((member) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 18),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Team Member Details",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: Color(0xFF0F172A),
                    ),
                    onSelected: (value) {
                      if (value == "edit") {
                        Future.delayed(const Duration(milliseconds: 100),
                            () async {
                          if (!mounted) return;

                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddTeamMembers(memberId: member["id"]),
                            ),
                          );

                          if (result == true && mounted) {
                            await getMembers();
                          }
                        });
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: "edit",
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 10),
                            Text("Edit"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildInfoRow("Team", member["team_name"]?.toString() ?? "-"),
              const SizedBox(height: 10),
              _buildInfoRow("Staff", member["user_name"]?.toString() ?? "-"),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.memberId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () async {
              await _navigateBack();
            },
          ),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          isEditMode ? "Edit Team Members" : "Add Team Members",
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: isLoadingEditDetails
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Form(
                    key: _formKey,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          _buildLabel("Select Team *"),
                          isLoadingTeams
                              ? Container(
                                  height: 58,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: const CircularProgressIndicator(),
                                )
                              : _buildDropdownSearchField<Map<String, dynamic>>(
                                  hintText: "Choose team",
                                  selectedItem: selectedTeamMap,
                                  items: teams,
                                  itemAsString: (item) =>
                                      item['name']?.toString() ?? '',
                                  onChanged: (value) async {
                                    setState(() {
                                      selectedTeamMap = value;
                                      selectedTeamId = value?["id"];
                                      selectedStaffMap = null;
                                      selectedStaffId = null;
                                    });
                                    await getMembers();
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return "Please select a team";
                                    }
                                    return null;
                                  },
                                ),
                          const SizedBox(height: 18),
                          _buildLabel("Select Staff *"),
                          isLoadingStaff
                              ? Container(
                                  height: 58,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: const CircularProgressIndicator(),
                                )
                              : _buildDropdownSearchField<Map<String, dynamic>>(
                                  hintText: "Choose staff",
                                  selectedItem: selectedStaffMap,
                                  items: allStaff,
                                  itemAsString: (item) =>
                                      item['name']?.toString() ?? '',
                                  onChanged: (value) {
                                    setState(() {
                                      selectedStaffMap = value;
                                      selectedStaffId = value?['id'];
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return "Please select a staff";
                                    }
                                    return null;
                                  },
                                ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () {
                                      if (isEditMode) {
                                        updateMember(widget.memberId!);
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
                                      isEditMode
                                          ? "Update Team Member"
                                          : "Add Team Member",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isEditMode) ...[
                    const SizedBox(height: 20),
                    _buildMembersList(),
                  ],
                ],
              ),
            ),
    );
  }
}
