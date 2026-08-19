import 'dart:convert';

import 'package:beposoft/pages/api.dart';
import 'staff_order_summary_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FamilyStaffSummaryPage extends StatefulWidget {
  final int familyId;
  final String familyName;
  final DateTimeRange selectedRange;

  const FamilyStaffSummaryPage({
    super.key,
    required this.familyId,
    required this.familyName,
    required this.selectedRange,
  });

  @override
  State<FamilyStaffSummaryPage> createState() =>
      _FamilyStaffSummaryPageState();
}

class _FamilyStaffSummaryPageState
    extends State<FamilyStaffSummaryPage> {
  bool isLoading = true;

  Map<String, dynamic> family = {};
  Map<String, dynamic> summary = {};
  Map<String, dynamic> dateRange = {};

  List<dynamic> staffWise = [];

  String? errorMessage;

  // -------------------------------------------------------------
  // INIT
  // -------------------------------------------------------------
  @override
  void initState() {
    super.initState();

    fetchStaffSummary();
  }

  // -------------------------------------------------------------
  // GET TOKEN
  // -------------------------------------------------------------
  Future<String?> gettokenFromPrefs() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

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
  // SAFE INT
  // -------------------------------------------------------------
  int safeInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value.toString(),
        ) ??
        0;
  }

  // -------------------------------------------------------------
  // SAFE DOUBLE
  // -------------------------------------------------------------
  double safeDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString(),
        ) ??
        0.0;
  }

  // -------------------------------------------------------------
  // FETCH STAFF SUMMARY
  //
  // API:
  // api/orders/family/<family_id>/staff/summary/<start>/<end>/
  // -------------------------------------------------------------
  Future<void> fetchStaffSummary() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final String start = formatDate(
      widget.selectedRange.start,
    );

    final String end = formatDate(
      widget.selectedRange.end,
    );

    final Uri url = Uri.parse(
      '$api/api/orders/family/${widget.familyId}/staff/summary/$start/$end/',
    );

    try {
      final String? token = await gettokenFromPrefs();

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
      };

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] =
            'Bearer $token';
      }

      final http.Response response =
          await http.get(
        url,
        headers: headers,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        try {
          final dynamic decoded =
              jsonDecode(response.body);

          if (decoded
              is Map<String, dynamic>) {
            if (decoded["status"] ==
                "success") {
              setState(() {
                family =
                    decoded["family"]
                            is Map<String, dynamic>
                        ? decoded["family"]
                        : {};

                dateRange =
                    decoded["date_range"]
                            is Map<String, dynamic>
                        ? decoded["date_range"]
                        : {};

                summary =
                    decoded["summary"]
                            is Map<String, dynamic>
                        ? decoded["summary"]
                        : {};

                staffWise =
                    decoded["staff_wise"]
                            is List
                        ? decoded[
                            "staff_wise"]
                        : [];

                isLoading = false;
                errorMessage = null;
              });

              return;
            }

            setState(() {
              family = {};
              dateRange = {};
              summary = {};
              staffWise = [];
              isLoading = false;

              errorMessage =
                  decoded["message"]
                          ?.toString() ??
                      "Unable to load staff report.";
            });

            return;
          }

          setState(() {
            family = {};
            dateRange = {};
            summary = {};
            staffWise = [];
            isLoading = false;

            errorMessage =
                "Invalid response received from server.";
          });
        } catch (e) {
          setState(() {
            family = {};
            dateRange = {};
            summary = {};
            staffWise = [];
            isLoading = false;

            errorMessage =
                "Unable to read server response.";
          });
        }
      } else {
        String message =
            "Unable to load staff report. "
            "Status code: ${response.statusCode}";

        try {
          final dynamic decoded =
              jsonDecode(response.body);

          if (decoded
              is Map<String, dynamic>) {
            final dynamic apiMessage =
                decoded["message"] ??
                    decoded["detail"] ??
                    decoded["error"];

            if (apiMessage != null) {
              message =
                  apiMessage.toString();
            }
          }
        } catch (_) {}

        setState(() {
          family = {};
          dateRange = {};
          summary = {};
          staffWise = [];
          isLoading = false;
          errorMessage = message;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        family = {};
        dateRange = {};
        summary = {};
        staffWise = [];
        isLoading = false;

        errorMessage =
            "Unable to connect to server. Please try again.";
      });
    }
  }

  // -------------------------------------------------------------
  // BUILD
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final String pageFamilyName =
        family["family_name"]
                ?.toString() ??
            widget.familyName;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "$pageFamilyName Staff Report",
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // -----------------------------------------------------
          // TOP SUMMARY
          // -----------------------------------------------------
          Padding(
            padding: const EdgeInsets.all(
              12,
            ),
            child: buildSummaryCard(),
          ),

          // -----------------------------------------------------
          // BODY
          // -----------------------------------------------------
          Expanded(
            child: isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : errorMessage != null
                    ? buildErrorState()
                    : staffWise.isEmpty
                        ? buildEmptyState()
                        : RefreshIndicator(
                            onRefresh:
                                fetchStaffSummary,
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
                                  for (var staff
                                      in staffWise)
                                    buildStaffCard(
                                      staff,
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
    );
  }

  // -------------------------------------------------------------
  // SUMMARY CARD
  // -------------------------------------------------------------
  Widget buildSummaryCard() {
    final int totalOrders = safeInt(
      summary["total_orders"],
    );

    final double totalAmount = safeDouble(
      summary["total_amount"],
    );

    final String start =
        formatDisplayDate(
      widget.selectedRange.start,
    );

    final String end =
        formatDisplayDate(
      widget.selectedRange.end,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0150B8),
            Color(0xFF3BD67C),
          ],
        ),
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
          ),
        ],
      ),
      padding:
          const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 14,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            "${widget.familyName.toUpperCase()} Summary",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight:
                  FontWeight.bold,
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
                decoration:
                    BoxDecoration(
                  color: Colors.white
                      .withOpacity(
                    0.15,
                  ),
                ),
                children: const [
                  Padding(
                    padding:
                        EdgeInsets.all(
                      6,
                    ),
                    child: Text(
                      "Type",
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color:
                            Colors.white,
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.all(
                      6,
                    ),
                    child: Text(
                      "Count",
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color:
                            Colors.white,
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.all(
                      6,
                    ),
                    child: Text(
                      "Amount",
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color:
                            Colors.white,
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
          padding:
              const EdgeInsets.all(
            6,
          ),
          child: Text(
            title,
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),

        Padding(
          padding:
              const EdgeInsets.all(
            6,
          ),
          child: Text(
            "$count",
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),

        Padding(
          padding:
              const EdgeInsets.all(
            6,
          ),
          child: Text(
            "₹${amount.toStringAsFixed(2)}",
            textAlign:
                TextAlign.right,
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // STAFF CARD
  // -------------------------------------------------------------
 Widget buildStaffCard(
  dynamic staff,
) {
  final Map<String, dynamic> data =
      staff is Map<String, dynamic>
          ? staff
          : Map<String, dynamic>.from(
              staff as Map,
            );

  // -----------------------------------------------------------
  // IMPORTANT:
  // This is the User primary key returned by API.
  // It is required by:
  //
  // api/orders/staff/<staff_id>/summary/...
  // -----------------------------------------------------------
  final int staffId = safeInt(
    data["staff_id"],
  );

  final String staffName =
      data["staff_name"]?.toString() ??
          "Unknown Staff";

  final int totalOrders = safeInt(
    data["total_orders"],
  );

  final double totalAmount = safeDouble(
    data["total_amount"],
  );

  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () {
      if (staffId <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Invalid staff information.",
            ),
          ),
        );

        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              StaffOrderSummaryPage(
            staffId: staffId,
            staffName: staffName,
            selectedRange:
                widget.selectedRange,
          ),
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      decoration:
          _boxDecoration(),
      child: Column(
        children: [
          _staffHeader(
            staffName:
                staffName,
          ),

          _staffTableBody(
            totalOrders:
                totalOrders,
            totalAmount:
                totalAmount,
          ),

          _staffFooter(
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
      borderRadius:
          BorderRadius.circular(
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
      borderRadius:
          BorderRadius.vertical(
        top: Radius.circular(
          12,
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // STAFF HEADER
  // STAFF NAME + DATE IN SAME ROW
  // -------------------------------------------------------------
  Widget _staffHeader({
    required String staffName,
  }) {
    final String start =
        formatDisplayDate(
      widget.selectedRange.start,
    );

    final String end =
        formatDisplayDate(
      widget.selectedRange.end,
    );

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(
        12,
      ),
      decoration: _gradient(),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              staffName.toUpperCase(),
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Text(
            "$start → $end",
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // STAFF INFO
  // -------------------------------------------------------------

  // -------------------------------------------------------------
  // STAFF INFO ITEM
  // -------------------------------------------------------------
 
  // -------------------------------------------------------------
  // STAFF TABLE
  // -------------------------------------------------------------
  Widget _staffTableBody({
    required int totalOrders,
    required double totalAmount,
  }) {
    return Padding(
      padding:
          const EdgeInsets.all(
        12,
      ),
      child: Table(
        border: TableBorder.all(
          color:
              Colors.grey.shade400,
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
        color:
            Colors.grey.shade200,
      ),
      children: const [
        Padding(
          padding:
              EdgeInsets.all(
            8,
          ),
          child: Text(
            "Type",
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding:
              EdgeInsets.all(
            8,
          ),
          child: Text(
            "Count",
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding:
              EdgeInsets.all(
            8,
          ),
          child: Text(
            "Amount",
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TABLE ROW
  // -------------------------------------------------------------
  TableRow _row(
    String label,
    dynamic count,
    dynamic amount,
  ) {
    final double amt =
        safeDouble(amount);

    return TableRow(
      children: [
        Padding(
          padding:
              const EdgeInsets.all(
            8,
          ),
          child: Text(
            label,
          ),
        ),
        Padding(
          padding:
              const EdgeInsets.all(
            8,
          ),
          child: Text(
            "${count ?? 0}",
          ),
        ),
        Padding(
          padding:
              const EdgeInsets.all(
            8,
          ),
          child: Text(
            "₹${amt.toStringAsFixed(2)}",
            style:
                const TextStyle(
              color: Colors.green,
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // FOOTER
  // -------------------------------------------------------------
  Widget _staffFooter({
    required int totalOrders,
    required double totalAmount,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(
        12,
      ),
      decoration:
          const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0150B8),
            Color(0xFF3BD67C),
          ],
        ),
        borderRadius:
            BorderRadius.vertical(
          bottom:
              Radius.circular(
            12,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,
        children: [
          const Text(
            "Total",
            style:
                TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),

          Text(
            "$totalOrders",
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),

          Text(
            "₹${totalAmount.toStringAsFixed(2)}",
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
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
        formatDisplayDate(
      widget.selectedRange.start,
    );

    final String end =
        formatDisplayDate(
      widget.selectedRange.end,
    );

    return RefreshIndicator(
      onRefresh:
          fetchStaffSummary,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height:
                MediaQuery.of(context)
                        .size
                        .height *
                    0.30,
          ),

          const Icon(
            Icons.people_outline,
            size: 50,
            color: Colors.grey,
          ),

          const SizedBox(
            height: 12,
          ),

          const Center(
            child: Text(
              "No staff sales data found",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
                fontWeight:
                    FontWeight.w500,
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
                color:
                    Colors.grey.shade600,
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
      onRefresh:
          fetchStaffSummary,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height:
                MediaQuery.of(context)
                        .size
                        .height *
                    0.25,
          ),

          const Icon(
            Icons.error_outline,
            size: 50,
            color:
                Colors.redAccent,
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
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color:
                      Colors.grey.shade700,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          Center(
            child:
                ElevatedButton.icon(
              onPressed:
                  fetchStaffSummary,
              icon: const Icon(
                Icons.refresh,
                size: 18,
              ),
              label:
                  const Text(
                "Retry",
              ),
            ),
          ),
        ],
      ),
    );
  }
}