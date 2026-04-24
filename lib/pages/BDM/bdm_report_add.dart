import 'dart:convert';
import 'package:beposoft/Sales%20Directors/SD_dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BdmReportAdd extends StatefulWidget {
  const BdmReportAdd({super.key});

  @override
  State<BdmReportAdd> createState() => _BdmReportAddState();
}

class _BdmReportAddState extends State<BdmReportAdd> {
  String familyId = '';
  String familyName = '';

  List<Map<String, dynamic>> staffList = [];

  Map<String, dynamic>? selectedStaff;
  String? selectedStatus;

  List<Map<String, dynamic>> tempEntries = [];

  List<Map<String, dynamic>> attendanceRecords = [];
  Map<String, List<Map<String, dynamic>>> groupedByDate = {};

  DateTime selectedViewDate = DateTime.now();
  List<Map<String, dynamic>> selectedDateEntries = [];

  final Map<String, String> statusOptions = {
    "present": "Present",
    "absent": "Absent",
    "half_day": "Half Day",
  };

  bool isLoadingAttendance = true;

  @override
  void initState() {
    super.initState();
    getProfileData();
  }

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> getProfileData() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("PROFILE RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];

        setState(() {
          familyId = data['family'].toString();
          familyName = data['family_name'] ?? '';
        });

        getStaff();
        fetchAttendanceRecords();
      }
    } catch (e) {
      print("Profile error: $e");
    }
  }

  Future<void> getStaff() async {
    try {
      final token = await gettokenFromPrefs();
      var response = await http.get(
        Uri.parse('$api/api/staffs/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print("STAFF RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];

        List<Map<String, dynamic>> tempList = [];

        for (var item in data) {
          if (item['family_name'] != null &&
              item['family_name'].toString().toLowerCase().trim() ==
                  familyName.toLowerCase().trim()) {
            tempList.add({
              'id': item['id'],
              'name': item['name'],
            });
          }
        }

        print("FILTERED STAFF: $tempList");

        setState(() {
          staffList = tempList;
        });
      }
    } catch (e) {
      print("Staff error: $e");
    }
  }

  Future<void> fetchAttendanceRecords() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/bdm/order/analysis/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("ATTENDANCE STATUS: ${response.statusCode}");
      print("ATTENDANCE BODY: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        if (parsed['status'] == 'success' && parsed['data'] is List) {
          final List data = parsed['data'];

          Map<String, List<Map<String, dynamic>>> tempGrouped = {};

          for (var record in data) {
            final date = record['attendance_date'];

            if (!tempGrouped.containsKey(date)) {
              tempGrouped[date] = [];
            }

            if (record['staff_entries'] != null &&
                record['staff_entries'] is List) {
              for (var entry in record['staff_entries']) {
                tempGrouped[date]!.add({
                  'staff': entry['staff'],
                  'staff_name': entry['staff_name'],
                  'status': entry['status'],
                  'record_id': record['id'],
                  'staff_entry_id': entry['id'],
                  'created_at': entry['created_at'],
                  'updated_at': entry['updated_at'],
                });
              }
            }
          }
          Map<String, List<Map<String, dynamic>>> uniqueGrouped = {};

          tempGrouped.forEach((date, entries) {
            final Map<int, Map<String, dynamic>> uniqueEntries = {};
            for (var entry in entries) {
              final staffId = entry['staff'];
              if (!uniqueEntries.containsKey(staffId) ||
                  entry['record_id'] > uniqueEntries[staffId]!['record_id']) {
                uniqueEntries[staffId] = entry;
              }
            }
            uniqueGrouped[date] = uniqueEntries.values.toList();
          });
          final sortedDates = uniqueGrouped.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          setState(() {
            groupedByDate = uniqueGrouped;
            isLoadingAttendance = false;
            _updateSelectedDateEntries();
          });

          print("✅ Found ${groupedByDate.length} unique dates with entries");
          groupedByDate.forEach((date, entries) {
            print("   $date: ${entries.length} entries");
          });
        } else {
          setState(() {
            isLoadingAttendance = false;
          });
        }
      }
    } catch (e) {
      print("❌ Attendance fetch error: $e");
      setState(() {
        isLoadingAttendance = false;
      });
    }
  }

  void _updateSelectedDateEntries() {
    final selectedDateStr = _formatDateForApi(selectedViewDate);
    setState(() {
      selectedDateEntries = groupedByDate[selectedDateStr] ?? [];
    });
  }

  String _formatDateForApi(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _formatDateForDisplay(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  void _autoAddEntry() {
    print("🟦 AUTO ADD TRIGGERED");

    if (selectedStaff == null || selectedStatus == null) {
      print("❌ Missing staff or status");
      return;
    }

    final staffId = selectedStaff!['id'];
    final staffName = selectedStaff!['name'];
    final status = selectedStatus!;
    final statusDisplay = statusOptions[status] ?? status;

    print("Adding/Updating: $staffName - $statusDisplay");

    final tempExists = tempEntries.any((e) => e['staff'] == staffId);

    if (tempExists) {
      print("⚠️ Updating existing temp entry");
      setState(() {
        tempEntries = tempEntries.map((e) {
          if (e['staff'] == staffId) {
            return {
              "staff": staffId,
              "staff_name": staffName,
              "status": status,
            };
          }
          return e;
        }).toList();
      });
    } else {
      print("✅ Adding new entry");
      setState(() {
        tempEntries.add({
          "staff": staffId,
          "staff_name": staffName,
          "status": status,
        });
      });
    }

    print("📦 tempEntries: $tempEntries");

    setState(() {
      selectedStatus = null;
    });
  }

  Future<void> submitToServer() async {
    if (tempEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No entries to submit")),
      );
      return;
    }

    try {
      final token = await gettokenFromPrefs();
      final today = DateTime.now();
      final formattedDate = _formatDateForApi(today);

      final body = {
        "attendance_date": formattedDate,
        "staff_entries": tempEntries.map((e) {
          return {
            "staff": int.parse(e['staff'].toString()),
            "status": e['status'].toString(),
          };
        }).toList()
      };

      print("POST URL: $api/api/bdm/order/analysis/add/");
      print("POST BODY: ${jsonEncode(body)}");

      final response = await http.post(
        Uri.parse('$api/api/bdm/order/analysis/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print("STATUS CODE: ${response.statusCode}");
      print("RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final parsed = jsonDecode(response.body);

        if (parsed['status'] == 'success') {
          setState(() {
            tempEntries.clear();
            selectedStaff = null;
            selectedStatus = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Submitted successfully"),
              backgroundColor: Colors.green,
            ),
          );

          await fetchAttendanceRecords();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(parsed['message'] ?? "Unknown error"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        String errorMessage = "HTTP Error: ${response.statusCode}";

        try {
          final parsed = jsonDecode(response.body);
          if (parsed is Map) {
            errorMessage = parsed.toString();
          }
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("SUBMIT EXCEPTION: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedViewDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1565C0),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1565C0),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedViewDate) {
      setState(() {
        selectedViewDate = picked;
        _updateSelectedDateEntries();
      });
    }
  }

  Color _getStatusColor(String status) {
    if (status == 'present') return Colors.green;
    if (status == 'absent') return Colors.red;
    return Colors.orange;
  }

  IconData _getStatusIcon(String status) {
    if (status == 'present') return Icons.check_circle_outline;
    if (status == 'absent') return Icons.cancel_outlined;
    return Icons.timelapse_outlined;
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.groups_2_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "BDM Attendance Report",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Family: ${familyName.isEmpty ? '-' : familyName}",
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    EdgeInsets? padding,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1565C0), size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownCard<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade700),
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildEntryCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _formatDateForDisplay(selectedViewDate),
        style: const TextStyle(
          fontSize: 11.5,
          color: Color(0xFF1565C0),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            "No entries found for ${_formatDateForDisplay(selectedViewDate)}",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You can only add entries for today.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("You can only add entries for today"),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.info_outline),
            label: const Text("Show Note"),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(Map<String, dynamic> item) {
    final chipColor = _getStatusColor(item['status']);
    final statusIcon = _getStatusIcon(item['status']);
    final bool canModify =
        _formatDateForApi(selectedViewDate) == _formatDateForApi(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: chipColor.withOpacity(0.12),
                  child: Icon(statusIcon, color: chipColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item['staff_name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: chipColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item['status'].toString().toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (canModify) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => editStaffEntry(item),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text("Edit"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1565C0),
                      side: const BorderSide(color: Color(0xFF1565C0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => deleteStaffEntry(item),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text("Delete"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> editStaffEntry(Map<String, dynamic> entry) async {
    try {
      final token = await gettokenFromPrefs();

      final newStatus = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text("Edit Status for ${entry['staff_name']}"),
          content: DropdownButtonFormField<String>(
            value: entry['status'],
            decoration: const InputDecoration(
              labelText: "Select Status",
              border: OutlineInputBorder(),
            ),
            items: statusOptions.entries.map((statusEntry) {
              return DropdownMenuItem(
                value: statusEntry.key,
                child: Text(statusEntry.value),
              );
            }).toList(),
            onChanged: (value) {
              Navigator.pop(context, value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        ),
      );

      if (newStatus == null || newStatus == entry['status']) {
        return;
      }

      final allEntriesFromRecord = selectedDateEntries
          .where((e) => e['record_id'] == entry['record_id'])
          .toList();

      final updatedEntries = allEntriesFromRecord.map((e) {
        if (e['staff'] == entry['staff']) {
          return {
            "staff": e['staff'],
            "status": newStatus,
          };
        }
        return {
          "staff": e['staff'],
          "status": e['status'],
        };
      }).toList();

      final today = DateTime.now();
      final formattedDate = _formatDateForApi(today);

      final body = {
        "attendance_date": formattedDate,
        "staff_entries": updatedEntries,
      };

      final response = await http.put(
        Uri.parse('$api/api/bdm/order/analysis/edit/${entry['record_id']}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final parsed = jsonDecode(response.body);
        if (parsed['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Status updated successfully"),
              backgroundColor: Colors.green,
            ),
          );
          await fetchAttendanceRecords();
        }
      }
    } catch (e) {
      print("🔥 EDIT EXCEPTION: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating status: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> deleteStaffEntry(Map<String, dynamic> entry) async {
    try {
      final token = await gettokenFromPrefs();

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text("Delete Entry"),
          content: Text(
              "Are you sure you want to delete ${entry['staff_name']}'s entry?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      final allEntriesFromRecord = selectedDateEntries
          .where((e) => e['record_id'] == entry['record_id'])
          .toList();

      final remainingEntries = allEntriesFromRecord
          .where((e) => e['staff'] != entry['staff'])
          .map((e) => {
                "staff": e['staff'],
                "status": e['status'],
              })
          .toList();

      final today = DateTime.now();
      final formattedDate = _formatDateForApi(today);

      if (remainingEntries.isEmpty) {
        final response = await http.delete(
          Uri.parse('$api/api/bdm/order/analysis/edit/${entry['record_id']}/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200 || response.statusCode == 204) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Entry deleted successfully"),
              backgroundColor: Colors.green,
            ),
          );
          await fetchAttendanceRecords();
        }
      } else {
        final body = {
          "attendance_date": formattedDate,
          "staff_entries": remainingEntries,
        };

        final response = await http.put(
          Uri.parse('$api/api/bdm/order/analysis/edit/${entry['record_id']}/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Entry deleted successfully"),
              backgroundColor: Colors.green,
            ),
          );
          await fetchAttendanceRecords();
        }
      }
    } catch (e) {
      print("🔥 DELETE EXCEPTION: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error deleting entry: $e"),
          backgroundColor: Colors.red,
        ),
      );
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


  @override
  Widget build(BuildContext context) {
    final bool pageLoading = staffList.isEmpty && isLoadingAttendance;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () async {
              await _navigateBack();
            },
          ),
        titleSpacing: 4,
        title: const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "BDM Report",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 2),
              Text(
                "Attendance management",
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: _pickDate,
            icon: const Icon(
              Icons.calendar_month_outlined,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: pageLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchAttendanceRecords,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: "Add Attendance",
                      icon: Icons.playlist_add_check_circle_outlined,
                      child: Column(
                        children: [
                          _buildDropdownCard<Map<String, dynamic>>(
                            label: "Select Staff",
                            value: selectedStaff,
                            items: staffList.map((staff) {
                              return DropdownMenuItem(
                                value: staff,
                                child: Text(staff['name']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedStaff = value;
                                selectedStatus = null;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildDropdownCard<String>(
                            label: "Select Status",
                            value: selectedStatus,
                            items: statusOptions.entries.map((entry) {
                              return DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedStatus = value;
                              });
                              _autoAddEntry();
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: submitToServer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1565C0),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                "Submit",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: "Staff Entries",
                      icon: Icons.fact_check_outlined,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                "Entries",
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const Spacer(),
                              _buildEntryCounter(),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (isLoadingAttendance)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (selectedDateEntries.isEmpty)
                            _buildEmptyState()
                          else
                            ListView.builder(
                              itemCount: selectedDateEntries.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                final item = selectedDateEntries[index];
                                return _buildEntryCard(item);
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}