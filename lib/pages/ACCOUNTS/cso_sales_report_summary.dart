import 'dart:convert';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/ADMIN/sales_report_excel_familywise.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/MARKETING/marketing_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalesReportExcelsummary extends StatefulWidget {
  const SalesReportExcelsummary({super.key});

  @override
  State<SalesReportExcelsummary> createState() => _SalesReportExcelsummaryState();
}

class _SalesReportExcelsummaryState extends State<SalesReportExcelsummary> {
  bool isLoading = true;
  bool famLoaded = false;

  DateTimeRange? selectedRange;

  Map<String, dynamic> summary = {};
  List<dynamic> orders = [];
  List<Map<String, dynamic>> fam = [];

  final List<String> allowedFamilies = const [
    'cycling',
    'skating',
  ];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    selectedRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );

    getfamily().then((_) {
      if (mounted) fetchReport();
    });
  }

  Future<String?> gettokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  String formatDate(DateTime date) => DateFormat("yyyy-MM-dd").format(date);

  String formatDisplayDate(DateTime date) {
    return DateFormat("dd/MM/yyyy").format(date);
  }

  bool _isAllowedFamily(dynamic familyName) {
    return allowedFamilies.contains(
      familyName.toString().trim().toLowerCase(),
    );
  }

  Map<String, dynamic> _buildFilteredSummary(List<dynamic> filteredOrders) {
    int totalCount = 0;
    double totalAmount = 0.0;

    int approvedCount = 0;
    double approvedAmount = 0.0;

    int pendingCount = 0;
    double pendingAmount = 0.0;

    int rejectedCount = 0;
    double rejectedAmount = 0.0;

    final List<String> pendingStatuses = [
      "Invoice Created",
      "Invoice Approved",
      "Waiting for confirmation",
      "Waiting For Confirmation",
    ];

    final List<String> excludedFromApprovedStatuses = [
      "Invoice Rejected",
      "Invoice Created",
      "Invoice Approved",
      "Waiting for confirmation",
      "Waiting For Confirmation",
    ];

    for (var order in filteredOrders) {
      final double amount = ((order["amount"] ?? 0) as num).toDouble();
      final String status = order["status"]?.toString().trim() ?? "";

      final bool isRejected = status == "Invoice Rejected";
      final bool isPending = pendingStatuses.contains(status);
      final bool isApproved = !excludedFromApprovedStatuses.contains(status);

      totalCount++;
      totalAmount += amount;

      if (isRejected) {
        rejectedCount++;
        rejectedAmount += amount;
      }

      if (isPending) {
        pendingCount++;
        pendingAmount += amount;
      }

      if (isApproved) {
        approvedCount++;
        approvedAmount += amount;
      }
    }

    return {
      "total_orders": {
        "count": totalCount,
        "amount": totalAmount,
      },
      "non_rejected_orders": {
        "count": approvedCount,
        "amount": approvedAmount,
      },
      "pending_orders": {
        "count": pendingCount,
        "amount": pendingAmount,
      },
      "rejected_orders": {
        "count": rejectedCount,
        "amount": rejectedAmount,
      },
    };
  }

  Future<void> getfamily() async {
    try {
      final token = await gettokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/familys/'),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'] ?? [];

        fam = [];

        for (var f in data) {
          final familyName = f["name"].toString();

          if (_isAllowedFamily(familyName)) {
            fam.add({
              "id": f["id"],
              "name": familyName,
            });
          }
        }

        if (mounted) {
          setState(() {
            famLoaded = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            famLoaded = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          famLoaded = true;
        });
      }
    }
  }

  Future<void> fetchReport() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    final start = formatDate(selectedRange!.start);
    final end = formatDate(selectedRange!.end);

    final url = Uri.parse(
      "https://bepocart.in/api/orders/date/report/$start/$end/",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200 && response.body.startsWith("{")) {
        final data = jsonDecode(response.body);

        final List<dynamic> allOrders = data["orders"] ?? [];

        final List<dynamic> filteredOrders = allOrders.where((order) {
          return _isAllowedFamily(order["family_name"]);
        }).toList();

        if (!mounted) return;

        setState(() {
          orders = filteredOrders;
          summary = _buildFilteredSummary(filteredOrders);
          isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: selectedRange,
      firstDate: DateTime(2024),
      lastDate: DateTime(2027),
    );

    if (picked != null) {
      selectedRange = picked;

      if (mounted) {
        fetchReport();
      }
    }
  }

  Map<String, Map<String, dynamic>> groupByFamily() {
    final Map<String, Map<String, dynamic>> result = {};

    for (var f in fam) {
      result[f["name"]] = {
        "id": f["id"],
        "total_count": 0,
        "total_amount": 0.0,
        "approved_count": 0,
        "approved_amount": 0.0,
        "pending_count": 0,
        "pending_amount": 0.0,
        "rejected_count": 0,
        "rejected_amount": 0.0,
      };
    }

    final List<String> pendingStatuses = [
      "Invoice Created",
      "Invoice Approved",
      "Waiting for confirmation",
      "Waiting For Confirmation",
    ];

    final List<String> excludedFromApprovedStatuses = [
      "Invoice Rejected",
      "Invoice Created",
      "Invoice Approved",
      "Waiting for confirmation",
      "Waiting For Confirmation",
    ];

    for (var order in orders) {
      final family = order["family_name"];
      final amount = ((order["amount"] ?? 0) as num).toDouble();
      final status = order["status"]?.toString().trim() ?? "";

      if (!_isAllowedFamily(family)) continue;

      final bool isRejected = status == "Invoice Rejected";
      final bool isPending = pendingStatuses.contains(status);
      final bool isApproved = !excludedFromApprovedStatuses.contains(status);

      if (!result.containsKey(family)) continue;

      result[family]!["total_count"]++;
      result[family]!["total_amount"] += amount;

      if (isRejected) {
        result[family]!["rejected_count"]++;
        result[family]!["rejected_amount"] += amount;
      }

      if (isPending) {
        result[family]!["pending_count"]++;
        result[family]!["pending_amount"] += amount;
      }

      if (isApproved) {
        result[family]!["approved_count"]++;
        result[family]!["approved_amount"] += amount;
      }
    }

    return result;
  }

  drower d = drower();

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();

    Widget page;

    switch (dep) {
      case "BDO":
        page = bdo_dashbord();
        break;
      case "BDM":
        page = bdm_dashbord();
        break;
      case "warehouse":
        page = WarehouseDashboard();
        break;
      case "CEO":
        page = ceo_dashboard();
        break;
      case "COO":
        page = ceo_dashboard();
        break;
      case "CSO":
        page = cso_dashboard();
        break;
      case "Warehouse Admin":
        page = WarehouseAdmin();
        break;
      case "Marketing":
        page = marketing_dashboard();
        break;
      default:
        page = dashboard();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!famLoaded) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final grouped = groupByFamily();
    final reportSummary = summary;

    return WillPopScope(
      onWillPop: () async {
        _navigateBack();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Family Wise Sales Report",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.date_range),
              onPressed: pickDateRange,
            ),
          ],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _navigateBack();
            },
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: buildCompletedSummaryCard(reportSummary),
            ),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          for (var family in grouped.keys)
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FamilyReportPage(
                                      familyId: grouped[family]!["id"],
                                      familyName: family,
                                      selectedRange: selectedRange!,
                                    ),
                                  ),
                                );
                              },
                              child: buildFamilyCard(
                                family,
                                grouped[family]!,
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget buildCompletedSummaryCard(Map<String, dynamic> data) {
    final totalOrders = data["total_orders"] ??
        {
          "count": 0,
          "amount": 0.0,
        };

    final nonRejectedOrders = data["non_rejected_orders"] ??
        {
          "count": 0,
          "amount": 0.0,
        };

    final pendingOrders = data["pending_orders"] ??
        {
          "count": 0,
          "amount": 0.0,
        };

    final rejectedOrders = data["rejected_orders"] ??
        {
          "count": 0,
          "amount": 0.0,
        };

    final String start = formatDisplayDate(selectedRange!.start);
    final String end = formatDisplayDate(selectedRange!.end);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0150B8),
            Color(0xFF3BD67C),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Sales Summary",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "$start → $end",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          Table(
            border: TableBorder.all(
              color: Colors.white54,
              width: 0.8,
            ),
            columnWidths: const {
              0: FlexColumnWidth(2.3),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1.8),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(6),
                    child: Text(
                      "Type",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(6),
                    child: Text(
                      "Count",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(6),
                    child: Text(
                      "Amount",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              _summaryTableRow("Total Bills", totalOrders),
              _summaryTableRow("Approved Bills", nonRejectedOrders),
              _summaryTableRow("Pending Bills", pendingOrders),
              _summaryTableRow("Rejected Bills", rejectedOrders),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _summaryTableRow(String title, dynamic rowData) {
    final int count = rowData is Map ? (rowData["count"] ?? 0) : 0;

    final double amount = rowData is Map
        ? ((rowData["amount"] ?? 0) as num).toDouble()
        : 0.0;

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            title,
            textAlign: TextAlign.left,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            "$count",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            "₹${amount.toStringAsFixed(2)}",
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildFamilyCard(String family, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: _boxDecoration(),
      child: Column(
        children: [
          _header(family),
          _tableBody(data),
          _footer(data),
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 5,
        ),
      ],
    );
  }

  BoxDecoration _gradient() {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color(0xFF0150B8),
          Color(0xFF3BD67C),
        ],
      ),
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(12),
      ),
    );
  }

  Widget _header(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _gradient(),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _tableBody(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Table(
        border: TableBorder.all(
          color: Colors.grey.shade400,
        ),
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(2),
        },
        children: [
          _headerRow(),
          _row(
            "Total Bills",
            data["total_count"],
            data["total_amount"],
          ),
          _row(
            "Approved Bills",
            data["approved_count"],
            data["approved_amount"],
          ),
          _row(
            "Pending Bills",
            data["pending_count"],
            data["pending_amount"],
          ),
          _row(
            "Rejected Bills",
            data["rejected_count"],
            data["rejected_amount"],
          ),
        ],
      ),
    );
  }

  TableRow _headerRow() {
    return TableRow(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
      ),
      children: const [
        Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            "Type",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            "Count",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            "Amount",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  TableRow _row(String label, dynamic count, dynamic amount) {
    final double amt = ((amount ?? 0) as num).toDouble();

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(label),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text("${count ?? 0}"),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            "₹${amt.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.green,
            ),
          ),
        ),
      ],
    );
  }

  Widget _footer(Map<String, dynamic> data) {
    final double amount = ((data["total_amount"] ?? 0) as num).toDouble();
    final int count = data["total_count"] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _gradient(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Total",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          Text(
            "$count",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          Text(
            "₹${amount.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}