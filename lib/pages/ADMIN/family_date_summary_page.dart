import 'dart:convert';

import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/MARKETING/marketing_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'family_staff_summary_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FamilyDateSummaryPage extends StatefulWidget {
  const FamilyDateSummaryPage({super.key});

  @override
  State<FamilyDateSummaryPage> createState() =>
      _FamilyDateSummaryPageState();
}

class _FamilyDateSummaryPageState
    extends State<FamilyDateSummaryPage> {
  bool isLoading = true;

  DateTimeRange? selectedRange;

  Map<String, dynamic> summary = {};
  List<dynamic> familyWise = [];

  String? errorMessage;

  // -------------------------------------------------------------
  // INIT
  // -------------------------------------------------------------
  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    // -----------------------------------------------------------
    // DEFAULT:
    // START DATE = CURRENT DATE
    // END DATE   = CURRENT DATE
    // -----------------------------------------------------------
    selectedRange = DateTimeRange(
      start: DateTime(
        now.year,
        now.month,
        now.day,
      ),
      end: DateTime(
        now.year,
        now.month,
        now.day,
      ),
    );

    fetchReport();
  }

  // -------------------------------------------------------------
  // GET TOKEN
  // -------------------------------------------------------------
  Future<String?> gettokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // -------------------------------------------------------------
  // API DATE FORMAT
  // -------------------------------------------------------------
  String formatDate(DateTime date) {
    return DateFormat("yyyy-MM-dd").format(date);
  }

  // -------------------------------------------------------------
  // DISPLAY DATE FORMAT
  // -------------------------------------------------------------
  String formatDisplayDate(DateTime date) {
    return DateFormat("dd/MM/yyyy").format(date);
  }

  // -------------------------------------------------------------
  // FORMAT MONEY
  // -------------------------------------------------------------
  String formatAmount(dynamic amount) {
    final double value = amount is num
        ? amount.toDouble()
        : double.tryParse(
              amount?.toString() ?? '',
            ) ??
            0.0;

    return value.toStringAsFixed(2);
  }

  // -------------------------------------------------------------
  // FETCH FAMILY DATE SUMMARY
  //
  // API:
  // api/orders/family/date/summary/<start>/<end>/
  // -------------------------------------------------------------
  Future<void> fetchReport() async {
    if (selectedRange == null) {
      return;
    }

    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final String start = formatDate(
      selectedRange!.start,
    );

    final String end = formatDate(
      selectedRange!.end,
    );

    final Uri url = Uri.parse(
      '$api/api/orders/family/date/summary/$start/$end/',
    );

    try {
      final String? token = await gettokenFromPrefs();

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
      };

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final http.Response response = await http.get(
        url,
        headers: headers,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        try {
          final dynamic decoded = jsonDecode(
            response.body,
          );

          if (decoded is Map<String, dynamic>) {
            if (decoded["status"] == "success") {
              setState(() {
                summary =
                    decoded["summary"] is Map<String, dynamic>
                        ? decoded["summary"]
                        : {};

                familyWise =
                    decoded["family_wise"] is List
                        ? decoded["family_wise"]
                        : [];

                isLoading = false;
                errorMessage = null;
              });

              return;
            }

            setState(() {
              summary = {};
              familyWise = [];
              isLoading = false;
              errorMessage =
                  decoded["message"]?.toString() ??
                      "Unable to load report.";
            });

            return;
          }

          setState(() {
            summary = {};
            familyWise = [];
            isLoading = false;
            errorMessage =
                "Invalid response received from server.";
          });
        } catch (e) {
          setState(() {
            summary = {};
            familyWise = [];
            isLoading = false;
            errorMessage =
                "Unable to read server response.";
          });
        }
      } else {
        String message =
            "Unable to load report. "
            "Status code: ${response.statusCode}";

        try {
          final dynamic decoded = jsonDecode(
            response.body,
          );

          if (decoded is Map<String, dynamic>) {
            final dynamic apiMessage =
                decoded["message"] ??
                    decoded["detail"] ??
                    decoded["error"];

            if (apiMessage != null) {
              message = apiMessage.toString();
            }
          }
        } catch (_) {}

        setState(() {
          summary = {};
          familyWise = [];
          isLoading = false;
          errorMessage = message;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        summary = {};
        familyWise = [];
        isLoading = false;
        errorMessage =
            "Unable to connect to server. Please try again.";
      });
    }
  }

  // -------------------------------------------------------------
  // DATE RANGE PICKER
  // -------------------------------------------------------------
  Future<void> pickDateRange() async {
    final DateTime now = DateTime.now();

    final DateTimeRange? picked =
        await showDateRangePicker(
      context: context,
      initialDateRange: selectedRange,
      firstDate: DateTime(2024),
      lastDate: DateTime(
        now.year + 1,
        12,
        31,
      ),
      helpText: "Select Date Range",
      confirmText: "APPLY",
      cancelText: "CANCEL",
      saveText: "APPLY",
    );

    if (picked != null) {
      if (!mounted) return;

      setState(() {
        selectedRange = DateTimeRange(
          start: DateTime(
            picked.start.year,
            picked.start.month,
            picked.start.day,
          ),
          end: DateTime(
            picked.end.year,
            picked.end.month,
            picked.end.day,
          ),
        );
      });

      await fetchReport();
    }
  }

  // -------------------------------------------------------------
  // GET DEPARTMENT
  // -------------------------------------------------------------
  Future<String?> getdepFromPrefs() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getString('department');
  }

  // -------------------------------------------------------------
  // NAVIGATE BACK
  // SAME LOGIC AS REFERENCE PAGE
  // -------------------------------------------------------------
  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();

    if (!mounted) return;

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
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }

  // -------------------------------------------------------------
  // BUILD UI
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _navigateBack();
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

          // -----------------------------------------------------
          // TOP RIGHT DATE RANGE FILTER
          // -----------------------------------------------------
          actions: [
            IconButton(
              tooltip: "Select Date Range",
              icon: const Icon(
                Icons.date_range,
              ),
              onPressed:
                  isLoading ? null : pickDateRange,
            ),
          ],

          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
            ),
            onPressed: () async {
              await _navigateBack();
            },
          ),
        ),
        body: Column(
          children: [
            // ---------------------------------------------------
            // TOP SUMMARY CARD
            // ---------------------------------------------------
            Padding(
              padding: const EdgeInsets.all(12),
              child: buildCompletedSummaryCard(
                summary,
              ),
            ),

            // ---------------------------------------------------
            // BODY
            // ---------------------------------------------------
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : errorMessage != null
                      ? buildErrorState()
                      : familyWise.isEmpty
                          ? buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: fetchReport,
                              child:
                                  SingleChildScrollView(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.all(
                                  12,
                                ),
                                child: Column(
                                  children: [
                                    for (var family
                                        in familyWise)
                                      buildFamilyCard(
                                        family,
                                      ),
                                  ],
                                ),
                              ),
                            ),
            ),

            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TOP SUMMARY CARD
  // SAME DESIGN AS REFERENCE
  // -------------------------------------------------------------
  Widget buildCompletedSummaryCard(
    Map<String, dynamic> data,
  ) {
    final int totalOrders =
        (data["total_orders"] as num?)
                ?.toInt() ??
            0;

    final double totalAmount =
        (data["total_amount"] as num?)
                ?.toDouble() ??
            0.0;

    final String start =
        selectedRange == null
            ? ""
            : formatDisplayDate(
                selectedRange!.start,
              );

    final String end =
        selectedRange == null
            ? ""
            : formatDisplayDate(
                selectedRange!.end,
              );

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0150B8),
            Color(0xFF3BD67C),
          ],
        ),
        borderRadius: BorderRadius.circular(
          14,
        ),
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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            "Sales Summary",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            "$start → $end",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

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
                  color:
                      Colors.white.withOpacity(
                    0.15,
                  ),
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(
                      6,
                    ),
                    child: Text(
                      "Type",
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(
                      6,
                    ),
                    child: Text(
                      "Count",
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(
                      6,
                    ),
                    child: Text(
                      "Amount",
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              _summaryTableRow(
                "Total Bills",
                totalOrders,
                totalAmount,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SUMMARY TABLE ROW
  // -------------------------------------------------------------
  TableRow _summaryTableRow(
    String title,
    int count,
    double amount,
  ) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(
            6,
          ),
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
          padding: const EdgeInsets.all(
            6,
          ),
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
          padding: const EdgeInsets.all(
            6,
          ),
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

  // -------------------------------------------------------------
  // FAMILY CARD
  // SAME STRUCTURE AS REFERENCE:
  //
  // HEADER
  // TABLE
  // FOOTER
  // -------------------------------------------------------------
Widget buildFamilyCard(
  dynamic family,
) {
  final Map<String, dynamic> data =
      family is Map<String, dynamic>
          ? family
          : Map<String, dynamic>.from(
              family as Map,
            );

  final int familyId =
      (data["family_id"] as num?)
              ?.toInt() ??
          0;

  final String familyName =
      data["family_name"]
              ?.toString() ??
          "";

  final int totalOrders =
      (data["total_orders"] as num?)
              ?.toInt() ??
          0;

  final double totalAmount =
      (data["total_amount"] as num?)
              ?.toDouble() ??
          0.0;

  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () {
      if (familyId <= 0 ||
          selectedRange == null) {
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              FamilyStaffSummaryPage(
            familyId: familyId,
            familyName:
                familyName,
            selectedRange:
                selectedRange!,
          ),
        ),
      );
    },
    child: Container(
      margin:
          const EdgeInsets.only(
        bottom: 16,
      ),
      decoration:
          _boxDecoration(),
      child: Column(
        children: [
          _header(
            familyName,
          ),

          _tableBody(
            totalOrders:
                totalOrders,
            totalAmount:
                totalAmount,
          ),

          _footer(
            totalOrders:
                totalOrders,
            totalAmount:
                totalAmount,
          ),
        ],
      ),
    ),
  );
}

  // -------------------------------------------------------------
  // CARD DECORATION
  // -------------------------------------------------------------
  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(
        12,
      ),
      boxShadow: const [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 5,
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // GRADIENT
  // -------------------------------------------------------------
  BoxDecoration _gradient() {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color(0xFF0150B8),
          Color(0xFF3BD67C),
        ],
      ),
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(
          12,
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // FAMILY HEADER
  // -------------------------------------------------------------
Widget _header(String title) {
  final String start = selectedRange == null
      ? ""
      : formatDisplayDate(selectedRange!.start);

  final String end = selectedRange == null
      ? ""
      : formatDisplayDate(selectedRange!.end);

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: _gradient(),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(width: 10),

        Text(
          "$start → $end",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

  // -------------------------------------------------------------
  // FAMILY TABLE
  // -------------------------------------------------------------
  Widget _tableBody({
    required int totalOrders,
    required double totalAmount,
  }) {
    return Padding(
      padding: const EdgeInsets.all(
        12,
      ),
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
            totalOrders,
            totalAmount,
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TABLE HEADER
  // -------------------------------------------------------------
  TableRow _headerRow() {
    return TableRow(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
      ),
      children: const [
        Padding(
          padding: EdgeInsets.all(
            8,
          ),
          child: Text(
            "Type",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        Padding(
          padding: EdgeInsets.all(
            8,
          ),
          child: Text(
            "Count",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        Padding(
          padding: EdgeInsets.all(
            8,
          ),
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

  // -------------------------------------------------------------
  // TABLE DATA ROW
  // -------------------------------------------------------------
  TableRow _row(
    String label,
    dynamic count,
    dynamic amount,
  ) {
    final double amt =
        ((amount ?? 0) as num)
            .toDouble();

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(
            8,
          ),
          child: Text(
            label,
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(
            8,
          ),
          child: Text(
            "${count ?? 0}",
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(
            8,
          ),
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

  // -------------------------------------------------------------
  // CARD FOOTER
  // -------------------------------------------------------------
  Widget _footer({
    required int totalOrders,
    required double totalAmount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        12,
      ),
      decoration: _gradient(),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Total",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),

          Text(
            "$totalOrders",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),

          Text(
            "₹${totalAmount.toStringAsFixed(2)}",
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

  // -------------------------------------------------------------
  // EMPTY STATE
  // -------------------------------------------------------------
  Widget buildEmptyState() {
    final String start =
        selectedRange == null
            ? ""
            : formatDisplayDate(
                selectedRange!.start,
              );

    final String end =
        selectedRange == null
            ? ""
            : formatDisplayDate(
                selectedRange!.end,
              );

    return RefreshIndicator(
      onRefresh: fetchReport,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height:
                MediaQuery.of(context)
                        .size
                        .height *
                    0.35,
          ),

          const Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Colors.grey,
          ),

          const SizedBox(
            height: 12,
          ),

          const Center(
            child: Text(
              "No sales data found",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Center(
            child: Text(
              "$start → $end",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // ERROR STATE
  // -------------------------------------------------------------
  Widget buildErrorState() {
    return RefreshIndicator(
      onRefresh: fetchReport,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height:
                MediaQuery.of(context)
                        .size
                        .height *
                    0.28,
          ),

          const Icon(
            Icons.error_outline,
            size: 50,
            color: Colors.redAccent,
          ),

          const SizedBox(
            height: 12,
          ),

          Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 30,
              ),
              child: Text(
                errorMessage ??
                    "Something went wrong.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          Center(
            child: ElevatedButton.icon(
              onPressed: fetchReport,
              icon: const Icon(
                Icons.refresh,
                size: 18,
              ),
              label: const Text(
                "Retry",
              ),
            ),
          ),
        ],
      ),
    );
  }
}