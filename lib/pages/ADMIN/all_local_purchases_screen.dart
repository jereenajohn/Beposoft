import 'dart:convert';

import 'package:beposoft/pages/api.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AllLocalPurchaseOrderScreen extends StatefulWidget {
  const AllLocalPurchaseOrderScreen({super.key});

  @override
  State<AllLocalPurchaseOrderScreen> createState() =>
      _AllLocalPurchaseOrderScreenState();
}

class _AllLocalPurchaseOrderScreenState
    extends State<AllLocalPurchaseOrderScreen> {
  static const Color primary = Color(0xFF2563EB);
  static const Color background = Color(0xFFF1F5F9);
  static const Color muted = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  final TextEditingController searchController = TextEditingController();

  final Set<int> updatingStatusIds = <int>{};
  final Set<int> downloadingInvoiceIds = <int>{};
  final Set<int> editingLpoIds = <int>{};
  final Set<int> loadingEditDetailIds = <int>{};

  List<Map<String, dynamic>> banks = [];

  List<Map<String, dynamic>> allLpoList = [];
  List<Map<String, dynamic>> visibleLpoList = [];

  String currentDepartment = '';
  String selectedStatus = 'all';

  bool isLoading = false;
  bool isDepartmentLoading = true;

  int totalLpoCount = 0;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_applyFilters);
    _loadInitialData();
  }

  @override
  void dispose() {
    searchController
      ..removeListener(_applyFilters)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _loadCurrentDepartment();
    await Future.wait([
      getBanks(),
      getAllLpo(),
    ]);
  }

  Future<String?> getTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String> _token() async {
    final token = await getTokenFromPrefs();

    if (token == null || token.trim().isEmpty) {
      throw Exception(
        'Authentication token not found. Please log in again.',
      );
    }

    return token.trim();
  }

  Map<String, String> _jsonHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _loadCurrentDepartment() async {
    try {
      final token = await _token();
      final jwt = JWT.decode(token);

      final department =
          jwt.payload['active']?.toString().trim() ?? '';

      debugPrint(
        'ALL LPO JWT ACTIVE DEPARTMENT: $department',
      );

      if (!mounted) return;

      setState(() {
        currentDepartment = department;
        isDepartmentLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Department Load Error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        currentDepartment = '';
        isDepartmentLoading = false;
      });

      _showMessage(
        'Unable to identify the logged-in department.',
        error: true,
      );
    }
  }

  bool get _canApproveOrReject {
    return currentDepartment == 'HR' ||
        currentDepartment == 'CEO' ||
        currentDepartment == 'COO';
  }

  bool get _canConfirm {
    return currentDepartment == 'ADMIN' ||
        currentDepartment == 'Accounts / Accounting';
  }

  bool get _canEditLpo {
    return currentDepartment == 'ADMIN' ||
        currentDepartment == 'Accounts / Accounting';
  }

  Future<void> getBanks() async {
    try {
      final token = await _token();

      final response = await http.get(
        Uri.parse('$api/api/banks/'),
        headers: _jsonHeaders(token),
      );

      debugPrint('BANK STATUS: ${response.statusCode}');
      debugPrint('BANK RESPONSE: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(_responseError(response));
      }

      final decoded = jsonDecode(response.body);
      final rawList = _listFromResponse(decoded);

      final result = rawList
          .whereType<Map>()
          .map<Map<String, dynamic>>((rawBank) {
            final bank = Map<String, dynamic>.from(rawBank);

            return {
              'id': bank['id'],
              'name': bank['name']?.toString() ?? '',
              'branch': bank['branch']?.toString() ?? '',
            };
          })
          .where((bank) {
            return _toInt(bank['id']) != null &&
                bank['name'].toString().trim().isNotEmpty;
          })
          .toList();

      if (!mounted) return;

      setState(() {
        banks = result;
      });
    } catch (error, stackTrace) {
      debugPrint('Get Banks Error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage(_errorText(error), error: true);
    }
  }

  List<dynamic> _listFromResponse(dynamic body) {
    if (body is List) return body;
    if (body is! Map) return [];

    if (body['data'] is List) {
      return body['data'];
    }

    if (body['results'] is List) {
      return body['results'];
    }

    if (body['results'] is Map &&
        body['results']['data'] is List) {
      return body['results']['data'];
    }

    return [];
  }

  Map<String, dynamic> _objectFromResponse(dynamic body) {
    if (body is! Map) return {};

    final root = Map<String, dynamic>.from(body);

    if (root['data'] is Map) {
      return Map<String, dynamic>.from(root['data']);
    }

    if (root['results'] is Map &&
        root['results']['data'] is Map) {
      return Map<String, dynamic>.from(
        root['results']['data'],
      );
    }

    return root;
  }

  String _responseError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map) {
        for (final key in ['detail', 'message', 'error']) {
          final value = decoded[key];

          if (value != null && value.toString().trim().isNotEmpty) {
            return value.toString();
          }
        }

        return decoded.entries.map((entry) {
          final value = entry.value;

          if (value is List) {
            return '${entry.key}: ${value.join(', ')}';
          }

          return '${entry.key}: $value';
        }).join('\n');
      }
    } catch (_) {
      // Return raw response below.
    }

    if (response.body.trim().isNotEmpty) {
      return response.body.trim();
    }

    return 'Request failed with status ${response.statusCode}.';
  }

  String _errorText(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  Future<void> getAllLpo() async {
    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      final token = await _token();

      final response = await http.get(
        Uri.parse('$api/api/lpo/all/'),
        headers: _jsonHeaders(token),
      );

      debugPrint('ALL LPO STATUS: ${response.statusCode}');
      debugPrint('ALL LPO RESPONSE: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(_responseError(response));
      }

      final decoded = jsonDecode(response.body);
      final rawList = _listFromResponse(decoded);

      final result = rawList
          .whereType<Map>()
          .map<Map<String, dynamic>>((rawLpo) {
            final lpo = Map<String, dynamic>.from(rawLpo);
            final rawItems =
                lpo['items'] is List ? lpo['items'] as List : <dynamic>[];

            final parsedItems = rawItems
                .whereType<Map>()
                .map<Map<String, dynamic>>((rawItem) {
              final item = Map<String, dynamic>.from(rawItem);

              return {
                'id': item['id'],
                'product': item['product']?.toString() ?? '',
                'product_description':
                    item['product_description']?.toString() ?? '',
                'quantity': _toInt(item['quantity']) ?? 0,
                'amount': item['amount'],
              };
            }).toList();

            return {
              'id': lpo['id'],
              'invoice': lpo['invoice']?.toString() ?? '',
              'date': lpo['date']?.toString() ?? '',
              'status': lpo['status']?.toString() ?? 'pending',
              'company': lpo['company'],
              'company_name': lpo['company_name']?.toString() ?? '',
              'requested_by': lpo['requested_by'],
              'requested_by_name':
                  lpo['requested_by_name']?.toString() ?? '',
              'approved_by': lpo['approved_by'],
              'approved_by_name':
                  lpo['approved_by_name']?.toString() ?? '',
              'confirmed_by': lpo['confirmed_by'],
              'confirmed_by_name':
                  lpo['confirmed_by_name']?.toString() ?? '',
              'bank': lpo['bank'],
              'bank_name': lpo['bank_name']?.toString() ?? '',
              'note': lpo['note']?.toString() ?? '',
              'items': parsedItems,
              'created_at': lpo['created_at']?.toString() ?? '',
              'updated_at': lpo['updated_at']?.toString() ?? '',
            };
          })
          .where((lpo) => _toInt(lpo['id']) != null)
          .toList();

      int count = result.length;

      if (decoded is Map && _toInt(decoded['count']) != null) {
        count = _toInt(decoded['count'])!;
      } else if (decoded is Map &&
          decoded['results'] is Map &&
          _toInt(decoded['results']['count']) != null) {
        count = _toInt(decoded['results']['count'])!;
      }

      if (!mounted) return;

      setState(() {
        allLpoList = result;
        totalLpoCount = count;
      });

      _applyFilters();
    } catch (error, stackTrace) {
      debugPrint('Get All LPO Error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage(_errorText(error), error: true);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _applyFilters() {
    final query = searchController.text.trim().toLowerCase();

    final filtered = allLpoList.where((lpo) {
      final status =
          lpo['status']?.toString().trim().toLowerCase() ?? 'pending';

      final matchesStatus =
          selectedStatus == 'all' || status == selectedStatus;

      if (!matchesStatus) return false;
      if (query.isEmpty) return true;

      final items = lpo['items'] is List ? lpo['items'] as List : <dynamic>[];

      final itemSearchText = items.whereType<Map>().map((item) {
        return [
          item['product'],
          item['product_description'],
          item['quantity'],
          item['amount'],
        ].join(' ');
      }).join(' ');

      final searchableText = [
        lpo['invoice'],
        lpo['company_name'],
        lpo['requested_by_name'],
        lpo['approved_by_name'],
        lpo['confirmed_by_name'],
        lpo['bank_name'],
        lpo['note'],
        lpo['date'],
        status,
        itemSearchText,
      ].join(' ').toLowerCase();

      return searchableText.contains(query);
    }).toList();

    if (!mounted) return;

    setState(() {
      visibleLpoList = filtered;
    });
  }


  Future<void> openLpoForEditing(
    Map<String, dynamic> listLpo,
  ) async {
    final id = _toInt(listLpo['id']);

    if (id == null ||
        loadingEditDetailIds.contains(id) ||
        editingLpoIds.contains(id)) {
      return;
    }

    final status =
        listLpo['status']?.toString().trim().toLowerCase() ??
            'pending';

    if (!_canEditLpo ||
        status != 'approved') {
      return;
    }

    setState(() {
      loadingEditDetailIds.add(id);
    });

    try {
      final token = await _token();

      final response = await http.get(
        Uri.parse('$api/api/lpo/edit/$id/'),
        headers: _jsonHeaders(token),
      );

      debugPrint(
        'SINGLE ALL LPO STATUS: ${response.statusCode}',
      );
      debugPrint(
        'SINGLE ALL LPO RESPONSE: ${response.body}',
      );

      if (response.statusCode != 200) {
        throw Exception(_responseError(response));
      }

      final detail = _objectFromResponse(
        jsonDecode(response.body),
      );

      if (detail.isEmpty) {
        throw Exception('LPO details are not available.');
      }

      final rawItems =
          detail['items'] is List
              ? detail['items'] as List
              : <dynamic>[];

      final completeLpo = <String, dynamic>{
        ...listLpo,
        ...detail,
        'items': rawItems
            .whereType<Map>()
            .map<Map<String, dynamic>>((rawItem) {
          final item =
              Map<String, dynamic>.from(rawItem);

          return {
            'id': item['id'],
            'product':
                item['product']?.toString() ?? '',
            'product_description':
                item['product_description']
                        ?.toString() ??
                    '',
            'quantity':
                _toInt(item['quantity']) ?? 0,
            'amount': item['amount'],
          };
        }).toList(),
      };

      if (!mounted) return;

      await _showEditLpoDialog(completeLpo);
    } catch (error, stackTrace) {
      debugPrint('Open LPO Edit Error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage(
        _errorText(error),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          loadingEditDetailIds.remove(id);
        });
      }
    }
  }

  Future<void> updateLpo({
    required int id,
    required Map<String, dynamic> lpo,
    required int bankId,
    required String note,
    required List<Map<String, dynamic>> items,
  }) async {
    if (editingLpoIds.contains(id)) return;

    setState(() => editingLpoIds.add(id));

    try {
      final token = await _token();

      final body = {
        'date': lpo['date'],
        'company': lpo['company'],
        'bank': bankId,
        'note': note.trim(),
        'items': items.map((item) {
          return {
            if (item['id'] != null) 'id': item['id'],
            'product': item['product']?.toString().trim() ?? '',
            'product_description':
                item['product_description']?.toString().trim() ?? '',
            'quantity': _toInt(item['quantity']) ?? 0,
            'amount': item['amount'] == null ||
                    item['amount'].toString().trim().isEmpty
                ? null
                : _toDouble(item['amount']).toStringAsFixed(2),
          };
        }).toList(),
      };

      debugPrint('UPDATE LPO BODY: ${jsonEncode(body)}');

      final response = await http.put(
        Uri.parse('$api/api/lpo/edit/$id/'),
        headers: _jsonHeaders(token),
        body: jsonEncode(body),
      );

      debugPrint('UPDATE LPO STATUS: ${response.statusCode}');
      debugPrint('UPDATE LPO RESPONSE: ${response.body}');

      if (response.statusCode != 200 &&
          response.statusCode != 201) {
        throw Exception(_responseError(response));
      }

      await getAllLpo();
      _showMessage('LPO updated successfully.');
    } catch (error, stackTrace) {
      debugPrint('Update LPO Error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage(_errorText(error), error: true);
      rethrow;
    } finally {
      if (mounted) {
        setState(() => editingLpoIds.remove(id));
      }
    }
  }

  Future<void> updateLpoStatus(int id, String status) async {
    if (updatingStatusIds.contains(id)) return;

    setState(() => updatingStatusIds.add(id));

    try {
      final token = await _token();

      final response = await http.patch(
        Uri.parse('$api/api/lpo/status/$id/'),
        headers: _jsonHeaders(token),
        body: jsonEncode({
          'status': status,
        }),
      );

      debugPrint('STATUS UPDATE CODE: ${response.statusCode}');
      debugPrint('STATUS UPDATE RESPONSE: ${response.body}');

      if (response.statusCode != 200 &&
          response.statusCode != 204) {
        throw Exception(_responseError(response));
      }

      String message;

      switch (status) {
        case 'approved':
          message = 'LPO approved successfully.';
          break;
        case 'confirmed':
          message = 'LPO confirmed successfully.';
          break;
        case 'rejected':
          message = 'LPO rejected successfully.';
          break;
        default:
          message = 'LPO status updated successfully.';
      }

      await getAllLpo();
      _showMessage(message);
    } catch (error, stackTrace) {
      debugPrint('Status Update Error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage(_errorText(error), error: true);
    } finally {
      if (mounted) {
        setState(() => updatingStatusIds.remove(id));
      }
    }
  }

  Future<void> downloadInvoice(int id) async {
    if (downloadingInvoiceIds.contains(id)) return;

    setState(() => downloadingInvoiceIds.add(id));

    try {
      final token = await _token();
      final url = Uri.parse('$api/api/lpo/invoice/$id/');

      debugPrint('OPEN INVOICE URL: $url');

      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
        webViewConfiguration: WebViewConfiguration(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (!launched) {
        throw Exception('Could not open invoice.');
      }
    } catch (error, stackTrace) {
      debugPrint('Invoice Open Error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage(_errorText(error), error: true);
    } finally {
      if (mounted) {
        setState(() => downloadingInvoiceIds.remove(id));
      }
    }
  }

  String _displayApiDate(String value) {
    final parsed = DateTime.tryParse(value);

    if (parsed == null) {
      return value.trim().isEmpty ? '—' : value;
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${parsed.day.toString().padLeft(2, '0')} '
        '${months[parsed.month - 1]} ${parsed.year}';
  }

  String _displayDateTime(String value) {
    final parsed = DateTime.tryParse(value)?.toLocal();

    if (parsed == null) {
      return value.trim().isEmpty ? '—' : value;
    }

    final hour = parsed.hour == 0
        ? 12
        : parsed.hour > 12
            ? parsed.hour - 12
            : parsed.hour;

    final period = parsed.hour >= 12 ? 'PM' : 'AM';

    return '${_displayApiDate(parsed.toIso8601String())}, '
        '${hour.toString().padLeft(2, '0')}:'
        '${parsed.minute.toString().padLeft(2, '0')} $period';
  }

  String _formatAmount(dynamic value) {
    final amount = _toDouble(value);

    if (amount == 0 &&
        (value == null || value.toString().trim().isEmpty)) {
      return 'Not added';
    }

    return '₹${amount.toStringAsFixed(2)}';
  }

  double _lpoTotal(Map<String, dynamic> lpo) {
    final items = lpo['items'] is List ? lpo['items'] as List : <dynamic>[];

    return items.whereType<Map>().fold<double>(
      0,
      (total, item) => total + _toDouble(item['amount']),
    );
  }

  int _statusCount(String status) {
    return allLpoList.where((lpo) {
      return lpo['status']?.toString().toLowerCase() == status;
    }).length;
  }

  Widget _statusBadge(String status) {
    late final Color foregroundColor;
    late final Color backgroundColor;
    late final IconData icon;

    switch (status.toLowerCase()) {
      case 'approved':
        foregroundColor = const Color(0xFF15803D);
        backgroundColor = const Color(0xFFDCFCE7);
        icon = Icons.check_circle_outline;
        break;
      case 'confirmed':
        foregroundColor = const Color(0xFF1D4ED8);
        backgroundColor = const Color(0xFFDBEAFE);
        icon = Icons.verified_outlined;
        break;
      case 'rejected':
        foregroundColor = const Color(0xFFB91C1C);
        backgroundColor = const Color(0xFFFEE2E2);
        icon = Icons.cancel_outlined;
        break;
      default:
        foregroundColor = const Color(0xFFB45309);
        backgroundColor = const Color(0xFFFEF3C7);
        icon = Icons.schedule_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: foregroundColor,
          ),
          const SizedBox(width: 5),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: foregroundColor,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Local Purchase Orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Review and process purchase orders',
              style: TextStyle(
                color: textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: isLoading ? null : getAllLpo,
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: getAllLpo,
        color: primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      children: [
                        _buildSummarySection(),
                        const SizedBox(height: 14),
                        _buildFilterSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (isLoading && allLpoList.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (visibleLpoList.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 30),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: _buildLpoCard(visibleLpoList[index]),
                        ),
                      );
                    },
                    childCount: visibleLpoList.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                title: 'Total',
                value: '$totalLpoCount',
                icon: Icons.receipt_long_outlined,
                foregroundColor: primary,
                backgroundColor: const Color(0xFFDBEAFE),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                title: 'Pending',
                value: '${_statusCount('pending')}',
                icon: Icons.schedule_outlined,
                foregroundColor: const Color(0xFFB45309),
                backgroundColor: const Color(0xFFFEF3C7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                title: 'Approved',
                value: '${_statusCount('approved')}',
                icon: Icons.check_circle_outline,
                foregroundColor: const Color(0xFF15803D),
                backgroundColor: const Color(0xFFDCFCE7),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                title: 'Confirmed',
                value: '${_statusCount('confirmed')}',
                icon: Icons.verified_outlined,
                foregroundColor: const Color(0xFF1D4ED8),
                backgroundColor: const Color(0xFFDBEAFE),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color foregroundColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: foregroundColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search invoice, company, staff, item...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: searchController.clear,
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: muted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: primary,
                  width: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 11),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _statusFilterChip(
                  label: 'All',
                  value: 'all',
                  count: allLpoList.length,
                ),
                _statusFilterChip(
                  label: 'Pending',
                  value: 'pending',
                  count: _statusCount('pending'),
                ),
                _statusFilterChip(
                  label: 'Approved',
                  value: 'approved',
                  count: _statusCount('approved'),
                ),
                _statusFilterChip(
                  label: 'Confirmed',
                  value: 'confirmed',
                  count: _statusCount('confirmed'),
                ),
                _statusFilterChip(
                  label: 'Rejected',
                  value: 'rejected',
                  count: _statusCount('rejected'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusFilterChip({
    required String label,
    required String value,
    required int count,
  }) {
    final selected = selectedStatus == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        showCheckmark: false,
        label: Text('$label ($count)'),
        onSelected: (_) {
          setState(() {
            selectedStatus = value;
          });
          _applyFilters();
        },
        labelStyle: TextStyle(
          color: selected ? Colors.white : textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
        selectedColor: primary,
        backgroundColor: muted,
        side: BorderSide(
          color: selected ? primary : border,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 10, 14, 30),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 45,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                size: 52,
                color: primary,
              ),
              const SizedBox(height: 12),
              const Text(
                'No purchase orders found',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                searchController.text.trim().isNotEmpty ||
                        selectedStatus != 'all'
                    ? 'Try changing the search or status filter.'
                    : 'No LPO records are currently available.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLpoCard(Map<String, dynamic> lpo) {
    final id = _toInt(lpo['id']) ?? 0;
    final status =
        lpo['status']?.toString().trim().toLowerCase() ?? 'pending';
    final invoice = lpo['invoice']?.toString().trim() ?? '';
    final rawItems =
        lpo['items'] is List ? lpo['items'] as List : <dynamic>[];

    final isUpdatingStatus = updatingStatusIds.contains(id);
    final isDownloading = downloadingInvoiceIds.contains(id);
    final isEditing = editingLpoIds.contains(id);
    final isLoadingEditDetail =
        loadingEditDetailIds.contains(id);

    final canShowApproveReject =
        !isDepartmentLoading && _canApproveOrReject && status == 'pending';

    final canShowConfirm =
        !isDepartmentLoading && _canConfirm && status == 'approved';

    final canShowAccountsReject =
        !isDepartmentLoading && _canConfirm && status == 'approved';

    final canShowInvoice = status == 'confirmed';

    final canShowEdit = !isDepartmentLoading &&
        _canEditLpo &&
        status == 'approved';

    final totalAmount = _lpoTotal(lpo);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: canShowEdit && !isLoadingEditDetail
              ? () => openLpoForEditing(lpo)
              : null,
          child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.isEmpty ? 'LPO #$id' : invoice,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lpo['company_name']?.toString().trim().isEmpty ?? true
                            ? 'Company not available'
                            : lpo['company_name'].toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _statusBadge(status),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: muted,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: border),
                            ),
                            child: Text(
                              _displayApiDate(
                                lpo['date']?.toString() ?? '',
                              ),
                              style: const TextStyle(
                                color: textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isLoadingEditDetail)
                  const Padding(
                    padding: EdgeInsets.only(
                      left: 8,
                      top: 8,
                    ),
                    child: SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  )
                else if (canShowEdit)
                  const Padding(
                    padding: EdgeInsets.only(
                      left: 8,
                      top: 5,
                    ),
                    child: Icon(
                      Icons.edit_note_rounded,
                      color: Color(0xFF7C3AED),
                      size: 23,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: border),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPeopleAndBankSection(lpo),
                const SizedBox(height: 13),
                _buildNoteSection(lpo['note']?.toString() ?? ''),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const Text(
                      'Purchase Items',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${rawItems.length} '
                      '${rawItems.length == 1 ? 'item' : 'items'}',
                      style: const TextStyle(
                        color: textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (rawItems.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: muted,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Text(
                      'No items available.',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  ...rawItems.whereType<Map>().map(_buildItemCard),
                if (totalAmount > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: const Color(0xFFBFDBFE),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Total item amount',
                          style: TextStyle(
                            color: Color(0xFF1E40AF),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '₹${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF1D4ED8),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 13),
                _buildAuditSection(lpo),
                if (canShowApproveReject ||
                    canShowAccountsReject ||
                    canShowConfirm ||
                    canShowEdit ||
                    canShowInvoice) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: border),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        if (canShowApproveReject)
                          OutlinedButton.icon(
                            onPressed: isUpdatingStatus
                                ? null
                                : () => _showStatusConfirmationDialog(
                                      id: id,
                                      targetStatus: 'approved',
                                    ),
                            icon: isUpdatingStatus
                                ? const SizedBox(
                                    width: 17,
                                    height: 17,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.check_circle_outline,
                                    size: 17,
                                  ),
                            label: const Text('Approve'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF15803D),
                              side: const BorderSide(
                                color: Color(0xFF15803D),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                          ),
                        if (canShowApproveReject)
                          OutlinedButton.icon(
                            onPressed: isUpdatingStatus
                                ? null
                                : () => _showStatusConfirmationDialog(
                                      id: id,
                                      targetStatus: 'rejected',
                                    ),
                            icon: const Icon(
                              Icons.cancel_outlined,
                              size: 17,
                            ),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(
                                color: Color(0xFFDC2626),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                          ),
                        if (canShowAccountsReject)
                          OutlinedButton.icon(
                            onPressed: isUpdatingStatus
                                ? null
                                : () => _showStatusConfirmationDialog(
                                      id: id,
                                      targetStatus: 'rejected',
                                    ),
                            icon: const Icon(
                              Icons.cancel_outlined,
                              size: 17,
                            ),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(
                                color: Color(0xFFDC2626),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                          ),
                        if (canShowEdit)
                          OutlinedButton.icon(
                            onPressed: isEditing
                                ? null
                                : () => openLpoForEditing(lpo),
                            icon: isEditing
                                ? const SizedBox(
                                    width: 17,
                                    height: 17,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.edit_outlined,
                                    size: 17,
                                  ),
                            label: const Text('Edit'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF7C3AED),
                              side: const BorderSide(
                                color: Color(0xFF7C3AED),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                          ),
                        if (canShowConfirm)
                          ElevatedButton.icon(
                            onPressed: isUpdatingStatus
                                ? null
                                : () {
                                    final hasBank =
                                        _toInt(lpo['bank']) != null;
                                    final items = lpo['items'] is List
                                        ? lpo['items'] as List
                                        : <dynamic>[];
                                    final hasMissingAmount =
                                        items.whereType<Map>().any(
                                              (item) =>
                                                  item['amount'] == null ||
                                                  item['amount']
                                                      .toString()
                                                      .trim()
                                                      .isEmpty,
                                            );

                                    if (!hasBank ||
                                        hasMissingAmount) {
                                      _showMessage(
                                        'Edit this LPO and add the bank and all item amounts before confirmation.',
                                        error: true,
                                      );
                                      return;
                                    }

                                    _showStatusConfirmationDialog(
                                      id: id,
                                      targetStatus: 'confirmed',
                                    );
                                  },
                            icon: isUpdatingStatus
                                ? const SizedBox(
                                    width: 17,
                                    height: 17,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.verified_outlined,
                                    size: 17,
                                  ),
                            label: const Text('Confirm'),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xFF047857),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                          ),
                        if (canShowInvoice)
                          OutlinedButton.icon(
                            onPressed: isDownloading
                                ? null
                                : () => downloadInvoice(id),
                            icon: isDownloading
                                ? const SizedBox(
                                    width: 17,
                                    height: 17,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.download_rounded,
                                    size: 17,
                                  ),
                            label: Text(
                              isDownloading ? 'Opening...' : 'Invoice',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primary,
                              backgroundColor: const Color(0xFFEFF6FF),
                              side: const BorderSide(
                                color: Color(0xFFBFDBFE),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeopleAndBankSection(Map<String, dynamic> lpo) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: muted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          _infoRow(
            icon: Icons.person_outline,
            label: 'Requested by',
            value: lpo['requested_by_name']?.toString() ?? '',
          ),
          _infoRow(
            icon: Icons.check_circle_outline,
            label: 'Approved by',
            value: lpo['approved_by_name']?.toString() ?? '',
          ),
          _infoRow(
            icon: Icons.verified_outlined,
            label: 'Confirmed by',
            value: lpo['confirmed_by_name']?.toString() ?? '',
          ),
          _infoRow(
            icon: Icons.account_balance_outlined,
            label: 'Bank',
            value: lpo['bank_name']?.toString() ?? '',
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNoteSection(String note) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: muted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.notes_rounded,
            size: 18,
            color: textSecondary,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Note',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  note.trim().isEmpty ? 'No note added.' : note.trim(),
                  style: const TextStyle(
                    color: textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(Map item) {
    final product = item['product']?.toString().trim() ?? '';
    final description =
        item['product_description']?.toString().trim() ?? '';
    final quantity = _toInt(item['quantity']) ?? 0;
    final hasAmount =
        item['amount'] != null && item['amount'].toString().trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFF1F5F9),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 18,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.isEmpty ? 'Unnamed product' : product,
                  style: const TextStyle(
                    color: textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      color: textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 7),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _itemTag(
                      icon: Icons.numbers_rounded,
                      label: 'Qty $quantity',
                    ),
                    _itemTag(
                      icon: Icons.currency_rupee_rounded,
                      label: hasAmount
                          ? _formatAmount(item['amount'])
                          : 'Amount not added',
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

  Widget _itemTag({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: muted,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditSection(Map<String, dynamic> lpo) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 2),
      childrenPadding: const EdgeInsets.only(bottom: 8),
      shape: const Border(),
      collapsedShape: const Border(),
      leading: const Icon(
        Icons.history_rounded,
        size: 19,
        color: textSecondary,
      ),
      title: const Text(
        'Record history',
        style: TextStyle(
          color: textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: muted,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              _infoRow(
                icon: Icons.add_circle_outline,
                label: 'Created',
                value: _displayDateTime(
                  lpo['created_at']?.toString() ?? '',
                ),
              ),
              _infoRow(
                icon: Icons.update_rounded,
                label: 'Updated',
                value: _displayDateTime(
                  lpo['updated_at']?.toString() ?? '',
                ),
                last: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    bool last = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: textSecondary,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '—' : value.trim(),
              style: const TextStyle(
                color: textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _showEditLpoDialog(Map<String, dynamic> lpo) async {
    final id = _toInt(lpo['id']) ?? 0;
    final formKey = GlobalKey<FormState>();
    final noteController = TextEditingController(
      text: lpo['note']?.toString() ?? '',
    );

    int? selectedBankId = _toInt(lpo['bank']);

    final rawItems =
        lpo['items'] is List ? lpo['items'] as List : <dynamic>[];

    final editableItems = rawItems.whereType<Map>().map((rawItem) {
      final item = Map<String, dynamic>.from(rawItem);

      return {
        'id': item['id'],
        'product': item['product']?.toString() ?? '',
        'product_description':
            item['product_description']?.toString() ?? '',
        'quantity': _toInt(item['quantity']) ?? 0,
        'amount': item['amount'],
        'amount_controller': TextEditingController(
          text: item['amount']?.toString() ?? '',
        ),
      };
    }).toList();

    bool dialogSaving = false;

    InputDecoration professionalDecoration({
      required String label,
      required String hint,
      required IconData icon,
      bool alignLabelWithHint = false,
      String? prefixText,
    }) {
      OutlineInputBorder outline(Color color, [double width = 1]) {
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: color,
            width: width,
          ),
        );
      }

      return InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          size: 20,
          color: textSecondary,
        ),
        prefixText: prefixText,
        alignLabelWithHint: alignLabelWithHint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        labelStyle: const TextStyle(
          color: textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        border: outline(border),
        enabledBorder: outline(border),
        focusedBorder: outline(primary, 1.5),
        errorBorder: outline(const Color(0xFFDC2626)),
        focusedErrorBorder: outline(
          const Color(0xFFDC2626),
          1.5,
        ),
      );
    }

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              final mediaQuery = MediaQuery.of(dialogContext);
              final availableHeight =
                  mediaQuery.size.height - mediaQuery.viewInsets.bottom;

              double currentTotal = 0;

              for (final item in editableItems) {
                final controller =
                    item['amount_controller'] as TextEditingController;

                currentTotal +=
                    double.tryParse(controller.text.trim()) ?? 0;
              }

              return Dialog(
                insetPadding: EdgeInsets.symmetric(
                  horizontal: mediaQuery.size.width < 600 ? 12 : 28,
                  vertical: 18,
                ),
                backgroundColor: Colors.transparent,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 680,
                    maxHeight: availableHeight * 0.92,
                  ),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    clipBehavior: Clip.antiAlias,
                    elevation: 18,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(
                            20,
                            18,
                            12,
                            18,
                          ),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF1E3A8A),
                                Color(0xFF2563EB),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.22),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit_note_rounded,
                                  color: Colors.white,
                                  size: 25,
                                ),
                              ),
                              const SizedBox(width: 13),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Edit Local Purchase Order',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'Add bank details and update item amounts',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Close',
                                onPressed: dialogSaving
                                    ? null
                                    : () => Navigator.pop(dialogContext),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: Form(
                            key: formKey,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                18,
                                18,
                                20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: border),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDBEAFE),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.receipt_long_rounded,
                                            color: primary,
                                            size: 21,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                lpo['invoice']?.toString() ??
                                                    'LPO #$id',
                                                style: const TextStyle(
                                                  color: textPrimary,
                                                  fontSize: 14,
                                                  fontWeight:
                                                      FontWeight.w900,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                lpo['company_name']
                                                        ?.toString() ??
                                                    '',
                                                style: const TextStyle(
                                                  color: textSecondary,
                                                  fontSize: 11,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 7,
                                                runSpacing: 7,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 9,
                                                      vertical: 5,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFDCFCE7,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        20,
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      'APPROVED',
                                                      style: TextStyle(
                                                        color: Color(
                                                          0xFF15803D,
                                                        ),
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 9,
                                                      vertical: 5,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        20,
                                                      ),
                                                      border: Border.all(
                                                        color: border,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      _displayApiDate(
                                                        lpo['date']
                                                                ?.toString() ??
                                                            '',
                                                      ),
                                                      style: const TextStyle(
                                                        color: textSecondary,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
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
                                  const SizedBox(height: 18),
                                  const Text(
                                    'Purchase Details',
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Select the payment bank and update the order note.',
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<int>(
                                    value: selectedBankId,
                                    isExpanded: true,
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                    ),
                                    dropdownColor: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    decoration: professionalDecoration(
                                      label: 'Bank',
                                      hint: 'Select bank',
                                      icon:
                                          Icons.account_balance_outlined,
                                    ),
                                    items: banks.map((bank) {
                                      final branch = bank['branch']
                                              ?.toString()
                                              .trim() ??
                                          '';

                                      final bankName =
                                          bank['name']?.toString().trim() ??
                                              '';

                                      final displayName = branch.isEmpty
                                          ? bankName
                                          : '$bankName - $branch';

                                      return DropdownMenuItem<int>(
                                        value: _toInt(bank['id']),
                                        child: Text(
                                          displayName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: textPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: dialogSaving
                                        ? null
                                        : (value) {
                                            setDialogState(() {
                                              selectedBankId = value;
                                            });
                                          },
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Please select a bank';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 13),
                                  TextFormField(
                                    controller: noteController,
                                    enabled: !dialogSaving,
                                    maxLength: 500,
                                    maxLines: 3,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    decoration: professionalDecoration(
                                      label: 'Note',
                                      hint: 'Enter purchase note',
                                      icon: Icons.notes_rounded,
                                      alignLabelWithHint: true,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Purchase Items',
                                              style: TextStyle(
                                                color: textPrimary,
                                                fontSize: 14,
                                                fontWeight:
                                                    FontWeight.w900,
                                              ),
                                            ),
                                            SizedBox(height: 3),
                                            Text(
                                              'Enter the amount for every item.',
                                              style: TextStyle(
                                                color: textSecondary,
                                                fontSize: 11,
                                                fontWeight:
                                                    FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${editableItems.length} '
                                          '${editableItems.length == 1 ? 'item' : 'items'}',
                                          style: const TextStyle(
                                            color: primary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ...editableItems
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    final index = entry.key;
                                    final item = entry.value;
                                    final amountController =
                                        item['amount_controller']
                                            as TextEditingController;

                                    return Container(
                                      margin:
                                          const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        border: Border.all(color: border),
                                      ),
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding:
                                                const EdgeInsets.all(13),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: 38,
                                                  height: 38,
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFDBEAFE,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      11,
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '${index + 1}',
                                                      style: const TextStyle(
                                                        color: primary,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 11),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        item['product']
                                                                ?.toString()
                                                                .trim()
                                                                .isEmpty ??
                                                            true
                                                            ? 'Unnamed product'
                                                            : item['product']
                                                                .toString(),
                                                        style:
                                                            const TextStyle(
                                                          color: textPrimary,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                        ),
                                                      ),
                                                      if (item[
                                                              'product_description']
                                                          .toString()
                                                          .trim()
                                                          .isNotEmpty) ...[
                                                        const SizedBox(
                                                          height: 3,
                                                        ),
                                                        Text(
                                                          item[
                                                                  'product_description']
                                                              .toString(),
                                                          maxLines: 2,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                            color:
                                                                textSecondary,
                                                            fontSize: 10,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 9,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      10,
                                                    ),
                                                    border: Border.all(
                                                      color: border,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Qty ${item['quantity']}',
                                                    style: const TextStyle(
                                                      color: textSecondary,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Divider(
                                            height: 1,
                                            color: border,
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.all(13),
                                            child: TextFormField(
                                              controller:
                                                  amountController,
                                              enabled: !dialogSaving,
                                              keyboardType:
                                                  const TextInputType
                                                      .numberWithOptions(
                                                decimal: true,
                                              ),
                                              onChanged: (_) {
                                                setDialogState(() {});
                                              },
                                              decoration:
                                                  professionalDecoration(
                                                label: 'Item amount',
                                                hint: 'Enter amount',
                                                icon: Icons
                                                    .currency_rupee_rounded,
                                              ),
                                              validator: (value) {
                                                final amount =
                                                    double.tryParse(
                                                  value?.trim() ?? '',
                                                );

                                                if (amount == null ||
                                                    amount < 0) {
                                                  return 'Enter a valid amount';
                                                }

                                                return null;
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 13,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFEFF6FF),
                                          Color(0xFFF8FAFC),
                                        ],
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(15),
                                      border: Border.all(
                                        color: const Color(0xFFBFDBFE),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 37,
                                          height: 37,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(11),
                                          ),
                                          child: const Icon(
                                            Icons.calculate_outlined,
                                            color: primary,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Expanded(
                                          child: Text(
                                            'Total Amount',
                                            style: TextStyle(
                                              color: Color(0xFF1E3A8A),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '₹${currentTotal.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: primary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.fromLTRB(
                            18,
                            13,
                            18,
                            13 + mediaQuery.padding.bottom,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              top: BorderSide(color: border),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: dialogSaving
                                      ? null
                                      : () => Navigator.pop(dialogContext),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: textSecondary,
                                    side: const BorderSide(color: border),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(13),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: dialogSaving
                                      ? null
                                      : () async {
                                          if (!(formKey.currentState
                                                  ?.validate() ??
                                              false)) {
                                            return;
                                          }

                                          if (selectedBankId == null) {
                                            return;
                                          }

                                          setDialogState(() {
                                            dialogSaving = true;
                                          });

                                          try {
                                            for (final item
                                                in editableItems) {
                                              final controller =
                                                  item['amount_controller']
                                                      as TextEditingController;

                                              item['amount'] =
                                                  controller.text.trim();
                                            }

                                            await updateLpo(
                                              id: id,
                                              lpo: lpo,
                                              bankId: selectedBankId!,
                                              note: noteController.text,
                                              items: editableItems,
                                            );

                                            if (dialogContext.mounted) {
                                              Navigator.pop(dialogContext);
                                            }
                                          } catch (_) {
                                            if (dialogContext.mounted) {
                                              setDialogState(() {
                                                dialogSaving = false;
                                              });
                                            }
                                          }
                                        },
                                  icon: dialogSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.save_outlined,
                                          size: 19,
                                        ),
                                  label: Text(
                                    dialogSaving
                                        ? 'Saving changes...'
                                        : 'Save Changes',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: primary,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        primary.withOpacity(0.55),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(13),
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
                ),
              );
            },
          );
        },
      );
    } finally {
      noteController.dispose();

      for (final item in editableItems) {
        final controller =
            item['amount_controller'] as TextEditingController;
        controller.dispose();
      }
    }
  }

  void _showStatusConfirmationDialog({
    required int id,
    required String targetStatus,
  }) {
    final isApprove = targetStatus == 'approved';
    final isReject = targetStatus == 'rejected';

    final actionLabel = isApprove
        ? 'Approve'
        : isReject
            ? 'Reject'
            : 'Confirm';

    final actionColor = isApprove
        ? const Color(0xFF15803D)
        : isReject
            ? const Color(0xFFDC2626)
            : const Color(0xFF047857);

    final icon = isApprove
        ? Icons.check_circle_outline
        : isReject
            ? Icons.cancel_outlined
            : Icons.verified_outlined;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            '$actionLabel LPO?',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            isReject
                ? 'This LPO will be rejected and cannot proceed to confirmation.'
                : isApprove
                    ? 'This LPO will move to the approved stage.'
                    : 'This LPO will be confirmed and its invoice will become available to all departments.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                updateLpoStatus(id, targetStatus);
              },
              icon: Icon(icon, size: 18),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted || message.trim().isEmpty) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                error
                    ? Icons.error_outline
                    : Icons.check_circle_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  maxLines: 4,
                ),
              ),
            ],
          ),
          backgroundColor: error
              ? const Color(0xFFB91C1C)
              : const Color(0xFF047857),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }
}
