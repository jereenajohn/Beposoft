import 'dart:async';
import 'dart:convert';

import 'package:beposoft/Sales%20Directors/SD_dashboard.dart';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/performa_big_view.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/MARKETING/marketing_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProformaInvoiceList extends StatefulWidget {
  const ProformaInvoiceList({super.key});

  @override
  State<ProformaInvoiceList> createState() => _ProformaInvoiceListState();
}

class _ProformaInvoiceListState extends State<ProformaInvoiceList> {
  final drower d = drower();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController customerSearchController =
      TextEditingController();
  final TextEditingController staffSearchController =
      TextEditingController();

  Timer? _searchDebounce;
  Timer? _customerSearchDebounce;
  Timer? _staffSearchDebounce;

  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> companies = [];
  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> staffList = [];

  bool isLoading = true;
  bool isFilterDataLoading = false;
  bool isCustomerLoading = false;
  bool isStaffLoading = false;
  String? loadError;
  String? dep;

  int currentPage = 1;
  int totalCount = 0;
  String? nextPageUrl;
  String? previousPageUrl;

  int customerCurrentPage = 1;
  int customerTotalPages = 1;
  String customerSearchQuery = '';

  int staffCurrentPage = 1;
  int staffTotalPages = 1;
  String staffSearchQuery = '';

  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  int? selectedCustomerId;
  int? selectedCompanyId;
  int? selectedStaffId;
  String selectedStaffName = '';

  String searchQuery = '';

  static const int _invoicePageSize = 10;

  static const Set<String> _allInvoiceDepartments = {
    'ADMIN',
    'CEO',
    'COO',
    'CSO',
    'SD',
  };

  bool get canViewAllInvoices {
    final String department = dep?.trim().toUpperCase() ?? '';
    return _allInvoiceDepartments.contains(department);
  }

  String get _invoiceEndpoint {
    return canViewAllInvoices
        ? '$api/api/perfoma/invoices/new/'
        : '$api/api/performa/invoice/staff/new/';
  }

  bool get hasActiveFilters {
    return searchQuery.trim().isNotEmpty ||
        selectedStartDate != null ||
        selectedEndDate != null ||
        selectedCustomerId != null ||
        selectedCompanyId != null ||
        selectedStaffId != null;
  }

  @override
  void initState() {
    super.initState();
    initdata();
  }

  Future<void> initdata() async {
    dep = await getdepFromPrefs();

    if (!mounted) return;

    setState(() {
      isLoading = true;
      loadError = null;
    });

    await fetchFilterData();
    await fetchOrderData(page: 1);
  }

  Future<String?> getTokenFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  String _formatDateForApi(DateTime? date) {
    if (date == null) return '';

    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateForDisplay(DateTime? date) {
    if (date == null) return 'Select date';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year.toString().padLeft(4, '0')}';
  }

  Uri _buildInvoiceUri({
    required int page,
    bool includeSearch = true,
  }) {
    final Map<String, String> queryParameters = {
      'page': page.toString(),
    };

    if (includeSearch && searchQuery.trim().isNotEmpty) {
      queryParameters['search'] = searchQuery.trim();
    }

    if (selectedStartDate != null) {
      queryParameters['start_date'] = _formatDateForApi(selectedStartDate);
    }

    if (selectedEndDate != null) {
      queryParameters['end_date'] = _formatDateForApi(selectedEndDate);
    }

    if (selectedCustomerId != null) {
      queryParameters['customer'] = selectedCustomerId.toString();
    }

    if (selectedCompanyId != null) {
      queryParameters['company'] = selectedCompanyId.toString();
    }

    if (selectedStaffId != null) {
      queryParameters['manage_staff'] = selectedStaffId.toString();
    }

    return Uri.parse(_invoiceEndpoint).replace(
      queryParameters: queryParameters,
    );
  }

  Future<Map<String, dynamic>> _fetchInvoicePage({
    required int page,
    required String token,
    required bool includeSearch,
  }) async {
    final http.Response response = await http.get(
      _buildInvoiceUri(
        page: page,
        includeSearch: includeSearch,
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Request failed with status ${response.statusCode}.',
      );
    }

    final dynamic parsed = jsonDecode(response.body);

    if (parsed is! Map) {
      throw Exception('Invalid proforma invoice response.');
    }

    return Map<String, dynamic>.from(parsed);
  }

  List<Map<String, dynamic>> _extractMappedInvoices(
    Map<String, dynamic> parsed,
  ) {
    final List<dynamic> resultData = parsed['results'] is List
        ? parsed['results'] as List<dynamic>
        : parsed['data'] is List
            ? parsed['data'] as List<dynamic>
            : <dynamic>[];

    return resultData
        .whereType<Map>()
        .map(
          (dynamic rawItem) => _mapInvoice(
            Map<String, dynamic>.from(rawItem as Map),
          ),
        )
        .toList();
  }

  bool _matchesMainSearch(
    Map<String, dynamic> invoice,
    String normalizedQuery,
  ) {
    final String invoiceNumber =
        invoice['invoice']?.toString().toLowerCase() ?? '';
    final String customerName =
        invoice['customer_name']?.toString().toLowerCase() ?? '';
    final String staffName =
        invoice['manage_staff']?.toString().toLowerCase() ?? '';

    return invoiceNumber.contains(normalizedQuery) ||
        customerName.contains(normalizedQuery) ||
        staffName.contains(normalizedQuery);
  }

  Future<void> fetchOrderData({required int page}) async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      loadError = null;
    });

    try {
      final String? token = await getTokenFromPrefs();

      if (token == null || token.trim().isEmpty) {
        throw Exception('Authentication token not found.');
      }

      /*
       * Use the backend-supported search parameter directly.
       *
       * The same request also preserves:
       * - page
       * - start_date
       * - end_date
       * - customer
       * - company
       * - manage_staff
       */
      final Map<String, dynamic> parsed = await _fetchInvoicePage(
        page: page,
        token: token,
        includeSearch: true,
      );

      final List<Map<String, dynamic>> invoiceList =
          _extractMappedInvoices(parsed);

      if (!mounted) return;

      setState(() {
        orders = invoiceList;
        totalCount =
            _parseInt(parsed['count']) ?? invoiceList.length;
        nextPageUrl = parsed['next']?.toString();
        previousPageUrl = parsed['previous']?.toString();
        currentPage = page;
        isLoading = false;
        loadError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        loadError = 'Unable to load proforma invoices. $error';
      });
    }
  }

  String _resolveCompanyName(
    Map<String, dynamic> productData,
  ) {
    final dynamic rawCompany = productData['company'];

    if (rawCompany is Map) {
      final String nestedName =
          rawCompany['name']?.toString().trim() ?? '';

      if (nestedName.isNotEmpty) {
        return nestedName;
      }
    }

    final String directName =
        productData['company_name']?.toString().trim() ?? '';

    if (directName.isNotEmpty) {
      return directName;
    }

    final int? companyId = rawCompany is Map
        ? _parseInt(rawCompany['id'])
        : _parseInt(rawCompany);

    if (companyId != null) {
      final Map<String, dynamic> matchedCompany =
          companies.firstWhere(
        (company) => _parseInt(company['id']) == companyId,
        orElse: () => <String, dynamic>{},
      );

      final String matchedName =
          matchedCompany['name']?.toString().trim() ?? '';

      if (matchedName.isNotEmpty) {
        return matchedName;
      }
    }

    return 'Unknown';
  }

  Map<String, dynamic> _mapInvoice(Map<String, dynamic> productData) {
    final Map<String, dynamic> customer =
        productData['customer'] is Map<String, dynamic>
            ? productData['customer'] as Map<String, dynamic>
            : productData['customer'] is Map
                ? Map<String, dynamic>.from(
                    productData['customer'] as Map,
                  )
                : <String, dynamic>{};

    final Map<String, dynamic> billingAddress =
        productData['billing_address'] is Map<String, dynamic>
            ? productData['billing_address'] as Map<String, dynamic>
            : productData['billing_address'] is Map
                ? Map<String, dynamic>.from(
                    productData['billing_address'] as Map,
                  )
                : <String, dynamic>{};

    return {
      'id': productData['id'],
      'invoice': productData['invoice'],
      'manage_staff': productData['manage_staff_name'] ??
          productData['staffname'] ??
          productData['manage_staff']?.toString() ??
          'Unknown',
      'customer_id': customer['id'] ?? productData['customerID'],
      'customer_name': customer['name'] ??
          productData['customermame'] ??
          productData['customer_name'] ??
          'Unknown',
      'company_id': productData['company'] is Map
          ? productData['company']['id']
          : productData['company'],
      'company_name': _resolveCompanyName(productData),
      'status': productData['status'],
      'total_amount': productData['total_amount'],
      'order_date': productData['order_date'],
      'created_at': customer['created_at'],
      'family': productData['familyname'] ?? productData['family'],
      'state': customer['state'] ?? productData['state'],
      'billing_address': billingAddress,
      'payment_status': productData['payment_status'],
      'payment_method': productData['payment_method'],
      'shipping_mode': productData['shipping_mode'],
      'shipping_charge': productData['shipping_charge'],
      'code_charge': productData['code_charge'],
      'note': productData['note'],
    };
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  Future<void> fetchFilterData() async {
    if (!mounted) return;

    setState(() {
      isFilterDataLoading = true;
    });

    try {
      final List<Future<void>> requests = [
        getcompany(),
        getcustomer(page: 1),
      ];

      if (canViewAllInvoices) {
        requests.add(getstaff(page: 1));
      }

      await Future.wait(requests);
    } finally {
      if (mounted) {
        setState(() {
          isFilterDataLoading = false;
        });
      }
    }
  }

  Future<void> getcompany() async {
    try {
      final String? token = await getTokenFromPrefs();

      if (token == null || token.trim().isEmpty) return;

      final http.Response response = await http.get(
        Uri.parse('$api/api/company/data/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) return;

      final dynamic parsed = jsonDecode(response.body);
      final List<dynamic> productsData =
          parsed is Map && parsed['data'] is List
              ? parsed['data'] as List<dynamic>
              : <dynamic>[];

      final List<Map<String, dynamic>> companyList = [];

      for (final dynamic productData in productsData) {
        if (productData is! Map) continue;

        final int? id = _parseInt(productData['id']);
        if (id == null) continue;

        companyList.add({
          'id': id,
          'name': productData['name']?.toString() ?? 'Unknown',
        });
      }

      if (!mounted) return;

      setState(() {
        companies = companyList;
      });
    } catch (_) {}
  }

  Future<void> getcustomer({int page = 1}) async {
    if (!mounted) return;

    setState(() {
      isCustomerLoading = true;
    });

    try {
      final String? token = await getTokenFromPrefs();

      if (token == null || token.trim().isEmpty) {
        throw Exception('Authentication token not found.');
      }

      final Map<String, String> queryParams = {
        'page': page.toString(),
      };

      if (customerSearchQuery.trim().isNotEmpty) {
        queryParams['search'] = customerSearchQuery.trim();
      }

      final Uri uri = Uri.parse('$api/api/customers/').replace(
        queryParameters: queryParams,
      );

      final http.Response response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Customer request failed with status ${response.statusCode}.',
        );
      }

      final dynamic parsed = jsonDecode(response.body);
      final List<dynamic> data =
          parsed is Map && parsed['results'] is List
              ? parsed['results'] as List<dynamic>
              : <dynamic>[];

      final int count = parsed is Map
          ? (_parseInt(parsed['count']) ?? data.length)
          : data.length;

      final List<Map<String, dynamic>> customerList = [];

      for (final dynamic item in data) {
        if (item is! Map) continue;

        final int? id = _parseInt(item['id']);
        if (id == null) continue;

        customerList.add({
          'id': id,
          'name': item['name']?.toString() ?? 'Unknown',
          'created_at': item['created_at'],
          'phone': item['phone'],
          'family': item['family'],
          'state_name': item['state_name'],
          'manager': item['manager'],
        });
      }

      if (!mounted) return;

      setState(() {
        customers = customerList;
        customerCurrentPage = page;
        customerTotalPages = (count / 10).ceil();
        if (customerTotalPages < 1) {
          customerTotalPages = 1;
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        customers = [];
        customerCurrentPage = 1;
        customerTotalPages = 1;
      });
    } finally {
      if (mounted) {
        setState(() {
          isCustomerLoading = false;
        });
      }
    }
  }

  Uri _buildStaffUri({required int page}) {
    final Map<String, String> queryParameters = {
      'page': page.toString(),
    };

    if (staffSearchQuery.trim().isNotEmpty) {
      queryParameters['search'] = staffSearchQuery.trim();
    }

    return Uri.parse('$api/api/get/staffs/').replace(
      queryParameters: queryParameters,
    );
  }

  Future<void> getstaff({int page = 1}) async {
    if (!mounted) return;

    setState(() {
      isStaffLoading = true;
    });

    try {
      final String? token = await getTokenFromPrefs();

      if (token == null || token.trim().isEmpty) {
        throw Exception('Authentication token not found.');
      }

      final http.Response response = await http.get(
        _buildStaffUri(page: page),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Staff request failed with status ${response.statusCode}.',
        );
      }

      final dynamic parsed = jsonDecode(response.body);

      final int count = parsed is Map
          ? (_parseInt(parsed['count']) ?? 0)
          : 0;

      final dynamic results =
          parsed is Map ? parsed['results'] : null;

      final List<dynamic> productsData =
          results is Map && results['data'] is List
              ? results['data'] as List<dynamic>
              : results is List
                  ? results
                  : <dynamic>[];

      final List<Map<String, dynamic>> mappedStaff = [];

      for (final dynamic item in productsData) {
        if (item is! Map) continue;

        final int? id = _parseInt(item['id']);
        if (id == null) continue;

        mappedStaff.add({
          'id': id,
          'eid': item['eid'],
          'name': item['name']?.toString() ?? 'Unknown',
          'username': item['username'],
          'email': item['email'],
          'phone': item['phone'],
          'designation': item['designation'],
          'department_name': item['department_name'],
          'supervisor_name': item['supervisor_name'],
          'family_name': item['family_name'],
          'image': item['image'],
          'approval_status': item['approval_status'],
        });
      }

      if (!mounted) return;

      setState(() {
        staffList = mappedStaff;
        staffCurrentPage = page;
        staffTotalPages = (count / 10).ceil();

        if (staffTotalPages < 1) {
          staffTotalPages = 1;
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        staffList = [];
        staffCurrentPage = 1;
        staffTotalPages = 1;
      });
    } finally {
      if (mounted) {
        setState(() {
          isStaffLoading = false;
        });
      }
    }
  }

  void _onStaffSearchChanged(
    String value,
    StateSetter setSelectorState,
  ) {
    staffSearchQuery = value.trim();

    if (_staffSearchDebounce?.isActive ?? false) {
      _staffSearchDebounce!.cancel();
    }

    _staffSearchDebounce = Timer(
      const Duration(milliseconds: 500),
      () async {
        await getstaff(page: 1);

        if (mounted) {
          setSelectorState(() {});
        }
      },
    );
  }

  Future<void> _openStaffSelector(
    StateSetter parentSheetSetState,
  ) async {
    staffSearchController.text = staffSearchQuery;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext selectorContext) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter selectorSetState,
          ) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD0D5DD),
                        borderRadius: BorderRadius.circular(999),
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
                              'Select Staff',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF101828),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                Navigator.of(selectorContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      child: TextField(
                        controller: staffSearchController,
                        onChanged: (value) {
                          _onStaffSearchChanged(
                            value,
                            selectorSetState,
                          );
                        },
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) async {
                          staffSearchQuery =
                              staffSearchController.text.trim();

                          await getstaff(page: 1);
                          selectorSetState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: 'Search staff...',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                          ),
                          suffixIcon:
                              staffSearchController.text.isNotEmpty
                                  ? IconButton(
                                      onPressed: () async {
                                        staffSearchController.clear();
                                        staffSearchQuery = '';

                                        await getstaff(page: 1);
                                        selectorSetState(() {});
                                      },
                                      icon: const Icon(
                                        Icons.close_rounded,
                                      ),
                                    )
                                  : null,
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
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
                              color: Color(0xFF2563EB),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: isStaffLoading
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : staffList.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No staff found',
                                    style: TextStyle(
                                      color: Color(0xFF667085),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  itemCount: staffList.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final Map<String, dynamic> staff =
                                        staffList[index];

                                    final int staffId =
                                        staff['id'] as int;

                                    final bool selected =
                                        selectedStaffId == staffId;

                                    final String staffName =
                                        staff['name']?.toString() ??
                                            'Unknown';

                                    final String subtitle = [
                                      staff['eid'],
                                      staff['department_name'],
                                      staff['designation'],
                                    ]
                                        .where(
                                          (value) =>
                                              value != null &&
                                              value
                                                  .toString()
                                                  .trim()
                                                  .isNotEmpty,
                                        )
                                        .join(' • ');

                                    return ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            const Color(0xFFEFF8FF),
                                        child: Text(
                                          staffName.trim().isNotEmpty
                                              ? staffName
                                                  .trim()[0]
                                                  .toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: Color(0xFF175CD3),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        staffName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: subtitle.isEmpty
                                          ? null
                                          : Text(
                                              subtitle,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                      trailing: selected
                                          ? const Icon(
                                              Icons.check_circle_rounded,
                                              color: Color(0xFF2563EB),
                                            )
                                          : null,
                                      onTap: () {
                                        setState(() {
                                          selectedStaffId = staffId;
                                          selectedStaffName = staffName;
                                        });

                                        parentSheetSetState(() {});
                                        Navigator.of(selectorContext).pop();
                                      },
                                    );
                                  },
                                ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        10,
                        16,
                        16,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(
                            color: Color(0xFFEAECF0),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: staffCurrentPage <= 1 ||
                                      isStaffLoading
                                  ? null
                                  : () async {
                                      await getstaff(
                                        page: staffCurrentPage - 1,
                                      );
                                      selectorSetState(() {});
                                    },
                              icon: const Icon(
                                Icons.chevron_left_rounded,
                              ),
                              label: const Text('Previous'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Page $staffCurrentPage of $staffTotalPages',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475467),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: staffCurrentPage >=
                                          staffTotalPages ||
                                      isStaffLoading
                                  ? null
                                  : () async {
                                      await getstaff(
                                        page: staffCurrentPage + 1,
                                      );
                                      selectorSetState(() {});
                                    },
                              icon: const Icon(
                                Icons.chevron_right_rounded,
                              ),
                              label: const Text('Next'),
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
  }

  void _onSearchChanged(String value) {
    searchQuery = value.trim();

    if (_searchDebounce?.isActive ?? false) {
      _searchDebounce!.cancel();
    }

    setState(() {});

    _searchDebounce = Timer(
      const Duration(milliseconds: 500),
      () {
        if (!mounted) return;
        fetchOrderData(page: 1);
      },
    );
  }

  Future<void> _submitInvoiceSearch() async {
    if (_searchDebounce?.isActive ?? false) {
      _searchDebounce!.cancel();
    }

    searchQuery = searchController.text.trim();
    await fetchOrderData(page: 1);
  }

  Future<void> _clearInvoiceSearch() async {
    if (_searchDebounce?.isActive ?? false) {
      _searchDebounce!.cancel();
    }

    searchController.clear();
    customerSearchController.clear();

    setState(() {
      searchQuery = '';
      customerSearchQuery = '';
    });

    await fetchOrderData(page: 1);
  }

  void _onCustomerSearchChanged(
    String value,
    StateSetter setSheetState,
  ) {
    customerSearchQuery = value.trim();

    if (_customerSearchDebounce?.isActive ?? false) {
      _customerSearchDebounce!.cancel();
    }

    _customerSearchDebounce = Timer(
      const Duration(milliseconds: 500),
      () async {
        await getcustomer(page: 1);

        if (mounted) {
          setSheetState(() {});
        }
      },
    );
  }

  Future<void> _openCustomerSelector(
    StateSetter parentSheetSetState,
  ) async {
    customerSearchController.text = customerSearchQuery;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext selectorContext) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter selectorSetState,
          ) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD0D5DD),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Select Customer',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF101828),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                Navigator.of(selectorContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: customerSearchController,
                        onChanged: (value) {
                          _onCustomerSearchChanged(
                            value,
                            selectorSetState,
                          );
                        },
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) async {
                          await getcustomer(page: 1);
                          selectorSetState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: 'Search customer...',
                          prefixIcon:
                              const Icon(Icons.search_rounded),
                          suffixIcon:
                              customerSearchController.text.isNotEmpty
                                  ? IconButton(
                                      onPressed: () async {
                                        customerSearchController.clear();
                                        customerSearchQuery = '';
                                        await getcustomer(page: 1);
                                        selectorSetState(() {});
                                      },
                                      icon: const Icon(
                                        Icons.close_rounded,
                                      ),
                                    )
                                  : null,
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
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
                              color: Color(0xFF2563EB),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: isCustomerLoading
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : customers.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No customers found',
                                    style: TextStyle(
                                      color: Color(0xFF667085),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  itemCount: customers.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final customer = customers[index];
                                    final int customerId =
                                        customer['id'] as int;
                                    final bool selected =
                                        selectedCustomerId == customerId;

                                    return ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            const Color(0xFFEFF8FF),
                                        child: Text(
                                          (customer['name']
                                                      ?.toString()
                                                      .trim()
                                                      .isNotEmpty ??
                                                  false)
                                              ? customer['name']
                                                  .toString()
                                                  .trim()[0]
                                                  .toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: Color(0xFF175CD3),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        customer['name']?.toString() ??
                                            'Unknown',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        [
                                          customer['phone'],
                                          customer['state_name'],
                                        ]
                                            .where(
                                              (value) =>
                                                  value != null &&
                                                  value
                                                      .toString()
                                                      .trim()
                                                      .isNotEmpty,
                                            )
                                            .join(' • '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: selected
                                          ? const Icon(
                                              Icons.check_circle_rounded,
                                              color: Color(0xFF2563EB),
                                            )
                                          : null,
                                      onTap: () {
                                        setState(() {
                                          selectedCustomerId = customerId;
                                        });
                                        parentSheetSetState(() {});
                                        Navigator.of(selectorContext).pop();
                                      },
                                    );
                                  },
                                ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(
                            color: Color(0xFFEAECF0),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: customerCurrentPage <= 1 ||
                                      isCustomerLoading
                                  ? null
                                  : () async {
                                      await getcustomer(
                                        page:
                                            customerCurrentPage - 1,
                                      );
                                      selectorSetState(() {});
                                    },
                              icon: const Icon(
                                Icons.chevron_left_rounded,
                              ),
                              label: const Text('Previous'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Page $customerCurrentPage of $customerTotalPages',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475467),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: customerCurrentPage >=
                                          customerTotalPages ||
                                      isCustomerLoading
                                  ? null
                                  : () async {
                                      await getcustomer(
                                        page:
                                            customerCurrentPage + 1,
                                      );
                                      selectorSetState(() {});
                                    },
                              icon: const Icon(
                                Icons.chevron_right_rounded,
                              ),
                              label: const Text('Next'),
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
  }

  Future<void> _pickStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedStartDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: selectedEndDate ?? DateTime(2100),
    );

    if (picked == null || !mounted) return;

    setState(() {
      selectedStartDate = picked;
    });
  }

  Future<void> _pickEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedEndDate ?? selectedStartDate ?? DateTime.now(),
      firstDate: selectedStartDate ?? DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) return;

    setState(() {
      selectedEndDate = picked;
    });
  }

  Future<void> _applyFilters() async {
    Navigator.of(context).pop();
    await fetchOrderData(page: 1);
  }

  Future<void> _clearFilters({bool closeSheet = false}) async {
    searchController.clear();
    staffSearchController.clear();

    setState(() {
      searchQuery = '';
      staffSearchQuery = '';
      selectedStartDate = null;
      selectedEndDate = null;
      selectedCustomerId = null;
      selectedCompanyId = null;
      selectedStaffId = null;
      selectedStaffName = '';
    });

    if (closeSheet && mounted) {
      Navigator.of(context).pop();
    }

    await fetchOrderData(page: 1);
  }

  void _openFilters() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter setSheetState,
          ) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
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
                    top: 12,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD0D5DD),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Filter Proforma Invoices',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF101828),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Date Range',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF344054),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _dateField(
                                label: 'Start Date',
                                value: _formatDateForDisplay(
                                  selectedStartDate,
                                ),
                                onTap: () async {
                                  await _pickStartDate();
                                  setSheetState(() {});
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _dateField(
                                label: 'End Date',
                                value: _formatDateForDisplay(
                                  selectedEndDate,
                                ),
                                onTap: () async {
                                  await _pickEndDate();
                                  setSheetState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Customer',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF344054),
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            await _openCustomerSelector(
                              setSheetState,
                            );
                          },
                          child: InputDecorator(
                            decoration: _filterInputDecoration(
                              hint: 'All customers',
                              icon: Icons.person_outline_rounded,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    selectedCustomerId == null
                                        ? 'All customers'
                                        : customers
                                            .firstWhere(
                                              (customer) =>
                                                  customer['id'] ==
                                                  selectedCustomerId,
                                              orElse: () => {
                                                'name':
                                                    'Selected customer',
                                              },
                                            )['name']
                                            .toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: selectedCustomerId == null
                                          ? const Color(0xFF98A2B3)
                                          : const Color(0xFF101828),
                                      fontWeight:
                                          selectedCustomerId == null
                                              ? FontWeight.w400
                                              : FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (selectedCustomerId != null)
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      setState(() {
                                        selectedCustomerId = null;
                                      });
                                      setSheetState(() {});
                                    },
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: Color(0xFF667085),
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Color(0xFF667085),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (canViewAllInvoices) ...[
                          const Text(
                            'Staff',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF344054),
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () async {
                              await _openStaffSelector(
                                setSheetState,
                              );
                            },
                            child: InputDecorator(
                              decoration: _filterInputDecoration(
                                hint: 'All staff',
                                icon: Icons.badge_outlined,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      selectedStaffId == null
                                          ? 'All staff'
                                          : selectedStaffName.isNotEmpty
                                              ? selectedStaffName
                                              : 'Selected staff',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: selectedStaffId == null
                                            ? const Color(0xFF98A2B3)
                                            : const Color(0xFF101828),
                                        fontWeight:
                                            selectedStaffId == null
                                                ? FontWeight.w400
                                                : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (selectedStaffId != null)
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      onPressed: () {
                                        setState(() {
                                          selectedStaffId = null;
                                          selectedStaffName = '';
                                        });
                                        setSheetState(() {});
                                      },
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: Color(0xFF667085),
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Color(0xFF667085),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        const Text(
                          'Company',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF344054),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: selectedCompanyId,
                          isExpanded: true,
                          decoration: _filterInputDecoration(
                            hint: isFilterDataLoading
                                ? 'Loading companies...'
                                : 'All companies',
                            icon: Icons.apartment_outlined,
                          ),
                          items: companies
                              .map(
                                (company) => DropdownMenuItem<int>(
                                  value: company['id'] as int,
                                  child: Text(
                                    company['name']?.toString() ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCompanyId = value;
                            });
                            setSheetState(() {});
                          },
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  await _clearFilters(closeSheet: true);
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text('Clear'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _applyFilters,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
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

  InputDecoration _filterInputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF2563EB),
          width: 1.5,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Widget _dateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE4E7EC)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: Color(0xFF667085),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF667085),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF101828),
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
    final String? department = await getdepFromPrefs();

    if (!mounted) return;

    if (department == 'BDO') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => bdo_dashbord()),
      );
    } 
           else if (dep == "Marketing") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => marketing_dashboard(),
        ),
      );
    } 
    else if (department == 'COO' || department == 'CEO') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ceo_dashboard()),
      );
    } else if (department == 'CSO') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => cso_dashboard()),
      );
    } else if (department == 'SD') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SdDashboard()),
      );
    } else if (department == 'BDM') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => bdm_dashbord()),
      );
    } else if (department == 'warehouse') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WarehouseDashboard()),
      );
    } else if (department == 'Warehouse Admin') {
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

  void logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('token');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logged out successfully'),
        duration: Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => login()),
    );
  }

  String _safeText(dynamic value, {String fallback = '—'}) {
    final String text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  String _currency(dynamic value) {
    return '₹${_asDouble(value).toStringAsFixed(2)}';
  }

  Color _statusColor(String status) {
    final String normalized = status.toLowerCase();

    if (normalized.contains('approved') ||
        normalized.contains('confirmed') ||
        normalized.contains('created')) {
      return const Color(0xFF027A48);
    }

    if (normalized.contains('rejected') ||
        normalized.contains('cancelled') ||
        normalized.contains('disapproved')) {
      return const Color(0xFFB42318);
    }

    if (normalized.contains('pending') ||
        normalized.contains('waiting') ||
        normalized.contains('progress')) {
      return const Color(0xFFB54708);
    }

    return const Color(0xFF175CD3);
  }

  Color _statusBackground(String status) {
    final String normalized = status.toLowerCase();

    if (normalized.contains('approved') ||
        normalized.contains('confirmed') ||
        normalized.contains('created')) {
      return const Color(0xFFECFDF3);
    }

    if (normalized.contains('rejected') ||
        normalized.contains('cancelled') ||
        normalized.contains('disapproved')) {
      return const Color(0xFFFEF3F2);
    }

    if (normalized.contains('pending') ||
        normalized.contains('waiting') ||
        normalized.contains('progress')) {
      return const Color(0xFFFFFAEB);
    }

    return const Color(0xFFEFF8FF);
  }

  Widget _statusChip(dynamic statusValue) {
    final String status = _safeText(statusValue, fallback: 'Unknown');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: _statusBackground(status),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _statusColor(status),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 17,
            color: const Color(0xFF667085),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF667085),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF101828),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> order) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PerformaInvoice_BigView_List(
              invoice: _safeText(order['invoice'], fallback: ''),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEAECF0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D101828),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF2563EB),
                    Color(0xFF1D4ED8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PROFORMA INVOICE',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: Color(0xFFDCEBFF),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '#${_safeText(order['invoice'])}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 16,
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
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 15,
                        color: Color(0xFF667085),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        _safeText(order['order_date']),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475467),
                        ),
                      ),
                      const Spacer(),
                      _statusChip(order['status']),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _detailRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Staff',
                    value: _safeText(order['manage_staff']),
                  ),
                  const SizedBox(height: 12),
                  _detailRow(
                    icon: Icons.business_center_outlined,
                    label: 'Customer',
                    value: _safeText(order['customer_name']),
                  ),
                  const SizedBox(height: 12),
                  _detailRow(
                    icon: Icons.apartment_outlined,
                    label: 'Company',
                    value: _safeText(order['company_name']),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFABEFC6)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Color(0xFF027A48),
                          size: 20,
                        ),
                        const SizedBox(width: 9),
                        const Expanded(
                          child: Text(
                            'Billing Amount',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF027A48),
                            ),
                          ),
                        ),
                        Text(
                          _currency(order['total_amount']),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF027A48),
                          ),
                        ),
                      ],
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

  Widget _buildPagination() {
    if (isLoading || loadError != null || totalCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      color: const Color(0xFFF4F7FB),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: previousPageUrl == null
                  ? null
                  : () => fetchOrderData(page: currentPage - 1),
              icon: const Icon(Icons.chevron_left_rounded),
              label: const Text('Previous'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE4E7EC)),
            ),
            child: Text(
              'Page $currentPage',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF344054),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: nextPageUrl == null
                  ? null
                  : () => fetchOrderData(page: currentPage + 1),
              icon: const Icon(Icons.chevron_right_rounded),
              label: const Text('Next'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 160),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (loadError != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEAECF0)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 42,
                  color: Color(0xFFB42318),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Unable to load proforma invoices',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  loadError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF667085),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => fetchOrderData(page: currentPage),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEAECF0)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 44,
                  color: Color(0xFF98A2B3),
                ),
                const SizedBox(height: 12),
                Text(
                  hasActiveFilters
                      ? 'No matching invoices found'
                      : 'No proforma invoices found',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasActiveFilters
                      ? 'Change or clear the applied backend filters.'
                      : 'There are no proforma invoice records available.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF667085),
                  ),
                ),
                if (hasActiveFilters) ...[
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.filter_alt_off_outlined),
                    label: const Text('Clear Filters'),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _buildInvoiceCard(orders[index]);
      },
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _customerSearchDebounce?.cancel();
    _staffSearchDebounce?.cancel();
    searchController.dispose();
    customerSearchController.dispose();
    staffSearchController.dispose();
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
        backgroundColor: const Color(0xFFF4F7FB),
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          leading: IconButton(
            tooltip: 'Back',
            onPressed: _navigateBack,
            icon: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: Color(0xFF344054),
              ),
            ),
          ),
          titleSpacing: 4,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Proforma Invoices',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF101828),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Review and manage generated proforma invoices',
                style: TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF667085),
                ),
              ),
            ],
          ),
          actions: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: 'Filters',
                  onPressed: _openFilters,
                  icon: const Icon(
                    Icons.tune_rounded,
                    color: Color(0xFF344054),
                  ),
                ),
                if (hasActiveFilters)
                  Positioned(
                    top: 10,
                    right: 9,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
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
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: TextField(
                  controller: searchController,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _submitInvoiceSearch(),
                  decoration: InputDecoration(
                    hintText: 'Search by invoice number',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF98A2B3),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF667085),
                    ),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            tooltip: 'Clear search',
                            onPressed: _clearInvoiceSearch,
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF667085),
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
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
                        color: Color(0xFF2563EB),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              if (!isLoading && loadError == null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                  child: Row(
                    children: [
                      Text(
                        '$totalCount invoice${totalCount == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF667085),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        canViewAllInvoices
                            ? 'All invoices'
                            : 'My invoices',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF667085),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => fetchOrderData(page: currentPage),
                        icon: const Icon(
                          Icons.refresh_rounded,
                          size: 18,
                        ),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => fetchOrderData(page: currentPage),
                  child: _buildBody(),
                ),
              ),
              _buildPagination(),
            ],
          ),
        ),
      ),
    );
  }
}
