import 'dart:async';
import 'dart:convert';

import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductRackUsabilityPage extends StatefulWidget {
  const ProductRackUsabilityPage({
    super.key,
    required this.baseUrl,
    required this.token,
    this.initialUsability = 'usable',
  });

  final String baseUrl;
  final String token;
  final String initialUsability;

  @override
  State<ProductRackUsabilityPage> createState() =>
      _ProductRackUsabilityPageState();
}

class _ProductRackUsabilityPageState extends State<ProductRackUsabilityPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  final List<ProductRackItem> _items = [];
  RackReportSummary _summary = const RackReportSummary();
  RackPagination _pagination = const RackPagination();
  RackReportFilters _filters = const RackReportFilters();

  bool _initialLoading = true;
  bool _pageLoading = false;
  String? _errorMessage;
  late String _usability;

  @override
  void initState() {
    super.initState();
    _usability = widget.initialUsability;
    _scrollController.addListener(_handleScroll);
    _fetchReport(reset: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients ||
        _initialLoading ||
        _pageLoading ||
        !_pagination.hasNext) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 500) {
      _fetchReport(page: _pagination.currentPage + 1);
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 550), () {
      _filters = _filters.copyWith(search: value.trim());
      _fetchReport(reset: true);
    });
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

  Future<void> _fetchReport({bool reset = false, int? page}) async {
    if (_pageLoading) return;

    final requestedPage = reset ? 1 : (page ?? 1);
    setState(() {
      if (reset) {
        _initialLoading = true;
        _errorMessage = null;
      } else {
        _pageLoading = true;
      }
    });

    try {
      final query = <String, String>{
        'page': requestedPage.toString(),
        'page_size': '50',
        ..._filters.toQueryParameters(),
      };

      final normalizedBase = widget.baseUrl.replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse(
        '$normalizedBase/api/products/rack/usability/$_usability/',
      ).replace(queryParameters: query);

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          if (widget.token.trim().isNotEmpty)
            'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          _extractApiError(response.body) ??
              'Request failed with status ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Unexpected API response format.');
      }

      final result = RackUsabilityResponse.fromJson(decoded);

      if (!mounted) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(result.data);
        _summary = result.summary;
        _pagination = result.pagination;
        _initialLoading = false;
        _pageLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _initialLoading = false;
        _pageLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String? _extractApiError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        for (final key in ['message', 'detail', 'error']) {
          final value = decoded[key];
          if (value != null && value.toString().trim().isNotEmpty) {
            return value.toString();
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<RackReportFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RackReportFilterSheet(
        initial: _filters,
        baseUrl: widget.baseUrl,
        token: widget.token,
      ),
    );

    if (result == null) return;
    setState(() {
      _filters = result;
      _searchController.text = result.search;
    });
    await _fetchReport(reset: true);
  }

  Future<void> _clearFilters() async {
    _searchController.clear();
    setState(() => _filters = const RackReportFilters());
    await _fetchReport(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        colorScheme: theme.colorScheme.copyWith(
          primary: const Color(0xFF174EA6),
          secondary: const Color(0xFF2F80ED),
          surface: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDDE3EC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDDE3EC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF174EA6),
              width: 1.5,
            ),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF0F2F5F),
          foregroundColor: Colors.white,
          elevation: 0,
          leadingWidth: 56,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: IconButton(
              tooltip: 'Back',
              onPressed: _navigateBack,
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),
          titleSpacing: 4,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product Rack Usability',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Monitor rack stock and availability',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFD7E4F8),
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: 'Refresh',
                onPressed:
                    _initialLoading ? null : () => _fetchReport(reset: true),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          color: const Color(0xFF174EA6),
          onRefresh: () => _fetchReport(reset: true),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              if (_initialLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ProfessionalLoadingView(),
                )
              else if (_errorMessage != null && _items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorView(
                    message: _errorMessage!,
                    onRetry: () => _fetchReport(reset: true),
                  ),
                )
              else if (_items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyView(
                    hasFilters: _filters.activeCount > 0,
                    onClearFilters: _clearFilters,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 90),
                  sliver: SliverList.builder(
                    itemCount: _items.length + (_pageLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.6),
                            ),
                          ),
                        );
                      }
                      return ProductRackCard(item: _items[index]);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hasFilters = _filters.activeCount > 0;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF174EA6), Color(0xFF2F80ED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26174EA6),
                  blurRadius: 22,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _usability,
                        dropdownColor: Colors.white,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF174EA6),
                        ),
                        decoration: InputDecoration(
                          labelText: '',
                          labelStyle: const TextStyle(
                            color: Color(0xFF5B6B80),
                          ),
                          prefixIcon: const Icon(
                            Icons.inventory_2_outlined,
                            color: Color(0xFF174EA6),
                          ),
                          fillColor: Colors.white,
                          filled: true,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'usable',
                            child: Text('Usable'),
                          ),
                          DropdownMenuItem(
                            value: 'damaged',
                            child: Text('Damaged'),
                          ),
                          DropdownMenuItem(
                            value: 'partially_damaged',
                            child: Text('Partially Damaged'),
                          ),
                          DropdownMenuItem(
                            value: 'liquidation_stock',
                            child: Text('Liquidation Stock'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null || value == _usability) return;
                          setState(() => _usability = value);
                          _fetchReport(reset: true);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Badge(
                      isLabelVisible: hasFilters,
                      label: Text('${_filters.activeCount}'),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: _openFilters,
                          borderRadius: BorderRadius.circular(14),
                          child: const SizedBox(
                            width: 52,
                            height: 52,
                            child: Icon(
                              Icons.tune_rounded,
                              color: Color(0xFF174EA6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    _onSearchChanged(value);
                    setState(() {});
                  },
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search product, HSN, rack or column',
                    hintStyle: const TextStyle(color: Color(0xFF8491A3)),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF174EA6),
                    ),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCFE0FC)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_alt_rounded,
                    size: 18,
                    color: Color(0xFF174EA6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_filters.activeCount} active filter${_filters.activeCount == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF174EA6),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _clearFilters,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF174EA6),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Clear all'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          _SummaryGrid(summary: _summary),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFDDE3EC)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 16,
                      color: Color(0xFF174EA6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_pagination.totalRecords} products',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Page ${_pagination.currentPage} of ${_pagination.totalPages}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6F7C8E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProductRackCard extends StatelessWidget {
  const ProductRackCard({super.key, required this.item});

  final ProductRackItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = item.selectedRackSummary;
    final available = selected.availableStock;
    final statusColor =
        available > 0 ? const Color(0xFF0F9D58) : const Color(0xFFD93025);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D152238),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(14, 13, 12, 11),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          iconColor: const Color(0xFF174EA6),
          collapsedIconColor: const Color(0xFF718096),
          leading: _ProductImage(url: item.image),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 15,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A2433),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  available > 0 ? 'In stock' : 'No stock',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Tag(text: '#${item.id}', highlighted: true),
                    if (item.groupId.isNotEmpty) _Tag(text: item.groupId),
                    if (item.type.isNotEmpty) _Tag(text: item.type),
                    if (item.unit.isNotEmpty) _Tag(text: item.unit),
                    if (item.color.isNotEmpty) _Tag(text: item.color),
                    if (item.size.isNotEmpty) _Tag(text: item.size),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _MiniMetric(
                          label: 'Rack stock',
                          value: selected.rackStock,
                          icon: Icons.inventory_2_outlined,
                        ),
                      ),
                      const _MetricDivider(),
                      Expanded(
                        child: _MiniMetric(
                          label: 'Locked',
                          value: selected.rackLock,
                          icon: Icons.lock_outline_rounded,
                        ),
                      ),
                      const _MetricDivider(),
                      Expanded(
                        child: _MiniMetric(
                          label: 'Available',
                          value: selected.availableStock,
                          icon: Icons.check_circle_outline_rounded,
                          emphasize: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          children: [
            const Divider(height: 22, color: Color(0xFFE8ECF2)),
            _DetailsGrid(item: item),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.view_column_outlined,
                  size: 20,
                  color: Color(0xFF174EA6),
                ),
                const SizedBox(width: 8),
                Text(
                  'Rack details',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${item.rackDetails.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF174EA6),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (item.rackDetails.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'No rack entries available for this product.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF718096)),
                ),
              )
            else
              ...item.rackDetails.map((rack) => _RackDetailTile(rack: rack)),
          ],
        ),
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      color: const Color(0xFFE0E5ED),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final RackReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 900
        ? 5
        : width >= 620
            ? 3
            : 2;

    final cards = [
      const _SummaryStyle(
        'Products',
        Icons.inventory_2_outlined,
        Color(0xFF174EA6),
        Color(0xFFEAF2FF),
      ),
      const _SummaryStyle(
        'Rack entries',
        Icons.view_column_outlined,
        Color(0xFF7B61FF),
        Color(0xFFF0ECFF),
      ),
      const _SummaryStyle(
        'Rack stock',
        Icons.warehouse_outlined,
        Color(0xFFF2994A),
        Color(0xFFFFF3E7),
      ),
      const _SummaryStyle(
        'Locked',
        Icons.lock_outline_rounded,
        Color(0xFFD93025),
        Color(0xFFFFECEA),
      ),
      const _SummaryStyle(
        'Available',
        Icons.check_circle_outline_rounded,
        Color(0xFF0F9D58),
        Color(0xFFE8F7EF),
      ),
    ];

    final values = [
      summary.totalProducts,
      summary.totalRackEntries,
      summary.totalRackStock,
      summary.totalRackLock,
      summary.totalAvailableStock,
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: width >= 620 ? 2.25 : 1.55,
      ),
      itemBuilder: (context, index) {
        final card = cards[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE3E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A152238),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: card.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(card.icon, color: card.color, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      NumberFormat.decimalPattern().format(values[index]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1A2433),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      card.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF6F7C8E),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryStyle {
  const _SummaryStyle(
    this.label,
    this.icon,
    this.color,
    this.backgroundColor,
  );

  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final uri = url == null ? null : Uri.tryParse(url!.trim());
    final valid = uri != null && uri.hasScheme && uri.host.isNotEmpty;

    return Container(
      width: 66,
      height: 66,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E5ED)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: valid
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
              )
            : const _ImagePlaceholder(),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3F6FA),
      child: const Icon(
        Icons.inventory_2_outlined,
        color: Color(0xFF8A96A8),
        size: 28,
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, this.highlighted = false});
  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFEAF2FF) : const Color(0xFFF1F4F8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              highlighted ? const Color(0xFFCFE0FC) : const Color(0xFFE4E8EF),
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: highlighted
                  ? const Color(0xFF174EA6)
                  : const Color(0xFF5C697A),
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    this.icon,
    this.emphasize = false,
  });

  final String label;
  final int value;
  final IconData? icon;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final color = emphasize ? const Color(0xFF0F9D58) : const Color(0xFF263445);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF748195),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            NumberFormat.decimalPattern().format(value),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

class _DetailsGrid extends StatelessWidget {
  const _DetailsGrid({required this.item});
  final ProductRackItem item;

  @override
  Widget build(BuildContext context) {
    final values = <_DetailValue>[
      _DetailValue('HSN', item.hsnCode, Icons.qr_code_2_rounded),
      _DetailValue(
        'Warehouse',
        item.warehouse?.name ?? '-',
        Icons.warehouse_outlined,
      ),
      _DetailValue(
        'Main category',
        item.mainCategory?.name ?? '-',
        Icons.category_outlined,
      ),
      _DetailValue(
        'Product category',
        item.productCategory?.name ?? '-',
        Icons.account_tree_outlined,
      ),
      _DetailValue(
        'Families',
        item.families.map((e) => e.name).join(', '),
        Icons.group_work_outlined,
      ),
      _DetailValue(
        'Created by',
        item.createdUser?.name ?? '-',
        Icons.person_outline_rounded,
      ),
      _DetailValue(
        'Approved by',
        item.approvedUser?.name ?? '-',
        Icons.verified_user_outlined,
      ),
      _DetailValue(
        'Approval',
        item.approvalStatus,
        Icons.verified_outlined,
      ),
      _DetailValue(
        'Purchase type',
        item.purchaseType,
        Icons.shopping_bag_outlined,
      ),
      _DetailValue(
        'Purchase rate',
        _money(item.purchaseRate),
        Icons.payments_outlined,
      ),
      _DetailValue(
        'Selling price',
        _money(item.sellingPrice),
        Icons.sell_outlined,
      ),
      _DetailValue(
        'Landing cost',
        _money(item.landingCost),
        Icons.flight_land_outlined,
      ),
      _DetailValue(
        'Retail price',
        _money(item.retailPrice),
        Icons.storefront_outlined,
      ),
      _DetailValue(
        'Final price',
        _money(item.finalPrice),
        Icons.price_check_outlined,
      ),
      _DetailValue(
        'Tax',
        item.tax == null ? '-' : '${item.tax}%',
        Icons.percent_rounded,
      ),
      _DetailValue(
        'Rack count',
        '${item.selectedRackSummary.rackCount}',
        Icons.view_column_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 800
            ? 4
            : width >= 520
                ? 3
                : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: values.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: width >= 520 ? 2.35 : 1.85,
          ),
          itemBuilder: (context, index) {
            final value = values[index];
            final displayValue = value.value.trim().isEmpty ? '-' : value.value;

            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5EAF1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      value.icon,
                      size: 17,
                      color: const Color(0xFF174EA6),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: const Color(0xFF7A8798),
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayValue,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF263445),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static String _money(double? value) {
    if (value == null) return '-';
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: value % 1 == 0 ? 0 : 2,
    ).format(value);
  }
}

class _DetailValue {
  const _DetailValue(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class _RackDetailTile extends StatelessWidget {
  const _RackDetailTile({required this.rack});
  final RackDetail rack;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.shelves,
                  color: Color(0xFF174EA6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rack.rackName.isEmpty
                          ? 'Rack #${rack.rackId}'
                          : rack.rackName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF263445),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rack.columnName.isEmpty
                          ? 'Column not specified'
                          : rack.columnName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF718096),
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7EF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  rack.usability.isEmpty ? 'N/A' : rack.usability,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF0F9D58),
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    label: 'Stock',
                    value: rack.rackStock,
                    icon: Icons.inventory_2_outlined,
                  ),
                ),
                const _MetricDivider(),
                Expanded(
                  child: _MiniMetric(
                    label: 'Locked',
                    value: rack.rackLock,
                    icon: Icons.lock_outline_rounded,
                  ),
                ),
                const _MetricDivider(),
                Expanded(
                  child: _MiniMetric(
                    label: 'Available',
                    value: rack.availableStock,
                    icon: Icons.check_circle_outline_rounded,
                    emphasize: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfessionalLoadingView extends StatelessWidget {
  const _ProfessionalLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(height: 14),
          Text(
            'Loading rack inventory...',
            style: TextStyle(
              color: Color(0xFF617085),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class RackReportFilterSheet extends StatefulWidget {
  const RackReportFilterSheet({
    super.key,
    required this.initial,
    required this.baseUrl,
    required this.token,
  });

  final RackReportFilters initial;
  final String baseUrl;
  final String token;

  @override
  State<RackReportFilterSheet> createState() => _RackReportFilterSheetState();
}

class _RackReportFilterSheetState extends State<RackReportFilterSheet> {
  late final Map<String, TextEditingController> _controllers;
  late String _productType;
  late String _purchaseType;
  late String _approvalStatus;
  late String _hasStock;
  late String _ordering;
  late String _warehouseId;
  late String _mainCategoryId;
  late String _productCategoryId;
  late String _familyId;
  DateTime? _startDate;
  DateTime? _endDate;

  bool _classificationLoading = true;
  String? _classificationError;
  List<FilterOption> _warehouses = const [];
  List<FilterOption> _mainCategories = const [];
  List<FilterOption> _productCategories = const [];
  List<FilterOption> _families = const [];

  @override
  void initState() {
    super.initState();
    final f = widget.initial;
    _controllers = {
      'search': TextEditingController(text: f.search),
      'product_id': TextEditingController(text: f.productId),
      'warehouse_id': TextEditingController(text: f.warehouseId),
      'main_category_id': TextEditingController(text: f.mainCategoryId),
      'product_category_id': TextEditingController(text: f.productCategoryId),
      'family_id': TextEditingController(text: f.familyId),
      'created_user_id': TextEditingController(text: f.createdUserId),
      'approved_user_id': TextEditingController(text: f.approvedUserId),
      'unit': TextEditingController(text: f.unit),
      'color': TextEditingController(text: f.color),
      'size': TextEditingController(text: f.size),
      'tax': TextEditingController(text: f.tax),
      'rack_id': TextEditingController(text: f.rackId),
      'rack_name': TextEditingController(text: f.rackName),
      'column_name': TextEditingController(text: f.columnName),
      'min_stock': TextEditingController(text: f.minStock),
      'max_stock': TextEditingController(text: f.maxStock),
      'min_purchase_rate': TextEditingController(text: f.minPurchaseRate),
      'max_purchase_rate': TextEditingController(text: f.maxPurchaseRate),
      'min_selling_price': TextEditingController(text: f.minSellingPrice),
      'max_selling_price': TextEditingController(text: f.maxSellingPrice),
      'min_landing_cost': TextEditingController(text: f.minLandingCost),
      'max_landing_cost': TextEditingController(text: f.maxLandingCost),
      'min_retail_price': TextEditingController(text: f.minRetailPrice),
      'max_retail_price': TextEditingController(text: f.maxRetailPrice),
      'min_final_price': TextEditingController(text: f.minFinalPrice),
      'max_final_price': TextEditingController(text: f.maxFinalPrice),
    };
    _productType = f.productType;
    _purchaseType = f.purchaseType;
    _approvalStatus = f.approvalStatus;
    _hasStock = f.hasStock;
    _ordering = f.ordering;
    _warehouseId = f.warehouseId;
    _mainCategoryId = f.mainCategoryId;
    _productCategoryId = f.productCategoryId;
    _familyId = f.familyId;
    _startDate = _parseDate(f.startDate);
    _endDate = _parseDate(f.endDate);
    _fetchClassificationOptions();
  }

  String get _normalizedBaseUrl =>
      widget.baseUrl.replaceAll(RegExp(r'/+$'), '');

  Future<void> _fetchClassificationOptions() async {
    if (!mounted) return;

    setState(() {
      _classificationLoading = true;
      _classificationError = null;
    });

    try {
      final responses = await Future.wait([
        _getOptions(
          'api/warehouse/add/',
          preferredListKeys: const [],
          nameKeys: const ['name'],
        ),
        _getOptions(
          'api/main/categories/add/',
          preferredListKeys: const ['data', 'results'],
          nameKeys: const ['name', 'category_name', 'main_category_name'],
        ),
        _getOptions(
          'api/product/category/add/',
          preferredListKeys: const [],
          nameKeys: const ['category_name', 'name'],
        ),
        _getOptions(
          'api/familys/',
          preferredListKeys: const ['data', 'results'],
          nameKeys: const ['name', 'family_name'],
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _warehouses = responses[0];
        _mainCategories = responses[1];
        _productCategories = responses[2];
        _families = responses[3];
        _classificationLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _classificationLoading = false;
        _classificationError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<List<FilterOption>> _getOptions(
    String path, {
    required List<String> preferredListKeys,
    required List<String> nameKeys,
  }) async {
    final uri = Uri.parse('$_normalizedBaseUrl/$path');
    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (widget.token.trim().isNotEmpty)
          'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Unable to load filter options (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);
    final rawList = _extractOptionsList(decoded, preferredListKeys);

    final options = <FilterOption>[];
    final seenIds = <String>{};

    for (final raw in rawList) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final id = item['id']?.toString().trim() ?? '';
      if (id.isEmpty || !seenIds.add(id)) continue;

      String name = '';
      for (final key in nameKeys) {
        final candidate = item[key]?.toString().trim() ?? '';
        if (candidate.isNotEmpty && candidate.toLowerCase() != 'null') {
          name = candidate;
          break;
        }
      }

      if (name.isEmpty) continue;
      options.add(FilterOption(id: id, name: name));
    }

    options.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return options;
  }

  List<dynamic> _extractOptionsList(
    dynamic decoded,
    List<String> preferredListKeys,
  ) {
    if (decoded is List) return decoded;
    if (decoded is! Map) return const [];

    final map = Map<String, dynamic>.from(decoded);
    for (final key in preferredListKeys) {
      final value = map[key];
      if (value is List) return value;
      if (value is Map) {
        for (final nestedKey in const ['data', 'results', 'items']) {
          final nested = value[nestedKey];
          if (nested is List) return nested;
        }
      }
    }

    for (final key in const ['data', 'results', 'items']) {
      final value = map[key];
      if (value is List) return value;
      if (value is Map) {
        for (final nestedKey in const ['data', 'results', 'items']) {
          final nested = value[nestedKey];
          if (nested is List) return nested;
        }
      }
    }

    return const [];
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  DateTime? _parseDate(String value) {
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  Future<void> _pickDate(bool start) async {
    final value = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: (start ? _startDate : _endDate) ?? DateTime.now(),
    );
    if (value == null) return;

    setState(() {
      if (start) {
        _startDate = value;
      } else {
        _endDate = value;
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD4DAE4),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 12, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5EAF1)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Color(0xFF174EA6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report Filters',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF1A2433),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Refine products using the options below',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF748195),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: const Color(0xFFF1F4F8),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: const SizedBox(
                      width: 42,
                      height: 42,
                      child: Icon(
                        Icons.close_rounded,
                        color: Color(0xFF536174),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                14,
                14,
                14,
                28 + keyboardHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _filterCard(
                    child: _field(
                      'search',
                      'Search products',
                      hint: 'Product name, HSN, rack or column',
                      icon: Icons.search_rounded,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _filterCard(
                    title: 'Classification',
                    subtitle: 'Filter using product and user information',
                    icon: Icons.category_outlined,
                    child: Column(
                      children: [
                        if (_classificationLoading)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: LinearProgressIndicator(minHeight: 3),
                          ),
                        if (_classificationError != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFECEA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFF4C7C3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 18,
                                  color: Color(0xFFD93025),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _classificationError!,
                                    style: const TextStyle(
                                      color: Color(0xFF9B1C13),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _fetchClassificationOptions,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        _optionDropdown(
                          label: 'Warehouse',
                          value: _warehouseId,
                          options: _warehouses,
                          icon: Icons.warehouse_outlined,
                          allLabel: 'All warehouses',
                          onChanged: (value) {
                            setState(() => _warehouseId = value);
                          },
                        ),
                        _twoFields(
                          _optionDropdown(
                            label: 'Main category',
                            value: _mainCategoryId,
                            options: _mainCategories,
                            icon: Icons.account_tree_outlined,
                            allLabel: 'All main categories',
                            onChanged: (value) {
                              setState(() => _mainCategoryId = value);
                            },
                          ),
                          _optionDropdown(
                            label: 'Product category',
                            value: _productCategoryId,
                            options: _productCategories,
                            icon: Icons.category_rounded,
                            allLabel: 'All product categories',
                            onChanged: (value) {
                              setState(() => _productCategoryId = value);
                            },
                          ),
                        ),
                        _optionDropdown(
                          label: 'Family',
                          value: _familyId,
                          options: _families,
                          icon: Icons.group_work_outlined,
                          allLabel: 'All families',
                          onChanged: (value) {
                            setState(() => _familyId = value);
                          },
                        ),
                        _twoFields(
                          _dropdown(
                            label: 'Product type',
                            value: _productType,
                            icon: Icons.widgets_outlined,
                            values: const {
                              '': 'All product types',
                              'single': 'Single',
                              'variant': 'Variant',
                            },
                            onChanged: (value) {
                              setState(() => _productType = value);
                            },
                          ),
                          _dropdown(
                            label: 'Purchase type',
                            value: _purchaseType,
                            icon: Icons.shopping_bag_outlined,
                            values: const {
                              '': 'All purchase types',
                              'Local': 'Local',
                              'International': 'International',
                            },
                            onChanged: (value) {
                              setState(() => _purchaseType = value);
                            },
                          ),
                        ),
                        _twoFields(
                          _dropdown(
                            label: 'Approval status',
                            value: _approvalStatus,
                            icon: Icons.verified_outlined,
                            values: const {
                              '': 'All statuses',
                              'Approved': 'Approved',
                              'Disapproved': 'Disapproved',
                            },
                            onChanged: (value) {
                              setState(() => _approvalStatus = value);
                            },
                          ),
                          _dropdown(
                            label: 'Stock availability',
                            value: _hasStock,
                            icon: Icons.inventory_outlined,
                            values: const {
                              '': 'All stock',
                              'true': 'Has stock',
                              'false': 'No stock',
                            },
                            onChanged: (value) {
                              setState(() => _hasStock = value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // _filterCard(
                  //   title: 'Rack Details',
                  //   subtitle: 'Locate products by rack and column',
                  //   icon: Icons.shelves,
                  //   child: Column(
                  //     children: [
                  //       _twoFields(
                  //         _field(
                  //           'rack_id',
                  //           'Rack ID',
                  //           number: true,
                  //           icon: Icons.tag_rounded,
                  //         ),
                  //         _field(
                  //           'rack_name',
                  //           'Rack name',
                  //           icon: Icons.shelves,
                  //         ),
                  //       ),
                  //       _field(
                  //         'column_name',
                  //         'Column name',
                  //         icon: Icons.view_column_outlined,
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // const SizedBox(height: 14),
                  _filterCard(
                    title: 'Date Range',
                    subtitle: 'Choose the product creation period',
                    icon: Icons.date_range_outlined,
                    child: _twoFields(
                      _dateField(
                        'Start date',
                        _startDate,
                        () => _pickDate(true),
                      ),
                      _dateField(
                        'End date',
                        _endDate,
                        () => _pickDate(false),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _filterCard(
                    title: 'Stock Range',
                    subtitle: 'Set minimum and maximum stock limits',
                    icon: Icons.inventory_2_outlined,
                    child: _twoFields(
                      _field(
                        'min_stock',
                        'Minimum stock',
                        number: true,
                        icon: Icons.remove_rounded,
                      ),
                      _field(
                        'max_stock',
                        'Maximum stock',
                        number: true,
                        icon: Icons.add_rounded,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _filterCard(
                    title: 'Price Ranges',
                    subtitle: 'Filter products based on price limits',
                    icon: Icons.currency_rupee_rounded,
                    child: Column(
                      children: [
                        _range(
                          'Purchase rate',
                          'min_purchase_rate',
                          'max_purchase_rate',
                        ),
                        _range(
                          'Selling price',
                          'min_selling_price',
                          'max_selling_price',
                        ),
                        _range(
                          'Landing cost',
                          'min_landing_cost',
                          'max_landing_cost',
                        ),
                        _range(
                          'Retail price',
                          'min_retail_price',
                          'max_retail_price',
                        ),
                        _range(
                          'Final price',
                          'min_final_price',
                          'max_final_price',
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _filterCard(
                    title: 'Sort Results',
                    subtitle: 'Choose how report results should be arranged',
                    icon: Icons.sort_rounded,
                    child: _dropdown(
                      label: 'Order by',
                      value: _ordering,
                      icon: Icons.swap_vert_rounded,
                      values: const {
                        '-id': 'Newest first',
                        'id': 'Oldest first',
                        'name': 'Name A–Z',
                        '-name': 'Name Z–A',
                        'selected_rack_stock': 'Rack stock: low to high',
                        '-selected_rack_stock': 'Rack stock: high to low',
                        'selected_available_stock': 'Available: low to high',
                        '-selected_available_stock': 'Available: high to low',
                      },
                      onChanged: (value) {
                        setState(() => _ordering = value);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE5EAF1)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x120F243F),
                  blurRadius: 18,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            const RackReportFilters(),
                          );
                        },
                        icon: const Icon(
                          Icons.restart_alt_rounded,
                          size: 20,
                        ),
                        label: const Text('Reset'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF174EA6),
                          side: const BorderSide(
                            color: Color(0xFFB8C8E3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _apply,
                        icon: const Icon(
                          Icons.check_rounded,
                          size: 21,
                        ),
                        label: const Text('Apply Filters'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF174EA6),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
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
    );
  }

  Widget _filterCard({
    String? title,
    String? subtitle,
    IconData? icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A152238),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: const Color(0xFF174EA6),
                    ),
                  ),
                  const SizedBox(width: 11),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: const Color(0xFF263445),
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF7A8798),
                                    height: 1.3,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
          ],
          child,
        ],
      ),
    );
  }

  Widget _field(
    String key,
    String label, {
    bool number = false,
    String? hint,
    IconData? icon,
    String? suffixText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: TextField(
        controller: _controllers[key],
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        textInputAction: TextInputAction.next,
        style: const TextStyle(
          color: Color(0xFF263445),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon == null
              ? null
              : Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFF758399),
                ),
          suffixText: suffixText,
          suffixStyle: const TextStyle(
            color: Color(0xFF657286),
            fontWeight: FontWeight.w700,
          ),
          labelStyle: const TextStyle(
            color: Color(0xFF657286),
            fontWeight: FontWeight.w500,
          ),
          hintStyle: const TextStyle(
            color: Color(0xFFA0AABA),
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: const Color(0xFFF8FAFD),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: Color(0xFFDDE3EC),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: Color(0xFFDDE3EC),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: Color(0xFF174EA6),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required Map<String, String> values,
    required ValueChanged<String> onChanged,
    IconData? icon,
  }) {
    final safeValue = values.containsKey(value) ? value : values.keys.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: DropdownButtonFormField<String>(
        value: safeValue,
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Color(0xFF657286),
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(14),
        style: const TextStyle(
          color: Color(0xFF263445),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon == null
              ? null
              : Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFF758399),
                ),
          labelStyle: const TextStyle(
            color: Color(0xFF657286),
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: const Color(0xFFF8FAFD),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: Color(0xFFDDE3EC),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: Color(0xFFDDE3EC),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: Color(0xFF174EA6),
              width: 1.5,
            ),
          ),
        ),
        items: values.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(
              entry.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (selectedValue) {
          if (selectedValue != null) {
            onChanged(selectedValue);
          }
        },
      ),
    );
  }

  Widget _optionDropdown({
    required String label,
    required String value,
    required List<FilterOption> options,
    required ValueChanged<String> onChanged,
    required String allLabel,
    IconData? icon,
  }) {
    final validValue =
        value.isEmpty || options.any((e) => e.id == value) ? value : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: DropdownButtonFormField<String>(
        value: validValue,
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Color(0xFF657286),
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(14),
        style: const TextStyle(
          color: Color(0xFF263445),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon == null
              ? null
              : Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFF758399),
                ),
          labelStyle: const TextStyle(
            color: Color(0xFF657286),
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: const Color(0xFFF8FAFD),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xFFDDE3EC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xFFDDE3EC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: Color(0xFF174EA6),
              width: 1.5,
            ),
          ),
        ),
        items: [
          DropdownMenuItem<String>(
            value: '',
            child: Text(allLabel),
          ),
          ...options.map(
            (option) => DropdownMenuItem<String>(
              value: option.id,
              child: Text(
                option.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        onChanged: _classificationLoading
            ? null
            : (selectedValue) {
                if (selectedValue != null) onChanged(selectedValue);
              },
      ),
    );
  }

  Widget _dateField(
    String label,
    DateTime? date,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: const Icon(
                Icons.calendar_month_outlined,
                size: 20,
                color: Color(0xFF758399),
              ),
              suffixIcon: date == null
                  ? const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF657286),
                    )
                  : IconButton(
                      tooltip: 'Clear date',
                      onPressed: () {
                        setState(() {
                          if (label.startsWith('Start')) {
                            _startDate = null;
                          } else {
                            _endDate = null;
                          }
                        });
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 19,
                      ),
                    ),
              labelStyle: const TextStyle(
                color: Color(0xFF657286),
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFD),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: Color(0xFFDDE3EC),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: Color(0xFFDDE3EC),
                ),
              ),
            ),
            child: Text(
              date == null
                  ? 'Select date'
                  : DateFormat('dd MMM yyyy').format(date),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: date == null
                    ? const Color(0xFFA0AABA)
                    : const Color(0xFF263445),
                fontSize: 14,
                fontWeight: date == null ? FontWeight.w400 : FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _twoFields(Widget first, Widget second) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 390) {
          return Column(
            children: [
              first,
              second,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 10),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  Widget _range(
    String label,
    String minKey,
    String maxKey, {
    bool showDivider = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF174EA6),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF354255),
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        _twoFields(
          _field(
            minKey,
            'Minimum',
            number: true,
            icon: Icons.currency_rupee_rounded,
          ),
          _field(
            maxKey,
            'Maximum',
            number: true,
            icon: Icons.currency_rupee_rounded,
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Divider(
              height: 1,
              color: Color(0xFFE8ECF2),
            ),
          ),
        if (showDivider) const SizedBox(height: 12),
      ],
    );
  }

  void _apply() {
    String text(String key) => _controllers[key]!.text.trim();
    String date(DateTime? value) =>
        value == null ? '' : DateFormat('yyyy-MM-dd').format(value);

    Navigator.pop(
      context,
      RackReportFilters(
        search: text('search'),
        productId: text('product_id'),
        warehouseId: _warehouseId,
        mainCategoryId: _mainCategoryId,
        productCategoryId: _productCategoryId,
        familyId: _familyId,
        createdUserId: text('created_user_id'),
        approvedUserId: text('approved_user_id'),
        productType: _productType,
        purchaseType: _purchaseType,
        approvalStatus: _approvalStatus,
        unit: text('unit'),
        color: text('color'),
        size: text('size'),
        tax: text('tax'),
        startDate: date(_startDate),
        endDate: date(_endDate),
        minStock: text('min_stock'),
        maxStock: text('max_stock'),
        minPurchaseRate: text('min_purchase_rate'),
        maxPurchaseRate: text('max_purchase_rate'),
        minSellingPrice: text('min_selling_price'),
        maxSellingPrice: text('max_selling_price'),
        minLandingCost: text('min_landing_cost'),
        maxLandingCost: text('max_landing_cost'),
        minRetailPrice: text('min_retail_price'),
        maxRetailPrice: text('max_retail_price'),
        minFinalPrice: text('min_final_price'),
        maxFinalPrice: text('max_final_price'),
        hasStock: _hasStock,
        rackId: text('rack_id'),
        rackName: text('rack_name'),
        columnName: text('column_name'),
        ordering: _ordering,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE3E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D152238),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEA),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: Color(0xFFD93025),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load products',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF263445),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF718096),
                    ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.hasFilters,
    required this.onClearFilters,
  });

  final bool hasFilters;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE3E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 34,
                  color: Color(0xFF174EA6),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No products found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF263445),
                    ),
              ),
              const SizedBox(height: 7),
              Text(
                hasFilters
                    ? 'Try changing or clearing the applied filters.'
                    : 'There are no products available for this usability type.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF718096),
                    ),
              ),
              if (hasFilters) ...[
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  label: const Text('Clear filters'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class FilterOption {
  const FilterOption({required this.id, required this.name});

  final String id;
  final String name;
}

class RackUsabilityResponse {
  const RackUsabilityResponse({
    required this.summary,
    required this.pagination,
    required this.data,
  });

  final RackReportSummary summary;
  final RackPagination pagination;
  final List<ProductRackItem> data;

  factory RackUsabilityResponse.fromJson(Map<String, dynamic> json) {
    return RackUsabilityResponse(
      summary: RackReportSummary.fromJson(_map(json['summary'])),
      pagination: RackPagination.fromJson(_map(json['pagination'])),
      data: _list(json['data'])
          .map((e) => ProductRackItem.fromJson(_map(e)))
          .toList(),
    );
  }
}

class RackReportSummary {
  const RackReportSummary({
    this.totalProducts = 0,
    this.totalRackEntries = 0,
    this.totalRackStock = 0,
    this.totalRackLock = 0,
    this.totalAvailableStock = 0,
  });

  final int totalProducts;
  final int totalRackEntries;
  final int totalRackStock;
  final int totalRackLock;
  final int totalAvailableStock;

  factory RackReportSummary.fromJson(Map<String, dynamic> json) {
    return RackReportSummary(
      totalProducts: _int(json['total_products']),
      totalRackEntries: _int(json['total_rack_entries']),
      totalRackStock: _int(json['total_rack_stock']),
      totalRackLock: _int(json['total_rack_lock']),
      totalAvailableStock: _int(json['total_available_stock']),
    );
  }
}

class RackPagination {
  const RackPagination({
    this.currentPage = 1,
    this.pageSize = 50,
    this.totalPages = 1,
    this.totalRecords = 0,
    this.hasNext = false,
    this.hasPrevious = false,
  });

  final int currentPage;
  final int pageSize;
  final int totalPages;
  final int totalRecords;
  final bool hasNext;
  final bool hasPrevious;

  factory RackPagination.fromJson(Map<String, dynamic> json) {
    return RackPagination(
      currentPage: _int(json['current_page'], fallback: 1),
      pageSize: _int(json['page_size'], fallback: 50),
      totalPages: _int(json['total_pages'], fallback: 1),
      totalRecords: _int(json['total_records']),
      hasNext: _bool(json['has_next']),
      hasPrevious: _bool(json['has_previous']),
    );
  }
}

class ProductRackItem {
  const ProductRackItem({
    required this.id,
    required this.name,
    required this.hsnCode,
    required this.variantId,
    required this.groupId,
    required this.type,
    required this.unit,
    required this.purchaseType,
    required this.approvalStatus,
    required this.color,
    required this.size,
    required this.image,
    required this.purchaseRate,
    required this.sellingPrice,
    required this.landingCost,
    required this.retailPrice,
    required this.finalPrice,
    required this.tax,
    required this.warehouse,
    required this.mainCategory,
    required this.productCategory,
    required this.families,
    required this.createdUser,
    required this.approvedUser,
    required this.overallStock,
    required this.selectedUsability,
    required this.selectedRackSummary,
    required this.rackDetails,
  });

  final int id;
  final String name;
  final String hsnCode;
  final String variantId;
  final String groupId;
  final String type;
  final String unit;
  final String purchaseType;
  final String approvalStatus;
  final String color;
  final String size;
  final String? image;
  final double? purchaseRate;
  final double? sellingPrice;
  final double? landingCost;
  final double? retailPrice;
  final double? finalPrice;
  final double? tax;
  final NamedEntity? warehouse;
  final NamedEntity? mainCategory;
  final NamedEntity? productCategory;
  final List<NamedEntity> families;
  final NamedEntity? createdUser;
  final NamedEntity? approvedUser;
  final OverallStock overallStock;
  final String selectedUsability;
  final SelectedRackSummary selectedRackSummary;
  final List<RackDetail> rackDetails;

  factory ProductRackItem.fromJson(Map<String, dynamic> json) {
    NamedEntity? entity(dynamic value) {
      if (value is! Map) return null;
      return NamedEntity.fromJson(Map<String, dynamic>.from(value));
    }

    return ProductRackItem(
      id: _int(json['id']),
      name: _string(json['name'], fallback: 'Unnamed product'),
      hsnCode: _string(json['hsn_code']),
      variantId: _string(json['variant_id']),
      groupId: _string(json['group_id']),
      type: _string(json['type']),
      unit: _string(json['unit']),
      purchaseType: _string(json['purchase_type']),
      approvalStatus: _string(json['approval_status']),
      color: _string(json['color']),
      size: _string(json['size']),
      image: json['image']?.toString(),
      purchaseRate: _doubleOrNull(json['purchase_rate']),
      sellingPrice: _doubleOrNull(json['selling_price']),
      landingCost: _doubleOrNull(json['landing_cost']),
      retailPrice: _doubleOrNull(json['retail_price']),
      finalPrice: _doubleOrNull(json['final_price']),
      tax: _doubleOrNull(json['tax']),
      warehouse: entity(json['warehouse']),
      mainCategory: entity(json['main_category']),
      productCategory: entity(json['product_category']),
      families: _list(json['families'])
          .map((e) => NamedEntity.fromJson(_map(e)))
          .toList(),
      createdUser: entity(json['created_user']),
      approvedUser: entity(json['approved_user']),
      overallStock: OverallStock.fromJson(_map(json['overall_stock'])),
      selectedUsability: _string(json['selected_usability']),
      selectedRackSummary:
          SelectedRackSummary.fromJson(_map(json['selected_rack_summary'])),
      rackDetails: _list(json['rack_details'])
          .map((e) => RackDetail.fromJson(_map(e)))
          .toList(),
    );
  }
}

class NamedEntity {
  const NamedEntity({required this.id, required this.name});
  final int id;
  final String name;

  factory NamedEntity.fromJson(Map<String, dynamic> json) {
    return NamedEntity(id: _int(json['id']), name: _string(json['name']));
  }
}

class OverallStock {
  const OverallStock({
    this.usable = 0,
    this.locked = 0,
    this.damaged = 0,
    this.partiallyDamaged = 0,
    this.liquidationStock = 0,
  });

  final int usable;
  final int locked;
  final int damaged;
  final int partiallyDamaged;
  final int liquidationStock;

  factory OverallStock.fromJson(Map<String, dynamic> json) {
    return OverallStock(
      usable: _int(json['usable']),
      locked: _int(json['locked']),
      damaged: _int(json['damaged']),
      partiallyDamaged: _int(json['partially_damaged']),
      liquidationStock: _int(json['liquidation_stock']),
    );
  }
}

class SelectedRackSummary {
  const SelectedRackSummary({
    this.rackCount = 0,
    this.rackStock = 0,
    this.rackLock = 0,
    this.availableStock = 0,
  });

  final int rackCount;
  final int rackStock;
  final int rackLock;
  final int availableStock;

  factory SelectedRackSummary.fromJson(Map<String, dynamic> json) {
    return SelectedRackSummary(
      rackCount: _int(json['rack_count']),
      rackStock: _int(json['rack_stock']),
      rackLock: _int(json['rack_lock']),
      availableStock: _int(json['available_stock']),
    );
  }
}

class RackDetail {
  const RackDetail({
    required this.rackId,
    required this.rackName,
    required this.columnName,
    required this.usability,
    required this.rackStock,
    required this.rackLock,
    required this.availableStock,
  });

  final int rackId;
  final String rackName;
  final String columnName;
  final String usability;
  final int rackStock;
  final int rackLock;
  final int availableStock;

  factory RackDetail.fromJson(Map<String, dynamic> json) {
    return RackDetail(
      rackId: _int(json['rack_id']),
      rackName: _string(json['rack_name']),
      columnName: _string(json['column_name']),
      usability: _string(json['usability']),
      rackStock: _int(json['rack_stock']),
      rackLock: _int(json['rack_lock']),
      availableStock: _int(json['available_stock']),
    );
  }
}

class RackReportFilters {
  const RackReportFilters({
    this.search = '',
    this.productId = '',
    this.warehouseId = '',
    this.mainCategoryId = '',
    this.productCategoryId = '',
    this.familyId = '',
    this.createdUserId = '',
    this.approvedUserId = '',
    this.productType = '',
    this.purchaseType = '',
    this.approvalStatus = '',
    this.unit = '',
    this.color = '',
    this.size = '',
    this.tax = '',
    this.startDate = '',
    this.endDate = '',
    this.minStock = '',
    this.maxStock = '',
    this.minPurchaseRate = '',
    this.maxPurchaseRate = '',
    this.minSellingPrice = '',
    this.maxSellingPrice = '',
    this.minLandingCost = '',
    this.maxLandingCost = '',
    this.minRetailPrice = '',
    this.maxRetailPrice = '',
    this.minFinalPrice = '',
    this.maxFinalPrice = '',
    this.hasStock = '',
    this.rackId = '',
    this.rackName = '',
    this.columnName = '',
    this.ordering = '-id',
  });

  final String search;
  final String productId;
  final String warehouseId;
  final String mainCategoryId;
  final String productCategoryId;
  final String familyId;
  final String createdUserId;
  final String approvedUserId;
  final String productType;
  final String purchaseType;
  final String approvalStatus;
  final String unit;
  final String color;
  final String size;
  final String tax;
  final String startDate;
  final String endDate;
  final String minStock;
  final String maxStock;
  final String minPurchaseRate;
  final String maxPurchaseRate;
  final String minSellingPrice;
  final String maxSellingPrice;
  final String minLandingCost;
  final String maxLandingCost;
  final String minRetailPrice;
  final String maxRetailPrice;
  final String minFinalPrice;
  final String maxFinalPrice;
  final String hasStock;
  final String rackId;
  final String rackName;
  final String columnName;
  final String ordering;

  RackReportFilters copyWith({String? search}) {
    return RackReportFilters(
      search: search ?? this.search,
      productId: productId,
      warehouseId: warehouseId,
      mainCategoryId: mainCategoryId,
      productCategoryId: productCategoryId,
      familyId: familyId,
      createdUserId: createdUserId,
      approvedUserId: approvedUserId,
      productType: productType,
      purchaseType: purchaseType,
      approvalStatus: approvalStatus,
      unit: unit,
      color: color,
      size: size,
      tax: tax,
      startDate: startDate,
      endDate: endDate,
      minStock: minStock,
      maxStock: maxStock,
      minPurchaseRate: minPurchaseRate,
      maxPurchaseRate: maxPurchaseRate,
      minSellingPrice: minSellingPrice,
      maxSellingPrice: maxSellingPrice,
      minLandingCost: minLandingCost,
      maxLandingCost: maxLandingCost,
      minRetailPrice: minRetailPrice,
      maxRetailPrice: maxRetailPrice,
      minFinalPrice: minFinalPrice,
      maxFinalPrice: maxFinalPrice,
      hasStock: hasStock,
      rackId: rackId,
      rackName: rackName,
      columnName: columnName,
      ordering: ordering,
    );
  }

  Map<String, String> toQueryParameters() {
    final values = <String, String>{
      'search': search,
      'product_id': productId,
      'warehouse_id': warehouseId,
      'main_category_id': mainCategoryId,
      'product_category_id': productCategoryId,
      'family_id': familyId,
      'created_user_id': createdUserId,
      'approved_user_id': approvedUserId,
      'product_type': productType,
      'purchase_type': purchaseType,
      'approval_status': approvalStatus,
      'unit': unit,
      'color': color,
      'size': size,
      'tax': tax,
      'start_date': startDate,
      'end_date': endDate,
      'min_stock': minStock,
      'max_stock': maxStock,
      'min_purchase_rate': minPurchaseRate,
      'max_purchase_rate': maxPurchaseRate,
      'min_selling_price': minSellingPrice,
      'max_selling_price': maxSellingPrice,
      'min_landing_cost': minLandingCost,
      'max_landing_cost': maxLandingCost,
      'min_retail_price': minRetailPrice,
      'max_retail_price': maxRetailPrice,
      'min_final_price': minFinalPrice,
      'max_final_price': maxFinalPrice,
      'has_stock': hasStock,
      'rack_id': rackId,
      'rack_name': rackName,
      'column_name': columnName,
      'ordering': ordering,
    };
    values.removeWhere((_, value) => value.trim().isEmpty);
    return values;
  }

  int get activeCount {
    final query = toQueryParameters()..remove('ordering');
    return query.length;
  }
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

List<dynamic> _list(dynamic value) => value is List ? value : const [];

String _string(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString();
  return text == 'null' ? fallback : text;
}

int _int(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double? _doubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

bool _bool(dynamic value) {
  if (value is bool) return value;
  return value?.toString().toLowerCase() == 'true';
}
