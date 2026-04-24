import 'dart:convert';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class Activity_log extends StatefulWidget {
  const Activity_log({super.key});

  @override
  State<Activity_log> createState() => _Activity_logState();
}

class _Activity_logState extends State<Activity_log> {
  List<Map<String, dynamic>> _raw = [];
  int _currentPage = 1;
  int _pageSize = 100;
  int _count = 0;
  bool _hasMore = true;
  bool _loading = false;
  bool _dataReady = false;

  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  DateTime? _startDate;
  DateTime? _endDate;

  List<String> _suggestions = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetch(); // start fetching
    _searchCtrl.addListener(() {
      final v = _searchCtrl.text.trim();
      if (v != _query) setState(() => _query = v);
      _updateSuggestions(v);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString('token');
  }

  /// Progressive pagination load — shows page 1 immediately,
  /// then continues loading in background.
  Future<void> _fetch({bool loadMore = false}) async {
    if (_loading) return;
    setState(() => _loading = true);

    final token = await _getToken();
    try {
      final res = await http.get(
        Uri.parse('$api/api/datalog/?page=$_currentPage'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final parsed = jsonDecode(res.body);
        final results = parsed['results'];

        if (results is List) {
          if (mounted) {
            setState(() {
              if (loadMore) {
                _raw.addAll(List<Map<String, dynamic>>.from(results));
              } else {
                _raw = List<Map<String, dynamic>>.from(results);
              }

              _count = parsed['count'] ?? 0;
              _pageSize = parsed['page_size'] ?? results.length;
              _hasMore = _raw.length < _count;
              _currentPage++;
            });
          }

          // Automatically fetch next pages
          if (_hasMore) {
            Future.microtask(() => _fetch(loadMore: true));
          } else {
            if (mounted) {
              setState(() {
                _dataReady = true; // all pages done
              });
            }
          }
        }
      } else {
      }
    } catch (e) {
    }

    if (mounted) setState(() => _loading = false);
  }

  void _updateSuggestions(String query) {
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    final q = query.toLowerCase();
    final seen = <String>{};
    final matches = _raw
        .expand((log) => [
              (log['order_name'] ?? '').toString(),
              (log['user_name'] ?? '').toString()
            ])
        .where((s) => s.isNotEmpty && s.toLowerCase().contains(q))
        .where(seen.add)
        .toList();
    setState(() => _suggestions = matches.take(8).toList());
  }

  DateTime _parseDt(dynamic v) {
    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  String _flattenInline(dynamic v) {
    if (v == null) return 'N/A';
    if (v is String) return v.trim().isEmpty ? 'N/A' : v;
    if (v is Map) {
      final parts = <String>[];
      v.forEach((k, val) {
        final s = _valueToInline(val);
        if (s.isNotEmpty) parts.add('$k: $s');
      });
      return parts.isEmpty ? 'N/A' : parts.join(', ');
    }
    if (v is Iterable) {
      final parts = v.map(_valueToInline).where((e) => e.isNotEmpty).toList();
      return parts.isEmpty ? 'N/A' : parts.join(', ');
    }
    return v.toString();
  }

  String _valueToInline(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    if (v is num || v is bool) return v.toString();
    if (v is Map || v is Iterable) return _flattenInline(v);
    return v.toString();
  }

  Map<String, dynamic> _ensureMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is String) {
      try {
        final m = jsonDecode(v);
        if (m is Map<String, dynamic>) return m;
      } catch (_) {}
    }
    return {'value': v?.toString()};
  }

  String _statusOf(dynamic v) {
    final m = _ensureMap(v);
    final s = m['status'];
    if (s == null) {
      if (m.containsKey('value')) return m['value'].toString();
      return _flattenInline(v);
    }
    return s.toString();
  }

  /// Filter by search and date (only after data ready)
  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> data) {
    final q = _query.toLowerCase();
   

    final filtered = data.where((log) {
      final orderName = (log['order_name'] ?? '').toString().toLowerCase();
      final userName = (log['user_name'] ?? '').toString().toLowerCase();
      final matchesQuery =
          _query.isEmpty || orderName.contains(q) || userName.contains(q);

      final dt = _parseDt(log['created_at']);
      bool matchesDate = true;

      if (_startDate != null && _endDate != null) {
        final start =
            DateTime(_startDate!.year, _startDate!.month, _startDate!.day, 0, 0, 0);
        final end =
            DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59, 999);

        matchesDate =
            dt.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
                dt.isBefore(end.add(const Duration(milliseconds: 1)));
      }

      return matchesQuery && matchesDate;
    }).toList();

   
    return filtered;
  }

  List<MapEntry<String, List<Map<String, dynamic>>>> _groupByDay(
      List<Map<String, dynamic>> source) {
    final Map<String, List<Map<String, dynamic>>> buckets = {};
    for (final log in source) {
      final dt = _parseDt(log['created_at']);
      final key = DateFormat('yyyy-MM-dd').format(dt);
      buckets.putIfAbsent(key, () => []).add(log);
    }
    final entries = buckets.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return entries;
  }

  String _prettyDay(String dayKey) =>
      DateFormat('EEE, d MMM').format(DateTime.parse(dayKey));
  String _prettyTime(DateTime dt) => DateFormat('hh:mm a').format(dt);

  Color _chipColor(String before, String after) =>
      before != after ? const Color(0xFFFF7676) : const Color(0xFF4CAF50);
  String _chipText(String before, String after) =>
      before != after ? 'Changed' : 'No Update';

  @override
  Widget build(BuildContext context) {
    final filtered = _dataReady ? _applyFilter(_raw) : _raw;
    final groups = _groupByDay(filtered);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Activity Log',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: Color(0xFF222222),
            letterSpacing: 0.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Stack(
              children: [
                TextField(
                  controller: _searchCtrl,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search by invoice or staff',
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF1976D2)),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon:
                                const Icon(Icons.close, color: Colors.grey),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                              _updateSuggestions('');
                            },
                          )
                        : null,
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                  style:
                      const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                if (_suggestions.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 48,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _suggestions.length,
                        itemBuilder: (context, i) {
                          final suggestion = _suggestions[i];
                          return ListTile(
                            title: Text(suggestion),
                            onTap: () {
                              _searchCtrl.text = suggestion;
                              _searchCtrl.selection =
                                  TextSelection.fromPosition(
                                TextPosition(offset: suggestion.length),
                              );
                              setState(() {
                                _query = suggestion;
                                _suggestions = [];
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Filter by date range',
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 5),
                lastDate: DateTime(now.year + 1),
                initialDateRange: _startDate != null && _endDate != null
                    ? DateTimeRange(start: _startDate!, end: _endDate!)
                    : null,
              );
              if (picked != null) {
                setState(() {
                  _startDate = picked.start;
                  _endDate = picked.end;
                });

                // Wait for data if still loading
                if (!_dataReady) {
                  Future.doWhile(() async {
                    await Future.delayed(const Duration(milliseconds: 400));
                    return !_dataReady;
                  }).then((_) {
                    if (mounted) setState(() {});
                  });
                }
              }
            },
          ),
          if (_startDate != null && _endDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear date filter',
              onPressed: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                });
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _raw.isEmpty && _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                _currentPage = 1;
                _hasMore = true;
                await _fetch();
              },
              child: groups.isEmpty
                  ? const Center(child: Text('No logs found'))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                      itemCount: groups.length,
                      itemBuilder: (_, i) {
                        final entry = groups[i];
                        final dayKey = entry.key;
                        final items = entry.value
                          ..sort((a, b) => _parseDt(b['created_at'])
                              .compareTo(_parseDt(a['created_at'])));

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 8, bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 18, color: Color(0xFF1976D2)),
                                  const SizedBox(width: 8),
                                  Text(
                                    _prettyDay(dayKey),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: Color(0xFF1976D2),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1976D2)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${items.length} entr${items.length == 1 ? 'y' : 'ies'}',
                                      style: const TextStyle(
                                        color: Color(0xFF1976D2),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...items.map((log) {
                              final before = _statusOf(log['before_data']);
                              final after = _statusOf(log['after_data']);
                              final dt = _parseDt(log['created_at']);
                              final userName =
                                  (log['user_name'] ?? '').toString();
                              final orderName =
                                  (log['order_name'] ?? '').toString();

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                      color: Colors.black.withOpacity(.06),
                                    ),
                                  ],
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _showDetail(
                                      context, log, before, after, dt),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor:
                                              const Color(0xFF1976D2)
                                                  .withOpacity(.15),
                                          child: Text(
                                            (userName.isNotEmpty
                                                    ? userName[0]
                                                    : orderName.isNotEmpty
                                                        ? orderName[0]
                                                        : '#')
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF1976D2),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      orderName.isEmpty
                                                          ? ''
                                                          : orderName,
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 15),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: _chipColor(
                                                              before, after)
                                                          .withOpacity(.14),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      border: Border.all(
                                                        color: _chipColor(
                                                            before, after),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      _chipText(before, after),
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 11,
                                                        color: _chipColor(
                                                            before, after),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 6,
                                                children: [
                                                  _statusPill(before,
                                                      background:
                                                          const Color(
                                                              0xFFF0F1F4)),
                                                  const Icon(
                                                      Icons
                                                          .arrow_forward_rounded,
                                                      size: 16),
                                                  _statusPill(after,
                                                      background:
                                                          const Color(
                                                              0xFFEFFAF0)),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 6,
                                                children: [
                                                  Icon(
                                                      Icons.person_outline,
                                                      size: 16,
                                                      color: Colors.black
                                                          .withOpacity(.55)),
                                                  Text(
                                                    userName,
                                                    style: TextStyle(
                                                      color: Colors.black
                                                          .withOpacity(.7),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  Icon(Icons.access_time,
                                                      size: 16,
                                                      color: Colors.black
                                                          .withOpacity(.55)),
                                                  Text(
                                                    _prettyTime(dt),
                                                    style: TextStyle(
                                                      color: Colors.black
                                                          .withOpacity(.65),
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
            ),
    );
  }

  Widget _statusPill(String text, {required Color background}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        (text.isEmpty ? 'N/A' : text),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }

  void _showDetail(BuildContext context, Map<String, dynamic> log,
      String before, String after, DateTime dt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                Text('Log #${log['id']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 8),
                if (log['order_name'] != null &&
                    log['order_name'].toString().isNotEmpty)
                  Text('Order: ${log['order_name']}'),
                Text('User: ${log['user_name']}'),
                Text('Date: ${DateFormat('dd-MM-yyyy hh:mm a').format(dt)}'),
                const Divider(),
                const Text('Change',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 10),
                _wideChangeBlock(_flattenInline(log['before_data']),
                    bg: const Color(0xFFF0F1F4)),
                const Center(child: Icon(Icons.arrow_downward_rounded)),
                _wideChangeBlock(_flattenInline(log['after_data']),
                    bg: const Color(0xFFEFFAF0)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _wideChangeBlock(String text, {Color bg = const Color(0xFFF3F5F7)}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        softWrap: true,
        overflow: TextOverflow.visible,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}
