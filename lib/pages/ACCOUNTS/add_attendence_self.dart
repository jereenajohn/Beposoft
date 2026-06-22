import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceAddPage extends StatefulWidget {
  const AttendanceAddPage({super.key});

  @override
  State<AttendanceAddPage> createState() => _AttendanceAddPageState();
}

class _AttendanceAddPageState extends State<AttendanceAddPage> {
  static const String baseUrl = "https://bepocart.in/";

  bool loading = false;
  bool submitLoading = false;
  bool updateLoading = false;

  List<Map<String, dynamic>> teams = [];
  List<Map<String, dynamic>> staffs = [];
  List<Map<String, dynamic>> attendanceData = [];

  Timer? _staffSearchDebounce;

  final todayDate = DateTime.now().toIso8601String().split('T').first;

  late Map<String, dynamic> filters;

  Map<String, dynamic> teamSummary = {
    'team_name': '-',
    'team_leader_name': '-',
    'members_count': 0,
  };

  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();

  String? addStaff;
  String? addStatus;
  final TextEditingController addTimeController = TextEditingController();

  int? selectedAttendanceId;
  String? editStaff;
  String? editStatus;
  String? editAttendanceDate;
  final TextEditingController editTimeController = TextEditingController();

  final List<Map<String, String>> statusOptions = const [
    {'value': 'present', 'label': 'Present'},
    {'value': 'absent', 'label': 'Absent'},
    {'value': 'half_day', 'label': 'Half Day'},
  ];

  static const Color primaryColor = Color(0xFF2563EB);
  static const Color darkColor = Color(0xFF0F172A);
  static const Color pageBg = Color(0xFFF4F7FB);
  static const Color borderColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();

    filters = {
      'start_date': todayDate,
      'end_date': todayDate,
      'member': '',
    };

    startDateController.text = todayDate;
    endDateController.text = todayDate;

    _init();
  }

  @override
  void dispose() {
    _staffSearchDebounce?.cancel();
    startDateController.dispose();
    endDateController.dispose();
    addTimeController.dispose();
    editTimeController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Map<String, String> _headers(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _init() async {
    setState(() => loading = true);

    await Future.wait([
      fetchTeams(),
      fetchStaffs(),
      fetchAttendance(),
    ]);

    if (mounted) setState(() => loading = false);
  }

  Future<void> fetchTeams() async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${baseUrl}api/staff/attendance/teams/'),
        headers: _headers(token),
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          teams = List<Map<String, dynamic>>.from(decoded['data'] ?? []);
        });
      } else {
        _showSnack(decoded['message'] ?? 'Failed to load teams', error: true);
      }
    } catch (_) {
      _showSnack('Failed to load teams', error: true);
    }
  }

  Future<void> fetchStaffs([String search = '']) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final uri = Uri.parse('${baseUrl}api/staff/attendance/added/users/').replace(
        queryParameters: {
          if (search.trim().isNotEmpty) 'search': search.trim(),
        },
      );

      final response = await http.get(uri, headers: _headers(token));
      final decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final attendanceList = List<Map<String, dynamic>>.from(
          decoded['results']?['data'] ?? [],
        );

        final Map<String, Map<String, dynamic>> uniqueMembers = {};

        for (final item in attendanceList) {
          final id = item['staff'];
          if (id == null) continue;

          uniqueMembers[id.toString()] = {
            'id': id,
            'name': item['staff_name'] ?? '-',
            'team_id': item['team_id'],
            'team_name': item['team_name'],
          };
        }

        setState(() {
          staffs = uniqueMembers.values.toList();
        });
      } else {
        _showSnack(decoded['message'] ?? 'Failed to load staff', error: true);
      }
    } catch (_) {
      _showSnack('Failed to load staff', error: true);
    }
  }

  Future<void> fetchAttendance() async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final uri = Uri.parse('${baseUrl}api/staff/attendance/added/users/').replace(
        queryParameters: {
          if ((filters['start_date'] ?? '').toString().isNotEmpty)
            'start_date': filters['start_date'],
          if ((filters['end_date'] ?? '').toString().isNotEmpty)
            'end_date': filters['end_date'],
          if ((filters['member'] ?? '').toString().isNotEmpty)
            'member': filters['member'],
        },
      );

      final response = await http.get(uri, headers: _headers(token));
      final decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final attendanceList = List<Map<String, dynamic>>.from(
          decoded['results']?['data'] ?? [],
        );

        final firstRecord =
            attendanceList.isNotEmpty ? attendanceList.first : <String, dynamic>{};

        setState(() {
          teamSummary = {
            'team_name': firstRecord['team_name'] ?? '-',
            'team_leader_name': firstRecord['team_leader_name'] ?? '-',
            'members_count': attendanceList.length,
          };
          attendanceData = attendanceList;
        });
      } else {
        _showSnack(decoded['message'] ?? 'Failed to load attendance', error: true);
      }
    } catch (_) {
      _showSnack('Failed to load attendance', error: true);
    }
  }

  Future<void> addAttendance() async {
    if (addTimeController.text.trim().isEmpty) {
      _showSnack('Select Time', error: true);
      return;
    }

    if (addStatus == null || addStatus!.isEmpty) {
      _showSnack('Select Status', error: true);
      return;
    }

    try {
      setState(() => submitLoading = true);

      final token = await _getToken();
      if (token == null) return;

      final payload = {
        'attendance_date': todayDate,
        'attendance_time': addTimeController.text.trim(),
        'status': addStatus,
      };

      final response = await http.post(
        Uri.parse('${baseUrl}api/staff/attendance/'),
        headers: _headers(token),
        body: jsonEncode(payload),
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showSnack('Attendance submitted. Waiting for manager approval');

        setState(() {
          addStaff = null;
          addStatus = null;
          addTimeController.clear();
        });

        await fetchAttendance();
      } else {
        _showSnack(decoded['message'] ?? 'Failed to add attendance', error: true);
      }
    } catch (_) {
      _showSnack('Failed to add attendance', error: true);
    } finally {
      if (mounted) setState(() => submitLoading = false);
    }
  }

  Future<void> openEditModal(int id) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${baseUrl}api/staff/attendance/edit/$id/'),
        headers: _headers(token),
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = decoded['data'] ?? {};

        setState(() {
          selectedAttendanceId = id;
          editStaff = data['staff']?.toString();
          editAttendanceDate = data['attendance_date'];
          editTimeController.text = data['attendance_time'] ?? '';
          editStatus = data['status'];
        });

        if (!mounted) return;
        _showEditDialog();
      } else {
        _showSnack(decoded['message'] ?? 'Failed to load attendance', error: true);
      }
    } catch (_) {
      _showSnack('Failed to load attendance', error: true);
    }
  }

  Future<void> updateAttendance() async {
    if (selectedAttendanceId == null) return;

    if (editStaff == null || editStaff!.isEmpty) {
      _showSnack('Select Staff', error: true);
      return;
    }

    if ((editAttendanceDate ?? '').isEmpty) {
      _showSnack('Select Date', error: true);
      return;
    }

    if (editTimeController.text.trim().isEmpty) {
      _showSnack('Select Time', error: true);
      return;
    }

    if (editStatus == null || editStatus!.isEmpty) {
      _showSnack('Select Status', error: true);
      return;
    }

    try {
      setState(() => updateLoading = true);

      final token = await _getToken();
      if (token == null) return;

      final payload = {
        'attendance_date': editAttendanceDate,
        'attendance_time': editTimeController.text.trim(),
        'status': editStatus,
      };

      final response = await http.put(
        Uri.parse('${baseUrl}api/staff/attendance/edit/$selectedAttendanceId/'),
        headers: _headers(token),
        body: jsonEncode(payload),
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showSnack('Attendance updated');

        if (mounted) Navigator.pop(context);
        await fetchAttendance();
      } else {
        _showSnack(decoded['message'] ?? 'Update failed', error: true);
      }
    } catch (_) {
      _showSnack('Update failed', error: true);
    } finally {
      if (mounted) setState(() => updateLoading = false);
    }
  }

  void resetFilters() {
    setState(() {
      filters = {
        'start_date': todayDate,
        'end_date': todayDate,
        'member': '',
      };

      startDateController.text = todayDate;
      endDateController.text = todayDate;
    });

    fetchAttendance();
  }

  int get presentCount =>
      attendanceData.where((item) => item['status'] == 'present').length;

  int get halfDayCount =>
      attendanceData.where((item) => item['status'] == 'half_day').length;

  int get absentCount =>
      attendanceData.where((item) => item['status'] == 'absent').length;

  void _onStaffSearch(String value) {
    _staffSearchDebounce?.cancel();
    _staffSearchDebounce = Timer(const Duration(milliseconds: 500), () {
      fetchStaffs(value);
    });
  }

  Future<void> pickDate({
    required TextEditingController controller,
    required String filterKey,
  }) async {
    final initialDate = DateTime.tryParse(controller.text) ?? DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: darkColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected == null) return;

    final date = selected.toIso8601String().split('T').first;

    setState(() {
      controller.text = date;
      filters[filterKey] = date;
    });
  }

  Future<void> pickAddTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');

    setState(() {
      addTimeController.text = '$hh:$mm';
    });
  }

  Future<void> pickEditTime(StateSetter dialogSetState) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');

    dialogSetState(() {
      editTimeController.text = '$hh:$mm';
    });
  }

  InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: TextStyle(
        color: Colors.grey.shade500,
        fontSize: 13,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryColor, width: 1.4),
      ),
    );
  }

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFEFF3F8)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.07),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  Widget fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        color: darkColor,
        fontSize: 13,
      ),
    );
  }

  Widget statusBadge(String? status) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    if (status == 'present') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF15803D);
      icon = Icons.check_rounded;
      label = 'Present';
    } else if (status == 'absent') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
      icon = Icons.close_rounded;
      label = 'Absent';
    } else {
      bg = const Color(0xFFFFEDD5);
      fg = const Color(0xFFC2410C);
      icon = Icons.access_time_rounded;
      label = 'Half Day';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget headerBadge(String text, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: textColor.withOpacity(0.20)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    Color? valueColor,
  }) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 112),
        margin: const EdgeInsets.only(right: 12, bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: valueColor ?? darkColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget dateField({
    required String label,
    required TextEditingController controller,
    required String filterKey,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldLabel(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: true,
          decoration: inputDecoration('Select date').copyWith(
            suffixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
          ),
          onTap: () => pickDate(controller: controller, filterKey: filterKey),
        ),
      ],
    );
  }

  Widget filterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: darkColor,
                      ),
                    ),
                    // SizedBox(height: 3),
                    // Text(
                    //   'Filter attendance records by date range.',
                    //   style: TextStyle(color: Colors.grey, fontSize: 13),
                    // ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: resetFilters,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reset'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: darkColor,
                  side: const BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 750;

              final fields = [
                dateField(
                  label: 'Start Date',
                  controller: startDateController,
                  filterKey: 'start_date',
                ),
                dateField(
                  label: 'End Date',
                  controller: endDateController,
                  filterKey: 'end_date',
                ),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: fetchAttendance,
                    icon: const Icon(Icons.search_rounded, size: 20),
                    label: const Text(
                      'Search',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ];

              if (isMobile) {
                return Column(
                  children: fields
                      .map(
                        (child) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: child,
                        ),
                      )
                      .toList(),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: fields[0]),
                  const SizedBox(width: 14),
                  Expanded(child: fields[1]),
                  const SizedBox(width: 14),
                  SizedBox(width: 170, child: fields[2]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget addAttendanceInlineCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: Color(0xFF16A34A),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Attendance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: darkColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Today's Date: $todayDate",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 850;

              final staffField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fieldLabel('Staff'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: addStaff,
                    isExpanded: true,
                    decoration: inputDecoration('Select staff'),
                    items: staffs.map((staff) {
                      return DropdownMenuItem<String>(
                        value: staff['id'].toString(),
                        child: Text(staff['name']?.toString() ?? '-'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => addStaff = value);
                    },
                  ),
                ],
              );

              final searchField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fieldLabel('Search Staff'),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: _onStaffSearch,
                    decoration: inputDecoration('Search staff').copyWith(
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    ),
                  ),
                ],
              );

              final timeField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fieldLabel('Reporting Time'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: addTimeController,
                    readOnly: true,
                    decoration: inputDecoration('Select time').copyWith(
                      suffixIcon: const Icon(Icons.access_time_rounded, size: 20),
                    ),
                    onTap: pickAddTime,
                  ),
                ],
              );

              final statusField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fieldLabel('Status'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: addStatus,
                    isExpanded: true,
                    decoration: inputDecoration('Select status'),
                    items: statusOptions.map((status) {
                      return DropdownMenuItem<String>(
                        value: status['value'],
                        child: Text(status['label'] ?? '-'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => addStatus = value);
                    },
                  ),
                ],
              );

              final submitButton = SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: submitLoading ? null : addAttendance,
                  icon: submitLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 20),
                  label: Text(
                    submitLoading ? 'Saving...' : 'Submit',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              );

              if (isMobile) {
                return Column(
                  children: [
                    staffField,
                    const SizedBox(height: 14),
                    searchField,
                    const SizedBox(height: 14),
                    timeField,
                    const SizedBox(height: 14),
                    statusField,
                    const SizedBox(height: 20),
                    SizedBox(width: double.infinity, child: submitButton),
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: staffField),
                      const SizedBox(width: 14),
                      Expanded(child: searchField),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: timeField),
                      const SizedBox(width: 14),
                      Expanded(child: statusField),
                      const SizedBox(width: 14),
                      SizedBox(width: 190, child: submitButton),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget attendanceListCard() {
    return Container(
      width: double.infinity,
      decoration: cardDecoration(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.fact_check_rounded,
                    color: Color(0xFF7C3AED),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attendance List',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: darkColor,
                        ),
                      ),
                      // const SizedBox(height: 4),
                      // Text(
                      //   '${teamSummary['team_name']} - Team Leader: ${teamSummary['team_leader_name']}',
                      //   style: const TextStyle(color: Colors.grey, fontSize: 13),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: borderColor),
          attendanceData.isEmpty ? emptyState() : attendanceTable(),
        ],
      ),
    );
  }

  Widget attendanceTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 850),
        child: DataTable(
          headingRowHeight: 54,
          dataRowMinHeight: 60,
          dataRowMaxHeight: 68,
          horizontalMargin: 22,
          columnSpacing: 24,
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          dividerThickness: 0.7,
          columns: const [
            DataColumn(
              label: Text(
                '#',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            DataColumn(
              label: Text(
                'Staff',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            DataColumn(
              label: Text(
                'Reporting Time',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            DataColumn(
              label: Text(
                'Date',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            DataColumn(
              label: Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            DataColumn(
              label: Text(
                'Action',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
          rows: List.generate(attendanceData.length, (index) {
            final item = attendanceData[index];

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    '${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                DataCell(
                  Text(
                    item['staff_name']?.toString() ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: darkColor,
                    ),
                  ),
                ),
                DataCell(Text(item['attendance_time']?.toString() ?? '-')),
                DataCell(Text(item['attendance_date']?.toString() ?? '-')),
                DataCell(statusBadge(item['status']?.toString())),
                DataCell(
                  OutlinedButton.icon(
                    onPressed: () {
                      final id = item['id'];
                      if (id != null) openEditModal(id);
                    },
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text(
                      'Edit',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF97316),
                      side: const BorderSide(color: Color(0xFFFED7AA)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              size: 40,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No attendance records found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: darkColor,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'No attendance data is available for the selected filters.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              title: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.edit_calendar_rounded,
                      color: Color(0xFFF97316),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Edit Attendance',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: darkColor,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 430,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      fieldLabel('Staff'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: editStaff,
                        isExpanded: true,
                        decoration: inputDecoration('Select staff'),
                        items: staffs.map((staff) {
                          return DropdownMenuItem<String>(
                            value: staff['id'].toString(),
                            child: Text(staff['name']?.toString() ?? '-'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          dialogSetState(() => editStaff = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      fieldLabel('Reporting Time'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: editTimeController,
                        readOnly: true,
                        decoration: inputDecoration('Select time').copyWith(
                          suffixIcon: const Icon(Icons.access_time_rounded),
                        ),
                        onTap: () => pickEditTime(dialogSetState),
                      ),
                      const SizedBox(height: 16),
                      fieldLabel('Status'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: editStatus,
                        isExpanded: true,
                        decoration: inputDecoration('Select status'),
                        items: statusOptions.map((status) {
                          return DropdownMenuItem<String>(
                            value: status['value'],
                            child: Text(status['label'] ?? '-'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          dialogSetState(() => editStatus = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: updateLoading ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: updateLoading ? null : updateAttendance,
                  icon: updateLoading
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(
                    updateLoading ? 'Updating...' : 'Update',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: pageBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

  return Scaffold(
  backgroundColor: pageBg,
  appBar: AppBar(
    title: const Text(
      'Attendance',
      style: TextStyle(fontWeight: FontWeight.w800),
    ),
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
  ),
  body: SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          filterCard(),
          const SizedBox(height: 22),
          addAttendanceInlineCard(),
          const SizedBox(height: 22),
          attendanceListCard(),
        ],
      ),
    ),
  ),
);
  }
}