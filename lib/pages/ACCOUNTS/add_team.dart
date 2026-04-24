import 'dart:convert';

import 'package:beposoft/Sales%20Directors/SD_dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
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

class AddTeam extends StatefulWidget {
  final int? teamId;

  const AddTeam({super.key, this.teamId});

  @override
  State<AddTeam> createState() => _AddTeamState();
}

class _AddTeamState extends State<AddTeam> {
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> fam = [];
  List<Map<String, dynamic>> sta = [];
  List<Map<String, dynamic>> teams = [];

  bool isLoadingTeams = false;
  bool isLoadingFamily = false;
  bool isLoadingStaff = false;
  bool isSubmitting = false;
  bool isLoadingTeamDetails = false;

  final TextEditingController teamNameController = TextEditingController();

  int? selectedFamilyId;
  int? selectedStaffId;
  Map<String, dynamic>? selectedFamilyMap;
  Map<String, dynamic>? selectedStaffMap;

  @override
  void initState() {
    super.initState();
    initializePage();
  }

  @override
  void dispose() {
    teamNameController.dispose();
    super.dispose();
  }

  Future<void> initializePage() async {
    if (widget.teamId != null) {
      await Future.wait([
        getFamily(),
        getStaff(),
      ]);
      await getTeamDetails(widget.teamId!);
    } else {
      await Future.wait([
        getFamily(),
        getStaff(),
        getTeams(),
      ]);
    }
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> getStaff() async {
    try {
      setState(() {
        isLoadingStaff = true;
      });

      final token = await getTokenFromPrefs();
      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.get(
        Uri.parse('$api/api/staffs/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final List staffData = parsed['data'] ?? [];

        setState(() {
          sta = staffData.map<Map<String, dynamic>>((staff) {
            return {
              'id': staff['id'],
              'name': staff['name']?.toString() ?? '',
              'email': staff['email']?.toString() ?? '',
              'designation': staff['designation']?.toString() ?? '',
              'image': staff['image']?.toString() ?? '',
              'approval_status': staff['approval_status']?.toString() ?? '',
            };
          }).toList();
        });
      } else {
        debugPrint("Staff fetch failed: ${response.statusCode}");
      }
    } catch (error) {
      debugPrint("Staff fetch error: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading staff: $error"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingStaff = false;
        });
      }
    }
  }

  Future<void> getFamily() async {
    try {
      setState(() {
        isLoadingFamily = true;
      });

      final token = await getTokenFromPrefs();
      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.get(
        Uri.parse('$api/api/familys/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final List familyData = parsed['data'] ?? [];

        setState(() {
          fam = familyData.map<Map<String, dynamic>>((family) {
            return {
              'id': family['id'],
              'name': family['name']?.toString() ?? '',
            };
          }).toList();
        });
      } else {
        debugPrint("Family fetch failed: ${response.statusCode}");
      }
    } catch (error) {
      debugPrint("Family fetch error: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading families: $error"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingFamily = false;
        });
      }
    }
  }

  Future<void> getTeams() async {
    try {
      setState(() {
        isLoadingTeams = true;
      });

      final token = await getTokenFromPrefs();
      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.get(
        Uri.parse('$api/api/sales/teams/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final List teamData = parsed['data'] ?? [];

        setState(() {
          teams = teamData.map<Map<String, dynamic>>((team) {
            return {
              "id": team["id"],
              "name": team["name"]?.toString() ?? "",
              "family_name": team["division"] is Map
                  ? team["division"]["name"]?.toString() ?? ""
                  : team["division_name"]?.toString() ?? "",
              "staff_name": team["team_leader"] is Map
                  ? team["team_leader"]["name"]?.toString() ?? ""
                  : team["team_leader_name"]?.toString() ?? "",
              "team_leader": team["team_leader"],
              "division": team["division"],
            };
          }).toList();
        });
      }
    } catch (error) {
      debugPrint("Get teams error: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading teams: $error"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingTeams = false;
        });
      }
    }
  }

  Future<void> getTeamDetails(int teamId) async {
    try {
      setState(() {
        isLoadingTeamDetails = true;
      });

      final token = await getTokenFromPrefs();
      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.get(
        Uri.parse('$api/api/sales/teams/edit/$teamId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final data = parsed["data"] ?? parsed;

        final int? divisionId =
            data["division"] is Map ? data["division"]["id"] : data["division"];
        final int? leaderId = data["team_leader"] is Map
            ? data["team_leader"]["id"]
            : data["team_leader"];

        setState(() {
          teamNameController.text = data["name"]?.toString() ?? "";
          selectedFamilyId = divisionId;
          selectedStaffId = leaderId;

          if (divisionId != null && fam.isNotEmpty) {
            try {
              selectedFamilyMap =
                  fam.firstWhere((item) => item['id'] == divisionId);
            } catch (e) {
              selectedFamilyMap = null;
            }
          }

          if (leaderId != null && sta.isNotEmpty) {
            try {
              selectedStaffMap =
                  sta.firstWhere((item) => item['id'] == leaderId);
            } catch (e) {
              selectedStaffMap = null;
            }
          }
        });
      } else {
        final parsed = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                parsed["message"] ??
                    parsed["detail"] ??
                    parsed["error"] ??
                    "Failed to load team details",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      debugPrint("Get team details error: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Something went wrong while loading team details"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingTeamDetails = false;
        });
      }
    }
  }

  Future<void> addTeam() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        isSubmitting = true;
      });

      final token = await getTokenFromPrefs();
      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.post(
        Uri.parse('$api/api/sales/teams/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "name": teamNameController.text.trim(),
          "team_leader": selectedStaffId,
          "division": selectedFamilyId,
        }),
      );

      final parsed = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          teamNameController.clear();
          selectedFamilyId = null;
          selectedStaffId = null;
          selectedFamilyMap = null;
          selectedStaffMap = null;
        });

        await getTeams();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(parsed["message"] ?? "Team added successfully"),
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
                    "Failed to add team",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      debugPrint("Add team error: $error");
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

  Future<void> updateTeam(int teamId) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        isSubmitting = true;
      });

      final token = await getTokenFromPrefs();
      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.put(
        Uri.parse('$api/api/sales/teams/edit/$teamId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "name": teamNameController.text.trim(),
          "team_leader": selectedStaffId,
          "division": selectedFamilyId,
        }),
      );

      final parsed = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await getTeams();

        print("reeeeesssssss ${response.body}");

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(parsed["message"] ?? "Team updated successfully"),
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
                    "Failed to update team",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      debugPrint("Update team error: $error");
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

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

   Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();
    if (dep == "BDO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                bdo_dashbord()), // Replace AnotherPage with your target page
      );
    } else if (dep == "BDM") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                bdm_dashbord()), // Replace AnotherPage with your target page
      );
    } 
    else if (dep == "SD") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                SdDashboard()), // Replace AnotherPage with your target page
      );
    } 
    else if (dep == "warehouse") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                WarehouseDashboard()), // Replace AnotherPage with your target page
      );
    } else if(dep=="CEO" ){
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
else if (dep == "Warehouse Admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                WarehouseAdmin()), // Replace AnotherPage with your target page
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => dashboard()),
      );
    }
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

  Widget _buildInfoRow(String label, String value) {
    return Container(
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

  Widget _buildSubmittedTeamsList() {
    if (isLoadingTeams) {
      return const Padding(
        padding: EdgeInsets.only(top: 18),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (teams.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "No teams added yet",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Column(
      children: teams.map((team) {
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
                      "Team Details",
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      if (value == "edit") {
                        Future.delayed(const Duration(milliseconds: 100),
                            () async {
                          if (!mounted) return;

                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddTeam(teamId: team["id"]),
                            ),
                          );

                          if (result == true) {
                            await getTeams();
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
              _buildInfoRow("Team Name", team["name"]?.toString() ?? "-"),
              const SizedBox(height: 10),
              _buildInfoRow("Family", team["family_name"]?.toString() ?? "-"),
              const SizedBox(height: 10),
              _buildInfoRow(
                  "Staff Leader", team["staff_name"]?.toString() ?? "-"),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditMode = widget.teamId != null;

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
          isEditMode ? "Edit Team" : "Add Team",
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: isLoadingTeamDetails
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
                          _buildLabel("Team Name *"),
                          TextFormField(
                            controller: teamNameController,
                            decoration: _inputDecoration("Enter team name"),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Please enter team name";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          _buildLabel("Select Family *"),
                          isLoadingFamily
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
                                  hintText: "Choose family",
                                  selectedItem: selectedFamilyMap,
                                  items: fam,
                                  itemAsString: (item) =>
                                      item['name']?.toString() ?? '',
                                  onChanged: (value) {
                                    setState(() {
                                      selectedFamilyMap = value;
                                      selectedFamilyId = value?['id'];
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return "Please select a family";
                                    }
                                    return null;
                                  },
                                ),
                          const SizedBox(height: 18),
                          _buildLabel("Select Staff Leader *"),
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
                                  hintText: "Choose staff leader",
                                  selectedItem: selectedStaffMap,
                                  items: sta,
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
                                      return "Please select a staff leader";
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
                                      if (_formKey.currentState!.validate()) {
                                        if (isEditMode) {
                                          updateTeam(widget.teamId!);
                                        } else {
                                          addTeam();
                                        }
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
                                      isEditMode ? "Update Team" : "Add Team",
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
                    _buildSubmittedTeamsList(),
                  ],
                ],
              ),
            ),
    );
  }
}
