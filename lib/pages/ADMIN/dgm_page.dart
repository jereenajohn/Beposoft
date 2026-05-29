import 'dart:convert';

import 'package:beposoft/pages/ACCOUNTS/daily_goods_movement.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class daily_goods_movementt extends StatefulWidget {
  const daily_goods_movementt({super.key});

  @override
  State<daily_goods_movementt> createState() => _daily_goods_movementtState();
}

class _daily_goods_movementtState extends State<daily_goods_movementt> {
  static const Color primaryBlue = Color(0xFF02347C);
  static const Color accentGreen = Color(0xFF82E49D);
  static const Color pageBg = Color(0xFFF4F7FB);

  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  bool isLoading = false;
  String? errorMessage;

  Map<String, dynamic> todaySummary = {};
  Map<String, dynamic> currentMonthSummary = {};

  List<Map<String, dynamic>> todayRows = [];
  List<Map<String, dynamic>> currentMonthRows = [];

  List<Map<String, dynamic>> overallTopProducts = [];
  bool showAllTopProducts = false;

  @override
  void initState() {
    super.initState();
    fetchDailyGoodsMovement();
    fetchOverallTopProducts();
  }

  Future<String?> getTokenFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? 0.0;
    return 0.0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  String _formatNumber(dynamic value, {int decimals = 2}) {
    return _toDouble(value).toStringAsFixed(decimals);
  }

  String _formatCurrency(dynamic value) {
    return currencyFormat.format(_toDouble(value));
  }

  Future<void> fetchDailyGoodsMovement() async {
    final String? token = await getTokenFromPrefs();

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        errorMessage = "Authentication token not found. Please login again.";
        isLoading = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$api/api/warehouse/get/summary/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final Map<String, dynamic> parsedTodaySummary =
            Map<String, dynamic>.from(decoded['today_summary'] ?? {});

        final Map<String, dynamic> parsedCurrentMonthSummary =
            Map<String, dynamic>.from(decoded['current_month_summary'] ?? {});

        final Map<String, dynamic> parsedData =
            Map<String, dynamic>.from(decoded['data'] ?? {});

        final List<Map<String, dynamic>> todayParsedRows = [];
        final List<Map<String, dynamic>> monthParsedRows = [];

        parsedData.forEach((serviceName, serviceValue) {
          final Map<String, dynamic> serviceMap =
              Map<String, dynamic>.from(serviceValue ?? {});

          final Map<String, dynamic> today =
              Map<String, dynamic>.from(serviceMap['today'] ?? {});

          final Map<String, dynamic> currentMonth = Map<String, dynamic>.from(
            serviceMap['current_month'] ??
                serviceMap['month'] ??
                serviceMap['currentMonth'] ??
                {},
          );

          final int todayBoxes = _toInt(today['total_boxes']);

          if (todayBoxes > 0) {
            todayParsedRows.add({
              'service': serviceName.toString(),
              'boxes': todayBoxes,
              'post_office_weight': _toDouble(
                today['total_weight_field_kg'] ?? today['total_weight_field'],
              ),
              'actual_weight': _toDouble(today['total_actual_weight_kg']),
              'volume': _toDouble(today['total_volume']),
              'tracking_amount': _toDouble(today['total_parcel_amount']),
              'average': _toDouble(today['average']),
            });
          }

          final int monthBoxes = _toInt(currentMonth['total_boxes']);

          if (monthBoxes > 0) {
            monthParsedRows.add({
              'service': serviceName.toString(),
              'boxes': monthBoxes,
              'post_office_weight': _toDouble(
                currentMonth['total_weight_field_kg'] ??
                    currentMonth['total_weight_field'],
              ),
              'actual_weight':
                  _toDouble(currentMonth['total_actual_weight_kg']),
              'volume': _toDouble(currentMonth['total_volume']),
              'tracking_amount': _toDouble(currentMonth['total_parcel_amount']),
              'average': _toDouble(currentMonth['average']),
            });
          }
        });

        todayParsedRows.sort(
          (a, b) => a['service'].toString().compareTo(
                b['service'].toString(),
              ),
        );

        monthParsedRows.sort(
          (a, b) => a['service'].toString().compareTo(
                b['service'].toString(),
              ),
        );

        if (!mounted) return;
        setState(() {
          todaySummary = parsedTodaySummary;
          currentMonthSummary = parsedCurrentMonthSummary;
          todayRows = todayParsedRows;
          currentMonthRows = monthParsedRows;
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          errorMessage =
              "Failed to load daily goods movement. Status: ${response.statusCode}";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = "Something went wrong while loading DGM data.";
      });
    }
  }

  int get todayTotalBoxes => _toInt(todaySummary['total_boxes']);

  double get todayPostOfficeWeight => _toDouble(
        todaySummary['total_weight_field_kg'] ??
            todaySummary['total_weight_field'],
      );

  double get todayActualWeight =>
      _toDouble(todaySummary['total_actual_weight_kg']);

  double get todayVolume => _toDouble(todaySummary['total_volume']);

  double get todayTrackingAmount =>
      _toDouble(todaySummary['total_parcel_amount']);

  double get todayAverage => _toDouble(todaySummary['average']);

  int get monthTotalBoxes => _toInt(currentMonthSummary['total_boxes']);

  double get monthPostOfficeWeight => _toDouble(
        currentMonthSummary['total_weight_field_kg'] ??
            currentMonthSummary['total_weight_field'],
      );

  double get monthActualWeight =>
      _toDouble(currentMonthSummary['total_actual_weight_kg']);

  double get monthVolume => _toDouble(currentMonthSummary['total_volume']);

  double get monthTrackingAmount =>
      _toDouble(currentMonthSummary['total_parcel_amount']);

  double get monthAverage => _toDouble(currentMonthSummary['average']);

  void _goToDailyGoodsMovement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => daily_goods_movement(),
      ),
    );
  }

  Future<void> fetchOverallTopProducts() async {
    final String? token = await getTokenFromPrefs();

    if (token == null || token.isEmpty) {
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$api/api/warehouse/box/detail/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is! List) {
          return;
        }

        final List<Map<String, dynamic>> topProductsList = [];

        for (var item in decoded) {
          if (item is! Map<String, dynamic>) {
            continue;
          }

          if (item['shipped_date'] == null) {
            final topProducts = item['top_5_products'];

            if (topProducts is List) {
              for (var product in topProducts) {
                if (product is Map<String, dynamic>) {
                  topProductsList.add({
                    'product_id': product['product_id'],
                    'product_name': product['product_name'] ?? '',
                    'display_name': product['display_name'] ??
                        product['product_name'] ??
                        '',
                    'total_quantity': product['total_quantity'] ?? 0,
                    'total_amount': product['total_amount'] ?? 0,
                  });
                }
              }
            }

            break;
          }
        }

        if (!mounted) return;
        setState(() {
          overallTopProducts = topProductsList;
          showAllTopProducts = false;
        });
      }
    } catch (e) {
      // Keep silent because summary page should still work even if top products fail.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: primaryBlue,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Daily Goods Movement",
          style: TextStyle(
            color: primaryBlue,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: () async {
              await fetchDailyGoodsMovement();
              await fetchOverallTopProducts();
            },
            icon: const Icon(
              Icons.refresh_rounded,
              color: primaryBlue,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: primaryBlue,
        onRefresh: () async {
          await fetchDailyGoodsMovement();
          await fetchOverallTopProducts();
        },
        child: isLoading
            ? _buildLoadingView()
            : errorMessage != null
                ? _buildErrorView()
                : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // _buildOverallTopProducts(),
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: _goToDailyGoodsMovement,
            child: _buildTodaySummaryTableSection(),
          ),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: _goToDailyGoodsMovement,
            child: _buildCurrentMonthTableSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallTopProducts() {
    if (overallTopProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<Map<String, dynamic>> visibleProducts = showAllTopProducts
        ? overallTopProducts
        : overallTopProducts.take(2).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Top 5 Products",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Colors.grey.shade400,
                width: 0.8,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 36,
                    dataRowHeight: 34,
                    headingRowColor: MaterialStateColor.resolveWith(
                      (states) => primaryBlue,
                    ),
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        width: 0.5,
                        color: Colors.grey.shade400,
                      ),
                      verticalInside: BorderSide(
                        width: 0.5,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    columnSpacing: 10,
                    columns: const [
                      DataColumn(
                        label: SizedBox(
                          width: 55,
                          child: Text(
                            "Sl No",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 230,
                          child: Text(
                            "Product",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 70,
                          child: Text(
                            "Qty",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 100,
                          child: Text(
                            "Amount",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                    rows: List<DataRow>.generate(
                      visibleProducts.length,
                      (index) {
                        final product = visibleProducts[index];

                        final String productName =
                            product['display_name']?.toString().isNotEmpty ==
                                    true
                                ? product['display_name'].toString()
                                : product['product_name']?.toString() ?? '-';

                        final String quantity =
                            product['total_quantity']?.toString() ?? '0';

                        final double amount = double.tryParse(
                              product['total_amount']?.toString() ?? '0',
                            ) ??
                            0.0;

                        return DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 55,
                                child: Text(
                                  "${index + 1}",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 230,
                                child: Text(
                                  productName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 70,
                                child: Text(
                                  quantity,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 100,
                                child: Text(
                                  amount.toStringAsFixed(2),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                if (overallTopProducts.length > 2)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey.shade400,
                          width: 0.5,
                        ),
                      ),
                    ),
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          showAllTopProducts = !showAllTopProducts;
                        });
                      },
                      icon: Icon(
                        showAllTopProducts
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                        color: primaryBlue,
                      ),
                      label: Text(
                        showAllTopProducts ? "See Less" : "See More",
                        style: const TextStyle(
                          color: primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.78),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySummaryTableSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7EDF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            title: "Today Goods Movement Summary",
            subtitle:
                "Service-wise DGM details for ${DateFormat('dd MMMM yyyy').format(DateTime.now())}",
            icon: Icons.inventory_2_rounded,
            compact: true,
          ),
          const SizedBox(height: 12),
          if (todayRows.isEmpty)
            _buildEmptyState(
              title: "No goods movement today",
              message:
                  "Today’s courier service movement will appear here once boxes are dispatched.",
              dark: false,
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                border: TableBorder.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
                columnWidths: const {
                  0: FixedColumnWidth(170),
                  1: FixedColumnWidth(90),
                  2: FixedColumnWidth(160),
                  3: FixedColumnWidth(155),
                  4: FixedColumnWidth(120),
                  5: FixedColumnWidth(155),
                  6: FixedColumnWidth(125),
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: primaryBlue),
                    children: [
                      _tableHeader("Service"),
                      _tableHeader("Boxes"),
                      _tableHeader("Post Office Wt.\n(kg)"),
                      _tableHeader("Actual Wt.\n(kg)"),
                      _tableHeader("Volume\n(kg)"),
                      _tableHeader("Tracking Amount"),
                      _tableHeader("Avg\n(₹/kg)"),
                    ],
                  ),
                  ...todayRows.map((row) {
                    return TableRow(
                      decoration: const BoxDecoration(color: Colors.white),
                      children: [
                        _tableCell(row['service'].toString(), alignLeft: true),
                        _tableCell(row['boxes'].toString()),
                        _tableCell(row['post_office_weight'].toString()),
                        _tableCell(_formatNumber(row['actual_weight'])),
                        _tableCell(_formatNumber(row['volume'])),
                        _tableCell(_formatCurrency(row['tracking_amount'])),
                        _tableCell(_formatNumber(row['average'])),
                      ],
                    );
                  }),
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFFEFF6FF)),
                    children: [
                      _tableCell(
                        "TODAY TOTAL",
                        isBold: true,
                        alignLeft: true,
                        textColor: primaryBlue,
                      ),
                      _tableCell(
                        todayTotalBoxes.toString(),
                        isBold: true,
                        textColor: primaryBlue,
                      ),
                      _tableCell(
                        todayPostOfficeWeight.toString(),
                        isBold: true,
                        textColor: primaryBlue,
                      ),
                      _tableCell(
                        _formatNumber(todayActualWeight),
                        isBold: true,
                        textColor: primaryBlue,
                      ),
                      _tableCell(
                        _formatNumber(todayVolume),
                        isBold: true,
                        textColor: primaryBlue,
                      ),
                      _tableCell(
                        _formatCurrency(todayTrackingAmount),
                        isBold: true,
                        textColor: primaryBlue,
                      ),
                      _tableCell(
                        _formatNumber(todayAverage),
                        isBold: true,
                        textColor: primaryBlue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentMonthTableSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.16),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.date_range_rounded,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Current Month Goods Movement",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Service-wise MGM details for ${DateFormat('MMMM yyyy').format(DateTime.now())}",
            style: TextStyle(
              color: Colors.white.withOpacity(0.76),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          if (currentMonthRows.isEmpty)
            _buildEmptyState(
              title: "No current month data",
              message:
                  "Current month goods movement will appear here once service-wise data is available.",
              dark: true,
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                border: TableBorder.all(
                  color: Colors.white.withOpacity(0.45),
                  width: 1,
                ),
                columnWidths: const {
                  0: FixedColumnWidth(170),
                  1: FixedColumnWidth(90),
                  2: FixedColumnWidth(160),
                  3: FixedColumnWidth(155),
                  4: FixedColumnWidth(120),
                  5: FixedColumnWidth(155),
                  6: FixedColumnWidth(125),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                    ),
                    children: [
                      _monthTableHeader("Service"),
                      _monthTableHeader("Boxes"),
                      _monthTableHeader("Post Office Wt.\n(kg)"),
                      _monthTableHeader("Actual Wt.\n(kg)"),
                      _monthTableHeader("Volume\n(kg)"),
                      _monthTableHeader("Tracking Amount"),
                      _monthTableHeader("Avg\n(₹/kg)"),
                    ],
                  ),
                  ...currentMonthRows.map((row) {
                    return TableRow(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                      ),
                      children: [
                        _monthTableCell(
                          row['service'].toString(),
                          alignLeft: true,
                        ),
                        _monthTableCell(row['boxes'].toString()),
                        _monthTableCell(
                          row['post_office_weight'].toString(),
                        ),
                        _monthTableCell(_formatNumber(row['actual_weight'])),
                        _monthTableCell(_formatNumber(row['volume'])),
                        _monthTableCell(
                          _formatCurrency(row['tracking_amount']),
                        ),
                        _monthTableCell(_formatNumber(row['average'])),
                      ],
                    );
                  }),
                  TableRow(
                    decoration: const BoxDecoration(color: accentGreen),
                    children: [
                      _tableCell(
                        "MONTH TOTAL",
                        isBold: true,
                        alignLeft: true,
                        textColor: primaryBlue,
                      ),
                      _tableCell(
                        monthTotalBoxes.toString(),
                        isBold: true,
                        textColor: primaryBlue,
                      ),
                      _tableCell(
                        monthPostOfficeWeight.toString(),
                        isBold: true,
                        textColor: primaryBlue,
                      ),
                      _tableCell(
                        _formatNumber(monthActualWeight),
                        isBold: true,
                        textColor: primaryBlue,
                      ),
                      _tableCell(
                        _formatNumber(monthVolume),
                        isBold: true,
                        textColor: primaryBlue,
                      ),
                      _tableCell(
                        _formatCurrency(monthTrackingAmount),
                        isBold: true,
                        textColor: primaryBlue,
                      ),
                      _tableCell(
                        _formatNumber(monthAverage),
                        isBold: true,
                        textColor: primaryBlue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
    required IconData icon,
    bool compact = false,
  }) {
    return Row(
      children: [
        Container(
          height: compact ? 34 : 40,
          width: compact ? 34 : 40,
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: primaryBlue,
            size: compact ? 18 : 21,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: const Color(0xFF111827),
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: compact ? 10.5 : 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          height: 1.25,
        ),
      ),
    );
  }

  Widget _tableCell(
    String text, {
    bool isBold = false,
    bool alignLeft = false,
    Color textColor = const Color(0xFF111827),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
      child: Text(
        text,
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontSize: 11.5,
          fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
          height: 1.25,
        ),
      ),
    );
  }

  Widget _monthTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          height: 1.25,
        ),
      ),
    );
  }

  Widget _monthTableCell(
    String text, {
    bool isBold = false,
    bool alignLeft = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
      child: Text(
        text,
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
          height: 1.25,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String message,
    required bool dark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withOpacity(0.10) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: dark ? Colors.white24 : const Color(0xFFE7EDF5),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: dark
                  ? Colors.white.withOpacity(0.12)
                  : primaryBlue.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: dark ? Colors.white : primaryBlue,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: dark ? Colors.white : const Color(0xFF111827),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: dark ? Colors.white70 : Colors.grey.shade600,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _skeleton(height: 190, radius: 24),
        const SizedBox(height: 16),
        _skeleton(height: 260, radius: 22),
        const SizedBox(height: 16),
        _skeleton(height: 260, radius: 22),
      ],
    );
  }

  Widget _skeleton({
    required double height,
    required double radius,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFE7EDF5)),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: primaryBlue.withOpacity(0.75),
          strokeWidth: 2.5,
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(18),
      children: [
        const SizedBox(height: 80),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE7EDF5)),
          ),
          child: Column(
            children: [
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                "Unable to load DGM",
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                errorMessage ?? "Please try again.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: fetchDailyGoodsMovement,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text("Retry"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
