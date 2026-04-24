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
import 'package:flutter/material.dart';
import 'package:beposoft/pages/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:intl/intl.dart';

class NewGrv extends StatefulWidget {
  const NewGrv({super.key});

  @override
  State<NewGrv> createState() => _NewGrvState();
}

class _NewGrvState extends State<NewGrv> {
  final TextEditingController returnreason = TextEditingController();
  final TextEditingController returnQuantityController =
      TextEditingController();
  final TextEditingController textEditingController = TextEditingController();

  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> orderItems = [];
  String orderId = '';
  String? selectedValue;
  String manageStaffName = '';
  String selectedInvoiceAddress = '';
  String createdAtDate = '';
  bool hasItems = true; // Flag to track if items exist

  @override
  void initState() {
    super.initState();
    fetchOrders();
    getwarehouse();
    getrack();
  }

  List<Map<String, dynamic>> allRacks = []; // Holds full rack list from API
// Normalized list per product to POST as another list
  final Map<int, List<Map<String, dynamic>>> _postRacksByProduct = {};

  List<Map<String, dynamic>> Warehouses = [];
  List<String> rackColumns = []; // State variable
  List<String> columnNames = []; // For storing selected rack's columns
  TextEditingController rackStockController =
      TextEditingController(); // Controller for rack stock input
  String? selectedUsability;
  List<Map<String, dynamic>> rackDetails = [];

  List<String> usabilityOptions = ["usable", "damaged", "partially_damaged"];
  String? selectedColumn; // For selected column
  int? selectedwarehouseId; // Variable to store the selected department's ID
  String? selectedwarehouseName;
  List<Map<String, dynamic>> filteredRacks =
      []; // Only racks matching selected warehouse
// Per-item UI state
  final Map<int, int?> _selectedWarehouseId = {};
  final Map<int, int?> _selectedRackId = {};
  final Map<int, String?> _selectedColumn = {};
  final Map<int, String?> _selectedUsability = {};

  final Map<int, List<Map<String, dynamic>>> _filteredRacksByItem = {};
  final Map<int, List<String>> _columnNamesByItem = {};
  final Map<int, TextEditingController> _rackStockControllerByItem =
      {}; // don't forget to dispose
  TextEditingController _ctrlFor(int itemId) {
    return _rackStockControllerByItem.putIfAbsent(
        itemId, () => TextEditingController());
  }

  @override
  void dispose() {
    for (final c in _rackStockControllerByItem.values) {
      c.dispose();
    }
    for (final c in _returnQtyCtrlByItem.values) {
      c.dispose();
    }
    returnQuantityController.dispose();
    returnreason.dispose();
    super.dispose();
  }

  int? selectedrackId; // Variable to store the selected department's ID
  String? selectedrackName;
  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  final Map<int, List<Map<String, dynamic>>> _allocationsByItem = {};

// add this constant if you like
  static const _BUCKET_PICK = 'pick';
  static const _BUCKET_STORE = 'store';

  void _addAllocation(
    int itemId,
    Map<String, dynamic> chosen, {
    required String bucket, // 👈 NEW
  }) {
    final list = _allocationsByItem.putIfAbsent(itemId, () => []);

    // keep bucket inside each record
    chosen['bucket'] = bucket;

    final key =
        '${chosen['rack_id']}|${chosen['column_name']}|$bucket'; // 👈 include bucket in merge key
    final idx = list.indexWhere(
      (e) => '${e['rack_id']}|${e['column_name']}|${e['bucket']}' == key,
    );

    if (idx >= 0) {
      final prev = int.tryParse(list[idx]['quantity'].toString()) ?? 0;
      final add = int.tryParse(chosen['quantity'].toString()) ?? 0;
      list[idx]['quantity'] = prev + add;
      if (chosen['usability'] != null)
        list[idx]['usability'] = chosen['usability'];
      if (chosen['warehouse'] != null)
        list[idx]['warehouse'] = chosen['warehouse'];
    } else {
      list.add({
        'warehouse': chosen['warehouse'],
        'rack_id': chosen['rack_id'],
        'rack_name': chosen['rack_name'],
        'column_name': chosen['column_name'],
        'quantity': chosen['quantity'],
        'usability': chosen['usability'],
        'bucket': bucket, // 👈 keep the tag
      });
    }

    _rebuildPostListFor(
        itemId); // will be updated below to ignore PICK allocations
    setState(() {});
  }

  Map<String, dynamic> _normalizeRec(Map<String, dynamic> r) {
    final warehouse =
        r['warehouse'] ?? r['warehouse_id'] ?? r['rack']?['warehouse'];
    final column = r['column'] ?? r['column_name'] ?? r['columnName'];
    final usability = r['usability'] ?? r['status'] ?? 'usable';
    final stockRaw = r['stock'] ?? r['rack_stock'] ?? r['quantity'];

    int stock = 0;
    if (stockRaw is int)
      stock = stockRaw;
    else if (stockRaw is String)
      stock = int.tryParse(stockRaw) ?? 0;
    else if (stockRaw is num) stock = stockRaw.toInt();

    return {
      'warehouse': warehouse ?? 0,
      'column': column ?? '',
      'usability': usability,
      'stock': stock,
    };
  }

  void _rebuildPostListFor(int itemId) {
    final src = (_allocationsByItem[itemId] ?? const <Map<String, dynamic>>[])
        .cast<Map<String, dynamic>>();

    // only store→normalized goes to this preview
    final normalized = src
        .where((m) => m['bucket'] == _BUCKET_STORE) // 👈 only STORE
        .map(_normalizeRec)
        .where(
            (m) => (m['stock'] ?? 0) > 0 && (m['column'] as String).isNotEmpty)
        .toList();

    _postRacksByProduct[itemId] = normalized;
  }

  void addRackDetail() {
    if (selectedrackId != null &&
        selectedColumn != null &&
        selectedUsability != null &&
        rackStockController.text.isNotEmpty) {
      // Find rack name from filteredRacks
      String? rackName = filteredRacks
          .firstWhere((rack) => rack['id'] == selectedrackId)['rack_name'];

      setState(() {
        rackDetails.add({
          "rack_id": selectedrackId,
          "rack_name": rackName, // <-- Add rack_name
          "column_name": selectedColumn,
          "usability": selectedUsability!.toLowerCase(),
          "rack_stock": int.parse(rackStockController.text),
          "rack_lock": 0
        });
        // Clear after adding
        selectedrackId = null;
        selectedColumn = null;
        selectedUsability = null;
        rackStockController.clear();
      });
    }
  }

  void _addRackDetailForItem(int itemId) {
    final rid = _selectedRackId[itemId];
    final col = _selectedColumn[itemId];
    final use = _selectedUsability[itemId];
    final whId = _selectedWarehouseId[itemId];
    final ctrl = _ctrlFor(itemId);

    if (rid == null || col == null || use == null || ctrl.text.isEmpty) return;

    final int enteredQty = int.tryParse(ctrl.text) ?? 0;
    if (enteredQty <= 0) return;

    // 🔹 return quantity for this product
    final item = orderItems.firstWhere(
      (i) => int.tryParse(i['id'].toString()) == itemId,
      orElse: () => {},
    );
    final int returnQty =
        int.tryParse(item['return_quantity']?.toString() ?? '0') ?? 0;

    // 🔹 already allocated rack quantity for this item
    final int usedQty = (_allocationsByItem[itemId] ?? [])
        .where((e) => e['bucket'] == _BUCKET_STORE)
        .fold<int>(
          0,
          (sum, e) => sum + (int.tryParse('${e['quantity']}') ?? 0),
        );

    // 🚫 Block if already fully allocated
    if (usedQty >= returnQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rack allocation already completed for this product'),
        ),
      );
      return;
    }

    // 🚫 Block if this entry exceeds remaining quantity
    if (usedQty + enteredQty > returnQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Rack stock exceeds return quantity. Remaining: ${returnQty - usedQty}',
          ),
        ),
      );
      return;
    }

    // find rack_name and (safety) warehouse for this rack
    final racksForItem = _filteredRacksByItem[itemId] ?? const [];
    final rackObj =
        racksForItem.firstWhere((r) => r['id'] == rid, orElse: () => {});
    final rackName = (rackObj['rack_name'] ?? '').toString();

    // Fallback: resolve warehouse from allRacks by rack id if not chosen
    int? resolvedWh = whId;
    if (resolvedWh == null) {
      try {
        resolvedWh =
            allRacks.firstWhere((r) => r['id'] == rid)['warehouse'] as int?;
      } catch (_) {}
    }

    _addAllocation(
      itemId,
      {
        'warehouse': resolvedWh,
        'rack_id': rid,
        'rack_name': rackName,
        'column_name': col,
        'quantity': enteredQty,
        'usability': use,
      },
      bucket: _BUCKET_STORE,
    );

    // clear per-item inputs
    setState(() {
      _selectedRackId[itemId] = null;
      _selectedColumn[itemId] = null;
      _selectedUsability[itemId] = null;
      _columnNamesByItem[itemId] = [];
      ctrl.clear();
    });
  }

  List<Map<String, dynamic>> rack = [];

  Future<void> getrack() async {
    final token = await getTokenFromPrefs();
    try {
      final response = await http.get(
        Uri.parse('$api/api/rack/add/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      List<Map<String, dynamic>> racklist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        for (var productData in parsed) {
          // String columnNames = (productData['column_names'] as List)
          //     .join(', '); // Convert list to a comma-separated string

          racklist.add({
            'id': productData['id'],
            'warehouse': productData['warehouse'], // required for filtering
            'rack_name': productData['rack_name'],
            'column_names':
                productData['column_names'], // already a List<String>
          });
        }
        setState(() {
          setState(() {
            allRacks = racklist;
          });
        });
      }
    } catch (e) {}
  }

  int _totalRackStockForItem(int itemId) {
    return (_allocationsByItem[itemId] ?? [])
        .where((e) => e['bucket'] == _BUCKET_STORE)
        .fold<int>(
          0,
          (sum, e) => sum + (int.tryParse('${e['quantity']}') ?? 0),
        );
  }

  Future<void> getwarehouse() async {
    final token = await getTokenFromPrefs();
    try {
      final response =
          await http.get(Uri.parse('$api/api/warehouse/add/'), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      List<Map<String, dynamic>> warehouselist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        for (var productData in parsed) {
          warehouselist.add({
            'id': productData['id'],
            'name': productData['name'],
            'location': productData['location']
          });
        }
        setState(() {
          Warehouses = warehouselist;
        });
      }
    } catch (e) {}
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('token');

    // Use a post-frame callback to show the SnackBar after the current frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ScaffoldMessenger.of(context).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged out successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });

    // Wait for the SnackBar to disappear before navigating
    await Future.delayed(Duration(seconds: 2));

    // Navigate to the HomePage after the snackbar is shown
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => login()),
    );
  }

  int currentPage = 1;
  String? nextPageUrl;
  Future<void> fetchOrders({bool loadMore = false}) async {
    final token = await getTokenFromPrefs();
    try {
      String url = loadMore && nextPageUrl != null
          ? nextPageUrl!
          : "$api/api/orders/Shipped/";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        nextPageUrl = parsed['next'];

        final List data = parsed['results'];
        List<Map<String, dynamic>> orderList = [];

        for (var order in data) {
          orderList.add({
            'id': order['id'],
            'manage_staff': order['manage_staff'] ?? 'Unknown',
            'name': order['customer']['name'] ?? 'Unknown',
            'invoice': order['invoice'] ?? 'Unknown',
            'address': order['billing_address']['address'] ?? 'Unknown Address',
            'created_at': order['customer']['created_at'] ?? 'Unknown Date',
          });
        }

        setState(() {
          if (loadMore) {
            orders.addAll(orderList.reversed.toList());
          } else {
            orders = orderList.reversed.toList();
          }
        });
      } else {}
    } catch (error) {
      ;
    }
  }

  final Map<int, TextEditingController> _returnQtyCtrlByItem = {};

  TextEditingController _returnCtrlFor(int itemId) {
    return _returnQtyCtrlByItem.putIfAbsent(
      itemId,
      () => TextEditingController(),
    );
  }

  Future<void> fetchOrderItems(String orderId) async {
    final token = await getTokenFromPrefs();
    try {
      final response = await http.get(
        Uri.parse("$api/api/order/$orderId/items/"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        if (parsed['items'] != null && (parsed['items'] as List).isNotEmpty) {
          List<Map<String, dynamic>> productItems =
              (parsed['items'] as List).map((item) {
            return {
              'id': item['id'] ?? 0,
              'name': item['name'] ?? 'Unknown Product',
              'rate': item['rate'] ?? 0.0,
              'quantity': item['quantity'] ?? 0,
              'discount': item['discount'] ?? 0,
              'images': item['image'] ?? '',
              'return_reason': null, // Add this line
              'return_quantity': 0,
              'product': item['product'] ?? 'Unknown Product',
              'products': item['products'] ?? []
            };
          }).toList();

          setState(() {
            orderItems = productItems;
            hasItems = true; // If items are found
          });
        } else {
          setState(() {
            orderItems = [];
            hasItems = false; // No items found
          });
        }
      } else {
        setState(() {
          orderItems = [];
          hasItems = false;
        });
      }
    } catch (error) {
      setState(() {
        hasItems = false;
      });
    }
  }

  List<Map<String, dynamic>> _buildFlatRackDetails() {
    // _allocationsByItem: Map<int, List<Map<String, dynamic>>>
    return _allocationsByItem.values
        .expand((list) => list)
        .map((a) => {
              'rack_id': a['rack_id'],
              'rack_name': a['rack_name'],
              'column_name': a['column_name'],
              'quantity': int.tryParse('${a['quantity']}') ?? 0,
            })
        .toList();
  }

  Future<void> showReturnQuantityDialog(Map<String, dynamic> item) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Return Quantity for ${item['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: returnQuantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Return Quantity'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                int returnQuantity =
                    int.tryParse(returnQuantityController.text) ?? 0;
                if (returnQuantity > 0) {
                  setState(() {
                    item['return_quantity'] = returnQuantity;
                  });
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Please enter a valid quantity'),
                  ));
                }
              },
              child: Text('Submit'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>?> showPopupDialog2(
    BuildContext context,
    Map<String, dynamic> item, {
    required int remaining, // 🔹 remaining qty for this item
  }) async {
    List<dynamic> _decodeProducts(dynamic raw) {
      if (raw == null) return <dynamic>[];
      if (raw is List) return raw;
      if (raw is String) {
        try {
          final d = jsonDecode(raw);
          if (d is List) return d;
        } catch (_) {}
        try {
          final fixed = raw.replaceAllMapped(RegExp(r"(?<!\\)'"), (m) => '"');
          final d2 = jsonDecode(fixed);
          if (d2 is List) return d2;
        } catch (_) {}
      }
      return <dynamic>[];
    }

    final racks = _decodeProducts(item['products']);

    int _asInt(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;
    int _available(Map r) => _asInt(r['rack_stock']) - _asInt(r['rack_lock']);

    final usableRacks = racks
        .where((r) {
          if (r is! Map) return false;
          final u = r['usability']?.toString().trim().toLowerCase();
          return u == 'usable';
        })
        .cast<Map<String, dynamic>>()
        .toList();

    String? selectedKey;
    Map<String, dynamic>? selectedRack;
    String qtyText = '';
    String? errorText;

    bool canConfirm() {
      if (selectedRack == null) return false;
      final q = int.tryParse(qtyText);
      if (q == null || q <= 0) return false;
      final rackAvail = _available(selectedRack!);
      final cap = rackAvail < remaining ? rackAvail : remaining;
      return q <= cap;
    }

    void validate() {
      final q = int.tryParse(qtyText);
      if (selectedRack == null) {
        errorText = null;
        return;
      }
      final rackAvail = _available(selectedRack!);
      if (q == null || q < 0) {
        errorText = 'Enter a quantity greater than 0';
      } else if (q > rackAvail) {
        errorText = 'Exceeds rack availability ($rackAvail)';
      } else if (q > remaining) {
        errorText = 'Exceeds remaining item quantity ($remaining)';
      } else {
        errorText = null;
      }
    }

    return await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final insets = MediaQuery.of(sheetCtx).viewInsets;

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + insets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((item['name'] ?? 'Product').toString(),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (usableRacks.isEmpty)
                    const Text('No usable rack slots for this product.',
                        style: TextStyle(color: Colors.grey))
                  else
                    DropdownButtonFormField<String>(
                      isExpanded:
                          true, // 👈 lets the button use all horizontal space
                      decoration: const InputDecoration(
                        labelText: 'Select rack slot',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      value: selectedKey,
                      items: usableRacks.map<DropdownMenuItem<String>>((r) {
                        final key = '${r['rack_id']}|${r['column_name']}';
                        final label =
                            '${r['rack_name'] ?? ''} - ${r['column_name'] ?? ''} '
                            '(stock: ${r['rack_stock'] ?? 0}, lock: ${r['rack_lock'] ?? 0}, '
                            'avail: ${_available(r)})';

                        // 👇 Ellipsize the *menu* items
                        return DropdownMenuItem(
                          value: key,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),

                      // 👇 Ellipsize the *selected* item (the closed state)
                      selectedItemBuilder: (_) {
                        return usableRacks.map<Widget>((r) {
                          final label =
                              '${r['rack_name'] ?? ''} - ${r['column_name'] ?? ''} '
                              '(stock: ${r['rack_stock'] ?? 0}, lock: ${r['rack_lock'] ?? 0}, '
                              'avail: ${_available(r)})';
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                          );
                        }).toList();
                      },

                      onChanged: (val) {
                        setSheetState(() {
                          selectedKey = val;
                          selectedRack = (val == null)
                              ? null
                              : usableRacks.firstWhere(
                                  (r) =>
                                      '${r['rack_id']}|${r['column_name']}' ==
                                      val,
                                );
                          validate();
                        });
                      },
                    ),
                  const SizedBox(height: 12),
                  if (selectedRack != null) ...[
                    TextFormField(
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        helperText:
                            'Rack avail: ${_available(selectedRack!)}, Remaining item: $remaining',
                        errorText: errorText,
                      ),
                      onChanged: (val) {
                        setSheetState(() {
                          qtyText = val.trim();
                          validate();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: canConfirm()
                              ? () {
                                  final chosen = <String, dynamic>{
                                    'rack_id': selectedRack!['rack_id'],
                                    'rack_name': selectedRack!['rack_name'],
                                    'column_name': selectedRack!['column_name'],
                                    'quantity': int.parse(qtyText),
                                  };
                                  Navigator.pop(sheetCtx, chosen);
                                }
                              : null,
                          child: const Text('Confirm'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // e.g. 07:35 PM
  void PostGRV() async {
    final token = await getTokenFromPrefs();
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.red,
        content: Text('No auth token found. Please login again.'),
      ));
      return;
    }

    // Buckets
    const String _BUCKET_PICK = 'pick';
    const String _BUCKET_STORE = 'store';

    // Helpers
    int _toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    int? _resolveWarehouse(Map<String, dynamic> r) {
      // prefer explicit value
      if (r['warehouse'] is int) return r['warehouse'] as int;
      // fallback via rack_id → allRacks
      final rid = _toInt(r['rack_id']);
      if (rid > 0) {
        try {
          final m = allRacks.firstWhere((ar) => ar['id'] == rid);
          return m['warehouse'] as int?;
        } catch (_) {}
      }
      return null;
    }

    try {
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd').format(now);
      final formattedTime = DateFormat('HH:mm').format(now);

      for (final item in orderItems) {
        final int itemId = _toInt(item['id']);
        final int returnQty = _toInt(item['return_quantity']);
        final String reason = (item['return_reason'] ?? '').toString().trim();

        if (returnQty <= 0 || reason.isEmpty) {
          continue; // skip items without valid returns
        }

        // All allocations captured in UI for this item
        final List<Map<String, dynamic>> allAllocs =
            ((_allocationsByItem[itemId] ?? const <Map<String, dynamic>>[])
                    as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();

        // Split into buckets (fallback inference if 'bucket' missing)
        final List<Map<String, dynamic>> pickAllocs = [];
        final List<Map<String, dynamic>> storeAllocs = [];

        for (final e in allAllocs) {
          final inferred = (e['warehouse'] != null || e['usability'] != null)
              ? _BUCKET_STORE
              : _BUCKET_PICK;
          final bucket = (e['bucket'] ?? inferred).toString();
          if (bucket == _BUCKET_STORE) {
            storeAllocs.add(e);
          } else {
            pickAllocs.add(e);
          }
        }

        // A) selected_racks: only PICK allocations
        final List<Map<String, dynamic>> selectedRacksUI = pickAllocs
            .map((e) {
              final qty = _toInt(e['quantity']);
              final col = (e['column_name'] ?? e['column'] ?? '').toString();
              return {
                'warehouse': e['warehouse'], // may be null
                'rack_id': e['rack_id'],
                'rack_name': e['rack_name'],
                'column_name': col,
                'quantity': qty,
                'usability': (e['usability'] ?? 'usable'), // default usable
              };
            })
            .where((m) =>
                (m['rack_id'] != null) &&
                (m['quantity'] ?? 0) > 0 &&
                (m['column_name'] as String).isNotEmpty)
            .toList();

        // B) rack_details: only STORE allocations (normalized + includes rack_id)
        final List<Map<String, dynamic>> rackDetailsNormalized = storeAllocs
            .map((e) {
              final qty = _toInt(e['quantity']);
              final col = (e['column_name'] ?? e['column'] ?? '').toString();
              final wh = _resolveWarehouse(e);
              return {
                'warehouse': wh,
                'rack_id': e['rack_id'],
                'rack_name': e['rack_name'], // keep if API allows
                'column_name': col,
                'usability': (e['usability'] ?? 'usable'),
                'quantity': qty, // server expects 'quantity'
              };
            })
            .where((m) =>
                m['warehouse'] != null &&
                m['rack_id'] != null &&
                (m['quantity'] ?? 0) > 0 &&
                (m['column_name'] as String).isNotEmpty)
            .toList();
        final payload = {
          'order': orderId,
          'product': item['name'],
          'product_id': item['product'],
          'price': item['rate'],
          'quantity': returnQty,

          'returnreason': reason,
          'remark': (item['remark'] ?? 'return'),
          'note': (item['description'] ?? ''),
          'cod_amount': (item['cod_amount'] ?? 0),
          'date': formattedDate,
          'time': formattedTime,

          // SEND SEPARATELY, no mixing:
          'rack_details':
              rackDetailsNormalized, // STORE bucket only (has rack_id)
          'selected_racks':
              selectedRacksUI, // PICK bucket only (warehouse may be null)
        };

        final res = await http.post(
          Uri.parse("$api/api/grv/data/"),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        );

      
        if (res.statusCode != 200 && res.statusCode != 201) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text('GRV post failed for ${item['name']}: ${res.body}'),
          ));
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Color.fromARGB(255, 49, 212, 4),
        content: Text('GRV submission complete.'),
      ));
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => NewGrv()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text('An error occurred while posting GRV. $e'),
      ));
    }
  }

  // @override
  // void dispose() {
  //   returnQuantityController.dispose();
  //   returnreason.dispose();
  //   super.dispose();
  // }

  drower d = drower();
  Widget _buildDropdownTile(
      BuildContext context, String title, List<String> options) {
    return ExpansionTile(
      title: Text(title),
      children: options.map((option) {
        return ListTile(
          title: Text(option),
          onTap: () {
            Navigator.pop(context);
            d.navigateToSelectedPage(
                context, option); // Navigate to selected page
          },
        );
      }).toList(),
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
    } else if (dep == "CSO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                cso_dashboard()), // Replace AnotherPage with your target page
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
    return WillPopScope(
      onWillPop: () async {
        // Prevent the swipe-back gesture (and back button)
        _navigateBack();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('New GRV'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back), // Custom back arrow
            onPressed: () async {
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
              } else if (dep == "Warehouse Admin") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          WarehouseAdmin()), // Replace AnotherPage with your target page
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
              } else if (dep == "CSO") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          cso_dashboard()), // Replace AnotherPage with your target page
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          dashboard()), // Replace AnotherPage with your target page
                );
              }
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                SizedBox(height: 15),
                Text(
                  "NEW GRV",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 25, horizontal: 10),
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Container(
                                child: DropdownButtonHideUnderline(
                                  child: Container(
                                    height: 46,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey, width: 1.0),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: DropdownButton2<String>(
                                      isExpanded: true,
                                      hint: Text(
                                        'Select Invoice',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).hintColor),
                                      ),
                                      items: orders.map((order) {
                                        return DropdownMenuItem<String>(
                                          value:
                                              '${order['invoice']} / ${order['name']}',
                                          child: Text(
                                            '${order['invoice']} / ${order['name']}',
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                        );
                                      }).toList(),
                                      value: selectedValue,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedValue = value;
                                          final selectedOrder =
                                              orders.firstWhere(
                                            (order) =>
                                                '${order['invoice']} / ${order['name']}' ==
                                                value,
                                            orElse: () => {},
                                          );
                                          if (selectedOrder != null) {
                                            orderId =
                                                selectedOrder['id'].toString();
                                            manageStaffName =
                                                selectedOrder['manage_staff'];
                                            selectedInvoiceAddress =
                                                selectedOrder['address'];
                                            createdAtDate =
                                                selectedOrder['created_at'];
                                            fetchOrderItems(orderId);
                                          }
                                        });
                                      },
                                      buttonStyleData: const ButtonStyleData(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16),
                                        height: 40,
                                      ),
                                      dropdownStyleData:
                                          const DropdownStyleData(
                                        maxHeight: 200,
                                      ),
                                      menuItemStyleData:
                                          const MenuItemStyleData(
                                        height: 40,
                                      ),
                                      dropdownSearchData: DropdownSearchData(
                                        searchController: textEditingController,
                                        searchInnerWidgetHeight: 50,
                                        searchInnerWidget: Container(
                                          height: 50,
                                          padding: const EdgeInsets.only(
                                              top: 8,
                                              bottom: 4,
                                              right: 8,
                                              left: 8),
                                          child: TextFormField(
                                            expands: true,
                                            maxLines: null,
                                            controller: textEditingController,
                                            decoration: InputDecoration(
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 8),
                                              hintText:
                                                  'Search for an invoice...',
                                              hintStyle:
                                                  const TextStyle(fontSize: 12),
                                              border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8)),
                                            ),
                                          ),
                                        ),
                                        searchMatchFn: (item, searchValue) {
                                          return item.value
                                              .toString()
                                              .toLowerCase()
                                              .contains(
                                                  searchValue.toLowerCase());
                                        },
                                      ),
                                      onMenuStateChange: (isOpen) {
                                        if (isOpen && nextPageUrl != null) {
                                          fetchOrders(); // Load more when dropdown opens
                                        }
                                        if (!isOpen) {
                                          textEditingController.clear();
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller:
                              TextEditingController(text: manageStaffName),
                          decoration: InputDecoration(
                            labelText: 'Managed by',
                            suffixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                          enabled: false,
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: TextEditingController(
                              text: selectedInvoiceAddress),
                          decoration: InputDecoration(
                            labelText: 'Address',
                            suffixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                          enabled: false,
                          maxLines:
                              null, // Makes it flexible for multiple lines
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          controller:
                              TextEditingController(text: createdAtDate),
                          decoration: InputDecoration(
                            labelText: 'Invoice Date',
                            suffixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                          enabled: false,
                        ),
                        // SizedBox(height: 10),
                        // DropdownButtonFormField<String>(
                        //   value: returnreason.text.isNotEmpty
                        //       ? returnreason.text
                        //       : null,
                        //   items: ['Usable', 'Damaged', 'Partially Damaged']
                        //       .map((label) => DropdownMenuItem(
                        //             child: Text(label),
                        //             value: label,
                        //           ))
                        //       .toList(),
                        //   onChanged: (value) {
                        //     setState(() {
                        //       returnreason.text = value!;
                        //     });
                        //   },
                        //   decoration: InputDecoration(
                        //     labelText: 'Reason',
                        //     border: OutlineInputBorder(
                        //       borderRadius: BorderRadius.circular(10.0),
                        //       borderSide: BorderSide(color: Colors.grey),
                        //     ),
                        //     contentPadding: EdgeInsets.symmetric(
                        //         vertical: 8.0, horizontal: 12.0),
                        //   ),
                        // ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: orderItems.length,
                          itemBuilder: (context, index) {
                            final item = orderItems[index];
                            final itemId =
                                int.tryParse(item['id'].toString()) ?? 0;

                            final int returnQty =
                                int.tryParse('${item['return_quantity']}') ?? 0;
                            final int usedRackQty =
                                _totalRackStockForItem(itemId);
                            final int remainingRackQty =
                                returnQty - usedRackQty;
                            final returnCtrl = _returnCtrlFor(itemId);
                            final currentVal =
                                item['return_quantity']?.toString() ?? '0';
                            if (returnCtrl.text != currentVal) {
                              returnCtrl.text = currentVal;
                            }

                            return Card(
                              color: Colors.white,
                              margin: EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['name'],
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(height: 8),
                                    Text("Rate: ₹${item['rate']}"),
                                    Text("Quantity: ${item['quantity']}"),
                                    Text("Discount: ${item['discount']}%"),

                                    if (item['images'] != null &&
                                        item['images'].isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        child: Image.network(
                                          "$api${item['images']}",
                                          height: 80,
                                          width: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Icon(Icons.image_not_supported),
                                        ),
                                      ),
                                    SizedBox(height: 8),
                                    // Return Quantity input
                                    TextFormField(
                                      controller: returnCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText:
                                            'Return Quantity (Max: ${item['quantity']})',
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (value) {
                                        final int entered =
                                            int.tryParse(value) ?? 0;
                                        final int productQty = int.tryParse(
                                                item['quantity']?.toString() ??
                                                    '0') ??
                                            0;

                                        if (entered > productQty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Return quantity cannot exceed product quantity ($productQty)',
                                              ),
                                              duration: Duration(seconds: 1),
                                            ),
                                          );

                                          // ✅ AUTO-REPLACE VALUE (same UX as rack stock)
                                          returnCtrl.text =
                                              productQty.toString();
                                          returnCtrl.selection =
                                              TextSelection.fromPosition(
                                            TextPosition(
                                                offset: returnCtrl.text.length),
                                          );

                                          setState(() {
                                            item['return_quantity'] =
                                                productQty;
                                          });
                                          return;
                                        }

                                        setState(() {
                                          item['return_quantity'] = entered;
                                          if (entered == 0) {
                                            item['return_reason'] = null;
                                          }
                                        });
                                      },
                                    ),

                                    // Show dropdown only if quantity > 0
                                    if ((item['return_quantity'] ?? 0) > 0)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: DropdownButtonFormField<String>(
                                          value: item['return_reason'],
                                          items: [
                                            'usable',
                                            'damaged',
                                            'partially_damaged'
                                          ]
                                              .map((label) => DropdownMenuItem(
                                                    child: Text(label),
                                                    value: label,
                                                  ))
                                              .toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              item['return_reason'] = value;
                                            });
                                          },
                                          decoration: InputDecoration(
                                            labelText: 'Usability',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),

                                    // Remark dropdown
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: DropdownButtonFormField<String>(
                                        value: item['remark'],
                                        items: [
                                          'exchange',
                                          'refund',
                                          'return',
                                          'cod_return'
                                        ]
                                            .map((label) => DropdownMenuItem(
                                                  child: Text(label),
                                                  value: label,
                                                ))
                                            .toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            item['remark'] = value;
                                          });
                                        },
                                        decoration: InputDecoration(
                                          labelText: 'Remark',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                    if (item['remark'] == "cod_return")
                                      Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: TextFormField(
                                          initialValue: item['amount'] ?? '',
                                          decoration: InputDecoration(
                                            labelText: 'COD Amount',
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              item['cod_amount'] = value;
                                            });
                                          },
                                        ),
                                      ),

                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: TextFormField(
                                        initialValue: item['description'] ?? '',
                                        maxLines: 2,
                                        decoration: InputDecoration(
                                          labelText: 'Description',
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            item['description'] = value;
                                          });
                                        },
                                      ),
                                    ),

                                    SizedBox(height: 10),
                                    // if(item['remark'] != "refund" && item['remark'] != "cod_return")
                                    // Card(
                                    //   elevation: 5,
                                    //   shape: RoundedRectangleBorder(
                                    //     borderRadius: BorderRadius.circular(16),
                                    //     side: BorderSide(
                                    //         color: Color(0xFF1976D2),
                                    //         width: 1.2),
                                    //   ),
                                    //   color: Color(0xFFF5F8FE),
                                    //   margin: EdgeInsets.symmetric(
                                    //       vertical: 8, horizontal: 0),
                                    //   child: Padding(
                                    //     padding: const EdgeInsets.symmetric(
                                    //         vertical: 18, horizontal: 16),
                                    //     child: Column(
                                    //       children: [
                                    //         Row(
                                    //           children: [
                                    //             Icon(Icons.info_outline,
                                    //                 color: Color(0xFF1976D2),
                                    //                 size: 22),
                                    //             SizedBox(width: 8),
                                    //             Expanded(
                                    //               child: Text(
                                    //                 "Select the racks from where the product needs to be taken for replacement.",
                                    //                 style: TextStyle(
                                    //                   fontSize: 15,
                                    //                   fontWeight:
                                    //                       FontWeight.w700,
                                    //                   color: Color(0xFF1976D2),
                                    //                   letterSpacing: 0.2,
                                    //                   height: 1.3,
                                    //                 ),
                                    //               ),
                                    //             ),
                                    //           ],
                                    //         ),
                                    //         SizedBox(height: 14),
                                    //         Center(
                                    //           child: LayoutBuilder(
                                    //             builder:
                                    //                 (context, constraints) {
                                    //               double buttonWidth =
                                    //                   constraints.maxWidth < 400
                                    //                       ? constraints.maxWidth
                                    //                       : 400;
                                    //               return Material(
                                    //                 elevation: 8,
                                    //                 borderRadius:
                                    //                     BorderRadius.circular(
                                    //                         30),
                                    //                 color: Colors.transparent,
                                    //                 child: InkWell(
                                    //                   borderRadius:
                                    //                       BorderRadius.circular(
                                    //                           30),
                                    //                   onTap: () async {
                                    //                     final itemId =
                                    //                         int.tryParse(item[
                                    //                                     'id']
                                    //                                 .toString()) ??
                                    //                             0;
                                    //                     final ordered =
                                    //                         int.tryParse(item[
                                    //                                     'quantity']
                                    //                                 .toString()) ??
                                    //                             0;
                                    //                     final already =
                                    //                         (_allocationsByItem[
                                    //                                     itemId] ??
                                    //                                 [])
                                    //                             .fold<int>(
                                    //                                 0,
                                    //                                 (s, a) =>
                                    //                                     s +
                                    //                                     (int.tryParse('${a['quantity']}') ??
                                    //                                         0));
                                    //                     final remaining =
                                    //                         (ordered - already);

                                    //                     if (remaining <= 0) {
                                    //                       ScaffoldMessenger.of(
                                    //                               context)
                                    //                           .showSnackBar(
                                    //                         const SnackBar(
                                    //                             content: Text(
                                    //                                 'Allocation complete for this product.')),
                                    //                       );
                                    //                       return;
                                    //                     }

                                    //                     final result =
                                    //                         await showPopupDialog2(
                                    //                             context, item,
                                    //                             remaining:
                                    //                                 remaining);
                                    //                     if (result != null) {
                                    //                       final addQty =
                                    //                           int.tryParse(
                                    //                                   '${result['quantity']}') ??
                                    //                               0;
                                    //                       if (already + addQty >
                                    //                           ordered) {
                                    //                         ScaffoldMessenger
                                    //                                 .of(context)
                                    //                             .showSnackBar(
                                    //                           SnackBar(
                                    //                               content: Text(
                                    //                                   'Exceeds total item quantity ($ordered).')),
                                    //                         );
                                    //                         return;
                                    //                       }
                                    //                       _addAllocation(
                                    //                           itemId, result, bucket: _BUCKET_PICK);
                                    //                     }
                                    //                   },
                                    //                   child: Container(
                                    //                     width: buttonWidth,
                                    //                     decoration:
                                    //                         BoxDecoration(
                                    //                       gradient:
                                    //                           LinearGradient(
                                    //                         colors: [
                                    //                           Color(0xFF1976D2),
                                    //                           Color(0xFF42A5F5)
                                    //                         ],
                                    //                         begin: Alignment
                                    //                             .centerLeft,
                                    //                         end: Alignment
                                    //                             .centerRight,
                                    //                       ),
                                    //                       borderRadius:
                                    //                           BorderRadius
                                    //                               .circular(10),
                                    //                       boxShadow: [
                                    //                         BoxShadow(
                                    //                           color: Colors.blue
                                    //                               .withOpacity(
                                    //                                   0.15),
                                    //                           blurRadius: 12,
                                    //                           offset:
                                    //                               Offset(0, 6),
                                    //                         ),
                                    //                       ],
                                    //                     ),
                                    //                     padding:
                                    //                         const EdgeInsets
                                    //                             .symmetric(
                                    //                             horizontal: 28,
                                    //                             vertical: 14),
                                    //                     child: Row(
                                    //                       mainAxisSize:
                                    //                           MainAxisSize.min,
                                    //                       mainAxisAlignment:
                                    //                           MainAxisAlignment
                                    //                               .center,
                                    //                       children: [
                                    //                         Icon(
                                    //                             Icons
                                    //                                 .inventory_2_rounded,
                                    //                             size: 24,
                                    //                             color: Colors
                                    //                                 .white),
                                    //                         SizedBox(width: 12),
                                    //                         Flexible(
                                    //                           child: Text(
                                    //                             "Select Rack",
                                    //                             style:
                                    //                                 TextStyle(
                                    //                               color: Colors
                                    //                                   .white,
                                    //                               fontWeight:
                                    //                                   FontWeight
                                    //                                       .bold,
                                    //                               letterSpacing:
                                    //                                   0.7,
                                    //                               fontSize: 16,
                                    //                               shadows: [
                                    //                                 Shadow(
                                    //                                   color: Colors
                                    //                                       .black26,
                                    //                                   offset:
                                    //                                       Offset(
                                    //                                           0,
                                    //                                           1),
                                    //                                   blurRadius:
                                    //                                       2,
                                    //                                 ),
                                    //                               ],
                                    //                             ),
                                    //                             overflow:
                                    //                                 TextOverflow
                                    //                                     .ellipsis,
                                    //                           ),
                                    //                         ),
                                    //                       ],
                                    //                     ),
                                    //                   ),
                                    //                 ),
                                    //               );
                                    //             },
                                    //           ),
                                    //         ),
                                    //       ],
                                    //     ),
                                    //   ),
                                    // ),

                                    Builder(
                                      builder: (_) {
                                        final itemId = int.tryParse(
                                                item['id'].toString()) ??
                                            0;

                                        // Pending allocations you built locally (per item)
                                        final List<Map<String, dynamic>>
                                            localAllocs =
                                            (_allocationsByItem[itemId] ?? [])
                                                .cast<Map<String, dynamic>>();

                                        // Existing allocations from API response: item['rack_details']
                                        final List<Map<String, dynamic>>
                                            serverAllocs =
                                            (item['rack_details'] is List)
                                                ? (item['rack_details'] as List)
                                                    .whereType<
                                                        Map>() // keep only maps
                                                    .map<
                                                        Map<String,
                                                            dynamic>>((m) => {
                                                          'rack_id':
                                                              m['rack_id'],
                                                          'rack_name':
                                                              m['rack_name'],
                                                          'column_name':
                                                              m['column_name'],
                                                          'quantity':
                                                              m['quantity'],
                                                        })
                                                    .toList()
                                                : <Map<String, dynamic>>[];

                                        final hasAny =
                                            serverAllocs.isNotEmpty ||
                                                localAllocs.isNotEmpty;
                                        if (!hasAny)
                                          return const SizedBox.shrink();

                                        Widget chipsFor(
                                            List<Map<String, dynamic>> list,
                                            {required bool deletable}) {
                                          return Wrap(
                                            spacing: 8,
                                            runSpacing: 6,
                                            children: list.map((a) {
                                              final rack = (a['rack_name'] ??
                                                      a['rack_id'] ??
                                                      '')
                                                  .toString();
                                              final col =
                                                  (a['column_name'] ?? '')
                                                      .toString();
                                              final qty = int.tryParse(
                                                      '${a['quantity']}') ??
                                                  0;
                                              final label =
                                                  '$rack${col.isNotEmpty ? '-$col' : ''} x $qty';

                                              return Chip(
                                                label: Text(label,
                                                    style: const TextStyle(
                                                        fontSize: 12)),
                                                // grey style for existing/server chips
                                                backgroundColor: deletable
                                                    ? null
                                                    : const Color(0xFFE9ECEF),
                                                deleteIcon: deletable
                                                    ? const Icon(Icons.close,
                                                        size: 16)
                                                    : null,
                                                onDeleted: deletable
                                                    ? () {
                                                        setState(() {
                                                          localAllocs.remove(a);
                                                          if (localAllocs
                                                              .isEmpty) {
                                                            _allocationsByItem
                                                                .remove(itemId);
                                                          }
                                                        });
                                                      }
                                                    : null,
                                              );
                                            }).toList(),
                                          );
                                        }

                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (serverAllocs.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              const Text('Existing allocation',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              chipsFor(serverAllocs,
                                                  deletable: false),
                                            ],
                                            if (localAllocs.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              const Text('New allocation',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              chipsFor(localAllocs,
                                                  deletable: true),
                                            ],
                                          ],
                                        );
                                      },
                                    ),

                                    SizedBox(height: 10),

                                    Card(
                                      elevation: 7,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                        side: BorderSide(
                                            color: Color(0xFF1976D2),
                                            width: 1.2),
                                      ),
                                      color: Color(0xFFF5F8FE),
                                      margin: EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 0),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 22, horizontal: 18),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: Color(0xFF1976D2)
                                                        .withOpacity(0.13),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  padding: EdgeInsets.all(8),
                                                  child: Icon(
                                                      Icons.info_outline,
                                                      color: Color(0xFF1976D2),
                                                      size: 24),
                                                ),
                                                SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    "Select the racks to store the product.",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: Color(0xFF1976D2),
                                                      letterSpacing: 0.3,
                                                      height: 1.2,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              "Choose warehouse, rack, column, usability, and enter stock for this product.",
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            SizedBox(height: 18),

                                            // Warehouse Dropdown
                                            Text("Warehouse",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87)),
                                            SizedBox(height: 6),
                                            DropdownButtonFormField<int>(
                                              isExpanded: true,
                                              value:
                                                  _selectedWarehouseId[itemId],
                                              decoration: InputDecoration(
                                                labelText: 'Select a Warehouse',
                                                border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 12),
                                                filled: true,
                                                fillColor: Colors.white,
                                                prefixIcon: Icon(
                                                    Icons.warehouse,
                                                    color: Color(0xFF1976D2)),
                                              ),
                                              onChanged: (int? newValue) {
                                                setState(() {
                                                  _selectedWarehouseId[itemId] =
                                                      newValue;
                                                  _filteredRacksByItem[itemId] =
                                                      allRacks
                                                          .where((rack) =>
                                                              rack[
                                                                  'warehouse'] ==
                                                              newValue)
                                                          .toList();
                                                  _selectedRackId[itemId] =
                                                      null;
                                                  _selectedColumn[itemId] =
                                                      null;
                                                  _columnNamesByItem[itemId] =
                                                      [];
                                                });
                                              },
                                              items: Warehouses.map<
                                                  DropdownMenuItem<int>>((w) {
                                                return DropdownMenuItem<int>(
                                                  value: w['id'],
                                                  child: Text(
                                                      w['name']?.toString() ??
                                                          ''),
                                                );
                                              }).toList(),
                                            ),

                                            SizedBox(height: 14),

                                            // Rack Dropdown
                                            if ((_filteredRacksByItem[itemId] ??
                                                    [])
                                                .isNotEmpty) ...[
                                              Text("Rack",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.black87)),
                                              SizedBox(height: 6),
                                              DropdownButtonFormField<int>(
                                                isExpanded: true,
                                                value: _selectedRackId[itemId],
                                                decoration: InputDecoration(
                                                  labelText: 'Select a Rack',
                                                  border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10)),
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                          horizontal: 14,
                                                          vertical: 12),
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                  prefixIcon: Icon(
                                                      Icons.storage,
                                                      color: Color(0xFF1976D2)),
                                                ),
                                                onChanged: (int? newValue) {
                                                  setState(() {
                                                    _selectedRackId[itemId] =
                                                        newValue;
                                                    final selectedRack =
                                                        (_filteredRacksByItem[
                                                                    itemId] ??
                                                                [])
                                                            .firstWhere(
                                                                (rack) =>
                                                                    rack[
                                                                        'id'] ==
                                                                    newValue);
                                                    _columnNamesByItem[
                                                        itemId] = List<
                                                            String>.from(
                                                        selectedRack[
                                                                'column_names'] ??
                                                            []);
                                                    _selectedColumn[itemId] =
                                                        null;
                                                  });
                                                },
                                                items: (_filteredRacksByItem[
                                                            itemId] ??
                                                        [])
                                                    .map<DropdownMenuItem<int>>(
                                                        (rack) {
                                                  return DropdownMenuItem<int>(
                                                    value: rack['id'],
                                                    child: Text(
                                                        rack['rack_name']
                                                                ?.toString() ??
                                                            ''),
                                                  );
                                                }).toList(),
                                              ),
                                              SizedBox(height: 14),
                                            ],

                                            // Column Dropdown
                                            if ((_columnNamesByItem[itemId] ??
                                                    [])
                                                .isNotEmpty) ...[
                                              Text("Column",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.black87)),
                                              SizedBox(height: 6),
                                              DropdownButtonFormField<String>(
                                                isExpanded: true,
                                                value: _selectedColumn[itemId],
                                                decoration: InputDecoration(
                                                  labelText: 'Select a Column',
                                                  border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10)),
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                          horizontal: 14,
                                                          vertical: 12),
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                  prefixIcon: Icon(
                                                      Icons.view_column,
                                                      color: Color(0xFF1976D2)),
                                                ),
                                                onChanged: (String? newValue) {
                                                  setState(() {
                                                    _selectedColumn[itemId] =
                                                        newValue;
                                                  });
                                                },
                                                items: (_columnNamesByItem[
                                                            itemId] ??
                                                        [])
                                                    .map<
                                                        DropdownMenuItem<
                                                            String>>((col) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: col,
                                                    child: Text(col),
                                                  );
                                                }).toList(),
                                              ),
                                              SizedBox(height: 14),
                                            ],

                                            // Usability Dropdown
                                            Text("Usability",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87)),
                                            SizedBox(height: 6),
                                            DropdownButtonFormField<String>(
                                              isExpanded: true,
                                              value: _selectedUsability[itemId],
                                              decoration: InputDecoration(
                                                labelText: 'Select Usability',
                                                border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 12),
                                                filled: true,
                                                fillColor: Colors.white,
                                                prefixIcon: Icon(
                                                    Icons.check_circle_outline,
                                                    color: Color(0xFF1976D2)),
                                              ),
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  _selectedUsability[itemId] =
                                                      newValue;
                                                });
                                              },
                                              items: usabilityOptions.map<
                                                      DropdownMenuItem<String>>(
                                                  (option) {
                                                return DropdownMenuItem<String>(
                                                  value: option,
                                                  child: Text(option),
                                                );
                                              }).toList(),
                                            ),

                                            SizedBox(height: 14),

                                            // Rack Stock Input
                                            Text("Rack Stock",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87)),
                                            SizedBox(height: 6),
                                            TextField(
                                              controller: _ctrlFor(itemId),
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (val) {
                                                final entered =
                                                    int.tryParse(val) ?? 0;
                                                if (entered >
                                                    remainingRackQty) {
                                                  _ctrlFor(itemId).text =
                                                      remainingRackQty
                                                          .toString();
                                                  _ctrlFor(itemId).selection =
                                                      TextSelection
                                                          .fromPosition(
                                                    TextPosition(
                                                        offset: _ctrlFor(itemId)
                                                            .text
                                                            .length),
                                                  );

                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Rack stock cannot exceed return quantity ($remainingRackQty)',
                                                      ),
                                                      duration:
                                                          Duration(seconds: 1),
                                                    ),
                                                  );
                                                }
                                              },
                                              decoration: InputDecoration(
                                                labelText:
                                                    'Rack Stock (Remaining: $remainingRackQty)',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10.0),
                                                ),
                                                filled: true,
                                                fillColor: Colors.white,
                                              ),
                                            ),

                                            SizedBox(height: 16),

                                            // Rack Details List
                                            if (rackDetails.isNotEmpty)
                                              ...rackDetails.map((rack) =>
                                                  ListTile(
                                                    leading: Icon(Icons.storage,
                                                        color:
                                                            Color(0xFF1976D2)),
                                                    title: Text(
                                                      'Rack: ${rack["rack_name"]}  ${rack["column_name"]} (${rack["usability"]})',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600),
                                                    ),
                                                    subtitle: Text(
                                                        'Stock: ${rack["rack_stock"]}'),
                                                    tileColor:
                                                        Color(0xFFE3F2FD),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8)),
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 4),
                                                  )),

                                            SizedBox(height: 10),

                                            // Add Rack Details Button
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                onPressed: (() {
                                                  final int returnQty = int.tryParse(
                                                          item['return_quantity']
                                                                  ?.toString() ??
                                                              '0') ??
                                                      0;

                                                  final int usedQty =
                                                      (_allocationsByItem[
                                                                  itemId] ??
                                                              [])
                                                          .where((e) =>
                                                              e['bucket'] ==
                                                              _BUCKET_STORE)
                                                          .fold<int>(
                                                            0,
                                                            (sum, e) =>
                                                                sum +
                                                                (int.tryParse(
                                                                        '${e['quantity']}') ??
                                                                    0),
                                                          );

                                                  // 🔒 Disable when fully allocated
                                                  if (returnQty > 0 &&
                                                      usedQty >= returnQty) {
                                                    return null;
                                                  }

                                                  return () =>
                                                      _addRackDetailForItem(
                                                          itemId);
                                                })(),
                                                icon: Icon(
                                                    Icons.add_box_outlined,
                                                    size: 22,
                                                    color: Colors.white),
                                                label: Text(
                                                  (() {
                                                    final int returnQty = int.tryParse(
                                                            item['return_quantity']
                                                                    ?.toString() ??
                                                                '0') ??
                                                        0;
                                                    final int usedQty =
                                                        (_allocationsByItem[
                                                                    itemId] ??
                                                                [])
                                                            .where((e) =>
                                                                e['bucket'] ==
                                                                _BUCKET_STORE)
                                                            .fold<int>(
                                                              0,
                                                              (sum, e) =>
                                                                  sum +
                                                                  (int.tryParse(
                                                                          '${e['quantity']}') ??
                                                                      0),
                                                            );

                                                    return (returnQty > 0 &&
                                                            usedQty >=
                                                                returnQty)
                                                        ? "Rack Allocation Complete"
                                                        : "Add Rack Details";
                                                  })(),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Color(0xFF1976D2),
                                                  foregroundColor: Colors.white,
                                                  minimumSize:
                                                      Size(double.infinity, 48),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  elevation: 4,
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 14),
                                                  textStyle: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if ((_postRacksByProduct[itemId] ?? [])
                                        .isNotEmpty)
                                      Card(
                                        elevation: 4,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          side: BorderSide(
                                              color: Colors.green.shade700,
                                              width: 1),
                                        ),
                                        color: Color(0xFFE8F5E9),
                                        margin: EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 0),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16, horizontal: 16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                      Icons
                                                          .check_circle_outline,
                                                      color: Colors
                                                          .green.shade700),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    "Rack Details to be Sent",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Colors.green.shade700,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 10),
                                              ...(_postRacksByProduct[itemId] ??
                                                      [])
                                                  .map<Widget>((rack) =>
                                                      ListTile(
                                                        leading: Icon(
                                                            Icons.storage,
                                                            color: Colors.green
                                                                .shade700),
                                                        title: Text(
                                                          'Warehouse: ${rack["warehouse"]}, Column: ${rack["column"]}',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                        ),
                                                        subtitle: Text(
                                                          'Usability: ${rack["usability"]}, Stock: ${rack["stock"]}',
                                                          style: TextStyle(
                                                              fontSize: 13),
                                                        ),
                                                        tileColor:
                                                            Colors.green[50],
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        contentPadding:
                                                            EdgeInsets
                                                                .symmetric(
                                                                    horizontal:
                                                                        12,
                                                                    vertical:
                                                                        4),
                                                      )),
                                            ],
                                          ),
                                        ),
                                      ),
                                    // Rack (Filtered)
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedValue != null && orderItems.isNotEmpty) {
                      PostGRV();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        backgroundColor: Colors.orange,
                        content: Text(
                            'Please select an order and ensure there are items to submit.'),
                      ));
                    }
                  },
                  child: Text("Submit"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
