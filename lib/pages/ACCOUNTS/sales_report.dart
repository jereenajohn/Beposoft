import 'dart:convert';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/invoice_report.dart';
import 'package:beposoft/pages/ACCOUNTS/invoicereportstaffwise.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/ADMIN/familywise_salesreport.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Sales_Report extends StatefulWidget {
  const Sales_Report({super.key});

  @override
  State<Sales_Report> createState() => _Sales_ReportState();
}

class _Sales_ReportState extends State<Sales_Report> {
  List<Map<String, dynamic>> filterdata = [];
  List<Map<String, dynamic>> sta = [];
  List<Map<String, dynamic>> sortedSta = [];
  List<Map<String, dynamic>> fam = [];

  double totalBills = 0.0;
  double totalAmount = 0.0;
  double approvedBills = 0.0;
  double approvedAmount = 0.0;
  double rejectedBills = 0.0;
  double rejectedAmount = 0.0;

  String? selectedstaff;
  String? selectedFamily;

  DateTime? startDate;
  DateTime? endDate;
  String? selectedFamilyId;
  String? selectedStaffId;

  bool isLoading = false;

  final DateFormat apiDateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat displayDateFormat = DateFormat('MM/dd/yyyy');

  drower d = drower();

  @override
  void initState() {
    super.initState();

    final today = DateTime.now();
    startDate = today;
    endDate = today;

    getSalesReport();
    getstaff();
    getfamily();
  }

  Future<String?> getTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  String _selectedFamilyId() {
    final family = fam.firstWhere(
      (item) => item['name'] == selectedFamily,
      orElse: () => <String, dynamic>{},
    );
    return family.isNotEmpty ? family['id'].toString() : '';
  }

  String _selectedStaffId() {
    final staff = sta.firstWhere(
      (item) => item['name'] == selectedstaff,
      orElse: () => <String, dynamic>{},
    );
    return staff.isNotEmpty ? staff['id'].toString() : '';
  }

  void _calculateTotalsFromApiList(List<Map<String, dynamic>> reports) {
    double tb = 0.0;
    double ta = 0.0;
    double ab = 0.0;
    double aa = 0.0;
    double cb = 0.0;
    double ca = 0.0;

    for (final report in reports) {
      final approved = report['approved'] ?? {};
      final rejected = report['rejected'] ?? {};

      tb += _toDouble(report['total_bills_in_date']);
      ta += _toDouble(report['amount']);
      ab += _toDouble(approved['bills']);
      aa += _toDouble(approved['amount']);
      cb += _toDouble(rejected['bills']);
      ca += _toDouble(rejected['amount']);
    }

    totalBills = tb;
    totalAmount = ta;
    approvedBills = ab;
    approvedAmount = aa;
    rejectedBills = cb;
    rejectedAmount = ca;
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
            'family_name': item['family_name'],
          };
        }).toList();

        setState(() {
          sta = stafflist;
          sortedSta = selectedFamily == null
              ? stafflist
              : stafflist
                  .where((staff) => staff['family_name'] == selectedFamily)
                  .toList();
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

  Future<void> getSalesReport() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final token = await getTokenFromPrefs();
      final familyId = selectedFamilyId ?? '';
      final staffId = selectedStaffId ?? '';

      final uri = Uri.parse('$api/api/salesreport/').replace(
        queryParameters: {
          if (startDate != null) 'start_date': apiDateFormat.format(startDate!),
          if (endDate != null) 'end_date': apiDateFormat.format(endDate!),
          if (familyId.isNotEmpty) 'family': familyId,
          if (staffId.isNotEmpty) 'staff': staffId,
        },
      );

      debugPrint('SALES REPORT URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('SALES REPORT STATUS: ${response.statusCode}');
      debugPrint('SALES REPORT BODY: ${response.body}');

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final salesData = parsed['sales_report'] ?? [];

        final List<Map<String, dynamic>> apiReports =
            salesData.map<Map<String, dynamic>>((reportData) {
          final approved = reportData['approved'] ?? {};
          final rejected = reportData['rejected'] ?? {};

          return {
            'date': reportData['date'],
            'total_bills_in_date': _toDouble(reportData['total_bills_in_date']),
            'amount': _toDouble(reportData['amount']),
            'approved': {
              'bills': _toDouble(approved['bills']),
              'amount': _toDouble(approved['amount']),
            },
            'rejected': {
              'bills': _toDouble(rejected['bills']),
              'amount': _toDouble(rejected['amount']),
            },
            'order_details': reportData['order_details'] ?? [],
          };
        }).toList();

        _calculateTotalsFromApiList(apiReports);

        setState(() {
          filterdata = apiReports;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to fetch sales report data (${response.statusCode})',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      debugPrint('SALES REPORT ERROR: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error fetching sales report data'),
          duration: Duration(seconds: 2),
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

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
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
        startDate = picked.start;
        endDate = picked.end;
      });

      getSalesReport();
    }
  }

  void _resetFilters() {
    final today = DateTime.now();

    setState(() {
      selectedFamily = null;
      selectedstaff = null;
      sortedSta = sta;
      startDate = today;
      endDate = today;
    });

    getSalesReport();
    getstaff();
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
    } else if (dep == "CSO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => cso_dashboard()),
      );
    } else if (dep == "CEO" || dep == "COO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ceo_dashboard()),
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

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('token');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    });

    await Future.delayed(const Duration(seconds: 2));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => login()),
    );
  }

  Widget _buildFilterDropdown({
    required String hint,
    required String? value,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blueAccent, width: 1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(icon, size: 18, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hint,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            ],
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: Colors.blue,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> reportData) {
    final approved = reportData['approved'] ?? {};

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date: ${reportData['date']}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: Color.fromARGB(255, 32, 43, 61),
              ),
            ),
            const SizedBox(height: 10),
            Divider(color: Colors.grey.shade400),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(3),
              },
              border: TableBorder.all(color: Colors.grey.shade300, width: 1),
              children: [
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'Bills:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        _toDouble(approved['bills']).toStringAsFixed(0),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'Amount:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        '₹${_toDouble(approved['amount']).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                final familyId = _selectedFamilyId();
                final staffId = _selectedStaffId();

                if (selectedstaff == null && selectedFamily == null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          Invoice_Report(date: reportData['date']),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => InvoiceReportStaffwise(
                              id: selectedStaffId,
                              staffName: selectedstaff,
                              familyId: selectedFamilyId,
                              familyName: selectedFamily,
                              date: reportData['date'],
                            )),
                  );
                }
              },
              child: const Text(
                "View",
                style: TextStyle(fontSize: 14, color: Colors.white),
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
        padding: const EdgeInsets.only(bottom: 180),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, color: Colors.grey.shade400, size: 56),
            const SizedBox(height: 10),
            const Text(
              'No sales report found',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Try changing date range or filters',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateLabel() {
    return Text(
      startDate != null && endDate != null
          ? '${displayDateFormat.format(startDate!)} - ${displayDateFormat.format(endDate!)}'
          : 'All Dates',
      style: const TextStyle(color: Colors.white, fontSize: 12),
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
            "Sales Report",
            style: TextStyle(
              fontSize: 15,
              color: Color.fromARGB(255, 32, 43, 61),
              fontWeight: FontWeight.w800,
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Color.fromARGB(255, 32, 43, 61),
            ),
            onPressed: _navigateBack,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.date_range),
              color: const Color.fromARGB(255, 12, 80, 163),
              onPressed: () => _selectDateRange(context),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              color: const Color.fromARGB(255, 32, 43, 61),
              onPressed: _resetFilters,
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.blueAccent, width: 1),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: Colors.blueAccent),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Select division and staff to filter. Date filter is applied from backend.",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterDropdown(
                      hint: 'Select Division',
                      value: selectedFamily,
                      icon: Icons.category_outlined,
                      items: fam.map((family) {
                        return DropdownMenuItem<String>(
                          value: family['name'],
                          child: Text(
                            family['name'].toString(),
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        final selectedFamilyData = fam.firstWhere(
                          (family) => family['name'] == newValue,
                          orElse: () => <String, dynamic>{},
                        );

                        setState(() {
                          selectedFamily = newValue;
                          selectedFamilyId = selectedFamilyData.isNotEmpty
                              ? selectedFamilyData['id'].toString()
                              : null;

                          selectedstaff = null;
                          selectedStaffId = null;

                          sortedSta = sta
                              .where((staff) =>
                                  staff['family_name'] == selectedFamily)
                              .toList();
                        });

                        getSalesReport();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFilterDropdown(
                      hint: 'Select Staff',
                      value: selectedstaff,
                      icon: Icons.person_outline,
                      items: sortedSta.map((staff) {
                        return DropdownMenuItem<String>(
                          value: staff['name'],
                          child: Text(
                            staff['name'].toString(),
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        final selectedStaffData = sta.firstWhere(
                          (staff) => staff['name'] == newValue,
                          orElse: () => <String, dynamic>{},
                        );

                        setState(() {
                          selectedstaff = newValue;
                          selectedStaffId = selectedStaffData.isNotEmpty
                              ? selectedStaffData['id'].toString()
                              : null;
                        });

                        getSalesReport();
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: getSalesReport,
                child: Stack(
                  children: [
                    isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color.fromARGB(255, 12, 80, 163),
                            ),
                          )
                        : filterdata.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 260),
                                itemCount: filterdata.length,
                                itemBuilder: (context, index) {
                                  return _buildReportCard(filterdata[index]);
                                },
                              ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Material(
                        elevation: 12,
                        color: const Color.fromARGB(255, 12, 80, 163),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 20,
                          ),
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            color: Color.fromARGB(255, 12, 80, 163),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Total Summary',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Spacer(),
                                  _buildDateLabel(),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.date_range,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      _selectDateRange(context);
                                    },
                                  ),
                                ],
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
                                  0: FlexColumnWidth(1),
                                  1: FlexColumnWidth(2),
                                  2: FlexColumnWidth(1),
                                  3: FlexColumnWidth(2),
                                },
                                children: [
                                  _buildTableRow(
                                    'TB',
                                    totalBills.toStringAsFixed(0),
                                    'TA',
                                    totalAmount.toStringAsFixed(2),
                                  ),
                                  _buildTableRow(
                                    'AB',
                                    approvedBills.toStringAsFixed(0),
                                    'AA',
                                    approvedAmount.toStringAsFixed(2),
                                  ),
                                  _buildTableRow(
                                    'CB',
                                    rejectedBills.toStringAsFixed(0),
                                    'CA',
                                    rejectedAmount.toStringAsFixed(2),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

TableRow _buildTableRow(
  String label1,
  String value1,
  String label2,
  String value2,
) {
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
