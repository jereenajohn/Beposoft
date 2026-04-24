import 'dart:async';
import 'dart:convert';

import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/BDO/update_dsr_call_status.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BdoDsrList extends StatefulWidget {
  const BdoDsrList({super.key});

  @override
  State<BdoDsrList> createState() => _BdoDsrListState();
}

class _BdoDsrListState extends State<BdoDsrList>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;
  bool isFetchingMore = false;

  List<Map<String, dynamic>> dsrList = [];
  List<Map<String, dynamic>> allDsrList = [];
  Map<int, bool> expandedProducts = {};

  late AnimationController _shimmerController;
  late ScrollController _scrollController;

  final TextEditingController searchController = TextEditingController();
  Timer? _searchDebounce;

  String? nextPageUrl;
  bool hasMore = true;

  DateTimeRange? selectedDateRange;

  int totalCount = 0;
  int activeCount = 0;
  int productiveCount = 0;
  int dsrCreatedCount = 0;
  int dsrApprovedCount = 0;
  int dsrConfirmedCount = 0;
  int dsrRejectedCount = 0;
  String totalCallDuration = "00:00:00";
  double totalInvoiceAmount = 0.0;
  double callDurationAvg8hrs = 0.0;
  double callDurationPercentage8hrs = 0.0;

  int filteredTotalCount = 0;
  int filteredActiveCount = 0;
  int filteredProductiveCount = 0;
  int filteredDsrCreatedCount = 0;
  int filteredDsrApprovedCount = 0;
  int filteredDsrConfirmedCount = 0;
  int filteredDsrRejectedCount = 0;
  String filteredTotalCallDuration = "00:00:00";
  double filteredTotalInvoiceAmount = 0.0;
  double filteredCallDurationAvg8hrs = 0.0;
  double filteredCallDurationPercentage8hrs = 0.0;

  String selectedSummaryFilter = "";

  drower d = drower();

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    getDsrList(isRefresh: true);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _scrollController.dispose();
    searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 250) {
      if (!isLoading && !isFetchingMore && hasMore) {
        getDsrList(loadMore: true);
      }
    }
  }

  String formatDateParam(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  String formatDateDisplay(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}";
  }

  int _durationToSeconds(String value) {
    try {
      final parts = value.split(":");
      if (parts.length != 3) return 0;

      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      final seconds = int.tryParse(parts[2]) ?? 0;

      return (hours * 3600) + (minutes * 60) + seconds;
    } catch (e) {
      return 0;
    }
  }

  String _secondsToDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    return "${hours.toString().padLeft(2, '0')}:"
        "${minutes.toString().padLeft(2, '0')}:"
        "${seconds.toString().padLeft(2, '0')}";
  }

  double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    return double.tryParse(value.toString().replaceAll(",", "").trim()) ?? 0.0;
  }

  Future<void> openDateRangePicker() async {
    final DateTime now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: selectedDateRange,
      helpText: "Select Date Range",
      saveText: "Apply",
      cancelText: "Cancel",
      confirmText: "Apply",
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xff2196F3),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
      });
      await getDsrList(isRefresh: true);
    }
  }

  Uri _buildDsrUri({
    String? nextUrl,
    String search = "",
  }) {
    if (nextUrl != null && nextUrl.isNotEmpty) {
      return Uri.parse(nextUrl);
    }

    final queryParams = <String, String>{};

    if (search.trim().isNotEmpty) {
      queryParams["search"] = search.trim();
    }

    if (selectedDateRange != null) {
      queryParams["start_date"] = formatDateParam(selectedDateRange!.start);
      queryParams["end_date"] = formatDateParam(selectedDateRange!.end);
    }

    return Uri.parse('$api/api/sales/analysis/add/').replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
  }

  List<Map<String, dynamic>> _parseResults(String responseBody) {
    final parsed = jsonDecode(responseBody);

    dynamic resultContainer;
    List data = [];

    if (parsed is Map && parsed["results"] is Map) {
      resultContainer = parsed["results"];
      data = resultContainer["results"] ?? [];
      totalCount = parsed["count"] ?? resultContainer["count"] ?? 0;
      activeCount = resultContainer["active_count"] ?? 0;
      productiveCount = resultContainer["productive_count"] ?? 0;
      dsrCreatedCount = resultContainer["dsr_created_count"] ?? 0;
      dsrApprovedCount = resultContainer["dsr_approved_count"] ?? 0;
      dsrConfirmedCount = resultContainer["dsr_confirmed_count"] ?? 0;
      dsrRejectedCount = resultContainer["dsr_rejected_count"] ?? 0;
      totalCallDuration =
          resultContainer["total_call_duration"]?.toString() ?? "00:00:00";
      totalInvoiceAmount =
          _parseAmount(resultContainer["total_invoice_amount"] ?? 0);
      callDurationAvg8hrs = _parseAmount(
        resultContainer["average_call_duration"] ??
            resultContainer["call_duration_average_8hrs"] ??
            0,
      );
      callDurationPercentage8hrs =
          _parseAmount(resultContainer["call_duration_percentage_8hrs"] ?? 0);
    } else if (parsed is Map && parsed["results"] is List) {
      data = parsed["results"] ?? [];
      totalCount = parsed["count"] ?? 0;
      activeCount = 0;
      productiveCount = 0;
      dsrCreatedCount = 0;
      dsrApprovedCount = 0;
      dsrConfirmedCount = 0;
      dsrRejectedCount = 0;
      totalCallDuration = "00:00:00";
      totalInvoiceAmount = 0.0;
      callDurationAvg8hrs = 0.0;
      callDurationPercentage8hrs = 0.0;
    } else if (parsed is Map && parsed["data"] is List) {
      data = parsed["data"] ?? [];
      totalCount = parsed["count"] ?? data.length;
      activeCount = 0;
      productiveCount = 0;
      dsrCreatedCount = 0;
      dsrApprovedCount = 0;
      dsrConfirmedCount = 0;
      dsrRejectedCount = 0;
      totalCallDuration = "00:00:00";
      totalInvoiceAmount = 0.0;
      callDurationAvg8hrs = 0.0;
      callDurationPercentage8hrs = 0.0;
    } else if (parsed is List) {
      data = parsed;
      totalCount = data.length;
      activeCount = 0;
      productiveCount = 0;
      dsrCreatedCount = 0;
      dsrApprovedCount = 0;
      dsrConfirmedCount = 0;
      dsrRejectedCount = 0;
      totalCallDuration = "00:00:00";
      totalInvoiceAmount = 0.0;
      callDurationAvg8hrs = 0.0;
      callDurationPercentage8hrs = 0.0;
    }

    final List<Map<String, dynamic>> tempList = [];

    for (var item in data) {
      final List<dynamic> rawProducts = item["product_details"] ?? [];
      final List<Map<String, dynamic>> products = rawProducts.map((product) {
        return {
          "product_id": product["product_id"],
          "name": product["name"]?.toString() ?? "",
          "image": product["image"]?.toString() ?? "",
          "quantity": product["quantity"]?.toString() ?? "",
          "rate": product["rate"]?.toString() ?? "",
          "discount": product["discount"]?.toString() ?? "",
          "tax": product["tax"]?.toString() ?? "",
          "description": product["description"]?.toString() ?? "",
        };
      }).toList();

      tempList.add({
        "id": item["id"],
        "invoice_no": item["invoice_number"]?.toString() ??
            item["invoice_no"]?.toString() ??
            "",
        "invoice": item["invoice"],
        "customer": item["customer"],
        "phone": item["phone"]?.toString() ?? "",
        "customer_name": item["customer_name"]?.toString() ?? "",
        "state_name": item["state_name"]?.toString() ?? "",
        "district_name": item["district_name"]?.toString() ?? "",
        "user_name": item["created_by_name"]?.toString() ??
            item["user_name"]?.toString() ??
            "",
        "call_status": item["call_status"]?.toString() ?? "",
        "call_duration": item["call_duration"]?.toString() ?? "",
        "note": item["note"]?.toString() ?? "",
        "created_at": item["created_at"]?.toString() ?? "",
        "status": item["status"]?.toString() ?? "",
        "invoice_amount": item["invoice_amount"]?.toString() ?? "",
        "product_details": products,
      });
    }

    return tempList;
  }

  void _applySummaryFilter() {
    List<Map<String, dynamic>> tempList =
        List<Map<String, dynamic>>.from(allDsrList);

    if (selectedSummaryFilter.isNotEmpty) {
      tempList = tempList.where((item) {
        final callStatus =
            item["call_status"]?.toString().toLowerCase().trim() ?? "";
        final dsrStatus = item["status"]?.toString().toLowerCase().trim() ?? "";

        if (selectedSummaryFilter == "active") {
          return callStatus == "active";
        } else if (selectedSummaryFilter == "productive") {
          return callStatus == "productive";
        } else if (selectedSummaryFilter == "created") {
          return dsrStatus == "dsr created";
        } else if (selectedSummaryFilter == "approved") {
          return dsrStatus == "dsr approved";
        } else if (selectedSummaryFilter == "confirmed") {
          return dsrStatus == "dsr confirmed";
        } else if (selectedSummaryFilter == "rejected") {
          return dsrStatus == "dsr rejected";
        }
        return true;
      }).toList();
    }

    int tempFilteredActiveCount = 0;
    int tempFilteredProductiveCount = 0;
    int tempFilteredDsrCreatedCount = 0;
    int tempFilteredDsrApprovedCount = 0;
    int tempFilteredDsrConfirmedCount = 0;
    int tempFilteredDsrRejectedCount = 0;
    int totalDurationSeconds = 0;
    double totalAmount = 0.0;

    for (final item in tempList) {
      final callStatus =
          item["call_status"]?.toString().toLowerCase().trim() ?? "";
      final dsrStatus = item["status"]?.toString().toLowerCase().trim() ?? "";
      final duration = item["call_duration"]?.toString() ?? "";

      totalDurationSeconds += _durationToSeconds(duration);
      totalAmount += _parseAmount(item["invoice_amount"]);

      if (callStatus == "active") {
        tempFilteredActiveCount++;
      } else if (callStatus == "productive") {
        tempFilteredProductiveCount++;
      }

      if (dsrStatus == "dsr created") {
        tempFilteredDsrCreatedCount++;
      } else if (dsrStatus == "dsr approved") {
        tempFilteredDsrApprovedCount++;
      } else if (dsrStatus == "dsr confirmed") {
        tempFilteredDsrConfirmedCount++;
      } else if (dsrStatus == "dsr rejected") {
        tempFilteredDsrRejectedCount++;
      }
    }

    final double avgMinutes =
        tempList.isEmpty ? 0.0 : (totalDurationSeconds / 60) / tempList.length;
    final double avgPercent8hrs = (avgMinutes / 480) * 100;

    setState(() {
      dsrList = tempList;
      filteredTotalCount = tempList.length;
      filteredActiveCount = tempFilteredActiveCount;
      filteredProductiveCount = tempFilteredProductiveCount;
      filteredDsrCreatedCount = tempFilteredDsrCreatedCount;
      filteredDsrApprovedCount = tempFilteredDsrApprovedCount;
      filteredDsrConfirmedCount = tempFilteredDsrConfirmedCount;
      filteredDsrRejectedCount = tempFilteredDsrRejectedCount;
      filteredTotalCallDuration = _secondsToDuration(totalDurationSeconds);
      filteredTotalInvoiceAmount = totalAmount;
      filteredCallDurationAvg8hrs = avgMinutes;
      filteredCallDurationPercentage8hrs = avgPercent8hrs;
    });
  }

  Future<void> getDsrList({
    bool isRefresh = false,
    bool loadMore = false,
  }) async {
    try {
      if (isRefresh) {
        if (mounted) {
          setState(() {
            isLoading = true;
            isFetchingMore = false;
            hasMore = true;
            nextPageUrl = null;
            dsrList = [];
            allDsrList = [];
            selectedSummaryFilter = "";
            totalCount = 0;
            activeCount = 0;
            productiveCount = 0;
            dsrCreatedCount = 0;
            dsrApprovedCount = 0;
            dsrConfirmedCount = 0;
            dsrRejectedCount = 0;
            totalCallDuration = "00:00:00";
            totalInvoiceAmount = 0.0;
            callDurationAvg8hrs = 0.0;
            callDurationPercentage8hrs = 0.0;
            filteredTotalCount = 0;
            filteredActiveCount = 0;
            filteredProductiveCount = 0;
            filteredDsrCreatedCount = 0;
            filteredDsrApprovedCount = 0;
            filteredDsrConfirmedCount = 0;
            filteredDsrRejectedCount = 0;
            filteredTotalCallDuration = "00:00:00";
            filteredTotalInvoiceAmount = 0.0;
            filteredCallDurationAvg8hrs = 0.0;
            filteredCallDurationPercentage8hrs = 0.0;
          });
        }
      } else if (loadMore) {
        if (!hasMore || isFetchingMore) return;
        if (mounted) {
          setState(() {
            isFetchingMore = true;
          });
        }
      }

      final token = await gettokenFromPrefs();

      final uri = _buildDsrUri(
        nextUrl: loadMore ? nextPageUrl : null,
        search: searchController.text,
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("DSR LIST STATUS: ${response.statusCode}");
      print("DSR LIST BODY: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final List<Map<String, dynamic>> tempList =
            _parseResults(response.body);

        String? newNext;
        if (parsed is Map) {
          newNext = parsed["next"]?.toString();
        }

        if (!mounted) return;
        setState(() {
          if (loadMore) {
            allDsrList.addAll(tempList);
          } else {
            allDsrList = tempList;
          }

          nextPageUrl = newNext;
          hasMore = newNext != null && newNext.isNotEmpty;
          isLoading = false;
          isFetchingMore = false;
        });

        _applySummaryFilter();
      } else {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          isFetchingMore = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Failed to load data: ${response.body}"),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        isFetchingMore = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error: $e"),
        ),
      );
    }
  }

  Future<void> deleteDsr(int id) async {
    try {
      final token = await gettokenFromPrefs();

      final response = await http.delete(
        Uri.parse('$api/api/sales/analysis/edit/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("DELETE STATUS: ${response.statusCode}");
      print("DELETE RESPONSE: ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200 ||
          response.statusCode == 202 ||
          response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("DSR deleted successfully"),
          ),
        );
        await getDsrList(isRefresh: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Delete failed: ${response.body}"),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error: $e"),
        ),
      );
    }
  }

  Future<void> confirmDelete(int id) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Delete DSR",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          content: const Text(
            "Are you sure you want to delete this DSR record?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Delete",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await deleteDsr(id);
    }
  }

  Widget _buildDropdownTile(
    BuildContext context,
    String title,
    List<String> options,
  ) {
    return ExpansionTile(
      title: Text(title),
      children: options.map((option) {
        return ListTile(
          title: Text(option),
          onTap: () {
            Navigator.pop(context);
            d.navigateToSelectedPage(context, option);
          },
        );
      }).toList(),
    );
  }

  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();
    if (!mounted) return;

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

  Widget buildInfoRow(
    String title,
    String value, {
    IconData? icon,
    Color? valueColor,
    FontWeight? valueWeight,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 95,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const Text(
            ":  ",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "-" : value,
              style: TextStyle(
                fontSize: 12.5,
                color: valueColor ?? Colors.black87,
                fontWeight: valueWeight ?? FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color getCallStatusColor(String status) {
    final s = status.toLowerCase().trim();
    if (s == "productive") {
      return Colors.green;
    } else if (s == "active") {
      return Colors.orange;
    }
    return Colors.grey;
  }

  Color getDsrStatusColor(String status) {
    final s = status.toLowerCase().trim();

    if (s == "dsr rejected") {
      return Colors.red;
    } else if (s == "dsr approved") {
      return Colors.green;
    } else if (s == "dsr created") {
      return Colors.blue;
    } else if (s == "dsr confirmed") {
      return Colors.orange;
    }

    return Colors.grey;
  }

  String formatDateTime(String value) {
    if (value.isEmpty) return "-";
    try {
      final dt = DateTime.parse(value).toLocal();
      return "${dt.day.toString().padLeft(2, '0')}-"
          "${dt.month.toString().padLeft(2, '0')}-"
          "${dt.year}  "
          "${dt.hour.toString().padLeft(2, '0')}:"
          "${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return value;
    }
  }

  Widget buildChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label.isEmpty ? "-" : label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProductCard(Map<String, dynamic> product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: (product["image"] ?? "").toString().trim().isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      "${api}${product["image"]}",
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.grey,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.grey,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (product["name"] ?? "").toString().isEmpty
                      ? "-"
                      : product["name"].toString(),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                buildInfoRow(
                  "Qty",
                  product["quantity"]?.toString() ?? "",
                  icon: Icons.confirmation_number_outlined,
                ),
                buildInfoRow(
                  "Rate",
                  product["rate"]?.toString() ?? "",
                  icon: Icons.currency_rupee_outlined,
                ),
                // buildInfoRow(
                //   "Discount",
                //   product["discount"]?.toString() ?? "",
                //   icon: Icons.local_offer_outlined,
                // ),
                // buildInfoRow(
                //   "Tax",
                //   product["tax"]?.toString() ?? "",
                //   icon: Icons.percent_outlined,
                // ),
                // if ((product["description"] ?? "").toString().trim().isNotEmpty)
                //   buildInfoRow(
                //     "Description",
                //     product["description"].toString(),
                //     icon: Icons.description_outlined,
                //   ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProductDetailsSection(Map<String, dynamic> item) {
    final List<Map<String, dynamic>> products =
        List<Map<String, dynamic>>.from(item["product_details"] ?? []);

    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    final int dsrId = item["id"];
    final bool isExpanded = expandedProducts[dsrId] ?? false;

    final List<Map<String, dynamic>> visibleProducts =
        isExpanded ? products : products.take(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        buildSectionTitle("Product Details", Icons.inventory_2_outlined),
        const SizedBox(height: 12),
        ...visibleProducts.map((product) => buildProductCard(product)).toList(),
        if (products.length > 1)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  expandedProducts[dsrId] = !isExpanded;
                });
              },
              icon: Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: const Color(0xff2196F3),
              ),
              label: Text(
                isExpanded ? "See less" : "See more",
                style: const TextStyle(
                  color: Color(0xff2196F3),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xff40B0FB)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xff1E293B),
          ),
        ),
      ],
    );
  }

  Widget buildSearchBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: "Search invoice, customer, note...",
          hintStyle: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade500,
          ),
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search, color: Color(0xff2196F3)),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    searchController.clear();
                    setState(() {});
                    getDsrList(isRefresh: true);
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 18,
          ),
        ),
        onChanged: (value) {
          setState(() {});
          _searchDebounce?.cancel();
          _searchDebounce = Timer(const Duration(milliseconds: 500), () {
            getDsrList(isRefresh: true);
          });
        },
      ),
    );
  }

  Widget buildSummaryMiniCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    required String filterKey,
  }) {
    final bool isClickable = filterKey.isNotEmpty;
    final bool isSelected = selectedSummaryFilter == filterKey;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: !isClickable
          ? null
          : () {
              setState(() {
                if (selectedSummaryFilter == filterKey) {
                  selectedSummaryFilter = "";
                } else {
                  selectedSummaryFilter = filterKey;
                }
              });
              _applySummaryFilter();
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isClickable
              ? (isSelected ? color.withOpacity(0.16) : color.withOpacity(0.08))
              : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isClickable
                ? (isSelected ? color : color.withOpacity(0.18))
                : color.withOpacity(0.18),
            width: isClickable && isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTopSummary() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 9, 137, 202),
                    Color.fromARGB(255, 46, 120, 239),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.analytics_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "DSR Summary",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          selectedSummaryFilter.isEmpty
                              ? "Overview of sales analysis records"
                              : "Filtered by ${selectedSummaryFilter[0].toUpperCase()}${selectedSummaryFilter.substring(1)}",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Total $filteredTotalCount",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: buildSummaryMiniCard(
                          title: "Active",
                          value: "$filteredActiveCount",
                          color: Colors.orange,
                          icon: Icons.phone_in_talk_outlined,
                          filterKey: "active",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: buildSummaryMiniCard(
                          title: "Productive",
                          value: "$filteredProductiveCount",
                          color: Colors.green,
                          icon: Icons.trending_up,
                          filterKey: "productive",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: buildSummaryMiniCard(
                          title: "Created",
                          value: "$filteredDsrCreatedCount",
                          color: Colors.blue,
                          icon: Icons.edit_note,
                          filterKey: "created",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: buildSummaryMiniCard(
                          title: "Approved",
                          value: "$filteredDsrApprovedCount",
                          color: Colors.green,
                          icon: Icons.verified_outlined,
                          filterKey: "approved",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: buildSummaryMiniCard(
                          title: "Confirmed",
                          value: "$filteredDsrConfirmedCount",
                          color: Colors.orange,
                          icon: Icons.task_alt,
                          filterKey: "confirmed",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: buildSummaryMiniCard(
                          title: "Rejected",
                          value: "$filteredDsrRejectedCount",
                          color: Colors.red,
                          icon: Icons.cancel_outlined,
                          filterKey: "rejected",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: buildSummaryMiniCard(
                          title: "Total Duration",
                          value: filteredTotalCallDuration,
                          color: Colors.purple,
                          icon: Icons.access_time,
                          filterKey: "",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: buildSummaryMiniCard(
                          title: "Total Amount",
                          value:
                              "₹${filteredTotalInvoiceAmount.toStringAsFixed(0)}",
                          color: const Color(0xff0F9D58),
                          icon: Icons.currency_rupee_outlined,
                          filterKey: "",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: buildSummaryMiniCard(
                          title: "Avg Duration (8h)",
                          value:
                              "${filteredCallDurationAvg8hrs.toStringAsFixed(1)} mins",
                          color: Colors.indigo,
                          icon: Icons.av_timer_outlined,
                          filterKey: "",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: buildSummaryMiniCard(
                          title: "Duration % (8h)",
                          value:
                              "${filteredCallDurationPercentage8hrs.toStringAsFixed(2)}%",
                          color: Colors.teal,
                          icon: Icons.pie_chart_outline,
                          filterKey: "",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDateRangeBar() {
    if (selectedDateRange == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range, color: Color(0xff2196F3), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "${formatDateDisplay(selectedDateRange!.start)}  to  ${formatDateDisplay(selectedDateRange!.end)}",
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          InkWell(
            onTap: () async {
              setState(() {
                selectedDateRange = null;
                selectedSummaryFilter = "";
              });
              await getDsrList(isRefresh: true);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                "Clear",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmptyState() {
    return ListView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        buildSearchBar(),
        buildDateRangeBar(),
        buildTopSummary(),
        const SizedBox(height: 70),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.description_outlined,
                size: 52,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 14),
              Text(
                selectedSummaryFilter.isEmpty
                    ? "No DSR records found"
                    : "No ${selectedSummaryFilter.toUpperCase()} DSR records found",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildSkeletonLine({
    double width = double.infinity,
    double height = 12,
    double radius = 8,
  }) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + (_shimmerController.value * 2), 0),
              end: Alignment(1.0 + (_shimmerController.value * 2), 0),
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildSkeletonCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildSkeletonLine(width: 120, height: 14),
                        const SizedBox(height: 8),
                        buildSkeletonLine(width: 170, height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      buildSkeletonLine(width: 90, height: 28, radius: 20),
                      const SizedBox(width: 8),
                      buildSkeletonLine(width: 100, height: 28, radius: 20),
                    ],
                  ),
                  const SizedBox(height: 18),
                  buildSkeletonLine(width: 130, height: 14),
                  const SizedBox(height: 14),
                  buildSkeletonLine(height: 12),
                  const SizedBox(height: 12),
                  buildSkeletonLine(height: 12),
                  const SizedBox(height: 12),
                  buildSkeletonLine(height: 12),
                  const SizedBox(height: 12),
                  buildSkeletonLine(height: 12),
                  const SizedBox(height: 12),
                  buildSkeletonLine(width: 140, height: 12),
                  const SizedBox(height: 16),
                  buildSkeletonLine(
                    width: double.infinity,
                    height: 60,
                    radius: 14,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSkeletonList() {
    return ListView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        buildSearchBar(),
        buildDateRangeBar(),
        buildTopSummary(),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          itemBuilder: (context, index) => buildSkeletonCard(index),
        ),
      ],
    );
  }

  Widget buildBottomLoader() {
    if (!isFetchingMore) return const SizedBox.shrink();

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _navigateBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xffF4F7FB),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () async {
              await _navigateBack();
            },
          ),
          titleSpacing: 0,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "DSR List",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 2),
              Text(
                "Sales analysis records",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: openDateRangePicker,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.date_range, color: Colors.black87),
                  if (selectedDateRange != null)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        height: 8,
                        width: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => getDsrList(isRefresh: true),
          child: isLoading
              ? buildSkeletonList()
              : dsrList.isEmpty
                  ? buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                      itemCount: dsrList.length + 4,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return buildSearchBar();
                        }

                        if (index == 1) {
                          return buildDateRangeBar();
                        }

                        if (index == 2) {
                          return buildTopSummary();
                        }

                        if (index == dsrList.length + 3) {
                          return buildBottomLoader();
                        }

                        final item = dsrList[index - 3];
                        final callColor =
                            getCallStatusColor(item["call_status"]);
                        final dsrColor = getDsrStatusColor(item["status"]);

                        final bool isActiveCard = item["call_status"]
                                .toString()
                                .toLowerCase()
                                .trim() ==
                            "active";

                        final bool canDelete =
                            item["status"].toString().toLowerCase().trim() ==
                                "dsr created";

                        return GestureDetector(
                          onTap: isActiveCard
                              ? () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UpdateDsrPage(
                                        dsrId: item["id"],
                                        selectedCustomerId:
                                            item["customer"] is int
                                                ? item["customer"]
                                                : int.tryParse(
                                                    "${item["customer"]}"),
                                        selectedInvoiceId:
                                            item["invoice"] is int
                                                ? item["invoice"]
                                                : int.tryParse(
                                                    "${item["invoice"]}"),
                                        selectedCallStatus:
                                            item["call_status"] ?? "active",
                                      ),
                                    ),
                                  );

                                  if (result == true) {
                                    getDsrList(isRefresh: true);
                                  }
                                }
                              : null,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Card(
                              margin: EdgeInsets.zero,
                              elevation: 0,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: isActiveCard
                                    ? const BorderSide(
                                        color: Color(0xff2196F3), width: 1)
                                    : BorderSide.none,
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xff40B0FB),
                                          Color(0xff2196F3),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        topRight: Radius.circular(20),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          height: 40,
                                          width: 40,
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.18),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: Text(
                                              "${index - 2}",
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item["invoice_no"].isEmpty
                                                    ? "No Invoice"
                                                    : item["invoice_no"],
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                item["customer_name"].isEmpty
                                                    ? "-"
                                                    : item["customer_name"],
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white
                                                      .withOpacity(0.9),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isActiveCard)
                                          Container(
                                            margin:
                                                const EdgeInsets.only(right: 6),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withOpacity(0.18),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.edit,
                                                  size: 13,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  "Edit",
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (canDelete)
                                          InkWell(
                                            onTap: () async {
                                              await confirmDelete(item["id"]);
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.red
                                                    .withOpacity(0.20),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.delete_outline,
                                                    size: 13,
                                                    color: Colors.white,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    "Delete",
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            buildChip(
                                              item["call_status"],
                                              callColor,
                                              item["call_status"]
                                                          .toString()
                                                          .toLowerCase() ==
                                                      "productive"
                                                  ? Icons.trending_up
                                                  : Icons.phone_in_talk,
                                            ),
                                            buildChip(
                                              item["status"],
                                              dsrColor,
                                              Icons.verified_outlined,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 18),
                                        buildSectionTitle(
                                          "Record Details",
                                          Icons.info_outline,
                                        ),
                                        const SizedBox(height: 12),
                                        buildInfoRow(
                                          "Customer",
                                          item["customer_name"],
                                          icon: Icons.person_outline,
                                          valueWeight: FontWeight.w600,
                                        ),
                                        buildInfoRow(
                                          "Phone",
                                          item["phone"],
                                          icon: Icons.phone_outlined,
                                        ),
                                        buildInfoRow(
                                          "State",
                                          item["state_name"],
                                          icon: Icons.map_outlined,
                                        ),
                                        buildInfoRow(
                                          "District",
                                          item["district_name"],
                                          icon: Icons.location_city_outlined,
                                        ),
                                        buildInfoRow(
                                          "Created By",
                                          item["user_name"],
                                          icon: Icons.badge_outlined,
                                        ),
                                        buildInfoRow(
                                          "Duration",
                                          item["call_duration"],
                                          icon: Icons.timer_outlined,
                                        ),
                                        buildInfoRow(
                                          "Invoice Amount",
                                          item["invoice_amount"],
                                          icon: Icons.currency_rupee_outlined,
                                          valueColor: const Color(0xff0F9D58),
                                          valueWeight: FontWeight.w700,
                                        ),
                                        buildInfoRow(
                                          "Created At",
                                          formatDateTime(item["created_at"]),
                                          icon: Icons.calendar_today_outlined,
                                        ),
                                        if ((item["note"] ?? "")
                                            .toString()
                                            .trim()
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xffF8FAFC),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: Colors.grey.shade200,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .sticky_note_2_outlined,
                                                      size: 16,
                                                      color:
                                                          Colors.grey.shade700,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      "Note",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors
                                                            .grey.shade800,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  item["note"],
                                                  style: const TextStyle(
                                                    fontSize: 12.5,
                                                    color: Colors.black87,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          buildProductDetailsSection(item),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
