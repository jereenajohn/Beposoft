import 'dart:convert';

import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceDepartmentPage extends StatefulWidget {
  const AttendanceDepartmentPage({
    super.key,
    required this.baseUrl,
  });

  final String baseUrl;

  @override
  State<AttendanceDepartmentPage> createState() =>
      _AttendanceDepartmentPageState();
}

class _AttendanceDepartmentPageState extends State<AttendanceDepartmentPage> {
  final GlobalKey<FormState> _createFormKey = GlobalKey<FormState>();

  final TextEditingController _departmentNameController =
      TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool loading = false;
  bool tableLoading = false;
  bool staffLoading = false;
  bool submitting = false;

  String token = '';
  String pageError = '';
  String searchText = '';

  int? viewLoadingId;

  List<AttendanceDepartmentModel> departments = [];
  List<StaffModel> staffList = [];

  StaffModel? selectedTeamLeader;
  String? selectedTeamLeaderError;

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  @override
  void dispose() {
    _departmentNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initPage() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? '';

    if (!mounted) return;

    if (token.isEmpty) {
      setState(() {
        pageError = 'Token not found';
      });
      return;
    }

    setState(() {
      loading = true;
      pageError = '';
    });

    await Future.wait([
      fetchDepartments(showLoader: false),
      fetchStaffs(),
    ]);

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  Map<String, String> get headers {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Uri buildUri(String endpoint, [Map<String, String>? queryParameters]) {
    final base =
        widget.baseUrl.endsWith('/') ? widget.baseUrl : '${widget.baseUrl}/';

    final cleanedParams = <String, String>{};

    if (queryParameters != null) {
      queryParameters.forEach((key, value) {
        if (value.trim().isNotEmpty) {
          cleanedParams[key] = value;
        }
      });
    }

    return Uri.parse('$base$endpoint').replace(
      queryParameters: cleanedParams.isEmpty ? null : cleanedParams,
    );
  }

  Future<void> fetchDepartments({bool showLoader = true}) async {
    try {
      if (showLoader && mounted) {
        setState(() {
          tableLoading = true;
          pageError = '';
        });
      }

      final response = await http.get(
        buildUri('api/staff/attendance/teams/'),
        headers: headers,
      );

      final decodedBody = _decodeResponse(response.body);

      if (response.statusCode == 200) {
        final rawData = decodedBody['data'];

        final departmentList = rawData is List
            ? rawData
                .map(
                  (item) => AttendanceDepartmentModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
            : <AttendanceDepartmentModel>[];

        if (!mounted) return;

        setState(() {
          departments = departmentList;
          pageError = '';
        });
      } else {
        final message = _extractErrorMessage(
          decodedBody,
          fallback: 'Failed to fetch departments',
        );

        if (!mounted) return;

        setState(() {
          departments = [];
          pageError = message;
        });

        showMsg(message, isError: true);
      }
    } catch (e) {
      final message = 'Failed to fetch departments: $e';

      if (!mounted) return;

      setState(() {
        departments = [];
        pageError = message;
      });

      showMsg(message, isError: true);
    } finally {
      if (mounted && showLoader) {
        setState(() {
          tableLoading = false;
        });
      }
    }
  }

  Future<void> fetchStaffs() async {
    try {
      if (mounted) {
        setState(() {
          staffLoading = true;
        });
      }

      final response = await http.get(
        buildUri('api/staff/managers/'),
        headers: headers,
      );

      final decodedBody = _decodeResponse(response.body);

      if (response.statusCode == 200) {
        final rawData = decodedBody['data'];

        final staffs = rawData is List
            ? rawData
                .map(
                  (item) => StaffModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
            : <StaffModel>[];

        if (!mounted) return;

        setState(() {
          staffList = staffs;
        });
      } else {
        final message = _extractErrorMessage(
          decodedBody,
          fallback: 'Failed to fetch staff list',
        );

        if (!mounted) return;

        setState(() {
          staffList = [];
        });

        showMsg(message, isError: true);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        staffList = [];
      });

      showMsg('Failed to fetch staff list: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          staffLoading = false;
        });
      }
    }
  }

  Future<void> createDepartment() async {
    FocusScope.of(context).unfocus();

    setState(() {
      selectedTeamLeaderError =
          selectedTeamLeader == null ? 'Please select team leader' : null;
    });

    if (!_createFormKey.currentState!.validate() ||
        selectedTeamLeader == null) {
      return;
    }

    try {
      setState(() {
        submitting = true;
        pageError = '';
      });

      final payload = {
        'team_name': _departmentNameController.text.trim(),
        'team_leader': selectedTeamLeader!.id,
      };

      final response = await http.post(
        buildUri('api/staff/attendance/teams/'),
        headers: headers,
        body: jsonEncode(payload),
      );

      final decodedBody = _decodeResponse(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        showMsg('Department created successfully');

        _departmentNameController.clear();

        if (!mounted) return;

        setState(() {
          selectedTeamLeader = null;
          selectedTeamLeaderError = null;
        });

        await fetchDepartments(showLoader: false);
      } else {
        final message = _extractErrorMessage(
          decodedBody,
          fallback: 'Failed to create department',
        );

        if (!mounted) return;

        setState(() {
          pageError = message;
        });

        showMsg(message, isError: true);
      }
    } catch (e) {
      final message = 'Something went wrong: $e';

      if (!mounted) return;

      setState(() {
        pageError = message;
      });

      showMsg(message, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          submitting = false;
        });
      }
    }
  }

  Future<void> openEditDepartment(int departmentId) async {
    try {
      setState(() {
        viewLoadingId = departmentId;
        pageError = '';
      });

      final response = await http.get(
        buildUri('api/staff/attendance/teams/edit/$departmentId/'),
        headers: headers,
      );

      final decodedBody = _decodeResponse(response.body);

      if (response.statusCode == 200) {
        final departmentData = decodedBody['data'] is Map
            ? Map<String, dynamic>.from(decodedBody['data'])
            : decodedBody;

        final teamName = departmentData['team_name']?.toString() ?? '';

        final leaderId = _toInt(
          departmentData['team_leader'] ??
              departmentData['team_leader_id'] ??
              departmentData['leader_id'],
        );

        StaffModel? selectedLeader;

        if (leaderId != null) {
          selectedLeader = staffList.where((staff) => staff.id == leaderId).isNotEmpty
              ? staffList.firstWhere((staff) => staff.id == leaderId)
              : StaffModel(
                  id: leaderId,
                  name: departmentData['team_leader_name']?.toString() ??
                      'Selected Leader',
                );
        }

        if (!mounted) return;

        await showEditDepartmentDialog(
          departmentId: departmentId,
          initialTeamName: teamName,
          initialTeamLeader: selectedLeader,
        );
      } else {
        final message = _extractErrorMessage(
          decodedBody,
          fallback: 'Failed to fetch department details',
        );

        showMsg(message, isError: true);
      }
    } catch (e) {
      showMsg('Failed to fetch department details: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          viewLoadingId = null;
        });
      }
    }
  }

  Future<void> showEditDepartmentDialog({
    required int departmentId,
    required String initialTeamName,
    required StaffModel? initialTeamLeader,
  }) async {
    final GlobalKey<FormState> editFormKey = GlobalKey<FormState>();
    final TextEditingController editDepartmentController =
        TextEditingController(text: initialTeamName);

    StaffModel? editSelectedLeader = initialTeamLeader;
    String? editLeaderError;
    bool editSubmitting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !editSubmitting,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> updateDepartment() async {
              FocusScope.of(context).unfocus();

              setDialogState(() {
                editLeaderError = editSelectedLeader == null
                    ? 'Please select team leader'
                    : null;
              });

              if (!editFormKey.currentState!.validate() ||
                  editSelectedLeader == null) {
                return;
              }

              try {
                setDialogState(() {
                  editSubmitting = true;
                });

                final payload = {
                  'team_name': editDepartmentController.text.trim(),
                  'team_leader': editSelectedLeader!.id,
                };

                final response = await http.put(
                  buildUri('api/staff/attendance/teams/edit/$departmentId/'),
                  headers: headers,
                  body: jsonEncode(payload),
                );

                final decodedBody = _decodeResponse(response.body);

                if (response.statusCode == 200 || response.statusCode == 201) {
                  if (!mounted) return;

                  Navigator.pop(dialogContext);

                  showMsg('Department updated successfully');

                  await fetchDepartments(showLoader: false);
                } else {
                  final message = _extractErrorMessage(
                    decodedBody,
                    fallback: 'Failed to update department',
                  );

                  if (mounted) {
                    setState(() {
                      pageError = message;
                    });
                  }

                  showMsg(message, isError: true);
                }
              } catch (e) {
                final message = 'Something went wrong: $e';

                if (mounted) {
                  setState(() {
                    pageError = message;
                  });
                }

                showMsg(message, isError: true);
              } finally {
                if (mounted) {
                  setDialogState(() {
                    editSubmitting = false;
                  });
                }
              }
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              backgroundColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withOpacity(0.14),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Form(
                    key: editFormKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Edit Department',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: editSubmitting
                                    ? null
                                    : () => Navigator.pop(dialogContext),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                buildTextInput(
                                  label: 'Department Name',
                                  controller: editDepartmentController,
                                  hint: 'Enter department name',
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'Department name is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                buildStaffSelectorField(
                                  label: 'Team Leader',
                                  selectedStaff: editSelectedLeader,
                                  hint: staffLoading
                                      ? 'Loading staff...'
                                      : 'Select Team Leader',
                                  errorText: editLeaderError,
                                  disabled: staffLoading || editSubmitting,
                                  onTap: () async {
                                    final selected = await openStaffPicker(
                                      title: 'Select Team Leader',
                                      currentStaff: editSelectedLeader,
                                    );

                                    if (!mounted) return;

                                    setDialogState(() {
                                      editSelectedLeader = selected;
                                      editLeaderError = null;
                                    });
                                  },
                                  onClear: () {
                                    setDialogState(() {
                                      editSelectedLeader = null;
                                      editLeaderError =
                                          'Please select team leader';
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: editSubmitting
                                    ? null
                                    : () => Navigator.pop(dialogContext),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(110, 46),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed:
                                    editSubmitting ? null : updateDepartment,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(160, 46),
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      const Color(0xFF2563EB).withOpacity(0.45),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: editSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Update Department',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Future<StaffModel?> openStaffPicker({
    required String title,
    required StaffModel? currentStaff,
  }) async {
    final TextEditingController searchController = TextEditingController();
    StaffModel? selectedStaff = currentStaff;

    final result = await showModalBottomSheet<StaffModel?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        List<StaffModel> filteredStaffs = List<StaffModel>.from(staffList);

        return StatefulBuilder(
          builder: (context, setSheetState) {
            void filterStaffs(String value) {
              final query = value.trim().toLowerCase();

              setSheetState(() {
                filteredStaffs = query.isEmpty
                    ? List<StaffModel>.from(staffList)
                    : staffList.where((staff) {
                        return staff.name.toLowerCase().contains(query);
                      }).toList();
              });
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 18,
                  right: 18,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 18,
                ),
                child: SizedBox(
                  height: MediaQuery.of(sheetContext).size.height * 0.72,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(sheetContext, null);
                            },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        onChanged: filterStaffs,
                        decoration: inputDecoration(
                          hint: 'Search staff...',
                          prefixIcon: Icons.search_rounded,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (staffLoading)
                        const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (filteredStaffs.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text(
                              'No staff found',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            itemCount: filteredStaffs.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final staff = filteredStaffs[index];
                              final isSelected = selectedStaff?.id == staff.id;

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  staff.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFF2563EB),
                                      )
                                    : const Icon(
                                        Icons.chevron_right_rounded,
                                        color: Color(0xFF94A3B8),
                                      ),
                                onTap: () {
                                  Navigator.pop(sheetContext, staff);
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    return result;
  }

  List<AttendanceDepartmentModel> get filteredDepartments {
    final query = searchText.trim().toLowerCase();

    if (query.isEmpty) {
      return departments;
    }

    return departments.where((item) {
      final teamName = item.teamName.toLowerCase();
      final leaderName = item.teamLeaderName.toLowerCase();

      return teamName.contains(query) || leaderName.contains(query);
    }).toList();
  }

  int get totalDepartments => departments.length;

  int get showingDepartments => filteredDepartments.length;

  Map<String, dynamic> _decodeResponse(String responseBody) {
    if (responseBody.trim().isEmpty) {
      return {};
    }

    final decoded = jsonDecode(responseBody);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {'data': decoded};
  }

  String _extractErrorMessage(
    Map<String, dynamic> data, {
    required String fallback,
  }) {
    final dynamic error =
        data['error'] ?? data['message'] ?? data['detail'] ?? data['errors'];

    if (error == null) {
      return fallback;
    }

    if (error is String) {
      return error;
    }

    if (error is List && error.isNotEmpty) {
      return error.first.toString();
    }

    if (error is Map && error.isNotEmpty) {
      final firstValue = error.values.first;

      if (firstValue is List && firstValue.isNotEmpty) {
        return firstValue.first.toString();
      }

      return firstValue.toString();
    }

    return fallback;
  }

  String formatDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return '-';
    }

    try {
      return DateFormat('dd/MM/yyyy').format(
        DateTime.parse(value.toString()).toLocal(),
      );
    } catch (_) {
      return value.toString();
    }
  }

  void showMsg(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
      ),
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
    final data = filteredDepartments;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
    appBar: AppBar(
  automaticallyImplyLeading: false,
  leading: IconButton(
    tooltip: 'Back',
    icon: const Icon(Icons.arrow_back_ios_new_rounded),
    onPressed: _navigateBack,
  ),
  title: const Text(
    'Add Department',
    style: TextStyle(
      fontWeight: FontWeight.w900,
      color: Color(0xFF0F172A),
    ),
  ),
  backgroundColor: Colors.white,
  foregroundColor: const Color(0xFF0F172A),
  elevation: 0,
),
      body: loading
          ? buildMainLoader()
          : RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  fetchDepartments(showLoader: false),
                  fetchStaffs(),
                ]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildAddDepartmentCard(),
                    const SizedBox(height: 16),
                    buildDepartmentListCard(data),
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildMainLoader() {
    return Center(
      child: buildCard(
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading Department Page...',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAddDepartmentCard() {
    return buildCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _createFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionHeader(
                title: 'Add Department',
                icon: Icons.add_business_rounded,
              ),
              if (pageError.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                buildErrorBox(pageError),
              ],
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 850;

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: buildTextInput(
                            label: 'Department Name',
                            controller: _departmentNameController,
                            hint: 'Enter department name',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Department name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 5,
                          child: buildStaffSelectorField(
                            label: 'Team Leader',
                            selectedStaff: selectedTeamLeader,
                            hint: staffLoading
                                ? 'Loading staff...'
                                : 'Select Team Leader',
                            errorText: selectedTeamLeaderError,
                            disabled: staffLoading || submitting,
                            onTap: () async {
                              final selected = await openStaffPicker(
                                title: 'Select Team Leader',
                                currentStaff: selectedTeamLeader,
                              );

                              if (!mounted) return;

                              setState(() {
                                selectedTeamLeader = selected;
                                selectedTeamLeaderError = null;
                              });
                            },
                            onClear: () {
                              setState(() {
                                selectedTeamLeader = null;
                                selectedTeamLeaderError =
                                    'Please select team leader';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        SizedBox(
                          width: 160,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 29),
                            child: buildPrimaryButton(
                              text: submitting ? 'Adding...' : 'Add Team',
                              loading: submitting,
                              onPressed:
                                  submitting ? null : createDepartment,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      buildTextInput(
                        label: 'Department Name',
                        controller: _departmentNameController,
                        hint: 'Enter department name',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Department name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      buildStaffSelectorField(
                        label: 'Team Leader',
                        selectedStaff: selectedTeamLeader,
                        hint: staffLoading
                            ? 'Loading staff...'
                            : 'Select Team Leader',
                        errorText: selectedTeamLeaderError,
                        disabled: staffLoading || submitting,
                        onTap: () async {
                          final selected = await openStaffPicker(
                            title: 'Select Team Leader',
                            currentStaff: selectedTeamLeader,
                          );

                          if (!mounted) return;

                          setState(() {
                            selectedTeamLeader = selected;
                            selectedTeamLeaderError = null;
                          });
                        },
                        onClear: () {
                          setState(() {
                            selectedTeamLeader = null;
                            selectedTeamLeaderError =
                                'Please select team leader';
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      buildPrimaryButton(
                        text: submitting ? 'Adding...' : 'Add Team',
                        loading: submitting,
                        onPressed: submitting ? null : createDepartment,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDepartmentListCard(List<AttendanceDepartmentModel> data) {
    return buildCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 760;

                final title = buildSectionHeader(
                  title: 'Department List',
                  icon: Icons.table_chart_rounded,
                );

                final searchAndRefresh = Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            searchText = value;
                          });
                        },
                        decoration: inputDecoration(
                          hint: 'Search department...',
                          prefixIcon: Icons.search_rounded,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: tableLoading
                          ? null
                          : () => fetchDepartments(showLoader: true),
                      icon: tableLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.refresh_rounded),
                      label: Text(
                        tableLoading ? 'Refreshing...' : 'Refresh',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(118, 48),
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(color: Color(0xFFBFDBFE)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                );

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: title),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 430,
                        child: searchAndRefresh,
                      ),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 14),
                    searchAndRefresh,
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            if (tableLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 42),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text(
                        'Loading departments...',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (data.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    'No departments found',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            else
              buildDepartmentTable(data),
          ],
        ),
      ),
    );
  }

  Widget buildDepartmentTable(List<AttendanceDepartmentModel> data) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              const Color(0xFFF1F7FF),
            ),
            dataRowMinHeight: 58,
            dataRowMaxHeight: 68,
            headingTextStyle: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
            dataTextStyle: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            columnSpacing: 28,
            columns: const [
              DataColumn(label: SizedBox(width: 60, child: Text('#'))),
              DataColumn(
                label: SizedBox(
                  width: 220,
                  child: Text('Department Name'),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: 220,
                  child: Text('Team Leader'),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: 150,
                  child: Text('Created At'),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: 120,
                  child: Text('Action'),
                ),
              ),
            ],
            rows: List<DataRow>.generate(data.length, (index) {
              final item = data[index];
              final isLoading = viewLoadingId == item.id;

              return DataRow(
                color: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (index.isOdd) {
                    return const Color(0xFFFAFCFF);
                  }
                  return Colors.white;
                }),
                cells: [
                  DataCell(Text('${index + 1}')),
                  DataCell(
                    SizedBox(
                      width: 220,
                      child: Text(
                        item.teamName.isEmpty ? '-' : item.teamName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 220,
                      child: Text(
                        item.teamLeaderName.isEmpty
                            ? '-'
                            : item.teamLeaderName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(Text(formatDate(item.createdAt))),
                  DataCell(
                    SizedBox(
                      width: 110,
                      height: 38,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () => openEditDepartment(item.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              const Color(0xFFF59E0B).withOpacity(0.45),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Edit',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF2F7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget buildSectionHeader({
    required String title,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF2563EB),
            size: 21,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildErrorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTextInput({
    required String label,
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          textInputAction: TextInputAction.next,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          decoration: inputDecoration(hint: hint),
        ),
      ],
    );
  }

  Widget buildStaffSelectorField({
    required String label,
    required StaffModel? selectedStaff,
    required String hint,
    required String? errorText,
    required bool disabled,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final hasError = errorText != null && errorText.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldLabel(label),
        const SizedBox(height: 8),
        InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: disabled ? const Color(0xFFF8FAFC) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasError
                    ? const Color(0xFFDC2626)
                    : const Color(0xFFDEE2E6),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedStaff?.name ?? hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selectedStaff == null
                          ? const Color(0xFF8C98A5)
                          : const Color(0xFF2B2F33),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (selectedStaff != null)
                  GestureDetector(
                    onTap: disabled ? null : onClear,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF64748B),
                  ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: const TextStyle(
              color: Color(0xFFDC2626),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  Widget fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF334155),
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  InputDecoration inputDecoration({
    required String hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF8C98A5),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(
              prefixIcon,
              color: const Color(0xFF64748B),
              size: 21,
            ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFF86B7FE),
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFDC2626),
          width: 1.4,
        ),
      ),
    );
  }

  Widget buildPrimaryButton({
    required String text,
    required bool loading,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D6EFD),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF0D6EFD).withOpacity(0.45),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }
}

class AttendanceDepartmentModel {
  const AttendanceDepartmentModel({
    required this.id,
    required this.teamName,
    required this.teamLeaderName,
    required this.createdAt,
  });

  final int id;
  final String teamName;
  final String teamLeaderName;
  final String createdAt;

  factory AttendanceDepartmentModel.fromJson(Map<String, dynamic> json) {
    return AttendanceDepartmentModel(
      id: _toInt(json['id']) ?? 0,
      teamName: json['team_name']?.toString() ?? '',
      teamLeaderName: json['team_leader_name']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class StaffModel {
  const StaffModel({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: _toInt(json['id']) ?? 0,
      name: json['name']?.toString() ??
          json['username']?.toString() ??
          json['full_name']?.toString() ??
          'Staff ${json['id'] ?? ''}',
    );
  }
}

int? _toInt(dynamic value) {
  if (value == null) return null;

  if (value is int) return value;

  if (value is double) return value.toInt();

  return int.tryParse(value.toString());
}