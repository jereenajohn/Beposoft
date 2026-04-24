import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseReview extends StatefulWidget {
  final String id;
  const PurchaseReview({super.key, required this.id});

  @override
  State<PurchaseReview> createState() => _PurchaseReviewState();
}

class _PurchaseReviewState extends State<PurchaseReview> {
  Map<String, dynamic>? orderData;
  List<Map<String, dynamic>> items = [];
  String? selectedStatus;
  final List<String> statusOptions = [
    'Created',
    'Approved',
    'Completed',
    'Received',
    'Cancelled',
    'Rejected'
  ];

  bool showAllProducts = false;
  Map<int, List<Map<String, dynamic>>> _allocationsByItem = {}; // itemId -> allocations
  String dep = "ADMIN"; // <-- set your department logic

  @override
  void initState() {
    super.initState();
    getPurchaseRequest();
  }



Future<void> AddStatusTime(BuildContext scaffoldContext) async {
  final token = await getToken();
  try {
    final response = await http.post(
      Uri.parse('$api/api/datalog/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
         'before_data': {"Action": "purchase request status $status "},
        'after_data':  {"status": "$selectedStatus"},
      }),
    );

    // print("====================${response.body}");

    if (response.statusCode == 201) {

      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('time added Successfully.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Adding time failed.'),
        ),
      );
    }
  } catch (e) {
  }
}
bool _submittingAll = false;
Future<void> submitAllAllocations() async {
  if (_submittingAll) return;

  // Prepare entries with non-empty allocations
  final entries = _allocationsByItem.entries
      .where((e) => (e.value).isNotEmpty)
      .toList();

  if (entries.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No rack allocations to submit')),
    );
    return;
  }

  setState(() => _submittingAll = true);

  final successIds = <int>[];
  final failedIds  = <int>[];

  // Submit SEQUENTIALLY (safe). Use Future.wait if you want parallel.
  for (final e in entries) {
    final ok = await updateOrderItem(e.key, e.value);
    if (ok) {
      successIds.add(e.key);
    } else {
      failedIds.add(e.key);
    }
  }

  // Clear only successful ones
  setState(() {
    for (final id in successIds) {
      _allocationsByItem.remove(id);
    }
    _submittingAll = false;
  });

  if (failedIds.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Submitted ${successIds.length} item(s) successfully'),
        backgroundColor: Colors.green,
      ),
    );
    // Optional: refresh items
    // fetchOrderItems();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Submitted ${successIds.length} succeeded, ${failedIds.length} failed: ${failedIds.join(", ")}',
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

Future<bool> updateOrderItem(
  int itemId,
  List<Map<String, dynamic>> racks,
) async {
  List<Map<String, dynamic>> _cleanAllocations(List<Map<String, dynamic>> list) {
    return list.map((a) => {
      'rack_id'    : a['rack_id'],
      'rack_name'  : a['rack_name'],
      'column_name': a['column_name'],
      'quantity'   : int.tryParse('${a['quantity']}') ?? 0,
    })
    .where((a) => (a['quantity'] as int) > 0)
    .toList();
  }
  final cleaned = _cleanAllocations(racks);
  if (cleaned.isEmpty) return true;
  try {
    final token = await getToken();
    final body = {
      'rack_details': cleaned, 
    };

    final url = Uri.parse('$api/api/warehouse/order/item/update/$itemId/');
    final res = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
if (res.statusCode == 200) {
  AddStatusTime(context);
}
    return res.statusCode >= 200 && res.statusCode < 300;
  } catch (e) {
    return false;
  }
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

  final racks = _decodeProducts(item['product_rack']);

  int _asInt(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;
  int _available(Map r) => _asInt(r['rack_stock']) - _asInt(r['rack_lock']);

  final usableRacks = racks.where((r) {
    if (r is! Map) return false;
    final u = r['usability']?.toString().trim().toLowerCase();
    return u == 'usable';
  }).cast<Map<String, dynamic>>().toList();

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
    if (selectedRack == null) { errorText = null; return; }
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
              left: 16, right: 16, top: 16, bottom: 16 + insets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((item['name'] ?? 'Product').toString(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                if (usableRacks.isEmpty)
                  const Text('No usable rack slots for this product.',
                      style: TextStyle(color: Colors.grey))
                else
                  DropdownButtonFormField<String>(
  isExpanded: true, // 👈 lets the button use all horizontal space
  decoration: const InputDecoration(
    labelText: 'Select rack slot',
    border: OutlineInputBorder(),
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              (r) => '${r['rack_id']}|${r['column_name']}' == val,
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
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                                  'rack_id'    : selectedRack!['rack_id'],
                                  'rack_name'  : selectedRack!['rack_name'],
                                  'column_name': selectedRack!['column_name'],
                                  'quantity'   : int.parse(qtyText),
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

  Future<String?> getToken() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString('token');
  }

  Future<void> updatestatus(var id) async {
    try {
      final token = await getToken();

      var response = await http.put(
        Uri.parse('$api/api/warehouse/order/update/${id}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          {
            'status': selectedStatus,
          },
        ),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PurchaseReview(id: widget.id,)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
var status;
  Future<void> getPurchaseRequest() async {
    final token = await getToken();
    try {
      final response = await http.get(
        Uri.parse('$api/api/warehouse/order/view/${widget.id}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        setState(() {
          orderData = parsed['data'];
          items = List<Map<String, dynamic>>.from(orderData?['items'] ?? []);
          selectedStatus = orderData?['status']?.toString() ?? statusOptions.first;
          status=orderData?['status']?.toString() ?? statusOptions.first;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (orderData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);
    final visibleItems = showAllProducts ? items : items.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Purchase Review', style: TextStyle(fontSize: 12)),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Order Summary Card ---
Container(
  margin: const EdgeInsets.symmetric(vertical: 6),
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  decoration: BoxDecoration(
    color: Colors.blueAccent.withOpacity(0.08),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
  ),
  child: Row(
    children: [
      const Icon(Icons.business, color: Colors.blueAccent, size: 22),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          orderData!['company_name'] ?? '',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.blueAccent,
            letterSpacing: 0.5,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  ),
),
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoice #${orderData!['invoice']}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    Divider(color:  Colors.blueAccent, thickness: 1.5),
                    const SizedBox(height: 12),
                    _buildInfoRow('Order Date', orderData!['order_date']),
                    _buildInfoRow('Requesting', orderData!['warehouses_name']),
                     _buildInfoRow('Reciving', orderData!['receiiver_warehouse_name']),
                    _buildInfoRow('Company', '${orderData!['company_name']}'),

                    // --- Status Dropdown ---
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Status:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(width: 5, // Adjust width as needed
                            ),
                          Flexible(
                            child: DropdownButtonFormField<String>(
                              value: selectedStatus,
                              items: statusOptions
                                  .map((status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(
                                          status,
                                          style: const TextStyle(color: Colors.black), // <-- make option text black
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedStatus = value;
                                  updatestatus(orderData!['id']);
                                  // Optionally, send status update to backend here
                                });
                              },
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black), // <-- selected value text black
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildInfoRow('Shipping Charge', '₹${orderData!['shipping_charge']}'),
                    if ((orderData!['note'] ?? '').isNotEmpty)
                      _buildInfoRow('Note', orderData!['note']),
                  ],
                ),
              ),
            ),


Container(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  margin: const EdgeInsets.symmetric(vertical: 8),
  decoration: BoxDecoration(
    color: const Color.fromARGB(255, 68, 255, 140).withOpacity(0.1), // soft blue background
    borderRadius: BorderRadius.circular(12),   // rounded corners
  ),
  child: Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 0, 169, 20),            // solid accent behind icon
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.shopping_bag,
          color: Color.fromARGB(255, 255, 255, 255),
          size: 22,
        ),
      ),
      const SizedBox(width: 12),
      Text(
        'Total Products: ${items.length}',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: Color.fromARGB(255, 0, 169, 20),
          letterSpacing: 0.5,
        ),
      ),
    ],
  ),
)
,




            Padding(
              padding: const EdgeInsets.only(top: 10, right: 15, left: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Products view',
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  for (var item in visibleItems)
                    Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product image
                                Container(
                                  height: 50,
                                  width: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: item['product_image'] != null
                                        ? DecorationImage(
                                            image: NetworkImage(
                                              item['product_image'].toString().startsWith('http')
                                                  ? item['product_image']
                                                  : 'https://bepocart.in${item['product_image']}',
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                    color: Colors.grey[200],
                                  ),
                                  child: item['product_image'] == null
                                      ? const Icon(Icons.inventory_2, color: Colors.blueAccent)
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                // Product details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['product_name'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Quantity: ${item["quantity"]}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      if (item['description'] != null && item['description'].toString().isNotEmpty)
                                        Text(
                                          item['description'],
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                  IconButton(
                                    icon: const Icon(Icons.inventory_2, color: Colors.blue, size: 22),
                                    tooltip: 'View Rack Details',
                                    onPressed: () async {
                                      final itemId = int.tryParse(item['id'].toString()) ?? 0;
                                      final ordered = int.tryParse(item['quantity'].toString()) ?? 0;
                                      final already = (_allocationsByItem[itemId] ?? [])
                                          .fold<int>(0, (s, a) => s + (int.tryParse('${a['quantity']}') ?? 0));
                                      final remaining = (ordered - already);

                                      if (remaining <= 0) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Allocation complete for this product.')),
                                        );
                                        return;
                                      }

                                      final result = await showPopupDialog2(context, item, remaining: remaining);
                                      if (result != null) {
                                        final addQty = int.tryParse('${result['quantity']}') ?? 0;
                                        if (already + addQty > ordered) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Exceeds total item quantity ($ordered).')),
                                          );
                                          return;
                                        }
                                        setState(() {
                                          _allocationsByItem.putIfAbsent(itemId, () => []).add(result);
                                        });
                                      }
                                    },
                                  ),
                              ],
                            ),
                            Builder(
                              builder: (_) {
                                final itemId = int.tryParse(item['id'].toString()) ?? 0;
                                final List<Map<String, dynamic>> localAllocs =
                                    (_allocationsByItem[itemId] ?? []).cast<Map<String, dynamic>>();
                                final List<Map<String, dynamic>> serverAllocs =
                                    (item['rack_details'] is List)
                                        ? (item['rack_details'] as List)
                                            .whereType<Map>()
                                            .map<Map<String, dynamic>>((m) => {
                                                  'rack_id': m['rack_id'],
                                                  'rack_name': m['rack_name'],
                                                  'column_name': m['column_name'],
                                                  'quantity': m['quantity'],
                                                })
                                            .toList()
                                        : <Map<String, dynamic>>[];

                                final hasAny = serverAllocs.isNotEmpty || localAllocs.isNotEmpty;
                                if (!hasAny) return const SizedBox.shrink();

                                Widget chipsFor(List<Map<String, dynamic>> list, {required bool deletable}) {
                                  return Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: list.map((a) {
                                      final rack = (a['rack_name'] ?? a['rack_id'] ?? '').toString();
                                      final col = (a['column_name'] ?? '').toString();
                                      final qty = int.tryParse('${a['quantity']}') ?? 0;
                                      final label = '$rack${col.isNotEmpty ? '-$col' : ''} x $qty';

                                      return Chip(
                                        label: Text(label, style: const TextStyle(fontSize: 12)),
                                        backgroundColor: deletable ? null : const Color(0xFFE9ECEF),
                                        deleteIcon: deletable ? const Icon(Icons.close, size: 16) : null,
                                        onDeleted: deletable
                                            ? () {
                                                setState(() {
                                                  localAllocs.remove(a);
                                                  if (localAllocs.isEmpty) {
                                                    _allocationsByItem.remove(itemId);
                                                  }
                                                });
                                              }
                                            : null,
                                      );
                                    }).toList(),
                                  );
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (serverAllocs.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      const Text('Existing allocation',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                      chipsFor(serverAllocs, deletable: false),
                                    ],
                                    if (localAllocs.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      const Text('New allocation',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                      chipsFor(localAllocs, deletable: true),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (items.length > 3)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          showAllProducts = !showAllProducts;
                        });
                      },
                      child: Text(
                        showAllProducts ? 'See Less' : 'See More',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                    
Center(
  child: ElevatedButton(
    onPressed: _submittingAll ? null : () async {
      await submitAllAllocations();
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color.fromARGB(255, 3, 125, 247),
    ),
    child: Text(
      _submittingAll ? 'Submitting...' : 'Submit Rack Details',
      style: const TextStyle(color: Colors.white),
    ),
  ),
)

,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              )),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
