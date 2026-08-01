import 'dart:async';
import 'dart:convert';

import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/add_attribute.dart';
import 'package:beposoft/pages/ACCOUNTS/add_bank.dart';
import 'package:beposoft/pages/ACCOUNTS/add_company.dart';
import 'package:beposoft/pages/ACCOUNTS/add_department.dart';
import 'package:beposoft/pages/ACCOUNTS/add_family.dart';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
import 'package:beposoft/pages/ACCOUNTS/add_state.dart';
import 'package:beposoft/pages/ACCOUNTS/add_supervisor.dart';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/customer.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/invoice_report.dart';
import 'package:beposoft/pages/ACCOUNTS/methods.dart';
import 'package:beposoft/pages/ACCOUNTS/update_recipt.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:beposoft/pages/api.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class recipt_Report extends StatefulWidget {
  const recipt_Report({super.key});

  @override
  State<recipt_Report> createState() => _recipt_ReportState();
}

class _recipt_ReportState extends State<recipt_Report> {
  List<Map<String, dynamic>> salesReportList = [];
  List<Map<String, dynamic>> allSalesReportList = [];

  double totalstock = 0.0;
  double totalsold = 0.0;
  double remaingitem = 0.0;
  double approvedAmount = 0.0;
  double rejectedBills = 0.0;
  double rejectedAmount = 0.0;

  int totalReceipts = 0;
  double totalAmount = 0.0;

  final TextEditingController searchController =
      TextEditingController();

  final ScrollController scrollController =
      ScrollController();

  Timer? searchDebounce;

  DateTime? selectedDate;
  DateTime? startDate;
  DateTime? endDate;

  bool isInitialLoading = false;
  bool isLoadingMore = false;
  bool hasMoreData = true;

  int currentPage = 1;
  int backendTotalCount = 0;

  String? nextPageUrl;

  final drower d = drower();

  List<Map<String, dynamic>> bank = [];
  List<Map<String, dynamic>> customer = [];
  List<Map<String, dynamic>> staff = [];
  List<Map<String, dynamic>> orders = [];

  String? selectedCreatedById;
  String? selectedBankId;
  String? selectedCustomerId;
  String? selectedOrderId;

  bool isFilterDataLoading = false;

  @override
  void initState() {
    super.initState();

    scrollController.addListener(_handlePaginationScroll);

    getreciptReport(
      reset: true,
    );

    getbank();
    getcustomer();
    getstaff();
    fetchOrderData();
  }

  void _handlePaginationScroll() {
    if (!scrollController.hasClients) {
      return;
    }

    final ScrollPosition position =
        scrollController.position;

    if (position.pixels >=
        position.maxScrollExtent - 300) {
      if (!isInitialLoading &&
          !isLoadingMore &&
          hasMoreData) {
        getreciptReport();
      }
    }
  }

  Future<void> logout() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.remove('userId');
    await prefs.remove('token');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logged out successfully'),
        duration: Duration(seconds: 2),
      ),
    );

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => login(),
      ),
    );
  }

  void _updateTotals() {
    int tempTotalReceipts = 0;
    double tempTotalAmount = 0.0;

    for (final Map<String, dynamic> reportData
        in salesReportList) {
      tempTotalReceipts++;

      tempTotalAmount +=
          _parseDouble(reportData['amount']);
    }

    if (!mounted) return;

    setState(() {
      totalReceipts = tempTotalReceipts;
      totalAmount = tempTotalAmount;
    });
  }

  double _parseDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString(),
        ) ??
        0.0;
  }

  Future<String?> getTokenFromPrefs() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getString('department');
  }

  Future<void> getbank() async {
    try {
      final String? token =
          await getTokenFromPrefs();

      if (token == null || token.isEmpty) {
        return;
      }

      final http.Response response =
          await http.get(
        Uri.parse('$api/api/banks/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        return;
      }

      final dynamic parsed =
          jsonDecode(response.body);

      final dynamic productsData =
          parsed is Map<String, dynamic>
              ? parsed['data']
              : null;

      if (productsData is! List) {
        return;
      }

      final List<Map<String, dynamic>>
          bankList = [];

      final Set<String> addedBankIds = {};

      for (final dynamic productData
          in productsData) {
        if (productData is! Map) {
          continue;
        }

        final Map<String, dynamic> bankData =
            Map<String, dynamic>.from(
          productData,
        );

        final String bankId =
            bankData['id']?.toString() ?? '';

        if (bankId.isEmpty ||
            addedBankIds.contains(bankId)) {
          continue;
        }

        addedBankIds.add(bankId);

        bankList.add({
          'id': bankData['id'],
          'name': bankData['name'] ?? '',
          'branch': bankData['branch'] ?? '',
        });
      }

      if (!mounted) return;

      setState(() {
        bank = bankList;
      });
    } catch (error) {
      debugPrint(
        'Bank loading error: $error',
      );
    }
  }

  Future<void> getcustomer() async {
    try {
      final String? token =
          await getTokenFromPrefs();

      if (token == null || token.isEmpty) {
        return;
      }

      final http.Response response =
          await http.get(
        Uri.parse('$api/api/customers/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load customer data',
        );
      }

      final dynamic parsed =
          jsonDecode(response.body);

      List<dynamic> productsData = [];

      if (parsed is Map<String, dynamic>) {
        if (parsed['data'] is List) {
          productsData =
              parsed['data'] as List<dynamic>;
        } else if (parsed['results'] is List) {
          productsData =
              parsed['results'] as List<dynamic>;
        }
      } else if (parsed is List) {
        productsData = parsed;
      }

      final Map<String, Map<String, dynamic>>
          uniqueCustomers = {};

      for (final dynamic productData
          in productsData) {
        if (productData is! Map) {
          continue;
        }

        final Map<String, dynamic>
            customerData =
            Map<String, dynamic>.from(
          productData,
        );

        final dynamic rawCustomerId =
            customerData['id'];

        if (rawCustomerId == null) {
          continue;
        }

        uniqueCustomers[
            rawCustomerId.toString()] = {
          'id': rawCustomerId,
          'name':
              customerData['name']?.toString() ??
                  '',
          'created_at':
              customerData['created_at'],
        };
      }

      if (!mounted) return;

      setState(() {
        customer =
            uniqueCustomers.values.toList();
      });
    } catch (error) {
      debugPrint(
        'Customer loading error: $error',
      );
    }
  }


  Future<void> getstaff() async {
    try {
      if (mounted) {
        setState(() {
          isFilterDataLoading = true;
        });
      }

      final String? token = await getTokenFromPrefs();

      if (token == null || token.isEmpty) {
        return;
      }

      final http.Response response = await http.get(
        Uri.parse('$api/api/get/staffs/').replace(
          queryParameters: const {
            'page': '1',
          },
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        debugPrint(
          'Staff fetch failed: ${response.statusCode} ${response.body}',
        );
        return;
      }

      final dynamic parsed = jsonDecode(response.body);

      List<dynamic> staffData = [];

      if (parsed is Map<String, dynamic>) {
        final dynamic results = parsed['results'];

        if (results is Map<String, dynamic> &&
            results['data'] is List) {
          staffData = results['data'] as List<dynamic>;
        } else if (results is List) {
          staffData = results;
        } else if (parsed['data'] is List) {
          staffData = parsed['data'] as List<dynamic>;
        }
      } else if (parsed is List) {
        staffData = parsed;
      }

      final Map<String, Map<String, dynamic>>
          uniqueStaff = {};

      for (final dynamic rawStaff in staffData) {
        if (rawStaff is! Map) {
          continue;
        }

        final Map<String, dynamic> staffDataMap =
            Map<String, dynamic>.from(rawStaff);

        final dynamic id = staffDataMap['id'];

        if (id == null) {
          continue;
        }

        uniqueStaff[id.toString()] = {
          'id': id,
          'name': staffDataMap['name']?.toString() ??
              staffDataMap['username']?.toString() ??
              '',
          'eid': staffDataMap['eid']?.toString() ?? '',
          'department_name':
              staffDataMap['department_name']?.toString() ?? '',
        };
      }

      if (!mounted) return;

      setState(() {
        staff = uniqueStaff.values.toList();
      });
    } catch (error) {
      debugPrint(
        'Staff loading error: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          isFilterDataLoading = false;
        });
      }
    }
  }

  Future<void> fetchOrderData() async {
    try {
      if (mounted) {
        setState(() {
          isFilterDataLoading = true;
        });
      }

      final String? token = await getTokenFromPrefs();

      if (token == null || token.isEmpty) {
        return;
      }

      final http.Response response = await http.get(
        Uri.parse('$api/api/orders/').replace(
          queryParameters: const {
            'page': '1',
          },
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        debugPrint(
          'Order fetch failed: ${response.statusCode} ${response.body}',
        );
        return;
      }

      final dynamic parsed = jsonDecode(response.body);

      List<dynamic> ordersData = [];

      if (parsed is Map<String, dynamic>) {
        final dynamic results = parsed['results'];

        if (results is Map<String, dynamic> &&
            results['results'] is List) {
          ordersData = results['results'] as List<dynamic>;
        } else if (results is List) {
          ordersData = results;
        } else if (parsed['data'] is List) {
          ordersData = parsed['data'] as List<dynamic>;
        }
      } else if (parsed is List) {
        ordersData = parsed;
      }

      final Map<String, Map<String, dynamic>>
          uniqueOrders = {};

      for (final dynamic rawOrder in ordersData) {
        if (rawOrder is! Map) {
          continue;
        }

        final Map<String, dynamic> orderData =
            Map<String, dynamic>.from(rawOrder);

        final dynamic id = orderData['id'];

        if (id == null) {
          continue;
        }

        String customerName = '';

        final dynamic customerData =
            orderData['customer'];

        if (customerData is Map) {
          customerName =
              customerData['name']?.toString() ??
                  customerData['customer_name']?.toString() ??
                  '';
        } else {
          customerName =
              orderData['customer_name']?.toString() ??
                  customerData?.toString() ??
                  '';
        }

        uniqueOrders[id.toString()] = {
          'id': id,
          'invoice':
              orderData['invoice']?.toString() ?? '',
          'customer_name': customerName,
        };
      }

      if (!mounted) return;

      setState(() {
        orders = uniqueOrders.values.toList();
      });
    } catch (error) {
      debugPrint(
        'Order loading error: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          isFilterDataLoading = false;
        });
      }
    }
  }

  Uri _buildReceiptUri({
    required int page,
  }) {
    final Map<String, String> queryParameters =
        {
      'page': page.toString(),
    };

    final String search =
        searchController.text.trim();

    if (search.isNotEmpty) {
      queryParameters['search'] = search;
    }

    if (selectedCreatedById != null &&
        selectedCreatedById!.isNotEmpty) {
      queryParameters['created_by'] =
          selectedCreatedById!;
    }

    if (selectedBankId != null &&
        selectedBankId!.isNotEmpty) {
      queryParameters['bank'] =
          selectedBankId!;
    }

    if (selectedCustomerId != null &&
        selectedCustomerId!.isNotEmpty) {
      queryParameters['customer'] =
          selectedCustomerId!;
    }

    if (selectedOrderId != null &&
        selectedOrderId!.isNotEmpty) {
      queryParameters['order'] =
          selectedOrderId!;
    }

    if (startDate != null) {
      queryParameters['start_date'] =
          DateFormat('yyyy-MM-dd').format(
        startDate!,
      );
    }

    if (endDate != null) {
      queryParameters['end_date'] =
          DateFormat('yyyy-MM-dd').format(
        endDate!,
      );
    }

    return Uri.parse(
      '$api/api/allreceipts/view/',
    ).replace(
      queryParameters: queryParameters,
    );
  }

  Future<void> getreciptReport({
    bool reset = false,
  }) async {
    if (reset) {
      currentPage = 1;
      nextPageUrl = null;
      hasMoreData = true;
    }

    if (isInitialLoading || isLoadingMore) {
      return;
    }

    if (!reset && !hasMoreData) {
      return;
    }

    if (!mounted) return;

    setState(() {
      if (reset) {
        isInitialLoading = true;
      } else {
        isLoadingMore = true;
      }
    });

    try {
      final String? token =
          await getTokenFromPrefs();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Authentication token not found',
        );
      }

      final Uri requestUri = _buildReceiptUri(
        page: currentPage,
      );

      debugPrint(
        'Receipt report URL: $requestUri',
      );

      final http.Response response =
          await http.get(
        requestUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch data. '
          'Status: ${response.statusCode}',
        );
      }

      final dynamic parsed =
          jsonDecode(response.body);

      if (parsed is! Map<String, dynamic>) {
        throw Exception(
          'Invalid receipt response format',
        );
      }

      final int responseCount =
          int.tryParse(
            parsed['count']?.toString() ?? '0',
          ) ??
          0;

      final String? responseNext =
          parsed['next']?.toString();

      final dynamic resultsData =
          parsed['results'];

      if (resultsData
          is! Map<String, dynamic>) {
        throw Exception(
          'Receipt results not found',
        );
      }

      final dynamic receiptsData =
          resultsData['receipts'];

      if (receiptsData is! List) {
        throw Exception(
          'Receipt list not found',
        );
      }

      final List<Map<String, dynamic>>
          receiptList = [];

      for (final dynamic rawReceipt
          in receiptsData) {
        if (rawReceipt is! Map) {
          continue;
        }

        final Map<String, dynamic>
            reportData =
            Map<String, dynamic>.from(
          rawReceipt,
        );

        final String receiptType =
            reportData['receipt_type']
                    ?.toString() ??
                'unknown';

        receiptList.add({
          'type': receiptType == 'advance'
              ? 'Advance Receipt'
              : receiptType == 'bank'
                  ? 'Bank Receipt'
                  : 'Payment Receipt',
          'id': reportData['id'],
          'receipt_type': receiptType,
          'payment_receipt':
              reportData['payment_receipt'] ??
                  '',
          'transactionID':
              reportData['transactionID'] ??
                  '',
          'amount': _parseDouble(
            reportData['amount'],
          ),
          'received_at':
              reportData['received_at'] ?? '',
          'bank': reportData['bank'],
          'bank_name':
              reportData['bank_name'] ?? '',
          'order': reportData['order'],
          'order_name':
              reportData['order_name'] ?? '',
          'customer':
              reportData['customer'],
          'customer_name':
              reportData['customer_name'] ??
                  '',
          'created_by':
              reportData['created_by'],
          'created_by_name':
              reportData['created_by_name'] ??
                  '',
          'remark':
              reportData['remark'] ?? '',
        });
      }

      if (!mounted) return;

      setState(() {
        backendTotalCount = responseCount;
        nextPageUrl = responseNext;

        if (reset) {
          allSalesReportList =
              List<Map<String, dynamic>>.from(
            receiptList,
          );
        } else {
          final Set<String> existingKeys =
              allSalesReportList.map(
            (Map<String, dynamic> item) {
              return '${item['receipt_type']}-${item['id']}';
            },
          ).toSet();

          for (final Map<String, dynamic>
              receipt in receiptList) {
            final String receiptKey =
                '${receipt['receipt_type']}-${receipt['id']}';

            if (!existingKeys.contains(
              receiptKey,
            )) {
              allSalesReportList.add(
                receipt,
              );

              existingKeys.add(
                receiptKey,
              );
            }
          }
        }

        salesReportList =
            List<Map<String, dynamic>>.from(
          allSalesReportList,
        );

        hasMoreData =
            responseNext != null &&
            responseNext.isNotEmpty;

        if (hasMoreData) {
          currentPage++;
        }
      });

      _updateTotals();
    } catch (error) {
      debugPrint(
        'Receipt report loading error: $error',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Error fetching data: $error',
            ),
            duration:
                const Duration(seconds: 2),
          ),
        );
    } finally {
      if (!mounted) return;

      setState(() {
        isInitialLoading = false;
        isLoadingMore = false;
      });
    }
  }

  void _filterProducts(String query) {
    searchDebounce?.cancel();

    searchDebounce = Timer(
      const Duration(milliseconds: 600),
      () {
        if (!mounted) return;

        getreciptReport(
          reset: true,
        );
      },
    );
  }


  bool get hasActiveFilters {
    return selectedCreatedById != null ||
        selectedBankId != null ||
        selectedCustomerId != null ||
        selectedOrderId != null ||
        startDate != null ||
        endDate != null;
  }

  Future<void> _clearAllFilters() async {
    if (!mounted) return;

    setState(() {
      selectedCreatedById = null;
      selectedBankId = null;
      selectedCustomerId = null;
      selectedOrderId = null;
      startDate = null;
      endDate = null;
    });

    await getreciptReport(
      reset: true,
    );
  }

  Future<void> _showFilterSheet() async {
    String? temporaryCreatedById =
        selectedCreatedById;
    String? temporaryBankId =
        selectedBankId;
    String? temporaryCustomerId =
        selectedCustomerId;
    String? temporaryOrderId =
        selectedOrderId;
    DateTime? temporaryStartDate =
        startDate;
    DateTime? temporaryEndDate =
        endDate;

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
            StateSetter setSheetState,
          ) {
            Future<void> selectFilterDateRange() async {
              final DateTimeRange? picked =
                  await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(
                  const Duration(days: 365),
                ),
                initialDateRange:
                    temporaryStartDate != null &&
                            temporaryEndDate != null
                        ? DateTimeRange(
                            start:
                                temporaryStartDate!,
                            end:
                                temporaryEndDate!,
                          )
                        : null,
              );

              if (picked == null) {
                return;
              }

              setSheetState(() {
                temporaryStartDate =
                    picked.start;
                temporaryEndDate =
                    picked.end;
              });
            }

            Widget buildDropdown({
              required String label,
              required String hint,
              required String? value,
              required List<
                      DropdownMenuItem<String>>
                  items,
              required ValueChanged<String?>
                  onChanged,
            }) {
              final bool valueExists =
                  value == null ||
                      items.any(
                        (
                          DropdownMenuItem<String>
                              item,
                        ) =>
                            item.value == value,
                      );

              return DropdownButtonFormField<
                  String>(
                value:
                    valueExists ? value : null,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: label,
                  hintText: hint,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          Color(0xFFE2E8F0),
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                    borderSide:
                        const BorderSide(
                      color: Colors.blue,
                      width: 1.5,
                    ),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                ),
                items: items,
                onChanged: onChanged,
              );
            }

            return SafeArea(
              child: Container(
                constraints:
                    BoxConstraints(
                  maxHeight:
                      MediaQuery.of(context)
                              .size
                              .height *
                          0.9,
                ),
                decoration:
                    const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(
                    top: Radius.circular(
                      22,
                    ),
                  ),
                ),
                child:
                    SingleChildScrollView(
                  padding:
                      EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 14,
                    bottom:
                        MediaQuery.of(
                                  context,
                                )
                                .viewInsets
                                .bottom +
                            20,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration:
                              BoxDecoration(
                            color:
                                Colors.grey[
                                    300],
                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Receipt Filters',
                              style:
                                  TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight
                                        .bold,
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
                              Icons.close,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      if (isFilterDataLoading)
                        const Padding(
                          padding:
                              EdgeInsets.only(
                            bottom: 12,
                          ),
                          child:
                              LinearProgressIndicator(),
                        ),
                      buildDropdown(
                        label: 'Created By',
                        hint:
                            'Select staff',
                        value:
                            temporaryCreatedById,
                        items: staff.map(
                          (
                            Map<String,
                                    dynamic>
                                staffItem,
                          ) {
                            final String id =
                                staffItem['id']
                                    .toString();

                            final String name =
                                staffItem['name']
                                        ?.toString() ??
                                    '';

                            final String eid =
                                staffItem['eid']
                                        ?.toString() ??
                                    '';

                            return DropdownMenuItem<
                                String>(
                              value: id,
                              child: Text(
                                eid.isEmpty
                                    ? name
                                    : '$name ($eid)',
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                              ),
                            );
                          },
                        ).toList(),
                        onChanged:
                            (String? value) {
                          setSheetState(() {
                            temporaryCreatedById =
                                value;
                          });
                        },
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      buildDropdown(
                        label: 'Bank',
                        hint:
                            'Select bank',
                        value:
                            temporaryBankId,
                        items: bank.map(
                          (
                            Map<String,
                                    dynamic>
                                bankItem,
                          ) {
                            final String id =
                                bankItem['id']
                                    .toString();

                            final String name =
                                bankItem['name']
                                        ?.toString() ??
                                    '';

                            final String branch =
                                bankItem['branch']
                                        ?.toString() ??
                                    '';

                            return DropdownMenuItem<
                                String>(
                              value: id,
                              child: Text(
                                branch.isEmpty
                                    ? name
                                    : '$name - $branch',
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                              ),
                            );
                          },
                        ).toList(),
                        onChanged:
                            (String? value) {
                          setSheetState(() {
                            temporaryBankId =
                                value;
                          });
                        },
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      buildDropdown(
                        label: 'Customer',
                        hint:
                            'Select customer',
                        value:
                            temporaryCustomerId,
                        items: customer.map(
                          (
                            Map<String,
                                    dynamic>
                                customerItem,
                          ) {
                            return DropdownMenuItem<
                                String>(
                              value:
                                  customerItem[
                                          'id']
                                      .toString(),
                              child: Text(
                                customerItem[
                                            'name']
                                        ?.toString() ??
                                    '',
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                              ),
                            );
                          },
                        ).toList(),
                        onChanged:
                            (String? value) {
                          setSheetState(() {
                            temporaryCustomerId =
                                value;
                          });
                        },
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      buildDropdown(
                        label: 'Order',
                        hint:
                            'Select invoice',
                        value:
                            temporaryOrderId,
                        items: orders.map(
                          (
                            Map<String,
                                    dynamic>
                                orderItem,
                          ) {
                            final String id =
                                orderItem['id']
                                    .toString();

                            final String invoice =
                                orderItem['invoice']
                                        ?.toString() ??
                                    '';

                            final String customerName =
                                orderItem[
                                            'customer_name']
                                        ?.toString() ??
                                    '';

                            return DropdownMenuItem<
                                String>(
                              value: id,
                              child: Text(
                                customerName.isEmpty
                                    ? invoice
                                    : '$invoice - $customerName',
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                              ),
                            );
                          },
                        ).toList(),
                        onChanged:
                            (String? value) {
                          setSheetState(() {
                            temporaryOrderId =
                                value;
                          });
                        },
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      InkWell(
                        onTap:
                            selectFilterDateRange,
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                        child: InputDecorator(
                          decoration:
                              InputDecoration(
                            labelText:
                                'Date Range',
                            suffixIcon:
                                const Icon(
                              Icons.date_range,
                            ),
                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),
                            enabledBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                              borderSide:
                                  const BorderSide(
                                color: Color(
                                  0xFFE2E8F0,
                                ),
                              ),
                            ),
                          ),
                          child: Text(
                            temporaryStartDate !=
                                        null &&
                                    temporaryEndDate !=
                                        null
                                ? '${DateFormat('dd/MM/yyyy').format(temporaryStartDate!)}'
                                    ' - '
                                    '${DateFormat('dd/MM/yyyy').format(temporaryEndDate!)}'
                                : 'Select date range',
                            style:
                                TextStyle(
                              color:
                                  temporaryStartDate !=
                                              null &&
                                          temporaryEndDate !=
                                              null
                                      ? Colors
                                          .black87
                                      : Colors
                                          .grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 18,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child:
                                OutlinedButton(
                              onPressed: () {
                                setSheetState(
                                  () {
                                    temporaryCreatedById =
                                        null;
                                    temporaryBankId =
                                        null;
                                    temporaryCustomerId =
                                        null;
                                    temporaryOrderId =
                                        null;
                                    temporaryStartDate =
                                        null;
                                    temporaryEndDate =
                                        null;
                                  },
                                );
                              },
                              style:
                                  OutlinedButton
                                      .styleFrom(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text(
                                'Clear',
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child:
                                ElevatedButton(
                              onPressed:
                                  () async {
                                if (!mounted) {
                                  return;
                                }

                                setState(() {
                                  selectedCreatedById =
                                      temporaryCreatedById;
                                  selectedBankId =
                                      temporaryBankId;
                                  selectedCustomerId =
                                      temporaryCustomerId;
                                  selectedOrderId =
                                      temporaryOrderId;
                                  startDate =
                                      temporaryStartDate;
                                  endDate =
                                      temporaryEndDate;
                                });

                                Navigator.pop(
                                  bottomSheetContext,
                                );

                                await getreciptReport(
                                  reset: true,
                                );
                              },
                              style:
                                  ElevatedButton
                                      .styleFrom(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  vertical: 14,
                                ),
                                backgroundColor:
                                    Colors.blue,
                                foregroundColor:
                                    Colors.white,
                              ),
                              child: const Text(
                                'Apply Filters',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked =
        await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
      initialDateRange:
          startDate != null && endDate != null
              ? DateTimeRange(
                  start: startDate!,
                  end: endDate!,
                )
              : DateTimeRange(
                  start: DateTime.now().subtract(
                    const Duration(days: 7),
                  ),
                  end: DateTime.now(),
                ),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      startDate = picked.start;
      endDate = picked.end;
    });

    await getreciptReport(
      reset: true,
    );
  }

  Widget _buildRow(
    String label,
    dynamic value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value?.toString() ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(
    BuildContext context,
    String title,
    List<String> options,
  ) {
    return ExpansionTile(
      title: Text(title),
      children: options.map(
        (String option) {
          return ListTile(
            title: Text(option),
            onTap: () {
              Navigator.pop(context);

              d.navigateToSelectedPage(
                context,
                option,
              );
            },
          );
        },
      ).toList(),
    );
  }

  Future<void> _navigateBack() async {
    final String? dep =
        await getdepFromPrefs();

    if (!mounted) return;

    if (dep == 'BDO') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) =>
              bdo_dashbord(),
        ),
      );
    } else if (dep == 'COO') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) =>
              ceo_dashboard(),
        ),
      );
    } else if (dep == 'CSO') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) =>
              cso_dashboard(),
        ),
      );
    } else if (dep == 'BDM') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) =>
              bdm_dashbord(),
        ),
      );
    } else if (dep == 'warehouse') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) =>
              WarehouseDashboard(),
        ),
      );
    } else if (dep == 'CEO') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) =>
              ceo_dashboard(),
        ),
      );
    } else if (dep == 'Warehouse Admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) =>
              WarehouseAdmin(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) =>
              dashboard(),
        ),
      );
    }
  }

  @override
  void dispose() {
    searchDebounce?.cancel();
    searchController.dispose();
    scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _navigateBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Recipt Report',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          leading: IconButton(
            icon:
                const Icon(Icons.arrow_back),
            onPressed: _navigateBack,
          ),
          actions: [
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  tooltip: 'Filters',
                  icon: const Icon(
                    Icons.filter_alt_outlined,
                  ),
                  onPressed: _showFilterSheet,
                ),
                if (hasActiveFilters)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration:
                          const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            IconButton(
              icon:
                  const Icon(Icons.date_range),
              onPressed: _selectDateRange,
            ),
            IconButton(
              icon: Image.asset(
                'lib/assets/profile.png',
              ),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.all(8),
              child: TextField(
                controller:
                    searchController,
                decoration: InputDecoration(
                  hintText:
                      'Search receipt...',
                  prefixIcon:
                      const Icon(Icons.search),
                  suffixIcon:
                      searchController
                              .text
                              .isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                              ),
                              onPressed: () {
                                searchController
                                    .clear();

                                if (mounted) {
                                  setState(() {});
                                }

                                getreciptReport(
                                  reset: true,
                                );
                              },
                            )
                          : null,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      30,
                    ),
                    borderSide:
                        const BorderSide(
                      color: Colors.blue,
                      width: 2,
                    ),
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      30,
                    ),
                    borderSide:
                        const BorderSide(
                      color: Colors.blue,
                      width: 2,
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      30,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          Colors.blueAccent,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (String value) {
                  setState(() {});
                  _filterProducts(value);
                },
              ),
            ),
            if (startDate != null &&
                endDate != null)
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  12,
                  0,
                  12,
                  8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${DateFormat('dd/MM/yyyy').format(startDate!)}'
                        ' - '
                        '${DateFormat('dd/MM/yyyy').format(endDate!)}',
                        style:
                            const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          startDate = null;
                          endDate = null;
                        });

                        getreciptReport(
                          reset: true,
                        );
                      },
                      icon: const Icon(
                        Icons.clear,
                        size: 16,
                      ),
                      label: const Text(
                        'Clear Date',
                      ),
                    ),
                  ],
                ),
              ),
            if (hasActiveFilters)
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  10,
                  0,
                  10,
                  8,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Filters applied',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed:
                          _clearAllFilters,
                      icon: const Icon(
                        Icons.filter_alt_off,
                        size: 16,
                      ),
                      label: const Text(
                        'Clear All',
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await getreciptReport(
                    reset: true,
                  );
                },
                child: Stack(
                  children: [
                    if (isInitialLoading &&
                        salesReportList.isEmpty)
                      const Center(
                        child:
                            CircularProgressIndicator(),
                      )
                    else if (salesReportList
                        .isEmpty)
                      ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 180),
                          Center(
                            child: Text(
                              'No receipts found',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      ListView.builder(
                        controller:
                            scrollController,
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        padding:
                            const EdgeInsets.only(
                          bottom: 260,
                        ),
                        itemCount:
                            salesReportList.length +
                                (isLoadingMore
                                    ? 1
                                    : 0),
                        itemBuilder: (
                          BuildContext context,
                          int index,
                        ) {
                          if (index ==
                              salesReportList
                                  .length) {
                            return const Padding(
                              padding:
                                  EdgeInsets.all(
                                20,
                              ),
                              child: Center(
                                child:
                                    CircularProgressIndicator(),
                              ),
                            );
                          }

                          final Map<String,
                                  dynamic>
                              reportData =
                              salesReportList[
                                  index];

                          return Card(
                            color: Colors.white,
                            margin:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 10,
                              horizontal: 15,
                            ),
                            elevation: 8,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                15,
                              ),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets
                                      .all(
                                16,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  _buildRow(
                                    'Receipt:',
                                    reportData[
                                        'payment_receipt'],
                                  ),
                                  if (reportData[
                                              'order_name'] !=
                                          null &&
                                      reportData[
                                              'order_name']
                                          .toString()
                                          .isNotEmpty)
                                    _buildRow(
                                      'Invoice:',
                                      reportData[
                                          'order_name'],
                                    ),
                                  if (reportData[
                                              'customer_name'] !=
                                          null &&
                                      reportData[
                                              'customer_name']
                                          .toString()
                                          .isNotEmpty)
                                    _buildRow(
                                      'customer:',
                                      reportData[
                                          'customer_name'],
                                    ),
                                  _buildRow(
                                    'Transaction ID:',
                                    reportData[
                                        'transactionID'],
                                  ),
                                  _buildRow(
                                    'Amount:',
                                    reportData[
                                        'amount'],
                                  ),
                                  _buildRow(
                                    'Received At:',
                                    reportData[
                                        'received_at'],
                                  ),
                                  _buildRow(
                                    'Bank:',
                                    reportData[
                                        'bank_name'],
                                  ),
                                  _buildRow(
                                    'Created By:',
                                    reportData[
                                        'created_by_name'],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Material(
                        elevation: 12,
                        color:
                            const Color.fromARGB(
                          255,
                          12,
                          80,
                          163,
                        ),
                        borderRadius:
                            const BorderRadius
                                .vertical(
                          top:
                              Radius.circular(20),
                        ),
                        child: Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 8,
                            horizontal: 20,
                          ),
                          decoration:
                              const BoxDecoration(
                            borderRadius:
                                BorderRadius
                                    .vertical(
                              top: Radius.circular(
                                20,
                              ),
                            ),
                            color:
                                Color.fromARGB(
                              255,
                              12,
                              80,
                              163,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              const Text(
                                'Total Report Summary',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.bold,
                                  color:
                                      Colors.white,
                                ),
                              ),
                              Divider(
                                color: Colors.white
                                    .withOpacity(
                                  0.5,
                                ),
                                thickness: 1,
                              ),
                              Row(
                                children: [
                                  const Text(
                                    'Total Receipts: ',
                                    style: TextStyle(
                                      color:
                                          Colors.white,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '$totalReceipts',
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Text(
                                    'Total Amount: ',
                                    style: TextStyle(
                                      color:
                                          Colors.white,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    totalAmount
                                        .toStringAsFixed(
                                      2,
                                    ),
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Row(
                                children: [
                                  const Text(
                                    'Loaded: ',
                                    style: TextStyle(
                                      color:
                                          Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    '${salesReportList.length}'
                                    ' of '
                                    '$backendTotalCount',
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 40,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}