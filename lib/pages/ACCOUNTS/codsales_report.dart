import 'dart:convert';
import 'package:beposoft/pages/ACCOUNTS/codsale_date_report.dart';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart' show cso_dashboard;
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CodSales2 extends StatefulWidget {
  const CodSales2({super.key});

  @override
  State<CodSales2> createState() => _CodSales2State();
}

class _CodSales2State extends State<CodSales2> {
  List<Map<String, dynamic>> allCodReportList = [];
  List<Map<String, dynamic>> stat = [];
  List<Map<String, dynamic>> allStaffList = [];
  List<Map<String, dynamic>> fam = [];
  List<Map<String, dynamic>> sta = [];
  List<Map<String, dynamic>> filteredStates = [];

  String? selectedFamily;
  String? selectedStaff;
  String? selectedState;

  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  double sumTotalAmount = 0.0;
  int sumTotalOrders = 0;
  double sumTotalPaidAmount = 0.0;
  double sumBalanceAmount = 0.0;

  final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    final today = DateTime.now();
    selectedStartDate = today;
    selectedEndDate = today;

    getCODsaleReport();
    getfamily();
    getstaff();
    getstate();
  }

  Future<String?> getTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  String _amount(dynamic value) {
    final parsed = double.tryParse(value.toString()) ?? 0.0;
    return parsed.toStringAsFixed(2);
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: selectedStartDate != null && selectedEndDate != null
          ? DateTimeRange(start: selectedStartDate!, end: selectedEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 12, 80, 163),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedStartDate = picked.start;
        selectedEndDate = picked.end;
      });
      getCODsaleReport();
    }
  }

  Future<void> getstate() async {
    try {
      final token = await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/states/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final productsData = parsed['data'] ?? [];

        final statelist = productsData.map<Map<String, dynamic>>((item) {
          return {
            'id': item['id'],
            'name': item['name'],
          };
        }).toList();

        setState(() {
          stat = statelist;
        });
      }
    } catch (_) {}
  }

  Future<void> getstaff() async {
    try {
      final token = await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/staffs/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final productsData = parsed['data'] ?? [];

        final stafflist = productsData.map<Map<String, dynamic>>((item) {
          return {
            'id': item['id'],
            'name': item['name'],
            'family': item['family_name'],
            'allocated_states': item['allocated_states'] ?? [],
          };
        }).toList();

        setState(() {
          allStaffList = stafflist;
          sta = stafflist;
        });
      }
    } catch (_) {}
  }

  Future<void> getfamily() async {
    try {
      final token = await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/familys/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final productsData = parsed['data'] ?? [];

        final familylist = productsData.map<Map<String, dynamic>>((item) {
          return {
            'id': item['id'],
            'name': item['name'],
          };
        }).toList();

        setState(() {
          fam = familylist;
        });
      }
    } catch (_) {}
  }

  Future<void> getCODsaleReport() async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = await getTokenFromPrefs();

      final selectedFamilyData = fam.firstWhere(
        (item) => item['name'] == selectedFamily,
        orElse: () => <String, dynamic>{},
      );

      final selectedStaffData = allStaffList.firstWhere(
        (item) => item['name'] == selectedStaff,
        orElse: () => <String, dynamic>{},
      );

      final selectedStateData = stat.firstWhere(
        (item) => item['name'] == selectedState,
        orElse: () => <String, dynamic>{},
      );

      final uri = Uri.parse('$api/api/COD/sales/').replace(
        queryParameters: {
          if (selectedStartDate != null)
            'start_date': _apiDateFormat.format(selectedStartDate!),
          if (selectedEndDate != null)
            'end_date': _apiDateFormat.format(selectedEndDate!),
          if (selectedFamilyData.isNotEmpty)
            'family': selectedFamilyData['id'].toString(),
          if (selectedStaffData.isNotEmpty)
            'staff': selectedStaffData['id'].toString(),
          if (selectedStateData.isNotEmpty)
            'state': selectedStateData['id'].toString(),
        },
      );

      debugPrint('COD SALES URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('COD SALES STATUS: ${response.statusCode}');
      debugPrint('COD SALES BODY: ${response.body}');

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        final summary = parsed['summary'] ?? {};
        final data = parsed['data'] ?? [];

        final reportList = data.map<Map<String, dynamic>>((item) {
          final itemSummary = item['summary'] ?? {};

          return {
            'date': item['date'],
            'total_orders': itemSummary['total_orders'] ?? 0,
            'total_amount': itemSummary['total_amount'] ?? 0.0,
            'total_paid_amount': itemSummary['paid_amount'] ?? 0.0,
            'balance_amount': itemSummary['balance_amount'] ?? 0.0,
          };
        }).toList();

        setState(() {
          allCodReportList = reportList;

          sumTotalOrders = summary['total_orders'] ?? 0;
          sumTotalAmount =
              double.tryParse((summary['total_amount'] ?? 0).toString()) ?? 0.0;
          sumTotalPaidAmount =
              double.tryParse((summary['paid_amount'] ?? 0).toString()) ?? 0.0;
          sumBalanceAmount =
              double.tryParse((summary['balance_amount'] ?? 0).toString()) ??
                  0.0;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to fetch sales report data (${response.statusCode})',
            ),
          ),
        );
      }
    } catch (error) {
      debugPrint('COD SALES ERROR: $error');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error fetching sales report data'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
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
    } else if (dep == "warehouse") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WarehouseDashboard()),
      );
    } else if (dep == "CEO" || dep == "COO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ceo_dashboard()),
      );
    } else if (dep == "CSO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => cso_dashboard()),
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

  void _resetFilters() {
    final today = DateTime.now();

    setState(() {
      selectedFamily = null;
      selectedStaff = null;
      selectedState = null;
      selectedStartDate = today;
      selectedEndDate = today;
      sta = allStaffList;
      filteredStates = [];
    });

    getCODsaleReport();
    getstaff();
  }

  Widget _buildFilterDropdown({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Row(
            children: [
              Icon(icon,
                  size: 18, color: const Color.fromARGB(255, 12, 80, 163)),
              const SizedBox(width: 8),
              Text(hint),
            ],
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDateRangeChip() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 12, 80, 163),
            Color.fromARGB(255, 28, 119, 219),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              selectedStartDate != null && selectedEndDate != null
                  ? '${_apiDateFormat.format(selectedStartDate!)}  to  ${_apiDateFormat.format(selectedEndDate!)}'
                  : 'All dates',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          InkWell(
            onTap: _selectDateRange,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Change',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 12, 80, 163)
                        .withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: Color.fromARGB(255, 12, 80, 163),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Date: ${report['date'] ?? ''}',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 12, 80, 163),
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(3),
              },
              border: TableBorder.all(color: Colors.grey.shade200),
              children: [
                _buildRow("Total Orders", report['total_orders'].toString()),
                _buildRow(
                    "Total Amount", "₹${_amount(report['total_amount'])}"),
                _buildRow(
                  "Paid Amount",
                  "₹${_amount(report['total_paid_amount'])}",
                ),
                _buildRow("Balance", "₹${_amount(report['balance_amount'])}"),
              ],
            ),
            const SizedBox(height: 12),
            // if (selectedFamily == null &&
            //     selectedStaff == null &&
            //     selectedState == null)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  final selectedFamilyData = fam.firstWhere(
                    (item) => item['name'] == selectedFamily,
                    orElse: () => <String, dynamic>{},
                  );

                  final selectedStaffData = allStaffList.firstWhere(
                    (item) => item['name'] == selectedStaff,
                    orElse: () => <String, dynamic>{},
                  );

                  final selectedStateData = stat.firstWhere(
                    (item) => item['name'] == selectedState,
                    orElse: () => <String, dynamic>{},
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => codsalereport_datewise_view(
                        date: report['date'].toString(),
                        family: selectedFamilyData.isNotEmpty
                            ? selectedFamilyData['id'].toString()
                            : null,
                        staff: selectedStaffData.isNotEmpty
                            ? selectedStaffData['id'].toString()
                            : null,
                        state: selectedStateData.isNotEmpty
                            ? selectedStateData['id'].toString()
                            : null,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility, size: 17),
                label: const Text('View'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 12, 80, 163),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 58, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            const Text(
              'No COD sales data found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try changing date range or filters',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xffF5F7FB),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: const Text(
            "COD Sales Report",
            style: TextStyle(
              fontSize: 15,
              color: Color.fromARGB(255, 32, 43, 61),
              fontWeight: FontWeight.w800,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back,
                color: Color.fromARGB(255, 32, 43, 61)),
            onPressed: _navigateBack,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.date_range),
              color: const Color.fromARGB(255, 12, 80, 163),
              onPressed: _selectDateRange,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              color: const Color.fromARGB(255, 32, 43, 61),
              onPressed: _resetFilters,
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                _buildDateRangeChip(),
                _buildFilterDropdown(
                  label: 'Family',
                  hint: 'Select Family',
                  icon: Icons.category_outlined,
                  value: selectedFamily,
                  items: fam.map((family) {
                    return DropdownMenuItem<String>(
                      value: family['name'],
                      child: Text(family['name'].toString()),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedFamily = newValue;
                      selectedStaff = null;
                      selectedState = null;
                      filteredStates = [];
                      sta = allStaffList
                          .where((staff) => staff['family'] == selectedFamily)
                          .toList();
                    });
                    getCODsaleReport();
                  },
                ),
                _buildFilterDropdown(
                  label: 'Staff',
                  hint: 'Select Staff',
                  icon: Icons.person_outline,
                  value: selectedStaff,
                  items: sta.map((staff) {
                    return DropdownMenuItem<String>(
                      value: staff['name'],
                      child: Text(staff['name'].toString()),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedStaff = newValue;
                      selectedState = null;

                      final staff = sta.firstWhere(
                        (s) => s['name'] == newValue,
                        orElse: () => <String, dynamic>{},
                      );

                      if (staff.isNotEmpty &&
                          staff['allocated_states'] != null) {
                        final allocatedStateIds = staff['allocated_states'];
                        filteredStates = stat
                            .where((state) =>
                                allocatedStateIds.contains(state['id']))
                            .toList();
                      } else {
                        filteredStates = [];
                      }
                    });
                    getCODsaleReport();
                  },
                ),
                _buildFilterDropdown(
                  label: 'State',
                  hint: 'Select State',
                  icon: Icons.location_on_outlined,
                  value: selectedState,
                  items: filteredStates.map((state) {
                    return DropdownMenuItem<String>(
                      value: state['name'],
                      child: Text(state['name'].toString()),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedState = newValue;
                    });
                    getCODsaleReport();
                  },
                ),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color.fromARGB(255, 12, 80, 163),
                          ),
                        )
                      : allCodReportList.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 175),
                              itemCount: allCodReportList.length,
                              itemBuilder: (context, index) {
                                return _buildReportCard(
                                  allCodReportList[index],
                                );
                              },
                            ),
                ),
              ],
            ),

            // Bottom summary design unchanged
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Material(
                elevation: 12,
                color: const Color.fromARGB(255, 12, 80, 163),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                  decoration: const BoxDecoration(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                    color: Color.fromARGB(255, 12, 80, 163),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Report Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Divider(
                        color: Colors.white.withOpacity(0.5),
                        thickness: 1,
                      ),
                      Table(
                        border: TableBorder.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                        columnWidths: const {
                          0: FlexColumnWidth(),
                          1: FlexColumnWidth(),
                        },
                        children: [
                          _buildCardTableRow(
                            'Total Orders',
                            sumTotalOrders.toString(),
                          ),
                          _buildCardTableRow(
                            'Total Amount',
                            sumTotalAmount.toStringAsFixed(2),
                          ),
                          _buildCardTableRow(
                            'Paid Amount',
                            sumTotalPaidAmount.toStringAsFixed(2),
                          ),
                          _buildCardTableRow(
                            'Balance Amount',
                            sumBalanceAmount.toStringAsFixed(2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildRowWithTwoColumns(
    String label1, dynamic value1, String label2, dynamic value2) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label1,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              Text(
                value1.toString(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label2,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              Text(
                value2.toString(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

TableRow _buildTableRow(
    String label1, String value1, String label2, String value2) {
  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          label1,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          value1,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          label2,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          value2,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    ],
  );
}

TableRow _buildCardTableRow(String label, String value) {
  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    ],
  );
}

TableRow _buildRow(String label, String value) {
  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    ],
  );
}
