import 'dart:async';
import 'dart:convert';

import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
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

class ShippingOrderSummaryPage extends StatefulWidget {
  const ShippingOrderSummaryPage({super.key, required String baseUrl});

  @override
  State<ShippingOrderSummaryPage> createState() =>
      _ShippingOrderSummaryPageState();
}

class _ShippingOrderSummaryPageState
    extends State<ShippingOrderSummaryPage> {
  final TextEditingController _searchController =
      TextEditingController();

  final TextEditingController _productIdController =
      TextEditingController();

  Timer? _searchDebounce;

  bool _isLoading = false;
  bool _isCustomerLoading = false;
  bool _isStaffLoading = false;
  bool _isFilterSheetOpen = false;

  String? _errorMessage;

  DateTime? _startDate;
  DateTime? _endDate;

  int? _selectedCustomerId;
  int? _selectedStaffId;

  String _selectedSection = 'overall';

  Map<String, dynamic> _filters = {};

  Map<String, dynamic> _overallSummary = {};
  Map<String, dynamic> _pendingSummary = {};
  Map<String, dynamic> _dispatchedSummary = {};

  List<Map<String, dynamic>> _customerOptions = [];
  List<Map<String, dynamic>> _staffOptions = [];

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();

    _fetchInitialData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _productIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    await Future.wait([
      _fetchShippingSummary(),
      _fetchCustomers(),
      _fetchStaffOptions(),
    ]);
  }

  Future<String?> _getTokenFromPrefs() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    return preferences.getString('token');
  }

  int _asInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }

  double _asDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is double) return value;

    if (value is num) return value.toDouble();

    return double.tryParse(value.toString()) ?? 0.0;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map(
          (Map item) => Map<String, dynamic>.from(item),
        )
        .toList();
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatDisplayDate(DateTime? date) {
    if (date == null) return 'Not selected';

    return DateFormat('dd MMM yyyy').format(date);
  }

  String _formatAmount(dynamic value) {
    final double amount = _asDouble(value);

    if (amount.abs() >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    }

    if (amount.abs() >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)} L';
    }

    if (amount.abs() >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(2)} K';
    }

    return _currencyFormat.format(amount);
  }

  Uri _buildSummaryUri() {
    final Map<String, String> queryParameters = {};

    final String search = _searchController.text.trim();
    final String productId = _productIdController.text.trim();

    if (_startDate != null) {
      queryParameters['start_date'] = _formatDate(_startDate!);
    }

    if (_endDate != null) {
      queryParameters['end_date'] = _formatDate(_endDate!);
    }

    if (search.isNotEmpty) {
      queryParameters['search'] = search;
    }

    if (productId.isNotEmpty) {
      queryParameters['product_id'] = productId;
    }

    if (_selectedCustomerId != null) {
      queryParameters['customer_id'] =
          _selectedCustomerId.toString();
    }

    if (_selectedStaffId != null) {
      queryParameters['manage_staff_id'] =
          _selectedStaffId.toString();
    }

    return Uri.parse(
      '$api/api/orders/shipping/product/count/',
    ).replace(
      queryParameters:
          queryParameters.isEmpty ? null : queryParameters,
    );
  }

  Future<void> _fetchShippingSummary() async {
    if (_isLoading) return;

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String? token = await _getTokenFromPrefs();

      if (token == null || token.trim().isEmpty) {
        throw Exception(
          'Authentication token not found. Please log in again.',
        );
      }

      final Uri uri = _buildSummaryUri();

      debugPrint('SHIPPING SUMMARY URL: $uri');

      final http.Response response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      debugPrint(
        'SHIPPING SUMMARY STATUS: ${response.statusCode}',
      );

      debugPrint(
        'SHIPPING SUMMARY BODY: ${response.body}',
      );

      if (response.statusCode != 200) {
        String message =
            'Unable to fetch shipping order summary.';

        try {
          final dynamic decodedError =
              jsonDecode(response.body);

          if (decodedError is Map) {
            message = (decodedError['message'] ??
                    decodedError['detail'] ??
                    message)
                .toString();
          }
        } catch (_) {}

        throw Exception(message);
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw Exception(
          'Invalid response received from the server.',
        );
      }

      final Map<String, dynamic> parsed =
          Map<String, dynamic>.from(decoded);

      final Map<String, dynamic> summary =
          _asMap(parsed['summary']);

      if (!mounted) return;

      setState(() {
        _filters = _asMap(parsed['filters']);

        _overallSummary = _asMap(summary['overall']);
        _pendingSummary = _asMap(summary['pending']);
        _dispatchedSummary = _asMap(
          summary['dispatched'],
        );

        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint(
        'SHIPPING SUMMARY ERROR: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      setState(() {
        _overallSummary = {};
        _pendingSummary = {};
        _dispatchedSummary = {};
        _errorMessage = error
            .toString()
            .replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchCustomers({
    String search = '',
  }) async {
    if (_isCustomerLoading) return;

    if (!mounted) return;

    setState(() {
      _isCustomerLoading = true;
    });

    try {
      final String? token = await _getTokenFromPrefs();

      if (token == null || token.trim().isEmpty) {
        return;
      }

      final Map<String, String> queryParameters = {
        'page': '1',
      };

      if (search.trim().isNotEmpty) {
        queryParameters['search'] = search.trim();
      }

      final Uri uri = Uri.parse(
        '$api/api/customers/',
      ).replace(
        queryParameters: queryParameters,
      );

      final http.Response response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        return;
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map) return;

      final Map<String, dynamic> parsed =
          Map<String, dynamic>.from(decoded);

      final List<dynamic> rawResults =
          parsed['results'] is List
              ? List<dynamic>.from(parsed['results'])
              : <dynamic>[];

      final List<Map<String, dynamic>> customers = [];

      for (final dynamic rawItem in rawResults) {
        if (rawItem is! Map) continue;

        final Map<String, dynamic> item =
            Map<String, dynamic>.from(rawItem);

        customers.add({
          'id': _asInt(item['id']),
          'name': (item['name'] ?? 'Unknown Customer')
              .toString(),
          'phone': (item['phone'] ?? '').toString(),
          'state_name':
              (item['state_name'] ?? '').toString(),
          'manager':
              (item['manager'] ?? '').toString(),
        });
      }

      if (!mounted) return;

      setState(() {
        _customerOptions = customers;
      });
    } catch (error) {
      debugPrint(
        'CUSTOMER OPTIONS ERROR: $error',
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isCustomerLoading = false;
      });
    }
  }

  Uri _buildStaffUri({
    int page = 1,
    String search = '',
  }) {
    final Map<String, String> queryParameters = {
      'page': page.toString(),
    };

    if (search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    return Uri.parse(
      '$api/api/get/staffs/',
    ).replace(
      queryParameters: queryParameters,
    );
  }

  Future<void> _fetchStaffOptions({
    String search = '',
  }) async {
    if (_isStaffLoading) return;

    if (!mounted) return;

    setState(() {
      _isStaffLoading = true;
    });

    try {
      final String? token = await _getTokenFromPrefs();

      if (token == null || token.trim().isEmpty) {
        return;
      }

      final Uri uri = _buildStaffUri(
        page: 1,
        search: search,
      );

      final http.Response response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        return;
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map) return;

      final Map<String, dynamic> parsed =
          Map<String, dynamic>.from(decoded);

      final Map<String, dynamic> results =
          _asMap(parsed['results']);

      final List<dynamic> rawStaff =
          results['data'] is List
              ? List<dynamic>.from(results['data'])
              : <dynamic>[];

      final List<Map<String, dynamic>> staff = [];

      for (final dynamic rawItem in rawStaff) {
        if (rawItem is! Map) continue;

        final Map<String, dynamic> item =
            Map<String, dynamic>.from(rawItem);

        staff.add({
          'id': _asInt(item['id']),
          'eid': (item['eid'] ?? '').toString(),
          'name':
              (item['name'] ?? 'Unknown Staff').toString(),
          'department_name':
              (item['department_name'] ?? '').toString(),
          'designation':
              (item['designation'] ?? '').toString(),
          'image': (item['image'] ?? '').toString(),
        });
      }

      if (!mounted) return;

      setState(() {
        _staffOptions = staff;
      });
    } catch (error) {
      debugPrint(
        'STAFF OPTIONS ERROR: $error',
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isStaffLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(
      const Duration(milliseconds: 600),
      () {
        _fetchShippingSummary();
      },
    );
  }

  Future<void> _selectDateRange() async {
    final DateTime now = DateTime.now();

    final DateTimeRange? selectedRange =
        await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange:
          _startDate != null && _endDate != null
              ? DateTimeRange(
                  start: _startDate!,
                  end: _endDate!,
                )
              : null,
      builder: (
        BuildContext context,
        Widget? child,
      ) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2368F5),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF172033),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedRange == null) return;

    if (!mounted) return;

    setState(() {
      _startDate = DateTime(
        selectedRange.start.year,
        selectedRange.start.month,
        selectedRange.start.day,
      );

      _endDate = DateTime(
        selectedRange.end.year,
        selectedRange.end.month,
        selectedRange.end.day,
      );
    });
  }

  Future<void> _resetFilters() async {
    if (!mounted) return;

    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedCustomerId = null;
      _selectedStaffId = null;
      _searchController.clear();
      _productIdController.clear();
    });

    await _fetchShippingSummary();
  }

  Map<String, dynamic> get _selectedSummary {
    switch (_selectedSection) {
      case 'pending':
        return _pendingSummary;

      case 'dispatched':
        return _dispatchedSummary;

      case 'overall':
      default:
        return _overallSummary;
    }
  }

  String get _selectedSectionTitle {
    switch (_selectedSection) {
      case 'pending':
        return 'Pending Orders';

      case 'dispatched':
        return 'Dispatched Orders';

      case 'overall':
      default:
        return 'Overall Orders';
    }
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'shipped':
        return const Color(0xFF159447);

      case 'ready to ship':
        return const Color(0xFF2368F5);

      case 'packing under progress':
        return const Color(0xFFF28C28);

      case 'packed':
        return const Color(0xFF7A5AF8);

      case 'to print':
        return const Color(0xFF008B8B);

      case 'waiting for confirmation':
        return const Color(0xFFE5484D);

      default:
        return const Color(0xFF667085);
    }
  }

  IconData _statusIcon(String status) {
    switch (status.trim().toLowerCase()) {
      case 'shipped':
        return Icons.local_shipping_rounded;

      case 'ready to ship':
        return Icons.inventory_2_rounded;

      case 'packing under progress':
        return Icons.move_to_inbox_rounded;

      case 'packed':
        return Icons.check_circle_rounded;

      case 'to print':
        return Icons.print_rounded;

      case 'waiting for confirmation':
        return Icons.hourglass_top_rounded;

      default:
        return Icons.receipt_long_rounded;
    }
  }

  Future<void> _showCustomerPicker() async {
    final TextEditingController searchController =
        TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (
        BuildContext bottomSheetContext,
      ) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter modalSetState,
          ) {
            Future<void> searchCustomers(
              String value,
            ) async {
              await _fetchCustomers(
                search: value,
              );

              modalSetState(() {});
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.72,
              minChildSize: 0.50,
              maxChildSize: 0.94,
              builder: (
                BuildContext context,
                ScrollController scrollController,
              ) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F9FC),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius:
                              BorderRadius.circular(50),
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(
                          20,
                          18,
                          12,
                          12,
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Select Customer',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight:
                                      FontWeight.w800,
                                  color:
                                      Color(0xFF172033),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.pop(
                                  bottomSheetContext,
                                );
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 18,
                        ),
                        child: TextField(
                          controller: searchController,
                          onChanged: searchCustomers,
                          decoration: InputDecoration(
                            hintText:
                                'Search customer name or phone',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                16,
                              ),
                              borderSide:
                                  BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _isCustomerLoading
                            ? const Center(
                                child:
                                    CircularProgressIndicator(),
                              )
                            : _customerOptions.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No customers found',
                                    ),
                                  )
                                : ListView.separated(
                                    controller:
                                        scrollController,
                                    padding:
                                        const EdgeInsets
                                            .fromLTRB(
                                      18,
                                      4,
                                      18,
                                      24,
                                    ),
                                    itemCount:
                                        _customerOptions
                                            .length,
                                    separatorBuilder:
                                        (_, __) =>
                                            const SizedBox(
                                      height: 8,
                                    ),
                                    itemBuilder: (
                                      BuildContext context,
                                      int index,
                                    ) {
                                      final Map<String,
                                              dynamic>
                                          customer =
                                          _customerOptions[
                                              index];

                                      final int customerId =
                                          _asInt(
                                        customer['id'],
                                      );

                                      final bool selected =
                                          _selectedCustomerId ==
                                              customerId;

                                      return Material(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          16,
                                        ),
                                        child: ListTile(
                                          shape:
                                              RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius
                                                    .circular(
                                              16,
                                            ),
                                          ),
                                          leading:
                                              CircleAvatar(
                                            backgroundColor:
                                                selected
                                                    ? const Color(
                                                        0xFF2368F5,
                                                      )
                                                    : const Color(
                                                        0xFFE9F0FF,
                                                      ),
                                            child: Icon(
                                              Icons
                                                  .person_rounded,
                                              color: selected
                                                  ? Colors.white
                                                  : const Color(
                                                      0xFF2368F5,
                                                    ),
                                            ),
                                          ),
                                          title: Text(
                                            customer[
                                                    'name']
                                                .toString(),
                                            style:
                                                const TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .w700,
                                            ),
                                          ),
                                          subtitle: Text(
                                            [
                                              customer[
                                                      'phone']
                                                  .toString(),
                                              customer[
                                                      'state_name']
                                                  .toString(),
                                            ]
                                                .where(
                                                  (
                                                    String value,
                                                  ) =>
                                                      value
                                                          .trim()
                                                          .isNotEmpty,
                                                )
                                                .join(
                                                  ' • ',
                                                ),
                                          ),
                                          trailing: selected
                                              ? const Icon(
                                                  Icons
                                                      .check_circle_rounded,
                                                  color:
                                                      Color(
                                                    0xFF2368F5,
                                                  ),
                                                )
                                              : null,
                                          onTap: () {
                                            setState(() {
                                              _selectedCustomerId =
                                                  customerId;
                                            });

                                            Navigator.pop(
                                              bottomSheetContext,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    searchController.dispose();
  }

  Future<void> _showStaffPicker() async {
    final TextEditingController searchController =
        TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (
        BuildContext bottomSheetContext,
      ) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter modalSetState,
          ) {
            Future<void> searchStaff(
              String value,
            ) async {
              await _fetchStaffOptions(
                search: value,
              );

              modalSetState(() {});
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.72,
              minChildSize: 0.50,
              maxChildSize: 0.94,
              builder: (
                BuildContext context,
                ScrollController scrollController,
              ) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F9FC),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius:
                              BorderRadius.circular(50),
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(
                          20,
                          18,
                          12,
                          12,
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Select Staff',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight:
                                      FontWeight.w800,
                                  color:
                                      Color(0xFF172033),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.pop(
                                  bottomSheetContext,
                                );
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 18,
                        ),
                        child: TextField(
                          controller: searchController,
                          onChanged: searchStaff,
                          decoration: InputDecoration(
                            hintText:
                                'Search staff name or employee ID',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                16,
                              ),
                              borderSide:
                                  BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _isStaffLoading
                            ? const Center(
                                child:
                                    CircularProgressIndicator(),
                              )
                            : _staffOptions.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No staff found',
                                    ),
                                  )
                                : ListView.separated(
                                    controller:
                                        scrollController,
                                    padding:
                                        const EdgeInsets
                                            .fromLTRB(
                                      18,
                                      4,
                                      18,
                                      24,
                                    ),
                                    itemCount:
                                        _staffOptions
                                            .length,
                                    separatorBuilder:
                                        (_, __) =>
                                            const SizedBox(
                                      height: 8,
                                    ),
                                    itemBuilder: (
                                      BuildContext context,
                                      int index,
                                    ) {
                                      final Map<String,
                                              dynamic>
                                          staff =
                                          _staffOptions[
                                              index];

                                      final int staffId =
                                          _asInt(
                                        staff['id'],
                                      );

                                      final bool selected =
                                          _selectedStaffId ==
                                              staffId;

                                      return Material(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          16,
                                        ),
                                        child: ListTile(
                                          shape:
                                              RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius
                                                    .circular(
                                              16,
                                            ),
                                          ),
                                          leading:
                                              CircleAvatar(
                                            backgroundColor:
                                                selected
                                                    ? const Color(
                                                        0xFF2368F5,
                                                      )
                                                    : const Color(
                                                        0xFFE9F0FF,
                                                      ),
                                            child: Icon(
                                              Icons
                                                  .badge_rounded,
                                              color: selected
                                                  ? Colors.white
                                                  : const Color(
                                                      0xFF2368F5,
                                                    ),
                                            ),
                                          ),
                                          title: Text(
                                            staff['name']
                                                .toString(),
                                            style:
                                                const TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .w700,
                                            ),
                                          ),
                                          subtitle: Text(
                                            [
                                              staff['eid']
                                                  .toString(),
                                              staff[
                                                      'department_name']
                                                  .toString(),
                                            ]
                                                .where(
                                                  (
                                                    String value,
                                                  ) =>
                                                      value
                                                          .trim()
                                                          .isNotEmpty,
                                                )
                                                .join(
                                                  ' • ',
                                                ),
                                          ),
                                          trailing: selected
                                              ? const Icon(
                                                  Icons
                                                      .check_circle_rounded,
                                                  color:
                                                      Color(
                                                    0xFF2368F5,
                                                  ),
                                                )
                                              : null,
                                          onTap: () {
                                            setState(() {
                                              _selectedStaffId =
                                                  staffId;
                                            });

                                            Navigator.pop(
                                              bottomSheetContext,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    searchController.dispose();
  }

  String _selectedCustomerName() {
    if (_selectedCustomerId == null) {
      return 'All customers';
    }

    final Iterable<Map<String, dynamic>> match =
        _customerOptions.where(
      (Map<String, dynamic> customer) {
        return _asInt(customer['id']) ==
            _selectedCustomerId;
      },
    );

    if (match.isEmpty) {
      return 'Customer #$_selectedCustomerId';
    }

    return match.first['name'].toString();
  }

  String _selectedStaffName() {
    if (_selectedStaffId == null) {
      return 'All staff';
    }

    final Iterable<Map<String, dynamic>> match =
        _staffOptions.where(
      (Map<String, dynamic> staff) {
        return _asInt(staff['id']) ==
            _selectedStaffId;
      },
    );

    if (match.isEmpty) {
      return 'Staff #$_selectedStaffId';
    }

    return match.first['name'].toString();
  }

  Future<void> _showFilterSheet() async {
    if (_isFilterSheetOpen) return;

    _isFilterSheetOpen = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (
        BuildContext bottomSheetContext,
      ) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter modalSetState,
          ) {
            return Padding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight:
                      MediaQuery.sizeOf(context).height *
                          0.90,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius:
                            BorderRadius.circular(50),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        18,
                        12,
                        12,
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Shipping Filters',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.w800,
                                color: Color(0xFF172033),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _startDate = null;
                                _endDate = null;
                                _selectedCustomerId = null;
                                _selectedStaffId = null;
                                _productIdController
                                    .clear();
                              });

                              modalSetState(() {});
                            },
                            child: const Text('Clear'),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.pop(
                                bottomSheetContext,
                              );
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        padding:
                            const EdgeInsets.fromLTRB(
                          18,
                          18,
                          18,
                          24,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            _buildFilterLabel(
                              'Date range',
                            ),
                            _buildFilterSelectionTile(
                              icon: Icons
                                  .calendar_month_rounded,
                              title: _startDate == null ||
                                      _endDate == null
                                  ? 'Select date range'
                                  : '${_formatDisplayDate(_startDate)} - ${_formatDisplayDate(_endDate)}',
                              onTap: () async {
                                await _selectDateRange();

                                modalSetState(() {});
                              },
                            ),
                            const SizedBox(height: 16),
                            // _buildFilterLabel(
                            //   'Product ID',
                            // ),
                            // TextField(
                            //   controller:
                            //       _productIdController,
                            //   keyboardType:
                            //       TextInputType.number,
                            //   decoration:
                            //       _filterInputDecoration(
                            //     hintText:
                            //         'Enter product ID',
                            //     icon: Icons
                            //         .inventory_2_outlined,
                            //   ),
                            // ),
                            // const SizedBox(height: 16),
                            _buildFilterLabel(
                              'Customer',
                            ),
                            _buildFilterSelectionTile(
                              icon:
                                  Icons.person_outline_rounded,
                              title:
                                  _selectedCustomerName(),
                              onTap: () async {
                                await _showCustomerPicker();

                                modalSetState(() {});
                              },
                              onClear:
                                  _selectedCustomerId == null
                                      ? null
                                      : () {
                                          setState(() {
                                            _selectedCustomerId =
                                                null;
                                          });

                                          modalSetState(
                                            () {},
                                          );
                                        },
                            ),
                            const SizedBox(height: 16),
                            _buildFilterLabel(
                              'Manage staff',
                            ),
                            _buildFilterSelectionTile(
                              icon: Icons
                                  .badge_outlined,
                              title: _selectedStaffName(),
                              onTap: () async {
                                await _showStaffPicker();

                                modalSetState(() {});
                              },
                              onClear:
                                  _selectedStaffId == null
                                      ? null
                                      : () {
                                          setState(() {
                                            _selectedStaffId =
                                                null;
                                          });

                                          modalSetState(
                                            () {},
                                          );
                                        },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(
                        18,
                        12,
                        18,
                        18,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(
                            color: Color(0xFFE4E7EC),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                Navigator.pop(
                                  bottomSheetContext,
                                );

                                await _resetFilters();
                              },
                              style:
                                  OutlinedButton.styleFrom(
                                minimumSize:
                                    const Size.fromHeight(
                                  50,
                                ),
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    14,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'Reset',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.pop(
                                  bottomSheetContext,
                                );

                                await _fetchShippingSummary();
                              },
                              icon: const Icon(
                                Icons.check_rounded,
                              ),
                              label: const Text(
                                'Apply Filters',
                              ),
                              style:
                                  ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(
                                  0xFF2368F5,
                                ),
                                foregroundColor:
                                    Colors.white,
                                minimumSize:
                                    const Size.fromHeight(
                                  50,
                                ),
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    _isFilterSheetOpen = false;
  }

  InputDecoration _filterInputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE4E7EC),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE4E7EC),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF2368F5),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildFilterLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 2,
        bottom: 8,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF344054),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildFilterSelectionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFE4E7EC),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF667085),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF344054),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onClear != null)
                IconButton(
                  onPressed: onClear,
                  visualDensity:
                      VisualDensity.compact,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                  ),
                )
              else
                const Icon(
                  Icons.keyboard_arrow_right_rounded,
                  color: Color(0xFF98A2B3),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAEFF7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSectionButton(
              value: 'overall',
              label: 'Overall',
              icon: Icons.dashboard_rounded,
            ),
          ),
          Expanded(
            child: _buildSectionButton(
              value: 'pending',
              label: 'Pending',
              icon: Icons.pending_actions_rounded,
            ),
          ),
          Expanded(
            child: _buildSectionButton(
              value: 'dispatched',
              label: 'Dispatched',
              icon: Icons.local_shipping_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionButton({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final bool selected =
        _selectedSection == value;

    return Material(
      color: selected
          ? Colors.white
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _selectedSection = value;
          });
        },
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected
                    ? const Color(0xFF2368F5)
                    : const Color(0xFF667085),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: selected
                        ? const Color(0xFF2368F5)
                        : const Color(0xFF667085),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSummary() {
    final Map<String, dynamic> summary =
        _selectedSummary;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        0,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1F5FD8),
            Color(0xFF4996FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332368F5),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      Colors.white.withOpacity(0.18),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons
                      .local_shipping_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedSectionTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _buildFilterPeriodText(),
                      style: TextStyle(
                        color: Colors.white
                            .withOpacity(0.82),
                        fontSize: 11.5,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _buildHeroMetric(
                  label: 'Total Orders',
                  value:
                      '${_asInt(summary['total_orders'])}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHeroMetric(
                  label: 'Total Amount',
                  value: _formatAmount(
                    summary['total_amount'],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildHeroMetric(
                  label: 'Product Qty',
                  value:
                      '${_asInt(summary['total_product_quantity'])}',
                ),
              ),
              // const SizedBox(width: 12),
              // Expanded(
              //   child: _buildHeroMetric(
              //     label: 'Distinct Products',
              //     value:
              //         '${_asInt(summary['total_distinct_products'])}',
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetric({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildFilterPeriodText() {
    if (_startDate != null &&
        _endDate != null) {
      return '${_formatDisplayDate(_startDate)} to ${_formatDisplayDate(_endDate)}';
    }

    return 'All available records';
  }

  Widget _buildQuickSummaryGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickSummaryCard(
              title: 'Pending',
              value:
                  '${_asInt(_pendingSummary['total_orders'])}',
              subtitle: _formatAmount(
                _pendingSummary['total_amount'],
              ),
              icon: Icons.pending_actions_rounded,
              iconColor:
                  const Color(0xFFF28C28),
              iconBackground:
                  const Color(0xFFFFF1DF),
              onTap: () {
                setState(() {
                  _selectedSection = 'pending';
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickSummaryCard(
              title: 'Dispatched',
              value:
                  '${_asInt(_dispatchedSummary['total_orders'])}',
              subtitle: _formatAmount(
                _dispatchedSummary['total_amount'],
              ),
              icon: Icons.local_shipping_rounded,
              iconColor:
                  const Color(0xFF159447),
              iconBackground:
                  const Color(0xFFE0F5E8),
              onTap: () {
                setState(() {
                  _selectedSection = 'dispatched';
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE7ECF3),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A101828),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Color(0xFF98A2B3),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF475467),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusWiseSection() {
    final List<Map<String, dynamic>> statuses =
        _asMapList(
      _selectedSummary['status_wise'],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        22,
        16,
        24,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Status-wise Summary',
                  style: TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F0FF),
                  borderRadius:
                      BorderRadius.circular(50),
                ),
                child: Text(
                  '${statuses.length} statuses',
                  style: const TextStyle(
                    color: Color(0xFF2368F5),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (statuses.isEmpty)
            _buildEmptyStatuses()
          else
            ...statuses.map(
              (Map<String, dynamic> status) {
                return _buildStatusCard(status);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    Map<String, dynamic> item,
  ) {
    final String status =
        (item['status'] ?? 'Unknown Status')
            .toString();

    final Color statusColor =
        _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: const Color(0xFFE7ECF3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  _statusIcon(status),
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(
                    0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(50),
                ),
                child: Text(
                  '${_asInt(item['order_count'])} orders',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(
            height: 1,
            color: Color(0xFFEEF1F5),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildStatusMetric(
                  label: 'Amount',
                  value: _formatAmount(
                    item['total_amount'],
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 34,
                color: const Color(0xFFEEF1F5),
              ),
              Expanded(
                child: _buildStatusMetric(
                  label: 'Product Qty',
                  value:
                      '${_asInt(item['total_product_quantity'])}',
                ),
              ),
              Container(
                width: 1,
                height: 34,
                color: const Color(0xFFEEF1F5),
              ),
              Expanded(
                child: _buildStatusMetric(
                  label: 'Distinct',
                  value:
                      '${_asInt(item['total_distinct_products'])}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMetric({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF98A2B3),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                color: Color(0xFF344054),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    final List<Widget> chips = [];

    if (_startDate != null &&
        _endDate != null) {
      chips.add(
        _buildFilterChip(
          label:
              '${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM').format(_endDate!)}',
          icon: Icons.calendar_month_rounded,
          onDeleted: () {
            setState(() {
              _startDate = null;
              _endDate = null;
            });

            _fetchShippingSummary();
          },
        ),
      );
    }

    if (_productIdController.text
        .trim()
        .isNotEmpty) {
      chips.add(
        _buildFilterChip(
          label:
              'Product ${_productIdController.text.trim()}',
          icon: Icons.inventory_2_outlined,
          onDeleted: () {
            setState(() {
              _productIdController.clear();
            });

            _fetchShippingSummary();
          },
        ),
      );
    }

    if (_selectedCustomerId != null) {
      chips.add(
        _buildFilterChip(
          label: _selectedCustomerName(),
          icon: Icons.person_outline_rounded,
          onDeleted: () {
            setState(() {
              _selectedCustomerId = null;
            });

            _fetchShippingSummary();
          },
        ),
      );
    }

    if (_selectedStaffId != null) {
      chips.add(
        _buildFilterChip(
          label: _selectedStaffName(),
          icon: Icons.badge_outlined,
          onDeleted: () {
            setState(() {
              _selectedStaffId = null;
            });

            _fetchShippingSummary();
          },
        ),
      );
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 8),
        itemBuilder: (
          BuildContext context,
          int index,
        ) {
          return chips[index];
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onDeleted,
  }) {
    return Container(
      padding: const EdgeInsets.only(
        left: 10,
        right: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F0FF),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: const Color(0xFFC9D8FF),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: const Color(0xFF2368F5),
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: 150),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF2368F5),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: onDeleted,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints.tightFor(
              width: 30,
              height: 30,
            ),
            icon: const Icon(
              Icons.close_rounded,
              color: Color(0xFF2368F5),
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStatuses() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 34,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE7ECF3),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: Color(0xFF98A2B3),
            size: 42,
          ),
          SizedBox(height: 12),
          Text(
            'No status data available',
            style: TextStyle(
              color: Color(0xFF344054),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Try changing the selected filters.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF98A2B3),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF2368F5),
            ),
            SizedBox(height: 14),
            Text(
              'Loading shipping summary...',
              style: TextStyle(
                color: Color(0xFF667085),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFF3C7C9),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE7E8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFE5484D),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Unable to load summary',
                  style: TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ??
                      'Something went wrong.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: _fetchShippingSummary,
                  icon: const Icon(
                    Icons.refresh_rounded,
                  ),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF2368F5),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Expanded(
      child: RefreshIndicator(
        color: const Color(0xFF2368F5),
        onRefresh: _fetchShippingSummary,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            _buildActiveFilters(),
            _buildSectionSelector(),
            _buildHeroSummary(),
            _buildQuickSummaryGrid(),
            _buildStatusWiseSection(),
          ],
        ),
      ),
    );
  }

    Future<String> _getDepartmentFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return (prefs.getString('department') ??
            prefs.getString('dep') ??
            prefs.getString('role') ??
            '')
        .trim();
  }

Future<void> _navigateBack() async {
    final String department = await _getDepartmentFromPrefs();

    if (!mounted) return;

    final String normalizedDepartment = department.toUpperCase();
    late final Widget destination;

    switch (normalizedDepartment) {
      case 'BDO':
        destination = bdo_dashbord();
        break;
      case 'BDM':
        destination = bdm_dashbord();
        break;
      case 'WAREHOUSE':
        destination = WarehouseDashboard();
        break;
      case 'WAREHOUSE ADMIN':
        destination = WarehouseAdmin();
        break;
      case 'CEO':
      case 'COO':
        destination = ceo_dashboard();
        break;
      case 'CSO':
        destination = cso_dashboard();
        break;
      default:
        destination = dashboard();
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => destination,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F9FC),
      appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: IconButton(
              tooltip: 'Back',
              onPressed: _navigateBack,
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.black,
                size: 21,
              ),
            ),
          ),
        elevation: 0,
        backgroundColor:
            const Color(0xFFF7F9FC),
        foregroundColor:
            const Color(0xFF172033),
        surfaceTintColor:
            Colors.transparent,
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Shipping Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Order and product dispatch analytics',
              style: TextStyle(
                color: Color(0xFF667085),
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading
                ? null
                : _fetchShippingSummary,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Filters',
                onPressed: _showFilterSheet,
                icon: const Icon(
                  Icons.tune_rounded,
                ),
              ),
              if (_startDate != null ||
                  _endDate != null ||
                  _selectedCustomerId != null ||
                  _selectedStaffId != null ||
                  _productIdController.text
                      .trim()
                      .isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration:
                        const BoxDecoration(
                      color: Color(0xFFE5484D),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                14,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                textInputAction:
                    TextInputAction.search,
                onSubmitted: (_) {
                  _fetchShippingSummary();
                },
                decoration: InputDecoration(
                  hintText:
                      'Search invoice, customer or product...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF98A2B3),
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF667085),
                  ),
                  suffixIcon:
                      _searchController.text
                              .trim()
                              .isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                setState(() {
                                  _searchController
                                      .clear();
                                });

                                _fetchShippingSummary();
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                              ),
                            ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(
                      color: Color(0xFFE4E7EC),
                    ),
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(
                      color: Color(0xFFE4E7EC),
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(
                      color: Color(0xFF2368F5),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              _buildLoadingState()
            else if (_errorMessage != null)
              _buildErrorState()
            else
              _buildContent(),
          ],
        ),
      ),
    );
  }
}