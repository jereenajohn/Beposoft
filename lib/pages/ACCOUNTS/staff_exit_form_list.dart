import 'dart:convert';

import 'package:beposoft/Sales%20Directors/SD_dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/Staff_exit_form_page.dart';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
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

class EmployeeExitListPage extends StatefulWidget {
  const EmployeeExitListPage({super.key});

  @override
  State<EmployeeExitListPage> createState() => _EmployeeExitListPageState();
}

class _EmployeeExitListPageState extends State<EmployeeExitListPage> {
  final TextEditingController searchController = TextEditingController();

  bool isLoading = false;
  bool isDeleting = false;

  List<Map<String, dynamic>> exitList = [];

  int currentPage = 1;
  int totalCount = 0;
  int pageSize = 10;
  String? nextPageUrl;
  String? previousPageUrl;
  String currentSearch = '';

  @override
  void initState() {
    super.initState();
    getExitList(page: 1, search: '');
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<String?> getTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> getExitList({
    int page = 1,
    String search = '',
  }) async {
    try {
      setState(() {
        isLoading = true;
      });

      final token = await getTokenFromPrefs();

      final uri = Uri.parse('$api/api/employee/exit/add/').replace(
        queryParameters: {
          'page': page.toString(),
          if (search.trim().isNotEmpty) 'search': search.trim(),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final List<Map<String, dynamic>> tempList = [];
        int tempCount = 0;
        String? tempNext;
        String? tempPrevious;

        if (decoded is Map<String, dynamic>) {
          tempCount = decoded['count'] ?? 0;
          tempNext = decoded['next']?.toString();
          tempPrevious = decoded['previous']?.toString();

          final results = decoded['results'];
          if (results is Map<String, dynamic>) {
            final data = results['data'];
            if (data is List) {
              for (final item in data) {
                if (item is Map<String, dynamic>) {
                  tempList.add(item);
                }
              }
            }
          }
        }

        setState(() {
          exitList = tempList;
          totalCount = tempCount;
          nextPageUrl = tempNext;
          previousPageUrl = tempPrevious;
          currentPage = page;
          currentSearch = search;
        });
      } else {
        showMessage('Failed to load employee exit list');
      }
    } catch (e) {
      showMessage('Error loading employee exit list');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> openEditPage(int id) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeExitFormPage(
          exitId: id,
          popOnSuccess: true,
        ),
      ),
    );

    if (result == true) {
      await getExitList(page: currentPage, search: currentSearch);
    }
  }

  Future<void> deleteExit(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Employee Exit'),
          content: const Text('Are you sure you want to delete this record?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      setState(() {
        isDeleting = true;
      });

      final token = await getTokenFromPrefs();

      final response = await http.delete(
        Uri.parse('$api/api/employee/exit/edit/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 ||
          response.statusCode == 202 ||
          response.statusCode == 204) {
        showMessage('Employee exit deleted successfully');

        int refreshPage = currentPage;
        if (exitList.length == 1 && currentPage > 1) {
          refreshPage = currentPage - 1;
        }

        await getExitList(page: refreshPage, search: currentSearch);
      } else {
        showMessage('Delete failed: ${response.body}');
      }
    } catch (e) {
      showMessage('Error deleting employee exit');
    } finally {
      setState(() {
        isDeleting = false;
      });
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
        MaterialPageRoute(builder: (context) => bdo_dashbord()),
      );
    } else if (dep == "BDM") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => bdm_dashbord()),
      );
    } 
    else if (dep == "SD") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SdDashboard()),
      );
    } 

    else if (dep == "HR") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HrDashboard()),
      );
    } 
    else if (dep == "warehouse") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WarehouseDashboard()),
      );
    } else if (dep == "CEO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ceo_dashboard()),
      );
    } else if (dep == "COO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ceo_dashboard()),
      );
    } else if (dep == "CSO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => cso_dashboard()),
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

  String formatDate(dynamic value) {
    if (value == null) return '';
    final text = value.toString();
    if (text.contains('T')) {
      return text.split('T').first;
    }
    return text;
  }

  String buildFullImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final cleanedApi =
        api.endsWith('/') ? api.substring(0, api.length - 1) : api;
    final cleanedPath = path.startsWith('/') ? path : '/$path';
    return '$cleanedApi$cleanedPath';
  }

  Widget buildInfoChip({
    required IconData icon,
    required String text,
    Color bgColor = const Color(0xFFF3F6FB),
    Color textColor = const Color(0xFF334155),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatusChip(String label, bool value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: value ? const Color(0xFFECFDF3) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: value ? const Color(0xFF027A48) : const Color(0xFFB42318),
        ),
      ),
    );
  }

  Widget buildSignaturePreview(String title, String? imagePath) {
    final fullUrl = buildFullImageUrl(imagePath);

    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 10, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475467),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 70,
            width: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: fullUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      fullUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: Colors.grey),
                        );
                      },
                    ),
                  )
                : const Center(
                    child: Icon(Icons.image_not_supported_outlined,
                        color: Colors.grey),
                  ),
          ),
        ],
      ),
    );
  }

  Widget buildEmployeeExitCard(Map<String, dynamic> item) {
    final int? id =
        item['id'] is int ? item['id'] : int.tryParse('${item['id']}');

    final String employeeName = item['employee_name']?.toString() ?? 'Employee';
    final String department = item['employee_department']?.toString() ?? '';
    final String designation = item['employee_designation']?.toString() ?? '';
    final String exitDate = formatDate(item['exit_date']);
    final String reasonType = item['reason_type']?.toString() ?? '';
    final String handoverToName = item['handover_to_name']?.toString() ?? '';
    final String handoverDate = formatDate(item['handover_date']);
    final String exitFormDate = formatDate(item['exit_form_date']);

    final bool logisticsClearance = item['logistics_clearance'] == true;
    final bool financeClearance = item['finance_clearance'] == true;
    final bool hrClearance = item['hr_clearance'] == true;
    final bool salesClearance = item['sales_clearance'] == true;
    final bool itClearance = item['it_clearance'] == true;

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
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employeeName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      department.isNotEmpty && designation.isNotEmpty
                          ? '$department • $designation'
                          : department.isNotEmpty
                              ? department
                              : designation,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: id == null ? null : () => openEditPage(id),
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF2563EB),
                ),
              ),
              IconButton(
                onPressed:
                    id == null || isDeleting ? null : () => deleteExit(id),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: isDeleting ? Colors.grey : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (exitDate.isNotEmpty)
                buildInfoChip(icon: Icons.event_outlined, text: exitDate),
              if (reasonType.isNotEmpty)
                buildInfoChip(icon: Icons.info_outline, text: reasonType),
              if (handoverToName.isNotEmpty)
                buildInfoChip(
                    icon: Icons.handshake_outlined, text: handoverToName),
              if (handoverDate.isNotEmpty)
                buildInfoChip(
                    icon: Icons.calendar_today_outlined, text: handoverDate),
              if (exitFormDate.isNotEmpty)
                buildInfoChip(
                    icon: Icons.assignment_outlined, text: exitFormDate),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              buildStatusChip('Logistics', logisticsClearance),
              buildStatusChip('Finance', financeClearance),
              buildStatusChip('HR', hrClearance),
              buildStatusChip('Sales', salesClearance),
              buildStatusChip('IT', itClearance),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Signatures',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                buildSignaturePreview(
                  'Logistics',
                  item['logistics_clearence_signature']?.toString(),
                ),
                buildSignaturePreview(
                  'Finance',
                  item['finance_clearance_signature']?.toString(),
                ),
                buildSignaturePreview(
                  'HR',
                  item['hr_clearance_signature']?.toString(),
                ),
                buildSignaturePreview(
                  'Sales',
                  item['sales_clearance_signature']?.toString(),
                ),
                buildSignaturePreview(
                  'IT',
                  item['it_clearance_signature']?.toString(),
                ),
                buildSignaturePreview(
                  'Employee',
                  item['employee_signature']?.toString(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSearchSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          TextFormField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search employee exit details...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.trim().isNotEmpty
                  ? IconButton(
                      onPressed: () async {
                        searchController.clear();
                        await getExitList(page: 1, search: '');
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF2563EB),
                  width: 1.4,
                ),
              ),
            ),
            onFieldSubmitted: (value) async {
              await getExitList(page: 1, search: value.trim());
            },
            onChanged: (value) {
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () async {
                          await getExitList(
                            page: 1,
                            search: searchController.text.trim(),
                          );
                        },
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () async {
                          searchController.clear();
                          await getExitList(page: 1, search: '');
                          setState(() {});
                        },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildPaginationSection() {
    final int totalPages =
        totalCount == 0 ? 1 : ((totalCount + pageSize - 1) ~/ pageSize);

    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Total: $totalCount',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              'Page $currentPage of $totalPages',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: previousPageUrl == null || isLoading
                    ? null
                    : () async {
                        if (currentPage > 1) {
                          await getExitList(
                            page: currentPage - 1,
                            search: currentSearch,
                          );
                        }
                      },
                icon: const Icon(Icons.chevron_left_rounded),
                label: const Text('Previous'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: nextPageUrl == null || isLoading
                    ? null
                    : () async {
                        await getExitList(
                          page: currentPage + 1,
                          search: currentSearch,
                        );
                      },
                icon: const Icon(Icons.chevron_right_rounded),
                label: const Text('Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF111827)),
            onPressed: () async {
              await _navigateBack();
            },
          ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        title: const Text(
          'Employee Exit List',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   backgroundColor: const Color(0xFF2563EB),
      //   foregroundColor: Colors.white,
      //   onPressed: () async {
      //     final result = await Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //         builder: (context) => const EmployeeExitFormPage(),
      //       ),
      //     );

      //     if (result == true) {
      //       await getExitList(page: 1, search: currentSearch);
      //     }
      //   },
      //   icon: const Icon(Icons.add),
      //   label: const Text('Add Exit'),
      // ),
      body: RefreshIndicator(
        onRefresh: () => getExitList(page: currentPage, search: currentSearch),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            buildSearchSection(),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (exitList.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Center(
                  child: Text(
                    'No employee exit details found',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else ...[
              ...exitList.map((item) => buildEmployeeExitCard(item)).toList(),
              buildPaginationSection(),
              SizedBox(height: 80),
            ],
          ],
        ),
      ),
    );
  }
}
