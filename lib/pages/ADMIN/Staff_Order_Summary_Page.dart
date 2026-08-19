import 'dart:convert';

import 'package:beposoft/pages/ACCOUNTS/order.review.dart';
import 'package:beposoft/pages/api.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StaffOrderSummaryPage extends StatefulWidget {
  final int staffId;
  final String staffName;
  final DateTimeRange selectedRange;

  const StaffOrderSummaryPage({
    super.key,
    required this.staffId,
    required this.staffName,
    required this.selectedRange,
  });

  @override
  State<StaffOrderSummaryPage> createState() =>
      _StaffOrderSummaryPageState();
}

class _StaffOrderSummaryPageState
    extends State<StaffOrderSummaryPage> {
  bool isLoading = true;

  Map<String, dynamic> staff = {};
  Map<String, dynamic> summary = {};
  Map<String, dynamic> dateRange = {};

  List<dynamic> orders = [];

  String? errorMessage;

  // -------------------------------------------------------------
  // INIT
  // -------------------------------------------------------------
  @override
  void initState() {
    super.initState();

    fetchStaffOrderSummary();
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
  // FETCH STAFF ORDER SUMMARY
  //
  // API:
  // api/orders/staff/<staff_id>/summary/<start>/<end>/
  // -------------------------------------------------------------
  Future<void> fetchStaffOrderSummary() async {
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
      '$api/api/orders/staff/${widget.staffId}/summary/$start/$end/',
    );

    try {
      final String? token =
          await gettokenFromPrefs();

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
      };

      if (token != null &&
          token.isNotEmpty) {
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

          if (decoded is Map<String, dynamic>) {
            if (decoded["status"] == "success") {
              setState(() {
                staff =
                    decoded["staff"]
                            is Map<String, dynamic>
                        ? decoded["staff"]
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

                orders =
                    decoded["orders"] is List
                        ? decoded["orders"]
                        : [];

                isLoading = false;
                errorMessage = null;
              });

              return;
            }

            setState(() {
              staff = {};
              dateRange = {};
              summary = {};
              orders = [];
              isLoading = false;

              errorMessage =
                  decoded["message"]?.toString() ??
                      "Unable to load order report.";
            });

            return;
          }

          setState(() {
            staff = {};
            dateRange = {};
            summary = {};
            orders = [];
            isLoading = false;

            errorMessage =
                "Invalid response received from server.";
          });
        } catch (_) {
          setState(() {
            staff = {};
            dateRange = {};
            summary = {};
            orders = [];
            isLoading = false;

            errorMessage =
                "Unable to read server response.";
          });
        }
      } else {
        String message =
            "Unable to load order report. "
            "Status code: ${response.statusCode}";

        try {
          final dynamic decoded =
              jsonDecode(response.body);

          if (decoded is Map<String, dynamic>) {
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
          staff = {};
          dateRange = {};
          summary = {};
          orders = [];
          isLoading = false;
          errorMessage = message;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        staff = {};
        dateRange = {};
        summary = {};
        orders = [];
        isLoading = false;

        errorMessage =
            "Unable to connect to server. Please try again.";
      });
    }
  }

  // -------------------------------------------------------------
  // OPEN ORDER REVIEW
  // -------------------------------------------------------------
 Future<void> openOrderReview(
  int orderId,
) async {
  if (orderId <= 0) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          "Invalid order ID.",
        ),
      ),
    );

    return;
  }

  // -----------------------------------------------------------
  // SHOW LOADING
  // -----------------------------------------------------------
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    },
  );

  try {
    final String? token =
        await gettokenFromPrefs();

    if (token == null ||
        token.trim().isEmpty) {
      if (!mounted) return;

      Navigator.of(
        context,
        rootNavigator: true,
      ).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Authentication token not found.",
          ),
        ),
      );

      return;
    }

    // -----------------------------------------------------------
    // FETCH ORDER DETAILS
    //
    // SAME API USED BY OrderReview
    // -----------------------------------------------------------
    final Uri url = Uri.parse(
      '$api/api/order/$orderId/items/',
    );

    final http.Response response =
        await http.get(
      url,
      headers: {
        'Authorization':
            'Bearer $token',
        'Content-Type':
            'application/json',
      },
    );

    if (!mounted) return;

    // -----------------------------------------------------------
    // CLOSE LOADING
    // -----------------------------------------------------------
    Navigator.of(
      context,
      rootNavigator: true,
    ).pop();

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Unable to load order details. "
            "Status: ${response.statusCode}",
          ),
        ),
      );

      return;
    }

    // -----------------------------------------------------------
    // DECODE RESPONSE
    // -----------------------------------------------------------
    final dynamic decoded =
        jsonDecode(response.body);

    if (decoded is! Map) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Invalid order response.",
          ),
        ),
      );

      return;
    }

    // -----------------------------------------------------------
    // GET ORDER
    // -----------------------------------------------------------
    final dynamic order =
        decoded['order'];

    if (order is! Map) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Order information not found.",
          ),
        ),
      );

      return;
    }

    // -----------------------------------------------------------
    // GET CUSTOMER
    // -----------------------------------------------------------
    final dynamic customer =
        order['customer'];

    if (customer is! Map) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Customer information not found.",
          ),
        ),
      );

      return;
    }

    // -----------------------------------------------------------
    // GET CUSTOMER ID
    // -----------------------------------------------------------
    final int customerId =
        safeInt(
      customer['id'],
    );

    if (customerId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Invalid customer ID.",
          ),
        ),
      );

      return;
    }

    // -----------------------------------------------------------
    // OPEN EXISTING ORDER REVIEW
    //
    // NO CHANGE REQUIRED IN OrderReview
    // -----------------------------------------------------------
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderReview(
          id: orderId,
          customer: customerId,
        ),
      ),
    );
  } catch (error) {
    if (!mounted) return;

    // -----------------------------------------------------------
    // CLOSE LOADING IF STILL OPEN
    // -----------------------------------------------------------
    if (Navigator.of(
      context,
      rootNavigator: true,
    ).canPop()) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).pop();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          "Unable to open order details.",
        ),
      ),
    );

    debugPrint(
      "OPEN ORDER REVIEW ERROR: $error",
    );
  }
}

  // -------------------------------------------------------------
  // BUILD
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final String staffName =
        staff["name"]?.toString() ??
            widget.staffName;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "$staffName Sales Report",
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
          // ORDERS
          // -----------------------------------------------------
          Expanded(
            child: isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : errorMessage != null
                    ? buildErrorState()
                    : orders.isEmpty
                        ? buildEmptyState()
                        : RefreshIndicator(
                            onRefresh:
                                fetchStaffOrderSummary,
                            child:
                                SingleChildScrollView(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.all(
                                12,
                              ),
                              child:
                                  buildOrdersTableCard(),
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
  // TOP SUMMARY CARD
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

    final String staffName =
        staff["name"]?.toString() ??
            widget.staffName;

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
            "${staffName.toUpperCase()}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
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
            style: const TextStyle(
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
            style: const TextStyle(
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
            style: const TextStyle(
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
  // SINGLE ORDERS TABLE CARD
  // -------------------------------------------------------------
  Widget buildOrdersTableCard() {
    final double totalAmount = safeDouble(
      summary["total_amount"],
    );

    return Container(
      width: double.infinity,
      decoration:
          _boxDecoration(),
      child: Column(
        children: [
          // -----------------------------------------------------
          // HEADER
          // -----------------------------------------------------
          _ordersHeader(),

          // -----------------------------------------------------
          // TABLE
          // -----------------------------------------------------
          Padding(
            padding:
                const EdgeInsets.all(
              12,
            ),
            child: Table(
              border:
                  TableBorder.all(
                color:
                    Colors.grey.shade400,
              ),
              columnWidths:
                  const {
                0: FlexColumnWidth(
                  0.8,
                ),
                1: FlexColumnWidth(
                  1.8,
                ),
                2: FlexColumnWidth(
                  1.8,
                ),
              },
              children: [
                _orderTableHeader(),

                ...List.generate(
                  orders.length,
                  (index) {
                    final dynamic order =
                        orders[index];

                    return _orderTableRow(
                      order: order,
                      serialNumber:
                          index + 1,
                    );
                  },
                ),
              ],
            ),
          ),

          // -----------------------------------------------------
          // TOTAL FOOTER
          // -----------------------------------------------------
          _ordersFooter(
            totalAmount:
                totalAmount,
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TABLE CARD HEADER
  // -------------------------------------------------------------
  Widget _ordersHeader() {
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
        children: [
          const Expanded(
            child: Text(
              "INVOICE DETAILS",
              style: TextStyle(
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
            style: const TextStyle(
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
  // TABLE HEADER
  // -------------------------------------------------------------
  TableRow _orderTableHeader() {
    return TableRow(
      decoration: BoxDecoration(
        color:
            Colors.grey.shade200,
      ),
      children: const [
        Padding(
          padding:
              EdgeInsets.all(
            10,
          ),
          child: Text(
            "SL NO",
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),

        Padding(
          padding:
              EdgeInsets.all(
            10,
          ),
          child: Text(
            "INV NO",
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),

        Padding(
          padding:
              EdgeInsets.all(
            10,
          ),
          child: Text(
            "Amount",
            textAlign:
                TextAlign.right,
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
  // EACH ROW CLICKABLE
  // -------------------------------------------------------------
  TableRow _orderTableRow({
    required dynamic order,
    required int serialNumber,
  }) {
    final Map<String, dynamic> data =
        order is Map<String, dynamic>
            ? order
            : Map<String, dynamic>.from(
                order as Map,
              );

    final int orderId = safeInt(
      data["order_id"],
    );

    final String invoiceNumber =
        data["invoice_number"]
                ?.toString() ??
            "-";

    final double amount = safeDouble(
      data["amount"],
    );

    return TableRow(
      children: [
        InkWell(
          onTap: () {
            openOrderReview(
              orderId,
            );
          },
          child: Padding(
            padding:
                const EdgeInsets.all(
              10,
            ),
            child: Text(
              "$serialNumber",
              textAlign:
                  TextAlign.center,
            ),
          ),
        ),

        InkWell(
          onTap: () {
            openOrderReview(
              orderId,
            );
          },
          child: Padding(
            padding:
                const EdgeInsets.all(
              10,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    invoiceNumber,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                ),

                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),

        InkWell(
          onTap: () {
            openOrderReview(
              orderId,
            );
          },
          child: Padding(
            padding:
                const EdgeInsets.all(
              10,
            ),
            child: Text(
              "₹${amount.toStringAsFixed(2)}",
              textAlign:
                  TextAlign.right,
              style:
                  const TextStyle(
                color: Colors.green,
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TOTAL FOOTER
  // -------------------------------------------------------------
  Widget _ordersFooter({
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
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),

          Text(
            "₹${totalAmount.toStringAsFixed(2)}",
            style: const TextStyle(
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
  // HEADER GRADIENT
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
          fetchStaffOrderSummary,
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
            Icons.receipt_long_outlined,
            size: 50,
            color: Colors.grey,
          ),

          const SizedBox(
            height: 12,
          ),

          const Center(
            child: Text(
              "No orders found",
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
          fetchStaffOrderSummary,
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
                  fetchStaffOrderSummary,
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