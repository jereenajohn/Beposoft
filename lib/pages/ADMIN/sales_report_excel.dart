import 'dart:convert';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
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
import 'sales_report_excel_familywise.dart';

class SalesReportExcel extends StatefulWidget {
  const SalesReportExcel({super.key});

  @override
  State<SalesReportExcel> createState() => _SalesReportExcelState();
}

class _SalesReportExcelState extends State<SalesReportExcel> {
  bool isLoading = true;
  bool famLoaded = false;

  DateTimeRange? selectedRange;

  Map<String, dynamic> summary = {};
  List<dynamic> orders = [];
  List<Map<String, dynamic>> fam = [];

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
  String formatDisplayDate(DateTime date) => DateFormat("dd/MM/yyyy").format(date);

  // -------------------------------------------------------------
  // LOAD FAMILY LIST
  // -------------------------------------------------------------
  Future<void> getfamily() async {
    try {
      final token = await gettokenFromPrefs();
      final response = await http.get(
        Uri.parse('$api/api/familys/'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];

        fam = [];
        for (var f in data) {
          fam.add({"id": f["id"], "name": f["name"].toString()});
        }

        if (mounted) setState(() => famLoaded = true);
      }
    } catch (e) {
    }
  }

  // -------------------------------------------------------------
  // FETCH FULL DATE-WISE REPORT
  // -------------------------------------------------------------
  Future<void> fetchReport() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    final start = formatDate(selectedRange!.start);
    final end = formatDate(selectedRange!.end);

    final url = Uri.parse("https://bepocart.in/api/orders/date/report/$start/$end/");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200 && response.body.startsWith("{")) {
        final data = jsonDecode(response.body);

        if (!mounted) return;

        setState(() {
          summary = data["summary"] ?? {};
          orders = data["orders"] ?? [];
          isLoading = false;
        });
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // -------------------------------------------------------------
  // DATE RANGE PICKER
  // -------------------------------------------------------------
  Future<void> pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: selectedRange,
      firstDate: DateTime(2024),
      lastDate: DateTime(2027),
    );

    if (picked != null) {
      selectedRange = picked;
      if (mounted) fetchReport();
    }
  }

  // -------------------------------------------------------------
  // GROUP ORDERS BY FAMILY
  // -------------------------------------------------------------
  Map<String, Map<String, dynamic>> groupByFamily() {
    final Map<String, Map<String, dynamic>> result = {};

    for (var f in fam) {
      result[f["name"]] = {
        "id": f["id"],
        "total_count": 0,
        "total_amount": 0.0,
        "approved_count": 0,
        "approved_amount": 0.0,
        "rejected_count": 0,
        "rejected_amount": 0.0,
      };
    }

    for (var order in orders) {
      final family = order["family_name"];
      final amount = (order["amount"] ?? 0).toDouble();
      final isRejected = order["status"] == "Invoice Rejected";

      if (!result.containsKey(family)) continue;

      result[family]!["total_count"]++;
      result[family]!["total_amount"] += amount;

      if (isRejected) {
        result[family]!["rejected_count"]++;
        result[family]!["rejected_amount"] += amount;
      } else {
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

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  // -------------------------------------------------------------
  // BUILD UI
  // -------------------------------------------------------------
@override
Widget build(BuildContext context) {
  if (!famLoaded) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  final grouped = groupByFamily();
  final nonRejected =
      summary["non_rejected_orders"] ?? {"count": 0, "amount": 0.0};

  return WillPopScope(
    onWillPop: () async {
      _navigateBack();
      return false;
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text(
          "Family Wise Sales Report",
          style: TextStyle(color: Colors.grey, fontSize: 14),
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
              MaterialPageRoute(builder: (context) => page),
            );
          },
        ),
      ),

      body: Column(
        children: [
          // FIXED SUMMARY CARD
          Padding(
            padding: const EdgeInsets.all(12),
            child: buildCompletedSummaryCard(nonRejected),
          ),

          // SCROLLABLE CONTENT
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
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
                            child: buildFamilyCard(family, grouped[family]!),
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


  // -------------------------------------------------------------
  // FULL GRADIENT COMPLETED SUMMARY CARD
  // -------------------------------------------------------------
 Widget buildCompletedSummaryCard(Map<String, dynamic> data) {
  double amount = (data["amount"] ?? 0).toDouble();
  int count = (data["count"] ?? 0);

  String start = formatDisplayDate(selectedRange!.start);
  String end = formatDisplayDate(selectedRange!.end);

  return Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0150B8), Color(0xFF3BD67C)],
      ),
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
    ),
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              "Completed Orders",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // Date Range (smaller)
        Text(
          "$start → $end",
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),

        const SizedBox(height: 10),

        // Small compact table
        Table(
          border: TableBorder.all(color: Colors.white54, width: 0.8),
          columnWidths: const {
            0: FlexColumnWidth(1.5),
            1: FlexColumnWidth(1.5),
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
                    "Count",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(6),
                  child: Text(
                    "Amount",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    "$count",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    "₹${amount.toStringAsFixed(2)}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}


  // -------------------------------------------------------------
  // FAMILY CARD
  // -------------------------------------------------------------
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

  BoxDecoration _boxDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
      );

  BoxDecoration _gradient() => const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF0150B8), Color(0xFF3BD67C)]),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      );

  Widget _header(String title) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: _gradient(),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );

  Widget _tableBody(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade400),
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(2),
        },
        children: [
          _headerRow(),
          _row("Total Bills", data["total_count"], data["total_amount"]),
          _row("Approved Bills", data["approved_count"], data["approved_amount"]),
          _row("Rejected Bills", data["rejected_count"], data["rejected_amount"]),
        ],
      ),
    );
  }

  TableRow _headerRow() => TableRow(
        decoration: BoxDecoration(color: Colors.grey.shade200),
        children: const [
          Padding(padding: EdgeInsets.all(8), child: Text("Type", style: TextStyle(fontWeight: FontWeight.bold))),
          Padding(padding: EdgeInsets.all(8), child: Text("Count", style: TextStyle(fontWeight: FontWeight.bold))),
          Padding(padding: EdgeInsets.all(8), child: Text("Amount", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      );

  TableRow _row(String label, dynamic count, dynamic amount) {
    double amt = (amount ?? 0).toDouble();
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(8), child: Text(label)),
        Padding(padding: const EdgeInsets.all(8), child: Text("${count ?? 0}")),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text("₹${amt.toStringAsFixed(2)}",
              style: const TextStyle(color: Colors.green)),
        ),
      ],
    );
  }

  Widget _footer(Map<String, dynamic> data) {
    double amount = (data["total_amount"] ?? 0).toDouble();
    int count = (data["total_count"] ?? 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _gradient(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Total", style: TextStyle(color: Colors.white, fontSize: 16)),
          Text("$count", style: const TextStyle(color: Colors.white, fontSize: 16)),
          Text("₹${amount.toStringAsFixed(2)}",
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
