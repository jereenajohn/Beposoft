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
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommissionReceiptScreen extends StatefulWidget {
  const CommissionReceiptScreen({super.key});

  @override
  State<CommissionReceiptScreen> createState() =>
      _CommissionReceiptScreenState();
}

class _CommissionReceiptScreenState extends State<CommissionReceiptScreen> {
  static const Color primary = Color(0xFF2563EB);
  static const Color background = Color(0xFFF1F5F9);
  static const Color muted = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color success = Color(0xFF047857);
  static const Color danger = Color(0xFFDC2626);

  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final transactionController = TextEditingController();
  final remarkController = TextEditingController();
  final receiptSearchController = TextEditingController();
  final orderSearchController = TextEditingController();

  List<Map<String, dynamic>> banks = [];
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> receipts = [];

  dynamic respo;

  int? selectedOrderId;
  int? selectedBankId;
  int? editingId;

  DateTime receivedAt = DateTime.now();

  bool loadingBanks = false;
  bool loadingOrders = false;
  bool loadingReceipts = false;
  bool loadingEdit = false;
  bool saving = false;

  String currentDepartment = '';

  int orderPage = 1;
  bool hasNextOrderPage = false;
  String bankFilter = 'all';

  Timer? searchDebounce;

  @override
  void initState() {
    super.initState();
    receiptSearchController.addListener(_onSearchChanged);
    loadDepartment();
    _loadInitialData();
  }

  @override
  void dispose() {
    searchDebounce?.cancel();
    receiptSearchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    amountController.dispose();
    transactionController.dispose();
    remarkController.dispose();
    orderSearchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    searchDebounce?.cancel();
    searchDebounce = Timer(
      const Duration(milliseconds: 450),
      fetchReceipts,
    );
    setState(() {});
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      fetchBanks(),
      fetchOrders(reset: true),
      fetchReceipts(),
    ]);
  }

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.trim().isEmpty) {
      throw Exception('Authentication token not found. Please log in again.');
    }

    return token.trim();
  }

  Future<String?> gettokenFromPrefs() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> loadDepartment() async {
    final String? department = await getdepFromPrefs();

    if (!mounted) return;

    setState(() {
      currentDepartment =
          department?.trim().toUpperCase() ?? '';
    });
  }

  bool get canUpdate {
    final String department =
        currentDepartment.trim().toUpperCase();

    return department == 'ADMIN' ||
        department == 'COO' ||
        department == 'CEO';
  }

  Future<void> AddStatusTime(
    BuildContext scaffoldContext,
  ) async {
    final String? token = await gettokenFromPrefs();

    try {
      final http.Response response = await http.post(
        Uri.parse(
          '$api/api/datalog/create/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'before_data': {
            "Action": "Recipt added ",
          },
          'after_data': {
            "Data": "$respo",
          },
          'order': "",
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(
          scaffoldContext,
        ).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              'time added Successfully.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          scaffoldContext,
        ).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'Adding time failed.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'Error adding status time: $e',
      );
    }
  }

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  int? _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  List<dynamic> _extractList(dynamic body) {
    if (body is List) return body;
    if (body is! Map) return [];

    if (body['data'] is List) return body['data'];
    if (body['results'] is List) return body['results'];

    if (body['results'] is Map) {
      if (body['results']['data'] is List) {
        return body['results']['data'];
      }
      if (body['results']['results'] is List) {
        return body['results']['results'];
      }
    }

    return [];
  }

  Map<String, dynamic> _extractObject(dynamic body) {
    if (body is! Map) return {};

    final root = Map<String, dynamic>.from(body);

    if (root['data'] is Map) {
      return Map<String, dynamic>.from(root['data']);
    }

    if (root['results'] is Map && root['results']['data'] is Map) {
      return Map<String, dynamic>.from(root['results']['data']);
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
    } catch (_) {}

    if (response.body.trim().isNotEmpty) {
      return response.body.trim();
    }

    return 'Request failed with status ${response.statusCode}.';
  }

  String _errorText(Object error) =>
      error.toString().replaceFirst('Exception: ', '').trim();

  Future<void> fetchBanks() async {
    if (mounted) setState(() => loadingBanks = true);

    try {
      final token = await _token();
      final response = await http.get(
        Uri.parse('$api/api/banks/'),
        headers: _headers(token),
      );

      debugPrint('BANK STATUS: ${response.statusCode}');
      debugPrint('BANK RESPONSE: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(_responseError(response));
      }

      final list = _extractList(jsonDecode(response.body));

      final parsed = list.whereType<Map>().map<Map<String, dynamic>>((raw) {
        return {
          'id': raw['id'],
          'name': raw['name']?.toString() ?? '',
          'branch': raw['branch']?.toString() ?? '',
        };
      }).where((item) {
        return _toInt(item['id']) != null &&
            item['name'].toString().trim().isNotEmpty;
      }).toList();

      if (!mounted) return;
      setState(() => banks = parsed);
    } catch (error, stackTrace) {
      debugPrint('BANK ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage(_errorText(error), error: true);
    } finally {
      if (mounted) setState(() => loadingBanks = false);
    }
  }

  Future<void> fetchOrders({
    bool reset = false,
    String search = '',
  }) async {
    if (reset) {
      orderPage = 1;
      if (mounted) {
        setState(() {
          loadingOrders = true;
          orders = [];
        });
      }
    } else {
      if (!hasNextOrderPage || loadingOrders) return;
      orderPage += 1;
      if (mounted) setState(() => loadingOrders = true);
    }

    try {
      final token = await _token();

      final query = <String, String>{
        'page': orderPage.toString(),
      };

      if (search.trim().isNotEmpty) {
        query['search'] = search.trim();
      }

      final uri = Uri.parse('$api/api/orders/').replace(
        queryParameters: query,
      );

      final response = await http.get(
        uri,
        headers: _headers(token),
      );

      debugPrint('ORDER STATUS: ${response.statusCode}');
      debugPrint('ORDER RESPONSE: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(_responseError(response));
      }

      final decoded = jsonDecode(response.body);
      final list = _extractList(decoded);

      final parsed = list
          .whereType<Map>()
          .map<Map<String, dynamic>>((raw) {
            final customer = raw['customer'];

            return {
              'id': raw['id'],
              'invoice': raw['invoice']?.toString() ?? '',
              'customer_name': customer is Map
                  ? customer['name']?.toString() ??
                      customer['customer_name']?.toString() ??
                      ''
                  : raw['customer_name']?.toString() ??
                      customer?.toString() ??
                      '',
              'status': raw['status']?.toString() ?? '',
              'total_amount': raw['total_amount'],
              'order_date': raw['order_date']?.toString() ?? '',
            };
          })
          .where((item) => _toInt(item['id']) != null)
          .toList();

      dynamic next;
      if (decoded is Map) {
        next = decoded['next'];
      }

      if (!mounted) return;

      setState(() {
        if (reset) {
          orders = parsed;
        } else {
          final ids = orders.map((e) => _toInt(e['id'])).toSet();
          orders.addAll(
            parsed.where((e) => !ids.contains(_toInt(e['id']))),
          );
        }

        hasNextOrderPage = next != null;
      });
    } catch (error, stackTrace) {
      debugPrint('ORDER ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage(_errorText(error), error: true);

      if (!reset && orderPage > 1) {
        orderPage -= 1;
      }
    } finally {
      if (mounted) setState(() => loadingOrders = false);
    }
  }

  Future<void> fetchReceipts() async {
    if (mounted) setState(() => loadingReceipts = true);

    try {
      final token = await _token();

      final query = <String, String>{};
      final search = receiptSearchController.text.trim();

      if (search.isNotEmpty) query['search'] = search;
      if (bankFilter != 'all') query['bank_id'] = bankFilter;

      final uri = Uri.parse(
        '$api/api/commission/receipts/add/',
      ).replace(
        queryParameters: query.isEmpty ? null : query,
      );

      final response = await http.get(
        uri,
        headers: _headers(token),
      );

      debugPrint('RECEIPT STATUS: ${response.statusCode}');
      debugPrint('RECEIPT RESPONSE: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(_responseError(response));
      }

      final list = _extractList(jsonDecode(response.body));

      final parsed = list
          .whereType<Map>()
          .map<Map<String, dynamic>>((raw) {
            final order = raw['order'];
            final bank = raw['bank'];
            final createdBy = raw['created_by'];

            return {
              'id': raw['id'],
              'order': order is Map ? order['id'] : order,
              'order_name': order is Map
                  ? order['invoice']?.toString() ??
                      order['order_name']?.toString() ??
                      ''
                  : raw['order_name']?.toString() ??
                      raw['order_invoice']?.toString() ??
                      '',
              'payment_receipt':
                  raw['payment_receipt']?.toString() ?? '',
              'amount': raw['amount'],
              'bank': bank is Map ? bank['id'] : bank,
              'bank_name': bank is Map
                  ? bank['name']?.toString() ?? ''
                  : raw['bank_name']?.toString() ?? '',
              'transactionID':
                  raw['transactionID']?.toString() ?? '',
              'received_at':
                  raw['received_at']?.toString() ?? '',
              'created_by':
                  createdBy is Map ? createdBy['id'] : createdBy,
              'created_by_name': createdBy is Map
                  ? createdBy['name']?.toString() ??
                      createdBy['username']?.toString() ??
                      ''
                  : raw['created_by_name']?.toString() ?? '',
              'remark': raw['remark']?.toString() ?? '',
              'created_at':
                  raw['created_at']?.toString() ?? '',
              'updated_at':
                  raw['updated_at']?.toString() ?? '',
            };
          })
          .where((item) => _toInt(item['id']) != null)
          .toList();

      if (!mounted) return;
      setState(() => receipts = parsed);
    } catch (error, stackTrace) {
      debugPrint('RECEIPT ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage(_errorText(error), error: true);
    } finally {
      if (mounted) setState(() => loadingReceipts = false);
    }
  }

  Future<void> fetchReceiptForEdit(int id) async {
    if (loadingEdit) return;
    setState(() => loadingEdit = true);

    try {
      final token = await _token();
      final response = await http.get(
        Uri.parse('$api/api/commission/receipts/edit/$id/'),
        headers: _headers(token),
      );

      debugPrint('EDIT RECEIPT STATUS: ${response.statusCode}');
      debugPrint('EDIT RECEIPT RESPONSE: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(_responseError(response));
      }

      final data = _extractObject(jsonDecode(response.body));
      final order = data['order'];
      final bank = data['bank'];

      final orderId = order is Map ? _toInt(order['id']) : _toInt(order);
      final bankId = bank is Map ? _toInt(bank['id']) : _toInt(bank);

      if (orderId != null &&
          !orders.any((item) => _toInt(item['id']) == orderId)) {
        orders.insert(0, {
          'id': orderId,
          'invoice': order is Map
              ? order['invoice']?.toString() ?? 'Order #$orderId'
              : 'Order #$orderId',
          'customer_name':
              order is Map ? order['customer_name']?.toString() ?? '' : '',
          'status': order is Map ? order['status']?.toString() ?? '' : '',
          'total_amount': order is Map ? order['total_amount'] : null,
          'order_date':
              order is Map ? order['order_date']?.toString() ?? '' : '',
        });
      }

      if (!mounted) return;

      setState(() {
        editingId = id;
        selectedOrderId = orderId;
        selectedBankId = bankId;
        amountController.text = data['amount']?.toString() ?? '';
        transactionController.text = data['transactionID']?.toString() ?? '';
        remarkController.text = data['remark']?.toString() ?? '';
        receivedAt = DateTime.tryParse(
              data['received_at']?.toString() ?? '',
            ) ??
            DateTime.now();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = formKey.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            alignment: 0.02,
          );
        }
      });
    } catch (error, stackTrace) {
      debugPrint('EDIT RECEIPT ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage(_errorText(error), error: true);
    } finally {
      if (mounted) setState(() => loadingEdit = false);
    }
  }

  Future<void> saveReceipt() async {
    FocusScope.of(context).unfocus();

    if (editingId != null && !canUpdate) {
      _showMessage(
        'Only ADMIN, COO, and CEO can update commission receipts.',
        error: true,
      );
      return;
    }

    if (!(formKey.currentState?.validate() ?? false)) {
      _showMessage('Please correct the highlighted fields.', error: true);
      return;
    }

    if (selectedOrderId == null) {
      _showMessage('Please select an order.', error: true);
      return;
    }

    if (selectedBankId == null) {
      _showMessage('Please select a bank.', error: true);
      return;
    }

    setState(() => saving = true);

    try {
      final token = await _token();

      final body = {
        'order': selectedOrderId,
        'amount': amountController.text.trim(),
        'bank': selectedBankId,
        'transactionID': transactionController.text.trim(),
        'received_at': DateFormat('yyyy-MM-dd').format(receivedAt),
        'remark': remarkController.text.trim(),
      };

      final editing = editingId != null;
      final uri = Uri.parse(
        editing
            ? '$api/api/commission/receipts/edit/$editingId/'
            : '$api/api/commission/receipts/add/',
      );

      final response = editing
          ? await http.put(
              uri,
              headers: _headers(token),
              body: jsonEncode(body),
            )
          : await http.post(
              uri,
              headers: _headers(token),
              body: jsonEncode(body),
            );

      debugPrint('SAVE RECEIPT STATUS: ${response.statusCode}');
      debugPrint('SAVE RECEIPT RESPONSE: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(_responseError(response));
      }

      try {
        final dynamic responseData = jsonDecode(response.body);

        if (responseData is Map<String, dynamic>) {
          respo = responseData['data'] ?? responseData;
        } else {
          respo = responseData;
        }
      } catch (_) {
        respo = response.body;
      }

      await AddStatusTime(context);

      if (!mounted) return;

      clearForm();
      await fetchReceipts();

      _showMessage(
        editing
            ? 'Commission receipt updated successfully.'
            : 'Commission receipt added successfully.',
      );
    } catch (error, stackTrace) {
      debugPrint('SAVE RECEIPT ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage(_errorText(error), error: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void clearForm() {
    if (!mounted) return;

    setState(() {
      editingId = null;
      selectedOrderId = null;
      selectedBankId = null;
      receivedAt = DateTime.now();
      amountController.clear();
      transactionController.clear();
      remarkController.clear();
    });

    formKey.currentState?.reset();
  }

  Map<String, dynamic>? get selectedOrder {
    for (final order in orders) {
      if (_toInt(order['id']) == selectedOrderId) return order;
    }
    return null;
  }

  Future<void> _showOrderPicker() async {
    orderSearchController.clear();

    List<Map<String, dynamic>> visibleOrders = List.of(orders);
    bool searching = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> runSearch() async {
              setSheetState(() => searching = true);

              await fetchOrders(
                reset: true,
                search: orderSearchController.text,
              );

              if (!sheetContext.mounted) return;

              setSheetState(() {
                visibleOrders = List.of(orders);
                searching = false;
              });
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.82,
              minChildSize: 0.55,
              maxChildSize: 0.94,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: border,
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 15, 10, 12),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Select Order',
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    'Search by invoice or customer',
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: TextField(
                          controller: orderSearchController,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => runSearch(),
                          decoration: InputDecoration(
                            hintText: 'Search order...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: IconButton(
                              onPressed: runSearch,
                              icon: const Icon(Icons.arrow_forward_rounded),
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
                      ),
                      const SizedBox(height: 10),
                      if (searching || loadingOrders)
                        const LinearProgressIndicator(minHeight: 2),
                      Expanded(
                        child: visibleOrders.isEmpty
                            ? const Center(
                                child: Text(
                                  'No orders found.',
                                  style: TextStyle(color: textSecondary),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  6,
                                  18,
                                  24,
                                ),
                                itemCount: visibleOrders.length +
                                    (hasNextOrderPage ? 1 : 0),
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  if (index == visibleOrders.length) {
                                    return OutlinedButton.icon(
                                      onPressed: loadingOrders
                                          ? null
                                          : () async {
                                              await fetchOrders();
                                              if (!sheetContext.mounted) {
                                                return;
                                              }
                                              setSheetState(() {
                                                visibleOrders = List.of(orders);
                                              });
                                            },
                                      icon: loadingOrders
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.expand_more_rounded,
                                            ),
                                      label: const Text('Load more'),
                                    );
                                  }

                                  final order = visibleOrders[index];
                                  final id = _toInt(order['id']);
                                  final selected = id == selectedOrderId;

                                  return InkWell(
                                    onTap: () {
                                      setState(() => selectedOrderId = id);
                                      Navigator.pop(sheetContext);
                                    },
                                    borderRadius: BorderRadius.circular(15),
                                    child: Container(
                                      padding: const EdgeInsets.all(13),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? const Color(0xFFEFF6FF)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: selected ? primary : border,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: selected ? primary : muted,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.receipt_long_rounded,
                                              color: selected
                                                  ? Colors.white
                                                  : textSecondary,
                                            ),
                                          ),
                                          const SizedBox(width: 11),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  order['invoice']
                                                              ?.toString()
                                                              .trim()
                                                              .isEmpty ??
                                                          true
                                                      ? 'Order #$id'
                                                      : order['invoice']
                                                          .toString(),
                                                  style: const TextStyle(
                                                    color: textPrimary,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  order['customer_name']
                                                              ?.toString()
                                                              .trim()
                                                              .isEmpty ??
                                                          true
                                                      ? 'Customer unavailable'
                                                      : order['customer_name']
                                                          .toString(),
                                                  style: const TextStyle(
                                                    color: textSecondary,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  order['status']?.toString() ??
                                                      '',
                                                  style: const TextStyle(
                                                    color: textSecondary,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (selected)
                                            const Icon(
                                              Icons.check_circle,
                                              color: primary,
                                            ),
                                        ],
                                      ),
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

  }
 Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();
    if (dep == "BDO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                bdo_dashbord()), // Replace AnotherPage with your target page
      );
    } else if (dep == "BDM") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                bdm_dashbord()), // Replace AnotherPage with your target page
      );
    } else if (dep == "warehouse") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                WarehouseDashboard()), // Replace AnotherPage with your target page
      );
    } else if (dep == "CEO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ceo_dashboard()), // Replace AnotherPage with your target page
      );
    } else if (dep == "COO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ceo_dashboard()), // Replace AnotherPage with your target page
      );
    } else if (dep == "COO") {
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
        MaterialPageRoute(
            builder: (context) =>
                WarehouseAdmin()), // Replace AnotherPage with your target page
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => dashboard()),
      );
    }
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
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
            ),
            onPressed: _navigateBack,
          ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Commission Receipts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Add and manage commission payments',
              style: TextStyle(
                color: textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () async {
              await Future.wait([
                fetchBanks(),
                fetchOrders(reset: true),
                fetchReceipts(),
              ]);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        color: primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                children: [
                  _buildForm(),
                  const SizedBox(height: 20),
                  _buildHistory(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final order = selectedOrder;

    return Form(
      key: formKey,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(17),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1E3A8A),
                    Color(0xFF2563EB),
                  ],
                ),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      editingId == null
                          ? Icons.add_card_rounded
                          : Icons.edit_note_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          editingId == null
                              ? 'Add Commission Receipt'
                              : 'Update Commission Receipt',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          editingId == null
                              ? 'Record a commission payment against an order.'
                              : 'Editing receipt ID $editingId',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (editingId != null)
                    IconButton(
                      onPressed: saving ? null : clearForm,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(17),
              child: Column(
                children: [
                  InkWell(
                    onTap: saving ? null : _showOrderPicker,
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration: _decoration(
                        label: 'Order',
                        hint: 'Select order',
                        icon: Icons.receipt_long_outlined,
                        suffixIcon: Icons.keyboard_arrow_down_rounded,
                      ),
                      child: order == null
                          ? const Text(
                              'Select an order',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order['invoice']?.toString().trim().isEmpty ??
                                          true
                                      ? 'Order #${order['id']}'
                                      : order['invoice'].toString(),
                                  style: const TextStyle(
                                    color: textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (order['customer_name']
                                        ?.toString()
                                        .trim()
                                        .isNotEmpty ??
                                    false)
                                  Text(
                                    order['customer_name'].toString(),
                                    style: const TextStyle(
                                      color: textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: amountController,
                    enabled: !saving,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    decoration: _decoration(
                      label: 'Amount',
                      hint: 'Enter commission amount',
                      icon: Icons.currency_rupee_rounded,
                    ),
                    validator: (value) {
                      final amount = double.tryParse(value?.trim() ?? '');
                      if (amount == null || amount <= 0) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    value: selectedBankId,
                    isExpanded: true,
                    decoration: _decoration(
                      label: 'Bank',
                      hint: loadingBanks ? 'Loading banks...' : 'Select bank',
                      icon: Icons.account_balance_outlined,
                    ),
                    items: banks.map((bank) {
                      final name = bank['name']?.toString().trim() ?? '';
                      final branch = bank['branch']?.toString().trim() ?? '';

                      return DropdownMenuItem<int>(
                        value: _toInt(bank['id']),
                        child: Text(
                          branch.isEmpty ? name : '$name - $branch',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: saving || loadingBanks
                        ? null
                        : (value) => setState(() => selectedBankId = value),
                    validator: (value) {
                      if (value == null) return 'Please select a bank';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: transactionController,
                    enabled: !saving,
                    maxLength: 50,
                    textCapitalization: TextCapitalization.characters,
                    decoration: _decoration(
                      label: 'Transaction ID',
                      hint: 'Enter transaction reference',
                      icon: Icons.tag_rounded,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Transaction ID is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: saving
                        ? null
                        : () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: receivedAt,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );

                            if (date != null && mounted) {
                              setState(() => receivedAt = date);
                            }
                          },
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration: _decoration(
                        label: 'Received Date',
                        hint: 'Select received date',
                        icon: Icons.calendar_month_outlined,
                        suffixIcon: Icons.keyboard_arrow_down_rounded,
                      ),
                      child: Text(
                        DateFormat('dd MMM yyyy').format(receivedAt),
                        style: const TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: remarkController,
                    enabled: !saving,
                    minLines: 2,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _decoration(
                      label: 'Remark',
                      hint: 'Enter payment remark',
                      icon: Icons.notes_rounded,
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Remark is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      if (editingId != null) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: saving ? null : clearForm,
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textSecondary,
                              side: const BorderSide(color: border),
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        flex: editingId == null ? 1 : 2,
                        child: ElevatedButton.icon(
                          onPressed: saving
                              ? null
                              : editingId == null
                                  ? saveReceipt
                                  : canUpdate
                                      ? saveReceipt
                                      : null,
                          icon: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  editingId == null
                                      ? Icons.add_card_rounded
                                      : Icons.save_outlined,
                                ),
                          label: Text(
                            saving
                                ? 'Saving...'
                                : editingId == null
                                    ? 'Add Commission'
                                    : 'Update Receipt',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
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
    );
  }

  Widget _buildHistory() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Commission History',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Search and edit commission receipts',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '${receipts.length} receipts',
                      style: const TextStyle(
                        color: primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              TextField(
                controller: receiptSearchController,
                decoration: InputDecoration(
                  hintText: 'Search receipt, invoice, transaction...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: receiptSearchController.text.trim().isEmpty
                      ? null
                      : IconButton(
                          onPressed: receiptSearchController.clear,
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
              DropdownButtonFormField<String>(
                value: bankFilter,
                isExpanded: true,
                decoration: _decoration(
                  label: 'Bank Filter',
                  hint: 'All banks',
                  icon: Icons.filter_alt_outlined,
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Text('All banks'),
                  ),
                  ...banks.map(
                    (bank) => DropdownMenuItem(
                      value: bank['id'].toString(),
                      child: Text(
                        bank['name']?.toString() ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => bankFilter = value ?? 'all');
                  fetchReceipts();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (loadingReceipts && receipts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 45),
            child: CircularProgressIndicator(),
          )
        else if (receipts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 44,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: border),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 50,
                  color: primary,
                ),
                SizedBox(height: 12),
                Text(
                  'No commission receipts found',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          )
        else
          ...receipts.map(_buildReceiptCard),
      ],
    );
  }

  Widget _buildReceiptCard(Map<String, dynamic> receipt) {
    final id = _toInt(receipt['id']) ?? 0;
    final orderId = _toInt(receipt['order']);
    final bankId = _toInt(receipt['bank']);
    final createdById = _toInt(receipt['created_by']);
    final amount = _toDouble(receipt['amount']);

    final receiptNumber =
        receipt['payment_receipt']?.toString().trim() ?? '';
    final orderName =
        receipt['order_name']?.toString().trim() ?? '';
    final bankName =
        receipt['bank_name']?.toString().trim() ?? '';
    final transactionId =
        receipt['transactionID']?.toString().trim() ?? '';
    final createdByName =
        receipt['created_by_name']?.toString().trim() ?? '';
    final remark =
        receipt['remark']?.toString().trim() ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.payments_outlined,
                    color: success,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receiptNumber.isEmpty
                            ? 'Receipt #$id'
                            : receiptNumber,
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        orderName.isEmpty
                            ? orderId == null
                                ? 'Order unavailable'
                                : 'Order #$orderId'
                            : orderName,
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      // Wrap(
                      //   spacing: 7,
                      //   runSpacing: 7,
                      //   children: [
                      //     _detailChip(
                      //       icon: Icons.numbers_rounded,
                      //       label: 'Receipt ID $id',
                      //     ),
                      //     _detailChip(
                      //       icon: Icons.shopping_bag_outlined,
                      //       label: orderId == null
                      //           ? 'Order ID —'
                      //           : 'Order ID $orderId',
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit',
                  onPressed:
                      loadingEdit ? null : () => fetchReceiptForEdit(id),
                  icon: loadingEdit && editingId == id
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: border),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _metric(
                        'Amount',
                        amount == null
                            ? '—'
                            : '₹${amount.toStringAsFixed(2)}',
                        Icons.currency_rupee_rounded,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _metric(
                        'Received Date',
                        _displayDate(
                          receipt['received_at']?.toString() ?? '',
                        ),
                        Icons.calendar_today_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: _metric(
                        'Bank Name',
                        bankName.isEmpty ? '—' : bankName,
                        Icons.account_balance_outlined,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _metric(
                        'Bank ID',
                        bankId?.toString() ?? '—',
                        Icons.badge_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                _fullWidthDetail(
                  icon: Icons.tag_rounded,
                  label: 'Transaction ID',
                  value: transactionId.isEmpty ? '—' : transactionId,
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: _metric(
                        'Created By',
                        createdByName.isEmpty ? '—' : createdByName,
                        Icons.person_outline,
                      ),
                    ),
                    // const SizedBox(width: 9),
                    // Expanded(
                    //   child: _metric(
                    //     'Created By ID',
                    //     createdById?.toString() ?? '—',
                    //     Icons.badge_outlined,
                    //   ),
                    // ),
                  ],
                ),
                const SizedBox(height: 9),
                _fullWidthDetail(
                  icon: Icons.notes_rounded,
                  label: 'Remark',
                  value: remark.isEmpty ? 'No remark added.' : remark,
                ),
                const SizedBox(height: 9),
                _fullWidthDetail(
                  icon: Icons.add_circle_outline,
                  label: 'Created At',
                  value: _displayDateTime(
                    receipt['created_at']?.toString() ?? '',
                  ),
                ),
                const SizedBox(height: 9),
                _fullWidthDetail(
                  icon: Icons.update_rounded,
                  label: 'Updated At',
                  value: _displayDateTime(
                    receipt['updated_at']?.toString() ?? '',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailChip({
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
            size: 12,
            color: textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fullWidthDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: muted,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 17,
            color: textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                SelectableText(
                  value.trim().isEmpty ? '—' : value.trim(),
                  style: const TextStyle(
                    color: textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _displayDateTime(String value) {
    final parsed = DateTime.tryParse(value)?.toLocal();

    if (parsed == null) {
      return value.trim().isEmpty ? '—' : value;
    }

    return DateFormat('dd MMM yyyy, hh:mm a').format(parsed);
  }

  Widget _metric(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: muted,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: textSecondary),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              color: textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  String _displayDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value.trim().isEmpty ? '—' : value;
    }
    return DateFormat('dd MMM yyyy').format(parsed);
  }

  InputDecoration _decoration({
    required String label,
    required String hint,
    required IconData icon,
    IconData? suffixIcon,
    bool alignLabelWithHint = false,
  }) {
    OutlineInputBorder outline(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      suffixIcon: suffixIcon == null ? null : Icon(suffixIcon),
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: muted,
      border: outline(border),
      enabledBorder: outline(border),
      focusedBorder: outline(primary, 1.4),
      errorBorder: outline(danger),
      focusedErrorBorder: outline(danger, 1.4),
    );
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted || message.trim().isEmpty) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                error ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message, maxLines: 4)),
            ],
          ),
          backgroundColor: error ? danger : success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }
}
