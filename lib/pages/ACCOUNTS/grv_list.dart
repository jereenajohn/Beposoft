import 'dart:convert';

import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
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

class GrvList extends StatefulWidget {
  final dynamic status;

  const GrvList({super.key, required this.status});

  @override
  State<GrvList> createState() => _GrvListState();
}

class _GrvListState extends State<GrvList> {
  static const Color primaryColor = Color.fromARGB(255, 12, 80, 163);
  static const Color backgroundColor = Color(0xffF5F7FB);
  static const Color textColor = Color.fromARGB(255, 32, 43, 61);

  final List<String> remarkOptions = [
    "exchange",
    "return",
    "refund",
    "cod_return",
  ];

  final List<String> statusOptions = [
    "Waiting For Approval",
    "approved",
    "rejected",
  ];

  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final drower d = drower();

  List<Map<String, dynamic>> grvlist = [];
  List<Map<String, dynamic>> filteredProducts = [];

  String selectedStatus = "";

  DateTime? startDate;
  DateTime? endDate;

  int currentPage = 1;
  bool hasMoreData = true;
  bool isLoadingMore = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    getGrvList(isRefresh: true);

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 220 &&
          !isLoadingMore &&
          hasMoreData &&
          !isLoading) {
        getGrvList();
      }
    });
  }

  Future<String?> getTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  String formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'N/A';

    try {
      final parsedDate = DateTime.parse(isoDate);
      return DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (_) {
      return 'Invalid date';
    }
  }

  Future<void> getGrvList({bool isRefresh = false}) async {
    if (isLoadingMore) return;

    if (isRefresh) {
      setState(() {
        isLoading = true;
        currentPage = 1;
        hasMoreData = true;
        grvlist.clear();
        filteredProducts.clear();
      });
    } else {
      setState(() {
        isLoadingMore = true;
      });
    }

    try {
      final token = await getTokenFromPrefs();
      final dep = await getdepFromPrefs();

      final baseUrl = dep == "CSO"
          ? '$api/api/grv/cycling/skating/'
          : '$api/api/grv/data/';

      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'page': currentPage.toString(),
        },
      );

      debugPrint('GRV URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('GRV STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        final productsData = dep == "CSO"
            ? (parsed['results']?['data'] ?? [])
            : (parsed['data'] ?? []);

        final List<Map<String, dynamic>> grvDataList = [];

        for (var productData in productsData) {
          if (widget.status == null || widget.status == productData['status']) {
            grvDataList.add({
              'id': productData['id'],
              'product': productData['product'] ?? '',
              'returnreason': productData['returnreason'] ?? '',
              'invoice': productData['invoice'] ?? '',
              'customer': productData['customer'] ?? '',
              'shipping_customer': productData['shipping_customer'] ?? '',
              'staff': productData['staff'] ?? '',
              'remark': productData['remark'] ?? remarkOptions[0],
              'cod_amount': productData['cod_amount'],
              'rack_details': productData['rack_details'] ?? [],
              'status': productData['status'] ?? statusOptions[0],
              'order_date': productData['order_date'] ?? '',
              'date': productData['date'] ?? productData['order_date'] ?? '',
              'note': productData['note'] ?? '',
              'parcel_service_name':
                  productData['parcel_service_name'] ?? 'No Parcel Service',
              'updated_at': productData['updated_at'] ??
                  productData['date'] ??
                  DateTime.now().toIso8601String().split('T')[0],
            });
          }
        }

        setState(() {
          grvlist.addAll(grvDataList);

          hasMoreData = dep == "CSO"
              ? parsed['next'] != null
              : false;

          if (hasMoreData) currentPage++;
        });

        _applyFilters();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch GRV data (${response.statusCode})'),
          ),
        );
      }
    } catch (error) {
      debugPrint('GRV FETCH ERROR: $error');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching GRV data')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
      }
    }
  }

  Future<void> updateGrvItem(int id, String status, String remark) async {
    try {
      final token = await getTokenFromPrefs();
      final formattedTime = DateFormat("HH:mm").format(DateTime.now());

      final response = await http.put(
        Uri.parse('$api/api/grv/update/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': status,
          'remark': remark,
          'updated_at': DateTime.now().toIso8601String().split('T')[0],
          'time': formattedTime,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          grvlist = grvlist.map((item) {
            if (item['id'] == id) {
              item['status'] = status;
              item['remark'] = remark;
            }
            return item;
          }).toList();

          _applyFilters();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GRV updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update GRV')),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating GRV')),
      );
    }
  }

  void _applyFilters() {
    final query = searchController.text.trim().toLowerCase();

    setState(() {
      filteredProducts = grvlist.where((product) {
        final productDate = product['date']?.toString() ?? '';

        final matchesStatus =
            selectedStatus.isEmpty || product['status'] == selectedStatus;

        final matchesSearch = query.isEmpty ||
            product['product'].toString().toLowerCase().contains(query) ||
            product['invoice'].toString().toLowerCase().contains(query) ||
            product['customer'].toString().toLowerCase().contains(query) ||
            product['shipping_customer'].toString().toLowerCase().contains(query) ||
            product['staff'].toString().toLowerCase().contains(query);

        bool matchesDate = true;

        if (startDate != null && endDate != null && productDate.isNotEmpty) {
          try {
            final parsedDate = DateFormat('yyyy-MM-dd').parse(productDate);
            matchesDate =
                parsedDate.isAfter(startDate!.subtract(const Duration(days: 1))) &&
                    parsedDate.isBefore(endDate!.add(const Duration(days: 1)));
          } catch (_) {
            matchesDate = true;
          }
        }

        return matchesStatus && matchesSearch && matchesDate;
      }).toList();
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: textColor,
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

      _applyFilters();
    }
  }

  void _clearFilters() {
    setState(() {
      selectedStatus = "";
      searchController.clear();
      startDate = null;
      endDate = null;
      filteredProducts = List<Map<String, dynamic>>.from(grvlist);
    });
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('token');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully')),
      );
    });

    await Future.delayed(const Duration(seconds: 2));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => login()),
    );
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

  String _dateLabel() {
    if (startDate == null || endDate == null) return 'All Dates';

    return '${DateFormat('yyyy-MM-dd').format(startDate!)} to ${DateFormat('yyyy-MM-dd').format(endDate!)}';
  }

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();

    if (normalized == 'approved') return Colors.green;
    if (normalized == 'rejected') return Colors.red;
    return Colors.orange;
  }

  Widget _buildSummaryHeader() {
    final approved =
        filteredProducts.where((e) => e['status'] == 'approved').length;
    final rejected =
        filteredProducts.where((e) => e['status'] == 'rejected').length;
    final waiting = filteredProducts
        .where((e) => e['status'] == 'Waiting For Approval')
        .length;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 12, 80, 163),
            Color.fromARGB(255, 40, 135, 236),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _summaryTile('Total', filteredProducts.length.toString(), Icons.list_alt),
          const SizedBox(width: 10),
          _summaryTile('Approved', approved.toString(), Icons.check_circle_outline),
          const SizedBox(width: 10),
          _summaryTile('Rejected', rejected.toString(), Icons.cancel_outlined),
          const SizedBox(width: 10),
          _summaryTile('Waiting', waiting.toString(), Icons.hourglass_empty),
        ],
      ),
    );
  }

  Widget _summaryTile(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.78),
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search product, invoice, customer, staff...",
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: primaryColor),
                suffixIcon: searchController.text.trim().isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (_) => _applyFilters(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedStatus.isEmpty ? null : selectedStatus,
                      isExpanded: true,
                      hint: const Text(
                        "Status",
                        style: TextStyle(fontSize: 13),
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: primaryColor,
                      ),
                      items: statusOptions.map((value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedStatus = newValue ?? "";
                        });
                        _applyFilters();
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDateRange(context),
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          size: 18,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _dateLabel(),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: _clearFilters,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrvCard(Map<String, dynamic> item) {
    final status = item['status']?.toString() ?? '';
    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 7, 14, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.assignment_return_outlined,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item['product'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _pill(
                  text: item['invoice']?.toString() ?? '',
                  color: Colors.orange,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _miniTile(
                        label: 'Status',
                        value: status,
                        color: statusColor,
                        icon: Icons.verified_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _miniTile(
                        label: 'Remark',
                        value: item['remark']?.toString() ?? '',
                        color: primaryColor,
                        icon: Icons.notes_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _infoRow(Icons.person_outline, 'Customer', item['customer']),
                _infoRow(
                  Icons.person_pin_circle_outlined,
                  'Shipping',
                  item['shipping_customer'],
                ),
                _infoRow(Icons.supervisor_account_outlined, 'Staff', item['staff']),
                _infoRow(
                  Icons.local_shipping_outlined,
                  'Parcel',
                  item['parcel_service_name'],
                ),
                _infoRow(
                  Icons.report_problem_outlined,
                  'Reason',
                  item['returnreason'],
                ),
                if (item['cod_amount'] != null &&
                    item['cod_amount'].toString() != '0' &&
                    item['cod_amount'].toString() != '0.00')
                  _infoRow(
                    Icons.currency_rupee,
                    'COD',
                    item['cod_amount'],
                  ),
                _infoRow(Icons.description_outlined, 'Note', item['note']),
                const SizedBox(height: 12),
                _buildRackSection(item),
                const SizedBox(height: 12),
                _buildActionDropdowns(item),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Created: ${item['order_date'] ?? ''}",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      "Updated: ${formatDate(item['updated_at'])}",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _pill({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _miniTile({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.isEmpty ? 'N/A' : value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, dynamic value) {
    final text = value?.toString() ?? '';

    if (text.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade500, size: 17),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRackSection(Map<String, dynamic> item) {
    final racks = item['rack_details'];

    if (racks == null || racks is! List || racks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Rack Details",
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: racks.map<Widget>((rack) {
              final rackName = rack['rack_name'] ?? '';
              final column = rack['column_name'] ?? '';
              final qty = rack['quantity'] ?? '';

              return Chip(
                label: Text(
                  "$rackName${column.toString().isNotEmpty ? '-$column' : ''} x $qty",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                backgroundColor: Colors.blue.shade50,
                side: BorderSide(color: Colors.blue.shade100),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionDropdowns(Map<String, dynamic> item) {
    return Row(
      children: [
        Expanded(
          child: _actionDropdown(
            label: 'Remark',
            value: item['remark'],
            options: remarkOptions,
            onChanged: (newValue) {
              if (newValue == null) return;

              setState(() {
                item['remark'] = newValue;
              });

              updateGrvItem(item['id'], item['status'], newValue);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionDropdown(
            label: 'Status',
            value: item['status'],
            options: statusOptions,
            onChanged: (newValue) {
              if (newValue == null) return;

              setState(() {
                item['status'] = newValue;
              });

              updateGrvItem(item['id'], newValue, item['remark'] ?? '');
            },
          ),
        ),
      ],
    );
  }

  Widget _actionDropdown({
    required String label,
    required String? value,
    required List<String> options,
    required void Function(String?) onChanged,
  }) {
    return Container(
      height: 47,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.contains(value) ? value : null,
          isExpanded: true,
          hint: Text(label),
          icon: const Icon(Icons.keyboard_arrow_down, color: primaryColor),
          items: options.map((value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildList() {
    if (isLoading && filteredProducts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (filteredProducts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          Icon(Icons.search_off, color: Colors.grey.shade400, size: 64),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'No GRV records found',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Center(
            child: Text(
              'Try changing filters or date range',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: filteredProducts.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filteredProducts.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(color: primaryColor),
            ),
          );
        }

        return _buildGrvCard(filteredProducts[index]);
      },
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
        backgroundColor: backgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: const Text(
            "GRV List",
            style: TextStyle(
              fontSize: 15,
              color: textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: textColor),
            onPressed: _navigateBack,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.date_range, color: primaryColor),
              onPressed: () => _selectDateRange(context),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: textColor),
              onPressed: () => getGrvList(isRefresh: true),
            ),
          ],
        ),
        body: Column(
          children: [
            // _buildSummaryHeader(),
            _buildSearchAndFilters(),
            Expanded(
              child: RefreshIndicator(
                color: primaryColor,
                onRefresh: () async {
                  await getGrvList(isRefresh: true);
                },
                child: _buildList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }
}