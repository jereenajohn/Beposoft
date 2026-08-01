import 'dart:async';
import 'dart:convert';

import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/update_recipt.dart';
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

class order_recipt_Report extends StatefulWidget {
  const order_recipt_Report({super.key});

  @override
  State<order_recipt_Report> createState() => _order_recipt_ReportState();
}

class _order_recipt_ReportState extends State<order_recipt_Report> {
  static const Color _primaryColor = Color(0xFF0C50A3);

  final TextEditingController searchController = TextEditingController();

  Timer? _searchDebounce;

  List<Map<String, dynamic>> salesReportList = [];
  List<Map<String, dynamic>> bank = [];
  List<Map<String, dynamic>> customer = [];
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> staff = [];

  Map<String, dynamic>? selectedOrder;
  Map<String, dynamic>? selectedCreatedBy;

  bool isLoading = false;
  bool isFilterDataLoading = false;
  String? errorMessage;

  int currentPage = 1;
  int totalPages = 1;
  int totalReceipts = 0;
  int pageSize = 50;
  bool hasNextPage = false;
  bool hasPreviousPage = false;

  double currentPageAmount = 0.0;

  int? selectedCustomerId;
  int? selectedBankId;
  DateTime? startDate;
  DateTime? endDate;

  bool get hasActiveFilters =>
      searchController.text.trim().isNotEmpty ||
      selectedOrder != null ||
      selectedCreatedBy != null ||
      selectedCustomerId != null ||
      selectedBankId != null ||
      startDate != null ||
      endDate != null;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      getbank(),
      getcustomer(),
      fetchOrderData(),
      getstaff(),
    ]);

    await getreciptReport(page: 1);
  }

  Future<String?> getTokenFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<void> getbank() async {
    final String? token = await getTokenFromPrefs();

    if (token == null || token.isEmpty) {
      return;
    }

    if (mounted) {
      setState(() {
        isFilterDataLoading = true;
      });
    }

    try {
      final http.Response response = await http.get(
        Uri.parse('$api/api/banks/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        debugPrint('Bank fetch failed: ${response.statusCode} ${response.body}');
        return;
      }

      final dynamic parsed = jsonDecode(response.body);
      final List<dynamic> bankData = parsed is Map<String, dynamic>
          ? (parsed['data'] as List<dynamic>? ?? <dynamic>[])
          : <dynamic>[];

      final List<Map<String, dynamic>> bankList = bankData
          .whereType<Map<String, dynamic>>()
          .map(
            (Map<String, dynamic> item) => {
              'id': item['id'],
              'name': item['name']?.toString() ?? '',
              'branch': item['branch']?.toString() ?? '',
            },
          )
          .toList();

      if (!mounted) return;

      setState(() {
        bank = bankList;
      });
    } catch (error, stackTrace) {
      debugPrint('Error fetching banks: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (mounted) {
        setState(() {
          isFilterDataLoading = false;
        });
      }
    }
  }

  Future<void> getcustomer() async {
    final String? token = await getTokenFromPrefs();

    if (token == null || token.isEmpty) {
      return;
    }

    if (mounted) {
      setState(() {
        isFilterDataLoading = true;
      });
    }

    try {
      final http.Response response = await http.get(
        Uri.parse('$api/api/customers/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        debugPrint(
          'Customer fetch failed: ${response.statusCode} ${response.body}',
        );
        return;
      }

      final dynamic parsed = jsonDecode(response.body);

      List<dynamic> customerData = <dynamic>[];

      if (parsed is Map<String, dynamic>) {
        final dynamic rawData = parsed['data'];

        if (rawData is List<dynamic>) {
          customerData = rawData;
        } else if (rawData is Map<String, dynamic>) {
          final dynamic nestedResults =
              rawData['results'] ?? rawData['data'] ?? rawData['customers'];

          if (nestedResults is List<dynamic>) {
            customerData = nestedResults;
          }
        } else if (parsed['results'] is List<dynamic>) {
          customerData = parsed['results'] as List<dynamic>;
        }
      }

      final List<Map<String, dynamic>> customerList = customerData
          .whereType<Map<String, dynamic>>()
          .map(
            (Map<String, dynamic> item) => {
              'id': item['id'],
              'name': item['name']?.toString() ?? '',
              'created_at': item['created_at']?.toString() ?? '',
            },
          )
          .toList();

      if (!mounted) return;

      setState(() {
        customer = customerList;
      });
    } catch (error, stackTrace) {
      debugPrint('Error fetching customers: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (mounted) {
        setState(() {
          isFilterDataLoading = false;
        });
      }
    }
  }


  Future<List<Map<String, dynamic>>> fetchOrderData({
    String searchQuery = '',
    int page = 1,
    bool updateState = true,
  }) async {
    final String? token = await getTokenFromPrefs();

    if (token == null || token.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    try {
      final Uri uri = Uri.parse('$api/api/orders/').replace(
        queryParameters: <String, String>{
          'page': page.toString(),
          if (searchQuery.trim().isNotEmpty)
            'search': searchQuery.trim(),
        },
      );

      final http.Response response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        debugPrint(
          'Order fetch failed: ${response.statusCode} ${response.body}',
        );
        return <Map<String, dynamic>>[];
      }

      final dynamic parsed = jsonDecode(response.body);
      final dynamic results = parsed is Map<String, dynamic>
          ? parsed['results']
          : null;

      List<dynamic> orderData = <dynamic>[];

      if (results is Map<String, dynamic>) {
        final dynamic nested =
            results['results'] ?? results['data'] ?? <dynamic>[];
        if (nested is List<dynamic>) {
          orderData = nested;
        }
      } else if (results is List<dynamic>) {
        orderData = results;
      }

      final List<Map<String, dynamic>> newOrders = orderData
          .whereType<Map<String, dynamic>>()
          .map(
            (Map<String, dynamic> item) => {
              'id': item['id'],
              'invoice': item['invoice']?.toString() ?? '',
              'manage_staff': item['manage_staff']?.toString() ?? '',
              'customer': item['customer'],
              'customer_name': item['customer_name']?.toString() ??
                  item['billing_address']?['name']?.toString() ??
                  '',
              'status': item['status']?.toString() ?? '',
              'total_amount': item['total_amount'],
              'order_date': item['order_date']?.toString() ?? '',
            },
          )
          .toList();

      if (updateState && mounted) {
        setState(() {
          orders = newOrders;
        });
      }

      return newOrders;
    } catch (error, stackTrace) {
      debugPrint('Error fetching orders: $error');
      debugPrintStack(stackTrace: stackTrace);
      return <Map<String, dynamic>>[];
    }
  }

  Future<List<Map<String, dynamic>>> getstaff({
    String searchQuery = '',
    int page = 1,
    bool updateState = true,
  }) async {
    final String? token = await getTokenFromPrefs();

    if (token == null || token.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    try {
      final Uri uri = Uri.parse('$api/api/get/staffs/').replace(
        queryParameters: <String, String>{
          'page': page.toString(),
          if (searchQuery.trim().isNotEmpty)
            'search': searchQuery.trim(),
        },
      );

      final http.Response response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        debugPrint(
          'Staff fetch failed: ${response.statusCode} ${response.body}',
        );
        return <Map<String, dynamic>>[];
      }

      final dynamic parsed = jsonDecode(response.body);
      final dynamic results = parsed is Map<String, dynamic>
          ? parsed['results']
          : null;

      List<dynamic> staffData = <dynamic>[];

      if (results is Map<String, dynamic>) {
        final dynamic nested =
            results['data'] ?? results['results'] ?? <dynamic>[];
        if (nested is List<dynamic>) {
          staffData = nested;
        }
      } else if (results is List<dynamic>) {
        staffData = results;
      }

      final List<Map<String, dynamic>> newStaff = staffData
          .whereType<Map<String, dynamic>>()
          .map(
            (Map<String, dynamic> item) => {
              'id': item['id'],
              'eid': item['eid']?.toString() ?? '',
              'name': item['name']?.toString() ?? '',
              'username': item['username']?.toString() ?? '',
              'email': item['email']?.toString() ?? '',
              'department_name':
                  item['department_name']?.toString() ?? '',
              'designation': item['designation']?.toString() ?? '',
            },
          )
          .toList();

      if (updateState && mounted) {
        setState(() {
          staff = newStaff;
        });
      }

      return newStaff;
    } catch (error, stackTrace) {
      debugPrint('Error fetching staff: $error');
      debugPrintStack(stackTrace: stackTrace);
      return <Map<String, dynamic>>[];
    }
  }

  Future<Map<String, dynamic>?> _showSearchablePicker({
    required String title,
    required String searchHint,
    required IconData icon,
    required String Function(Map<String, dynamic>) titleBuilder,
    required String Function(Map<String, dynamic>) subtitleBuilder,
    List<Map<String, dynamic>> initialItems = const [],
    Future<List<Map<String, dynamic>>> Function(String query)? remoteSearch,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext pickerContext) {
        return _SearchablePickerSheet(
          title: title,
          searchHint: searchHint,
          icon: icon,
          primaryColor: _primaryColor,
          initialItems: initialItems,
          remoteSearch: remoteSearch,
          titleBuilder: titleBuilder,
          subtitleBuilder: subtitleBuilder,
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _pickOrder() {
    return _showSearchablePicker(
      title: 'Select Order',
      searchHint: 'Search invoice, customer or order...',
      icon: Icons.receipt_long_outlined,
      initialItems: orders,
      remoteSearch: (String query) => fetchOrderData(
        searchQuery: query,
        updateState: false,
      ),
      titleBuilder: (Map<String, dynamic> item) =>
          item['invoice']?.toString().isNotEmpty == true
              ? item['invoice'].toString()
              : 'Order #${item['id']}',
      subtitleBuilder: (Map<String, dynamic> item) {
        final List<String> values = [
          item['customer_name']?.toString() ?? '',
          item['status']?.toString() ?? '',
          item['order_date']?.toString() ?? '',
        ].where((String value) => value.trim().isNotEmpty).toList();

        return values.join(' • ');
      },
    );
  }

  Future<Map<String, dynamic>?> _pickStaff() {
    return _showSearchablePicker(
      title: 'Select Created By',
      searchHint: 'Search staff name, EID or email...',
      icon: Icons.badge_outlined,
      initialItems: staff,
      remoteSearch: (String query) => getstaff(
        searchQuery: query,
        updateState: false,
      ),
      titleBuilder: (Map<String, dynamic> item) =>
          item['name']?.toString() ?? '',
      subtitleBuilder: (Map<String, dynamic> item) {
        final List<String> values = [
          item['eid']?.toString() ?? '',
          item['department_name']?.toString() ?? '',
          item['email']?.toString() ?? '',
        ].where((String value) => value.trim().isNotEmpty).toList();

        return values.join(' • ');
      },
    );
  }

  Future<Map<String, dynamic>?> _pickCustomer() {
    return _showSearchablePicker(
      title: 'Select Customer',
      searchHint: 'Search customer name...',
      icon: Icons.person_outline,
      initialItems: customer,
      titleBuilder: (Map<String, dynamic> item) =>
          item['name']?.toString() ?? '',
      subtitleBuilder: (Map<String, dynamic> item) =>
          'Customer ID: ${item['id']}',
    );
  }

  Future<Map<String, dynamic>?> _pickBank() {
    return _showSearchablePicker(
      title: 'Select Bank',
      searchHint: 'Search bank or branch...',
      icon: Icons.account_balance_outlined,
      initialItems: bank,
      titleBuilder: (Map<String, dynamic> item) =>
          item['name']?.toString() ?? '',
      subtitleBuilder: (Map<String, dynamic> item) =>
          item['branch']?.toString() ?? '',
    );
  }

  Widget _buildPickerField({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: InputDecorator(
        decoration: _inputDecoration(
          label: label,
          hint: hint,
          icon: icon,
        ).copyWith(
          suffixIcon: value != null && value.trim().isNotEmpty
              ? IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                )
              : const Icon(Icons.keyboard_arrow_down),
        ),
        child: Text(
          value?.trim().isNotEmpty == true ? value! : hint,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: value?.trim().isNotEmpty == true
                ? Colors.black87
                : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Future<void> getreciptReport({
    int? page,
    bool showLoader = true,
  }) async {
    if (isLoading) {
      return;
    }

    final int requestedPage = page ?? currentPage;
    final String? token = await getTokenFromPrefs();

    if (token == null || token.isEmpty) {
      _showMessage('Authentication token not found. Please log in again.');
      return;
    }

    if (mounted) {
      setState(() {
        isLoading = showLoader;
        errorMessage = null;
      });
    }

    try {
      final Map<String, String> queryParameters = <String, String>{
        'page': requestedPage.toString(),
        'search': searchController.text.trim(),
        'order': selectedOrder?['id']?.toString() ?? '',
        'customer': selectedCustomerId?.toString() ?? '',
        'bank': selectedBankId?.toString() ?? '',
        'created_by': selectedCreatedBy?['id']?.toString() ?? '',
        'start_date':
            startDate == null ? '' : DateFormat('yyyy-MM-dd').format(startDate!),
        'end_date':
            endDate == null ? '' : DateFormat('yyyy-MM-dd').format(endDate!),
      };

      queryParameters.removeWhere(
        (String key, String value) => value.trim().isEmpty,
      );

      final Uri uri = Uri.parse(
        '$api/api/orderreceipt/view/get/',
      ).replace(queryParameters: queryParameters);

      debugPrint('GET $uri');

      final http.Response response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Receipt fetch failed (${response.statusCode}): ${response.body}',
        );
      }

      final dynamic parsed = jsonDecode(response.body);

      if (parsed is! Map<String, dynamic>) {
        throw const FormatException('Invalid receipt response format.');
      }

      final int count = _parseInt(parsed['count']);
      final String? nextUrl = parsed['next']?.toString();
      final String? previousUrl = parsed['previous']?.toString();

      final dynamic outerResults = parsed['results'];
      List<dynamic> receiptData = <dynamic>[];

      if (outerResults is Map<String, dynamic>) {
        final dynamic rawData =
            outerResults['data'] ?? outerResults['results'] ?? <dynamic>[];

        if (rawData is List<dynamic>) {
          receiptData = rawData;
        }
      } else if (outerResults is List<dynamic>) {
        receiptData = outerResults;
      }

      final List<Map<String, dynamic>> receiptList = receiptData
          .whereType<Map<String, dynamic>>()
          .map(_mapReceipt)
          .toList();

      final int calculatedPageSize =
          receiptList.isNotEmpty ? receiptList.length : pageSize;

      final int calculatedTotalPages = count == 0
          ? 1
          : ((count + calculatedPageSize - 1) ~/ calculatedPageSize);

      final double pageAmount = receiptList.fold<double>(
        0.0,
        (double sum, Map<String, dynamic> receipt) =>
            sum + _parseDouble(receipt['amount']),
      );

      if (!mounted) return;

      setState(() {
        currentPage = requestedPage;
        pageSize = calculatedPageSize;
        totalReceipts = count;
        totalPages = calculatedTotalPages;
        hasNextPage = nextUrl != null && nextUrl.isNotEmpty;
        hasPreviousPage = previousUrl != null && previousUrl.isNotEmpty;
        currentPageAmount = pageAmount;
        salesReportList = receiptList;
        errorMessage = null;
      });
    } catch (error, stackTrace) {
      debugPrint('Error fetching receipt report: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        salesReportList = [];
        currentPageAmount = 0.0;
        errorMessage = 'Unable to load receipt report.';
      });

      _showMessage('Unable to load receipt report.');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _mapReceipt(Map<String, dynamic> reportData) {
    return {
      'type': 'Advance Receipt',
      'id': reportData['id'],
      'payment_receipt': reportData['payment_receipt']?.toString() ?? '',
      'transactionID': reportData['transactionID']?.toString() ?? '',
      'amount': _parseDouble(reportData['amount']),
      'received_at': reportData['received_at']?.toString() ?? '',
      'order': reportData['order'],
      'invoice': reportData['order_name']?.toString() ?? '',
      'customer': reportData['customer'],
      'customer_name': reportData['customer_name']?.toString() ?? '',
      'bank': reportData['bank'],
      'bank_name': reportData['bank_name']?.toString() ?? '',
      'created_by': reportData['created_by'],
      'created_by_name': reportData['created_by_name']?.toString() ?? '',
      'remark': reportData['remark']?.toString() ?? '',
    };
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 550), () {
      getreciptReport(page: 1);
    });
  }

  Future<void> _openFilters() async {
    Map<String, dynamic>? temporaryOrder = selectedOrder;
    Map<String, dynamic>? temporaryCreatedBy = selectedCreatedBy;
    int? temporaryCustomerId = selectedCustomerId;
    int? temporaryBankId = selectedBankId;
    DateTime? temporaryStartDate = startDate;
    DateTime? temporaryEndDate = endDate;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter setModalState,
          ) {
            Map<String, dynamic>? selectedCustomerData;
            Map<String, dynamic>? selectedBankData;

            for (final Map<String, dynamic> item in customer) {
              if (_parseInt(item['id']) == temporaryCustomerId) {
                selectedCustomerData = item;
                break;
              }
            }

            for (final Map<String, dynamic> item in bank) {
              if (_parseInt(item['id']) == temporaryBankId) {
                selectedBankData = item;
                break;
              }
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.92,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 14,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 46,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Receipt Filters',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildPickerField(
                          label: 'Order',
                          hint: 'Search and select order',
                          icon: Icons.receipt_long_outlined,
                          value: temporaryOrder?['invoice']?.toString(),
                          onTap: () async {
                            final Map<String, dynamic>? result =
                                await _pickOrder();

                            if (!sheetContext.mounted) return;

                            if (result != null) {
                              setModalState(() {
                                temporaryOrder = result;
                              });
                            }
                          },
                          onClear: () {
                            setModalState(() {
                              temporaryOrder = null;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildPickerField(
                          label: 'Customer',
                          hint: 'Search and select customer',
                          icon: Icons.person_outline,
                          value: selectedCustomerData?['name']?.toString(),
                          onTap: () async {
                            final Map<String, dynamic>? result =
                                await _pickCustomer();

                            if (!sheetContext.mounted) return;

                            if (result != null) {
                              setModalState(() {
                                temporaryCustomerId =
                                    _parseInt(result['id']);
                              });
                            }
                          },
                          onClear: () {
                            setModalState(() {
                              temporaryCustomerId = null;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildPickerField(
                          label: 'Bank',
                          hint: 'Search and select bank',
                          icon: Icons.account_balance_outlined,
                          value: selectedBankData?['name']?.toString(),
                          onTap: () async {
                            final Map<String, dynamic>? result =
                                await _pickBank();

                            if (!sheetContext.mounted) return;

                            if (result != null) {
                              setModalState(() {
                                temporaryBankId = _parseInt(result['id']);
                              });
                            }
                          },
                          onClear: () {
                            setModalState(() {
                              temporaryBankId = null;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildPickerField(
                          label: 'Created By',
                          hint: 'Search and select staff',
                          icon: Icons.badge_outlined,
                          value:
                              temporaryCreatedBy?['name']?.toString(),
                          onTap: () async {
                            final Map<String, dynamic>? result =
                                await _pickStaff();

                            if (!sheetContext.mounted) return;

                            if (result != null) {
                              setModalState(() {
                                temporaryCreatedBy = result;
                              });
                            }
                          },
                          onClear: () {
                            setModalState(() {
                              temporaryCreatedBy = null;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            final DateTimeRange? picked =
                                await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                              initialDateRange: temporaryStartDate != null &&
                                      temporaryEndDate != null
                                  ? DateTimeRange(
                                      start: temporaryStartDate!,
                                      end: temporaryEndDate!,
                                    )
                                  : null,
                            );

                            if (!sheetContext.mounted) return;

                            if (picked != null) {
                              setModalState(() {
                                temporaryStartDate = picked.start;
                                temporaryEndDate = picked.end;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: _inputDecoration(
                              label: 'Received Date Range',
                              hint: 'Select start and end date',
                              icon: Icons.date_range_outlined,
                            ).copyWith(
                              suffixIcon: temporaryStartDate != null
                                  ? IconButton(
                                      onPressed: () {
                                        setModalState(() {
                                          temporaryStartDate = null;
                                          temporaryEndDate = null;
                                        });
                                      },
                                      icon: const Icon(Icons.close),
                                    )
                                  : const Icon(
                                      Icons.keyboard_arrow_down,
                                    ),
                            ),
                            child: Text(
                              temporaryStartDate != null &&
                                      temporaryEndDate != null
                                  ? '${DateFormat('dd MMM yyyy').format(temporaryStartDate!)} - '
                                      '${DateFormat('dd MMM yyyy').format(temporaryEndDate!)}'
                                  : 'Select date range',
                              style: TextStyle(
                                color: temporaryStartDate == null
                                    ? Colors.grey.shade600
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setModalState(() {
                                    temporaryOrder = null;
                                    temporaryCreatedBy = null;
                                    temporaryCustomerId = null;
                                    temporaryBankId = null;
                                    temporaryStartDate = null;
                                    temporaryEndDate = null;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Clear'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    selectedOrder = temporaryOrder;
                                    selectedCreatedBy =
                                        temporaryCreatedBy;
                                    selectedCustomerId =
                                        temporaryCustomerId;
                                    selectedBankId = temporaryBankId;
                                    startDate = temporaryStartDate;
                                    endDate = temporaryEndDate;
                                  });

                                  Navigator.pop(sheetContext);
                                  getreciptReport(page: 1);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Apply Filters'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _clearAllFilters() async {
    _searchDebounce?.cancel();
    searchController.clear();

    setState(() {
      selectedOrder = null;
      selectedCreatedBy = null;
      selectedCustomerId = null;
      selectedBankId = null;
      startDate = null;
      endDate = null;
    });

    await getreciptReport(page: 1);
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF7F9FC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _primaryColor,
          width: 1.5,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _navigateBack() async {
    final String? dep = await getdepFromPrefs();

    if (!mounted) return;

    Widget destination;

    switch (dep) {
      case 'BDO':
        destination = bdo_dashbord();
        break;
      case 'BDM':
        destination = bdm_dashbord();
        break;
      case 'COO':
      case 'CEO':
        destination = ceo_dashboard();
        break;
      case 'CSO':
        destination = cso_dashboard();
        break;
      case 'warehouse':
        destination = WarehouseDashboard();
        break;
      case 'Warehouse Admin':
        destination = WarehouseAdmin();
        break;
      default:
        destination = dashboard();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  Widget _buildRow(String label, dynamic value) {
    final String displayValue = value?.toString().trim().isNotEmpty == true
        ? value.toString()
        : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              displayValue,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(Map<String, dynamic> reportData) {
    final double amount = _parseDouble(reportData['amount']);

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.fromLTRB(14, 7, 14, 7),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reportData['payment_receipt']?.toString() ??
                            'Receipt',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        reportData['invoice']?.toString().isNotEmpty == true
                            ? reportData['invoice'].toString()
                            : 'No invoice',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  NumberFormat.currency(
                    locale: 'en_IN',
                    symbol: '₹',
                    decimalDigits: 2,
                  ).format(amount),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 10),
            _buildRow('Customer', reportData['customer_name']),
            _buildRow('Transaction ID', reportData['transactionID']),
            _buildRow('Received At', reportData['received_at']),
            _buildRow('Bank', reportData['bank_name']),
            _buildRow('Created By', reportData['created_by_name']),
            if (reportData['remark']?.toString().trim().isNotEmpty == true)
              _buildRow('Remark', reportData['remark']),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => update_recipt(
                        id: reportData['id'],
                      ),
                    ),
                  );

                  if (!mounted) return;

                  await getreciptReport(
                    page: currentPage,
                    showLoader: false,
                  );
                },
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('View'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous page',
            onPressed: !isLoading && hasPreviousPage && currentPage > 1
                ? () => getreciptReport(page: currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Page $currentPage of $totalPages',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalReceipts receipt${totalReceipts == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Next page',
            onPressed: !isLoading && hasNextPage
                ? () => getreciptReport(page: currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Material(
      elevation: 12,
      color: _primaryColor,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          decoration: const BoxDecoration(
            color: _primaryColor,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Receipt Summary',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    'Page $currentPage',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.80),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text(
                    'Total filtered receipts',
                    style: TextStyle(color: Colors.white),
                  ),
                  const Spacer(),
                  Text(
                    NumberFormat.decimalPattern('en_IN').format(totalReceipts),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Text(
                    'Current page amount',
                    style: TextStyle(color: Colors.white),
                  ),
                  const Spacer(),
                  Text(
                    NumberFormat.currency(
                      locale: 'en_IN',
                      symbol: '₹',
                      decimalDigits: 2,
                    ).format(currentPageAmount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading && salesReportList.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null && salesReportList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 54,
                color: Colors.grey.shade500,
              ),
              const SizedBox(height: 14),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => getreciptReport(page: currentPage),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (salesReportList.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => getreciptReport(page: 1, showLoader: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.48,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 58,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'No receipts found',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hasActiveFilters
                            ? 'Try changing or clearing the applied filters.'
                            : 'Receipt records will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (hasActiveFilters) ...[
                        const SizedBox(height: 14),
                        TextButton.icon(
                          onPressed: _clearAllFilters,
                          icon: const Icon(Icons.filter_alt_off_outlined),
                          label: const Text('Clear filters'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => getreciptReport(
        page: currentPage,
        showLoader: false,
      ),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 10),
        itemCount: salesReportList.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == salesReportList.length) {
            return _buildPagination();
          }

          return _buildReceiptCard(salesReportList[index]);
        },
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
        backgroundColor: const Color(0xFFF4F7FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _navigateBack,
          ),
          title: const Text(
            'Receipt Report',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          actions: [
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  tooltip: 'Filters',
                  onPressed: _openFilters,
                  icon: const Icon(Icons.tune),
                ),
                if (hasActiveFilters)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: isLoading
                  ? null
                  : () => getreciptReport(page: currentPage),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    onChanged: _onSearchChanged,
                    onSubmitted: (_) => getreciptReport(page: 1),
                    decoration: InputDecoration(
                      hintText:
                          'Search receipt, invoice, customer, transaction...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                searchController.clear();
                                setState(() {});
                                getreciptReport(page: 1);
                              },
                              icon: const Icon(Icons.close),
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF4F7FB),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (hasActiveFilters) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Filters are applied',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _clearAllFilters,
                          icon: const Icon(
                            Icons.filter_alt_off_outlined,
                            size: 17,
                          ),
                          label: const Text('Clear all'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (isLoading && salesReportList.isNotEmpty)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _buildBody()),
            _buildSummaryCard(),
          ],
        ),
      ),
    );
  }
}


class _SearchablePickerSheet extends StatefulWidget {
  const _SearchablePickerSheet({
    required this.title,
    required this.searchHint,
    required this.icon,
    required this.primaryColor,
    required this.initialItems,
    required this.titleBuilder,
    required this.subtitleBuilder,
    this.remoteSearch,
  });

  final String title;
  final String searchHint;
  final IconData icon;
  final Color primaryColor;
  final List<Map<String, dynamic>> initialItems;
  final Future<List<Map<String, dynamic>>> Function(String query)? remoteSearch;
  final String Function(Map<String, dynamic>) titleBuilder;
  final String Function(Map<String, dynamic>) subtitleBuilder;

  @override
  State<_SearchablePickerSheet> createState() =>
      _SearchablePickerSheetState();
}

class _SearchablePickerSheetState extends State<_SearchablePickerSheet> {
  late final TextEditingController _searchController;
  Timer? _debounce;

  late List<Map<String, dynamic>> _displayedItems;
  bool _isLoading = false;
  int _requestVersion = 0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _displayedItems =
        List<Map<String, dynamic>>.from(widget.initialItems);
  }

  @override
  void dispose() {
    _requestVersion++;
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {});

    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => _performSearch(query),
    );
  }

  Future<void> _performSearch(String query) async {
    final int requestVersion = ++_requestVersion;
    final String normalizedQuery = query.trim().toLowerCase();

    if (widget.remoteSearch == null) {
      final List<Map<String, dynamic>> filteredItems =
          widget.initialItems.where((Map<String, dynamic> item) {
        final String title = widget.titleBuilder(item).toLowerCase();
        final String subtitle =
            widget.subtitleBuilder(item).toLowerCase();

        return title.contains(normalizedQuery) ||
            subtitle.contains(normalizedQuery);
      }).toList();

      if (!mounted || requestVersion != _requestVersion) return;

      setState(() {
        _displayedItems = filteredItems;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final List<Map<String, dynamic>> fetchedItems =
          await widget.remoteSearch!(query.trim());

      if (!mounted || requestVersion != _requestVersion) return;

      setState(() {
        _displayedItems = fetchedItems;
      });
    } catch (error, stackTrace) {
      debugPrint('Picker search failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted || requestVersion != _requestVersion) return;

      setState(() {
        _displayedItems = <Map<String, dynamic>>[];
      });
    } finally {
      if (mounted && requestVersion == _requestVersion) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    _requestVersion++;

    setState(() {
      _displayedItems =
          List<Map<String, dynamic>>.from(widget.initialItems);
      _isLoading = false;
    });

    if (widget.remoteSearch != null) {
      _performSearch('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight =
        MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: FractionallySizedBox(
        heightFactor: 0.82,
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 12, 12),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: _onSearchChanged,
                  onSubmitted: _performSearch,
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF4F7FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (_isLoading)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: _displayedItems.isEmpty && !_isLoading
                    ? Center(
                        child: Text(
                          'No results found',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(
                          12,
                          4,
                          12,
                          18,
                        ),
                        itemCount: _displayedItems.length,
                        separatorBuilder: (_, __) =>
                            Divider(color: Colors.grey.shade200),
                        itemBuilder: (
                          BuildContext context,
                          int index,
                        ) {
                          final Map<String, dynamic> item =
                              _displayedItems[index];
                          final String subtitle =
                              widget.subtitleBuilder(item);

                          return ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            leading: CircleAvatar(
                              backgroundColor:
                                  widget.primaryColor.withOpacity(0.10),
                              foregroundColor: widget.primaryColor,
                              child: Icon(widget.icon, size: 20),
                            ),
                            title: Text(
                              widget.titleBuilder(item),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: subtitle.isEmpty
                                ? null
                                : Text(
                                    subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                            onTap: () => Navigator.pop(context, item),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
