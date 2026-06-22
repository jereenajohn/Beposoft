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

class ManagerLeaveRequestsPage extends StatefulWidget {
  const ManagerLeaveRequestsPage({super.key});

  @override
  State<ManagerLeaveRequestsPage> createState() =>
      _ManagerLeaveRequestsPageState();
}

class _ManagerLeaveRequestsPageState extends State<ManagerLeaveRequestsPage>
    with SingleTickerProviderStateMixin {
  bool isLoading = false;
  List<Map<String, dynamic>> leaveRequests = [];

  final managerNoteController = TextEditingController();
  final searchController = TextEditingController();
  String searchQuery = '';
  String filterStatus = 'all'; // all | pending | approved | rejected
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController!.addListener(() {
      if (!_tabController!.indexIsChanging) return;
      final idx = _tabController!.index;
      setState(() {
        filterStatus = idx == 0
            ? 'all'
            : idx == 1
                ? 'pending'
                : idx == 2
                    ? 'approved'
                    : 'rejected';
      });
    });
    getManagerLeaveRequests();
  }

  @override
  void dispose() {
    managerNoteController.dispose();
    searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  Future<String?> getTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
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

  Future<void> getManagerLeaveRequests() async {
    try {
      setState(() => isLoading = true);

      final token = await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/employee/leaves/manager/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'];

        setState(() {
          leaveRequests = data is List
              ? data.map((e) => Map<String, dynamic>.from(e)).toList()
              : [];
        });
      } else {
        showMessage('Failed to load leave requests');
      }
    } catch (e) {
      showMessage('Error loading leave requests');
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> get filteredRequests {
    final q = searchQuery.trim().toLowerCase();
    return leaveRequests.where((item) {
      final status = (item['approval_status'] ?? '').toString().toLowerCase();
      final name = (item['employee_name'] ?? '').toString().toLowerCase();

      final statusMatch = filterStatus == 'all' ? true : status.contains(filterStatus);
      final queryMatch = q.isEmpty ? true : name.contains(q);

      return statusMatch && queryMatch;
    }).toList();
  }

  Future<void> updateLeaveStatus({
    required int leaveId,
    required String status,
    String? managerNote,
  }) async {
    try {
      final token = await getTokenFromPrefs();

      final body = {
        'approval_status': status,
        'manager_note': managerNote ?? '',
      };

      final response = await http.put(
        Uri.parse('$api/api/employee/leaves/edit/$leaveId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        showMessage('Leave $status successfully');
        await getManagerLeaveRequests();
      } else {
        showMessage('Failed: ${response.body}');
      }
    } catch (e) {
      showMessage('Error: $e');
    }
  }

void showManagerActionDialog({
  required int leaveId,
  required String status,
}) {
  managerNoteController.clear();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final isApprove = status == 'approved';
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isApprove ? const Color(0xFFE6F4EA) : const Color(0xFFFEEAEA),
                shape: BoxShape.circle,
              ),
              child: Icon(isApprove ? Icons.check_circle : Icons.cancel,
                  color: isApprove ? const Color(0xFF16A34A) : Colors.redAccent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isApprove ? 'Approve Leave' : 'Reject Leave',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isApprove
                  ? 'You can add an optional note for the employee.'
                  : 'Please provide a reason for rejecting (optional).',
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: managerNoteController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Manager note (optional)',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await updateLeaveStatus(
                leaveId: leaveId,
                status: status,
                managerNote: managerNoteController.text.trim(),
              );
            },
            child: Text(isApprove ? 'Approve' : 'Reject',style: TextStyle(color: Colors.white),),
          ),
        ],
      );
    },
  );
}

  String formatLeaveType(String value) {
    return value.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  Color getStatusColor(String status) {
    final value = status.toLowerCase();

    if (value.contains('approved')) return const Color(0xFF16A34A);
    if (value.contains('rejected')) return const Color(0xFFDC2626);
    if (value.contains('pending')) return const Color(0xFFF59E0B);

    return const Color(0xFF6B7280);
  }

  Widget buildLeaveRequestCard(Map<String, dynamic> item) {
    final status = item['approval_status']?.toString() ?? 'pending';
    final statusColor = getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    (item['employee_name'] ?? 'E')
                        .toString()
                        .trim()
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['employee_name']?.toString() ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatLeaveType(item['leave_type']?.toString() ?? ''),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.date_range_rounded,
                    size: 18, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${item['start_date']} to ${item['end_date']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Days ${item['no_of_days']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Reason: ${item['reason'] ?? ''}',
            style: const TextStyle(
              color: Color(0xFF475569),
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (item['manager_note'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Manager Note: ${item['manager_note']}',
              style: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          // Show actions for pending requests; allow rejecting even after approve
          if (status.toLowerCase() == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showManagerActionDialog(
                        leaveId: item['id'],
                        status: 'rejected',
                      );
                    },
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFEE2E2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showManagerActionDialog(
                        leaveId: item['id'],
                        status: 'approved',
                      );
                    },
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (status.toLowerCase() == 'approved') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showManagerActionDialog(
                        leaveId: item['id'],
                        status: 'rejected',
                      );
                    },
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFEE2E2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildFilterChip(String id, String label) {
    final selected = filterStatus == id;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => filterStatus = id),
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF374151),
        fontWeight: FontWeight.w700,
      ),
    );
  }

Future<String?> _showSwipeNoteDialog(String action) async {
  final ctrl = TextEditingController();
  final res = await showDialog<String?>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Icon(action.toLowerCase().contains('approve') ? Icons.check_circle : Icons.close,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Text('$action Leave', style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Manager note (optional)',
            filled: true,
            fillColor: const Color(0xFFF7F9FB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Confirm')),
        ],
      );
    },
  );
  return res;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
          leading: IconButton(
    tooltip: 'Back',
    icon: const Icon(Icons.arrow_back_ios_new_rounded),
    onPressed: _navigateBack,
  ),
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        title: const Text(
          'Leave Requests',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        actions: [
          IconButton(
            onPressed: getManagerLeaveRequests,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: getManagerLeaveRequests,
        color: const Color(0xFF2563EB),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : leaveRequests.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.inbox_rounded,
                              size: 44,
                              color: Color(0xFF9CA3AF),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'No leave requests found',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: leaveRequests
                        .map((item) => buildLeaveRequestCard(item))
                        .toList(),
                  ),
      ),
    );
  }
}