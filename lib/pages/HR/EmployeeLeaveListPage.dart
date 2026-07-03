import 'dart:convert';

import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/HR/hr_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EmployeeLeaveListPage extends StatefulWidget {
  const EmployeeLeaveListPage({super.key});

  @override
  State<EmployeeLeaveListPage> createState() =>
      _EmployeeLeaveListPageState();
}

class _EmployeeLeaveListPageState extends State<EmployeeLeaveListPage> {
  bool isLoading = false;

  List<Map<String, dynamic>> leaveList = [];

  @override
  void initState() {
    super.initState();
    getAllEmployeeLeaves();
  }

  Future<String?> getTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> getAllEmployeeLeaves() async {
    try {
      setState(() => isLoading = true);

      final token = await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/employee/leaves/all/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final data = decoded['data'];

        if (data is List) {
          setState(() {
            leaveList = data.map((e) => Map<String, dynamic>.from(e)).toList();
          });
        }
      } else {
        showMessage('Failed to load employee leaves');
      }
    } catch (e) {
      showMessage('Error loading employee leaves');
    } finally {
      setState(() => isLoading = false);
    }
  }

  String formatLeaveType(dynamic value) {
    return value?.toString().replaceAll('_', ' ').toUpperCase() ?? '';
  }

  Color getStatusBg(String status) {
    if (status == 'approved') return const Color(0xFFECFDF3);
    if (status == 'rejected') return const Color(0xFFFEF2F2);
    return const Color(0xFFFFF7ED);
  }

  Color getStatusColor(String status) {
    if (status == 'approved') return const Color(0xFF027A48);
    if (status == 'rejected') return const Color(0xFFB42318);
    return const Color(0xFFC2410C);
  }

  Widget buildLeaveCard(Map<String, dynamic> item) {
    final status = item['approval_status']?.toString() ?? 'pending';

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
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE8F0FF),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item['employee_name']?.toString() ?? 'Employee',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: getStatusBg(status),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: getStatusColor(status),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            formatLeaveType(item['leave_type']),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF2563EB),
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.date_range, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${item['start_date']} to ${item['end_date']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475467),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(Icons.timer_outlined,
                  size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                '${item['no_of_days']} day(s)',
                style: const TextStyle(color: Color(0xFF667085)),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(Icons.supervisor_account_outlined,
                  size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Manager: ${item['manager_name'] ?? '-'}',
                  style: const TextStyle(color: Color(0xFF667085)),
                ),
              ),
            ],
          ),

          if ((item['reason'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                item['reason'].toString(),
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
else if(dep=="HR" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HrDashboard()), // Replace AnotherPage with your target page
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
          leading: IconButton(
    tooltip: 'Back',
    icon: const Icon(Icons.arrow_back_ios_new_rounded),
    onPressed: _navigateBack,
  ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        title: const Text(
          'All Employee Leaves',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: getAllEmployeeLeaves,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.event_note, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Total Leave Requests: ${leaveList.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (leaveList.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Center(
                  child: Text(
                    'No employee leave requests found',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              )
            else
              ...leaveList.map((item) => buildLeaveCard(item)),
          ],
        ),
      ),
    );
  }
}