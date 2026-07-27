import 'dart:convert';
import 'dart:io';

import 'package:beposoft/pages/api.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class LocalPurchaseOrderScreen extends StatefulWidget {
  const LocalPurchaseOrderScreen({super.key});

  @override
  State<LocalPurchaseOrderScreen> createState() =>
      _LocalPurchaseOrderScreenState();
}

class LpoItem {
  String product;
  String description;
  int quantity;

  LpoItem({
    this.product = '',
    this.description = '',
    this.quantity = 1,
  });

  factory LpoItem.fromJson(Map<String, dynamic> json) {
    return LpoItem(
      product: json['product']?.toString() ?? '',
      description: json['product_description']?.toString() ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.trim(),
      'product_description': description.trim(),
      'quantity': quantity,
    };
  }
}

class _LocalPurchaseOrderScreenState extends State<LocalPurchaseOrderScreen> {
  static const Color primary = Color(0xFF2563EB);
  static const Color background = Color(0xFFF1F5F9);
  static const Color muted = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController noteController = TextEditingController();

  List<Map<String, dynamic>> company = [];
  List<Map<String, dynamic>> lpoList = [];
  List<LpoItem> items = [LpoItem()];

  final Set<int> downloadingInvoiceIds = <int>{};
  final Set<int> deletingIds = <int>{};
  final Set<int> updatingStatusIds = <int>{};

  String currentDepartment = '';
  bool isDepartmentLoading = true;

  int? selectedCompanyId;
  int? editingId;
  int? loadingEditId;
  int totalLpoCount = 0;

  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  bool isCompanyLoading = false;
  bool isSaving = false;
  List<Map<String, dynamic>> bank = [];

  int? selectedBankId;
  @override
  void initState() {
    super.initState();

    _loadCurrentDepartment();
    getcompany();
    getLpo();
    getbank();
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  String _normalizeDepartment(dynamic value) {
    return value
        ?.toString()
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'\s+'), ' ') ??
        '';
  }

  String _departmentFromMap(Map<dynamic, dynamic> data) {
    const departmentKeys = [
      'department',
      'department_name',
      'departmentName',
      'role',
      'role_name',
      'roleName',
    ];

    for (final key in departmentKeys) {
      final value = data[key];

      if (value is Map) {
        final nestedValue =
            value['name'] ?? value['department_name'] ?? value['role_name'];
        final normalized = _normalizeDepartment(nestedValue);
        if (normalized.isNotEmpty) return normalized;
      }

      final normalized = _normalizeDepartment(value);
      if (normalized.isNotEmpty) return normalized;
    }

    const nestedKeys = ['user', 'staff', 'employee', 'data', 'profile'];

    for (final key in nestedKeys) {
      final value = data[key];
      if (value is Map) {
        final department = _departmentFromMap(value);
        if (department.isNotEmpty) return department;
      }
    }

    return '';
  }

  Future<void> _loadCurrentDepartment() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      const directKeys = [
        'department',
        'department_name',
        'departmentName',
        'role',
        'role_name',
        'roleName',
      ];

      String department = '';

      for (final key in directKeys) {
        department = _normalizeDepartment(prefs.get(key));
        if (department.isNotEmpty) break;
      }

      if (department.isEmpty) {
        const jsonKeys = [
          'user',
          'user_data',
          'userData',
          'staff',
          'employee',
          'profile',
          'login_data',
          'loginData',
        ];

        for (final key in jsonKeys) {
          final rawValue = prefs.get(key);

          if (rawValue is String && rawValue.trim().isNotEmpty) {
            try {
              final decoded = jsonDecode(rawValue);
              if (decoded is Map) {
                department = _departmentFromMap(decoded);
              }
            } catch (_) {
              // Ignore non-JSON preference values.
            }
          } else if (rawValue is Map) {
            department = _departmentFromMap(rawValue);
          }

          if (department.isNotEmpty) break;
        }
      }

      debugPrint('CURRENT LPO DEPARTMENT: $department');

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
    }
  }

  bool get _canApproveOrReject {
    const departments = {'HR', 'CEO', 'COO'};
    return departments.contains(currentDepartment);
  }

  bool get _canConfirm {
    const departments = {'ADMIN', 'ACCOUNTS', 'ACCOUNTING'};
    return departments.contains(currentDepartment);
  }

  Future<String?> gettokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String> _token() async {
    final token = await gettokenFromPrefs();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Authentication token not found. Please log in again.');
    }
    return token.trim();
  }

  Map<String, String> _jsonHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  int? _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  List<dynamic> _listFromResponse(dynamic body) {
    if (body is List) return body;
    if (body is! Map) return [];
    if (body['data'] is List) return body['data'];
    if (body['results'] is List) return body['results'];
    if (body['results'] is Map && body['results']['data'] is List) {
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
          if (decoded[key] != null &&
              decoded[key].toString().trim().isNotEmpty) {
            return decoded[key].toString();
          }
        }
        return decoded.entries.map((entry) {
          final value = entry.value;
          if (value is List) return '${entry.key}: ${value.join(', ')}';
          return '${entry.key}: $value';
        }).join('\n');
      }
    } catch (_) {}

    if (response.body.trim().isNotEmpty) return response.body.trim();
    return 'Request failed with status ${response.statusCode}.';
  }

  String _errorText(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  Map<String, dynamic>? get selectedCompany {
    for (final item in company) {
      if (_toInt(item['id']) == selectedCompanyId) return item;
    }
    return null;
  }

  Future<void> getbank() async {
    try {
      final token = await _token();

      final response = await http.get(
        Uri.parse('$api/api/banks/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List<Map<String, dynamic>> bankList = [];

        for (var item in parsed['data']) {
          bankList.add({
            'id': item['id'],
            'name': item['name'],
            'branch': item['branch'],
          });
        }

        if (mounted) {
          setState(() {
            bank = bankList;
          });
        }
      }
    } catch (e) {
      debugPrint("BANK ERROR: $e");
    }
  }

  Future<void> getcompany() async {
    if (mounted) setState(() => isCompanyLoading = true);

    try {
      final token = await _token();
      final response = await http.get(
        Uri.parse('$api/api/company/data/'),
        headers: _jsonHeaders(token),
      );

      if (response.statusCode != 200) {
        throw Exception(_responseError(response));
      }

      final rawList = _listFromResponse(jsonDecode(response.body));
      final result = rawList.whereType<Map>().map<Map<String, dynamic>>((item) {
        return {
          'id': item['id'],
          'name': item['name']?.toString() ?? '',
        };
      }).where((item) {
        return _toInt(item['id']) != null &&
            item['name'].toString().trim().isNotEmpty;
      }).toList();

      if (!mounted) return;
      setState(() => company = result);
    } catch (error, stackTrace) {
      debugPrint('Company Error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage(_errorText(error), error: true);
    } finally {
      if (mounted) setState(() => isCompanyLoading = false);
    }
  }

  Future<void> getLpo() async {
    if (mounted) setState(() => isLoading = true);

    try {
      final token = await _token();
      final response = await http.get(
        Uri.parse('$api/api/lpo/'),
        headers: _jsonHeaders(token),
      );

      debugPrint('LPO STATUS: ${response.statusCode}');
      debugPrint('LPO RESPONSE: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(_responseError(response));
      }

      final decoded = jsonDecode(response.body);
      final rawList = _listFromResponse(decoded);

      final result = rawList
          .whereType<Map>()
          .map<Map<String, dynamic>>((lpo) {
            final rawItems = lpo['items'] is List ? lpo['items'] as List : [];

            return {
              'id': lpo['id'],
              'invoice': lpo['invoice']?.toString() ?? '',
              'date': lpo['date']?.toString() ?? '',
              'company': lpo['company'],
              'company_name': lpo['company_name']?.toString() ?? '',
              'requested_by': lpo['requested_by_name']?.toString() ?? '',
              'note': lpo['note']?.toString() ?? '',
              'status': lpo['status']?.toString() ?? 'pending',
              'items':
                  rawItems.whereType<Map>().map<Map<String, dynamic>>((item) {
                return {
                  'product': item['product']?.toString() ?? '',
                  'description': item['product_description']?.toString() ?? '',
                  'quantity': _toInt(item['quantity']) ?? 0,
                };
              }).toList(),
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
        lpoList = result;
        totalLpoCount = count;
      });
    } catch (error, stackTrace) {
      debugPrint('Get LPO Error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage(_errorText(error), error: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
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

      if (response.statusCode != 200 && response.statusCode != 204) {
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

      await getLpo();
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

  Widget _statusBadge(String status) {
    Color color;

    switch (status) {
      case "approved":
        color = Colors.green;
        break;

      case "rejected":
        color = Colors.red;
        break;

      case "confirmed":
        color = Colors.blue;
        break;

      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Future<void> getSingleLpo(int id) async {
    if (loadingEditId != null) return;

    final matchingLpo = lpoList.cast<Map<String, dynamic>?>().firstWhere(
          (lpo) => _toInt(lpo?['id']) == id,
          orElse: () => null,
        );

    final status =
        matchingLpo?['status']?.toString().trim().toLowerCase() ?? '';

    if (status != 'pending') {
      _showMessage(
        'Only pending LPOs can be edited.',
        error: true,
      );
      return;
    }

    setState(() => loadingEditId = id);

    try {
      final token = await _token();
      final response = await http.get(
        Uri.parse('$api/api/lpo/edit/$id/'),
        headers: _jsonHeaders(token),
      );

      debugPrint('SINGLE LPO STATUS: ${response.statusCode}');
      debugPrint('SINGLE LPO RESPONSE: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(_responseError(response));
      }

      final data = _objectFromResponse(jsonDecode(response.body));
      final rawItems = data['items'] is List ? data['items'] as List : [];
      final loadedItems = rawItems.whereType<Map>().map<LpoItem>((item) {
        return LpoItem.fromJson(Map<String, dynamic>.from(item));
      }).toList();

      if (!mounted) return;
      setState(() {
        editingId = id;

        selectedCompanyId = _toInt(data['company']);

        selectedBankId = _toInt(data['bank']);

        selectedDate =
            DateTime.tryParse(data['date']?.toString() ?? '') ?? DateTime.now();
        noteController.text = data['note']?.toString() ?? '';
        items = loadedItems.isEmpty ? [LpoItem()] : loadedItems;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentContext = formKey.currentContext;
        if (currentContext != null) {
          Scrollable.ensureVisible(
            currentContext,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            alignment: 0.03,
          );
        }
      });
    } catch (error, stackTrace) {
      debugPrint('Edit Fetch Error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage(_errorText(error), error: true);
    } finally {
      if (mounted) setState(() => loadingEditId = null);
    }
  }

  Future<void> saveLpo() async {
    FocusScope.of(context).unfocus();

    if (!(formKey.currentState?.validate() ?? false)) {
      _showMessage('Please correct the highlighted fields.', error: true);
      return;
    }

    if (selectedCompanyId == null) {
      _showMessage('Please select a company.', error: true);
      return;
    }

    if (items.isEmpty ||
        items
            .any((item) => item.product.trim().isEmpty || item.quantity <= 0)) {
      _showMessage('Add at least one valid item.', error: true);
      return;
    }

    setState(() => isSaving = true);

    try {
      final token = await _token();
      final body = {
        'date': _apiDate(selectedDate),
        'company': selectedCompanyId,
        'note': noteController.text.trim(),
        'items': items.map((item) => item.toJson()).toList(),
        if (selectedBankId != null) 'bank': selectedBankId,
      };

      final url =
          editingId == null ? '$api/api/lpo/' : '$api/api/lpo/edit/$editingId/';

      debugPrint('SAVE LPO URL: $url');
      debugPrint('SAVE LPO BODY: ${jsonEncode(body)}');

      final response = editingId == null
          ? await http.post(
              Uri.parse(url),
              headers: _jsonHeaders(token),
              body: jsonEncode(body),
            )
          : await http.put(
              Uri.parse(url),
              headers: _jsonHeaders(token),
              body: jsonEncode(body),
            );

      debugPrint('SAVE LPO STATUS: ${response.statusCode}');
      debugPrint('SAVE LPO RESPONSE: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(_responseError(response));
      }

      final wasEditing = editingId != null;
      clearForm();
      await getLpo();
      _showMessage(
        wasEditing ? 'LPO updated successfully.' : 'LPO created successfully.',
      );
    } catch (error, stackTrace) {
      debugPrint('Save LPO Error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage(_errorText(error), error: true);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> deleteLpo(int id) async {
    if (deletingIds.contains(id)) return;

    final matchingLpo = lpoList.cast<Map<String, dynamic>?>().firstWhere(
          (lpo) => _toInt(lpo?['id']) == id,
          orElse: () => null,
        );

    final status =
        matchingLpo?['status']?.toString().trim().toLowerCase() ?? '';

    if (status != 'pending') {
      _showMessage(
        'Only pending LPOs can be deleted.',
        error: true,
      );
      return;
    }

    setState(() => deletingIds.add(id));

    try {
      final token = await _token();
      final response = await http.delete(
        Uri.parse('$api/api/lpo/edit/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('DELETE LPO STATUS: ${response.statusCode}');
      debugPrint('DELETE LPO RESPONSE: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(_responseError(response));
      }

      if (editingId == id) clearForm();
      await getLpo();
      _showMessage('LPO deleted successfully.');
    } catch (error, stackTrace) {
      debugPrint('Delete LPO Error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage(_errorText(error), error: true);
    } finally {
      if (mounted) setState(() => deletingIds.remove(id));
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

  String? _contentDispositionFileName(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final utf8Match = RegExp(
      r"filename\*=UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(value);
    if (utf8Match != null) {
      return Uri.decodeComponent(utf8Match.group(1)!.trim());
    }

    final normalMatch = RegExp(
      r'filename="?([^";]+)"?',
      caseSensitive: false,
    ).firstMatch(value);
    return normalMatch?.group(1)?.trim();
  }

  String _safePdfName(String name) {
    var result = name
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (result.isEmpty) result = 'LPO-Invoice.pdf';
    if (!result.toLowerCase().endsWith('.pdf')) result = '$result.pdf';
    return result;
  }

  void addItem() => setState(() => items.add(LpoItem()));

  void removeItem(int index) {
    if (items.length == 1) {
      _showMessage('At least one item is required.', error: true);
      return;
    }
    setState(() => items.removeAt(index));
  }

  void clearForm() {
    if (!mounted) return;
    setState(() {
      editingId = null;
      selectedCompanyId = null;
      selectedBankId = null;
      selectedDate = DateTime.now();
      noteController.clear();
      items = [LpoItem()];
    });
    formKey.currentState?.reset();
  }

  String _apiDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _displayDate(DateTime date) {
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
    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} ${date.year}';
  }

  String _displayApiDate(String value) {
    final parsed = DateTime.tryParse(value);
    return parsed == null ? value : _displayDate(parsed);
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
          backgroundColor:
              error ? const Color(0xFFB91C1C) : const Color(0xFF047857),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
              'Local Purchase Orders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              'Create, manage and download invoices',
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
            onPressed: isLoading ? null : getLpo,
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
        onRefresh: getLpo,
        color: primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormCard(),
                  const SizedBox(height: 24),
                  _buildListHeader(),
                  const SizedBox(height: 12),
                  _buildLpoCards(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Form(
      key: formKey,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 22,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      editingId == null
                          ? Icons.post_add_rounded
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
                          editingId == null ? 'Create New LPO' : 'Update LPO',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          editingId == null
                              ? 'Enter purchase order details.'
                              : 'Editing LPO ID $editingId',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (editingId != null)
                    IconButton(
                      onPressed: isSaving ? null : clearForm,
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownSearch<Map<String, dynamic>>(
                    selectedItem: selectedCompany,
                    items: company,
                    itemAsString: (item) => item['name']?.toString() ?? '',
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      menuProps: MenuProps(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: _decoration(
                        'Company',
                        isCompanyLoading
                            ? 'Loading companies...'
                            : 'Select company',
                        Icons.business_outlined,
                      ),
                    ),
                    onChanged: isCompanyLoading
                        ? null
                        : (value) {
                            setState(() {
                              selectedCompanyId = _toInt(value?['id']);
                            });
                          },
                  ),
                  if (editingId != null &&
                      lpoList.any((e) =>
                          e['id'] == editingId &&
                          e['status'] == "approved")) ...[
                    const SizedBox(height: 14),
                    DropdownButtonFormField<int>(
                      value: selectedBankId,
                      decoration: _decoration(
                        "Bank",
                        "Select bank",
                        Icons.account_balance,
                      ),
                      items: bank.map((item) {
                        return DropdownMenuItem<int>(
                          value: item['id'],
                          child: Text(
                            item['name'].toString(),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedBankId = value;
                        });
                      },
                    ),
                  ],
                  if (isCompanyLoading) ...[
                    const SizedBox(height: 7),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  const SizedBox(height: 14),
                  _buildDateField(),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: noteController,
                    maxLines: 2,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _decoration(
                      'Note',
                      'Add an optional note',
                      Icons.notes_rounded,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Purchase Items',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Product, description and quantity',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: isSaving ? null : addItem,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Add item'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(items.length, _buildItemEditor),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (editingId != null) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isSaving ? null : clearForm,
                            icon: const Icon(Icons.close),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
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
                          onPressed: isSaving ? null : saveLpo,
                          icon: isSaving
                              ? const SizedBox(
                                  width: 17,
                                  height: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            isSaving
                                ? 'Saving...'
                                : editingId == null
                                    ? 'Save LPO'
                                    : 'Update LPO',
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
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

  Widget _buildDateField() {
    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: isSaving
          ? null
          : () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (date != null && mounted) {
                setState(() => selectedDate = date);
              }
            },
      child: InputDecorator(
        decoration: _decoration(
          'LPO Date',
          'Select date',
          Icons.calendar_month_outlined,
          suffixIcon: Icons.keyboard_arrow_down,
        ),
        child: Text(
          _displayDate(selectedDate),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildItemEditor(int index) {
    final item = items[index];

    return KeyedSubtree(
      key: ObjectKey(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: muted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: const Color(0xFFDBEAFE),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    'Item details',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: isSaving ? null : () => removeItem(index),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
            TextFormField(
              initialValue: item.product,
              enabled: !isSaving,
              textCapitalization: TextCapitalization.words,
              onChanged: (value) => item.product = value,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Product is required';
                }
                return null;
              },
              decoration: _decoration(
                'Product',
                'Enter product name',
                Icons.shopping_bag_outlined,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: item.description,
              enabled: !isSaving,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (value) => item.description = value,
              decoration: _decoration(
                'Description',
                'Enter product description',
                Icons.description_outlined,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: item.quantity.toString(),
              enabled: !isSaving,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) => item.quantity = int.tryParse(value) ?? 0,
              validator: (value) {
                if ((int.tryParse(value ?? '') ?? 0) <= 0) {
                  return 'Enter a valid quantity';
                }
                return null;
              },
              decoration: _decoration(
                'Quantity',
                'Enter quantity',
                Icons.numbers_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Purchase Order History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                ),
              ),
              Text(
                'Review records and download invoices',
                style: TextStyle(color: textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            '$totalLpoCount ${totalLpoCount == 1 ? 'LPO' : 'LPOs'}',
            style: const TextStyle(
              color: Color(0xFF1D4ED8),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLpoCards() {
    if (isLoading && lpoList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 50),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (lpoList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: const Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: primary),
            SizedBox(height: 12),
            Text(
              'No purchase orders found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 4),
            Text(
              'Create your first LPO using the form above.',
              style: TextStyle(color: textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: lpoList.map((lpo) {
        final id = _toInt(lpo['id']) ?? 0;
        final invoice = lpo['invoice']?.toString() ?? '';
        final rawItems = lpo['items'] is List ? lpo['items'] as List : [];
        final isDownloading = downloadingInvoiceIds.contains(id);
        final isUpdatingStatus = updatingStatusIds.contains(id);
        final isBusy = loadingEditId == id ||
            deletingIds.contains(id) ||
            isUpdatingStatus;
        final status =
            lpo['status']?.toString().trim().toLowerCase() ?? 'pending';

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 15, 9, 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
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
                            invoice.trim().isEmpty ? 'LPO #$id' : invoice,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            lpo['company_name']?.toString().trim().isEmpty ??
                                    true
                                ? 'Company not available'
                                : lpo['company_name'].toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _statusBadge(status),
                        ],
                      ),
                    ),
                    if (isBusy)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (status == 'pending')
                      PopupMenuButton<String>(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 19),
                                SizedBox(width: 9),
                                Text('Edit LPO'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: Color(0xFFDC2626),
                                  size: 19,
                                ),
                                SizedBox(width: 9),
                                Text(
                                  'Delete LPO',
                                  style: TextStyle(color: Color(0xFFDC2626)),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            getSingleLpo(id);
                          }

                          if (value == 'delete') {
                            _showDeleteDialog(id);
                          }
                        },
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
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: muted,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          _infoRow(
                            Icons.calendar_today_outlined,
                            'Date',
                            _displayApiDate(lpo['date']?.toString() ?? ''),
                          ),
                          _infoRow(
                            Icons.person_outline,
                            'Requested by',
                            lpo['requested_by']?.toString() ?? '',
                          ),
                          _infoRow(
                            Icons.notes,
                            'Note',
                            lpo['note']?.toString() ?? '',
                            last: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Text(
                          'Items',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const Spacer(),
                        Text(
                          '${rawItems.length} ${rawItems.length == 1 ? 'item' : 'items'}',
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
                      const Text(
                        'No items available.',
                        style: TextStyle(color: textSecondary),
                      )
                    else
                      ...rawItems.whereType<Map>().map(_buildDisplayItem),
                    const SizedBox(height: 5),
                    if (!isDepartmentLoading &&
                        ((_canApproveOrReject && status == 'pending') ||
                            (_canConfirm && status == 'approved') ||
                            status == 'confirmed'))
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_canApproveOrReject && status == 'pending')
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
                                foregroundColor: Colors.green,
                                side: const BorderSide(color: Colors.green),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          if (_canApproveOrReject && status == 'pending')
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
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          if (_canConfirm && status == 'approved')
                            ElevatedButton.icon(
                              onPressed: isUpdatingStatus
                                  ? null
                                  : () => _showStatusConfirmationDialog(
                                        id: id,
                                        targetStatus: 'confirmed',
                                      ),
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          if (status == 'confirmed')
                            OutlinedButton.icon(
                              onPressed:
                                  isDownloading ? null : () => downloadInvoice(id),
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
                                isDownloading
                                    ? 'Opening...'
                                    : 'Invoice',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primary,
                                backgroundColor: const Color(0xFFEFF6FF),
                                side: const BorderSide(
                                  color: Color(0xFFBFDBFE),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                        ],
                      )
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDisplayItem(Map item) {
    final product = item['product']?.toString() ?? '';
    final description = item['description']?.toString() ?? '';
    final quantity = _toInt(item['quantity']) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 17,
            backgroundColor: Color(0xFFF1F5F9),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 17,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.trim().isEmpty ? 'Unnamed product' : product,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (description.trim().isNotEmpty)
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textSecondary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Qty $quantity',
              style: const TextStyle(
                color: Color(0xFF1D4ED8),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String value, {
    bool last = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: textSecondary),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              title,
              style: const TextStyle(color: textSecondary, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '—' : value.trim(),
              style: const TextStyle(
                color: textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(
    String label,
    String hint,
    IconData icon, {
    IconData? suffixIcon,
  }) {
    OutlineInputBorder outline(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      suffixIcon: suffixIcon == null ? null : Icon(suffixIcon),
      filled: true,
      fillColor: muted,
      border: outline(border),
      enabledBorder: outline(border),
      focusedBorder: outline(primary, 1.4),
      errorBorder: outline(const Color(0xFFDC2626)),
      focusedErrorBorder: outline(const Color(0xFFDC2626), 1.4),
    );
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
            style: const TextStyle(fontWeight: FontWeight.w900),
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

  void _showDeleteDialog(int id) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Delete LPO?',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'This purchase order will be permanently deleted. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                deleteLpo(id);
              },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }   
}
