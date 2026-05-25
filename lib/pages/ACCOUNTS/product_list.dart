import 'dart:async';
import 'dart:convert';

import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/add_product_variant.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Product_List extends StatefulWidget {
  const Product_List({super.key});

  @override
  State<Product_List> createState() => _Product_ListState();
}

class _Product_ListState extends State<Product_List>
    with SingleTickerProviderStateMixin {
  static const Color primaryBlue = Color(0xFF0F3D75);
  static const Color pageBg = Color(0xFFF4F7FB);
  static const Color darkText = Color(0xFF111827);

  AnimationController? _shimmerController;

  final drower d = drower();

  final ScrollController _scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  Timer? _searchDebounce;

  List<String> purchasetype = <String>[
    "All Type",
    "International",
    "Local",
  ];

  String selectpurchasetype = "All Type";

  List<Map<String, dynamic>> fam = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> products = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> filteredProducts = <Map<String, dynamic>>[];
  List<bool> _checkboxValues = <bool>[];

  List<Map<String, dynamic>> categories = <Map<String, dynamic>>[
    <String, dynamic>{
      "id": "",
      "name": "All Categories",
    },
  ];

  String selectedCategoryId = "";
  String selectedCategoryName = "All Categories";

  bool isLoading = false;
  bool isPageLoading = false;
  bool hasMoreData = true;

  int backendTotalProducts = 0;
  String? nextPageUrl;
  String? previousPageUrl;
  String emptyMessage = "No products found";
  Map<String, dynamic> productSummary = <String, dynamic>{};

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _shimmerController?.repeat();

    _scrollController.addListener(_handlePaginationScroll);

    getFamily();
    initdata();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _shimmerController?.dispose();
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Widget _buildDropdownTile(
    BuildContext context,
    String title,
    List<String> options,
  ) {
    return ExpansionTile(
      title: Text(title),
      children: options.map((String option) {
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

  Future<void> initdata() async {
    await fetchProductList(refresh: true);
  }

  void _handlePaginationScroll() {
    if (!_scrollController.hasClients) return;

    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double currentScroll = _scrollController.position.pixels;

    if (currentScroll >= maxScroll - 250) {
      if (!isLoading && !isPageLoading && hasMoreData && nextPageUrl != null) {
        fetchProductList(refresh: false);
      }
    }
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getwarwhouseFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? warehouseId = prefs.getInt('warehouse');
    return warehouseId?.toString();
  }

  Future<String?> getwarehouseFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? warehouseId = prefs.getInt('warehouse');
    return warehouseId?.toString();
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? 0.0;
    return 0.0;
  }

  String _formatPrice(dynamic value) {
    final double price = _toDouble(value);
    return price.toStringAsFixed(2);
  }

  String _formatStock(dynamic value) {
    if (value == null) return "0";

    final double stockValue = _toDouble(value);

    if (stockValue == stockValue.toInt()) {
      return stockValue.toInt().toString();
    }

    return stockValue.toStringAsFixed(2);
  }

String _formatAmount(dynamic value) {
  final double amount = _toDouble(value);
  return "₹${amount.toStringAsFixed(2)}";
}

  String _formatNumber(dynamic value) {
    final double number = _toDouble(value);

    if (number == number.toInt()) {
      return number.toInt().toString();
    }

    return number.toStringAsFixed(2);
  }

  bool _isOutOfStock(dynamic value) {
    return _toDouble(value) <= 0;
  }

  double _calculateVariantTotalStock(dynamic variantIDs) {
    if (variantIDs is! List) return 0.0;

    double totalStock = 0.0;

    for (final dynamic variant in variantIDs) {
      if (variant is Map<String, dynamic>) {
        totalStock += _toDouble(variant['stock']);
      } else if (variant is Map) {
        totalStock += _toDouble(variant['stock']);
      }
    }

    return totalStock;
  }

  double _getProductLoadedStock(Map<String, dynamic> productData) {
    final dynamic variantIDs = productData['variantIDs'];

    if (variantIDs is List && variantIDs.isNotEmpty) {
      return _calculateVariantTotalStock(variantIDs);
    }

    return _toDouble(productData['stock']);
  }

  String _buildImageUrl(dynamic imageValue) {
    if (imageValue == null) return "";

    final String image = imageValue.toString().trim();

    if (image.isEmpty) return "";

    if (image.startsWith("http://") || image.startsWith("https://")) {
      return image;
    }

    if (image.startsWith("/")) {
      return "$api$image";
    }

    return "$api/$image";
  }

  List<String> _getFamilyNames(dynamic familyData) {
    if (familyData is! List) return <String>[];

    List<String> familyNames = <String>[];

    for (final dynamic item in familyData) {
      final int? familyId = item is int
          ? item
          : item is String
              ? int.tryParse(item)
              : null;

      if (familyId == null) continue;

      final Map<String, dynamic> matchedFamily = fam.firstWhere(
        (Map<String, dynamic> famItem) {
          return famItem['id'] == familyId;
        },
        orElse: () => <String, dynamic>{
          'name': 'Unknown',
        },
      );

      familyNames.add(matchedFamily['name']?.toString() ?? "Unknown");
    }

    return familyNames;
  }

  void _applyLocalFilters() {
    final List<Map<String, dynamic>> result = products.where(
      (Map<String, dynamic> product) {
        final bool matchesPurchaseType = selectpurchasetype == "All Type" ||
            product['purchase_type']?.toString() == selectpurchasetype;

        return matchesPurchaseType;
      },
    ).toList();

    if (!mounted) return;

    setState(() {
      filteredProducts = result;
    });
  }

  void _filterProductsByPurchaseType(String purchaseType) {
    setState(() {
      selectpurchasetype = purchaseType;
    });

    _applyLocalFilters();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      fetchProductList(refresh: true);
    });

    setState(() {});
  }

  void filterByCategory(String categoryId) {
    final Map<String, dynamic> selectedCategory = categories.firstWhere(
      (Map<String, dynamic> category) {
        return category['id'].toString() == categoryId;
      },
      orElse: () => <String, dynamic>{
        "id": "",
        "name": "All Categories",
      },
    );

    setState(() {
      selectedCategoryId = selectedCategory['id']?.toString() ?? "";
      selectedCategoryName =
          selectedCategory['name']?.toString() ?? "All Categories";
    });

    fetchProductList(refresh: true);
  }

  void _updateCategoryListFromProducts(List<Map<String, dynamic>> productList) {
    final Map<String, String> categoryMap = <String, String>{};

    categoryMap[""] = "All Categories";

    for (final Map<String, dynamic> product in productList) {
      final dynamic categoryId =
          product['product_category_id'] ?? product['product_category'];
      final dynamic categoryName = product['product_category_name'];

      if (categoryId == null || categoryName == null) continue;

      final String id = categoryId.toString();
      final String name = categoryName.toString();

      if (id.isNotEmpty && name.isNotEmpty) {
        categoryMap[id] = name;
      }
    }

    final List<Map<String, dynamic>> updatedCategories =
        categoryMap.entries.map<Map<String, dynamic>>(
      (MapEntry<String, String> entry) {
        return <String, dynamic>{
          "id": entry.key,
          "name": entry.value,
        };
      },
    ).toList();

    if (updatedCategories.isEmpty) {
      updatedCategories.add(
        <String, dynamic>{
          "id": "",
          "name": "All Categories",
        },
      );
    }

    final bool selectedStillExists = updatedCategories.any(
      (Map<String, dynamic> category) {
        return category['id'].toString() == selectedCategoryId;
      },
    );

    categories = updatedCategories;

    if (!selectedStillExists) {
      selectedCategoryId = "";
      selectedCategoryName = "All Categories";
    }
  }

  Uri _buildProductListUri({
    required String warehouseId,
    required bool refresh,
  }) {
    if (!refresh && nextPageUrl != null && nextPageUrl!.isNotEmpty) {
      return Uri.parse(nextPageUrl!);
    }

    final Map<String, String> queryParameters = <String, String>{};

    final String searchText = searchController.text.trim();

    if (searchText.isNotEmpty) {
      queryParameters["search"] = searchText;
    }

    if (selectedCategoryId.isNotEmpty) {
      queryParameters["category_id"] = selectedCategoryId;
    }

    return Uri.parse("$api/api/warehouse/products/gets/$warehouseId/").replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
  }

  Future<void> getFamily() async {
    try {
      final String? token = await getTokenFromPrefs();

      final http.Response response = await http.get(
        Uri.parse('$api/api/familys/'),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic parsed = jsonDecode(response.body);
        final dynamic productsData = parsed['data'];
        final List<Map<String, dynamic>> familyList = <Map<String, dynamic>>[];

        if (productsData is List) {
          for (final dynamic productData in productsData) {
            if (productData is Map) {
              familyList.add(
                <String, dynamic>{
                  'id': productData['id'],
                  'name': productData['name'],
                },
              );
            }
          }
        }

        if (!mounted) return;

        setState(() {
          fam = familyList;
          _checkboxValues = List<bool>.filled(fam.length, false);
        });
      }
    } catch (error) {}
  }

  Future<void> fetchProductList({bool refresh = true}) async {
    final String? token = await getTokenFromPrefs();
    final String? warehouse = await getwarehouseFromPrefs();

    if (warehouse == null || warehouse.isEmpty) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        isPageLoading = false;
        emptyMessage = "Warehouse not found";
      });

      return;
    }

    if (refresh) {
      if (!mounted) return;

      setState(() {
        isLoading = true;
        isPageLoading = false;
        hasMoreData = true;
        nextPageUrl = null;
        previousPageUrl = null;
        backendTotalProducts = 0;
        productSummary = <String, dynamic>{};
        products = <Map<String, dynamic>>[];
        filteredProducts = <Map<String, dynamic>>[];
        emptyMessage = "No products found";
      });
    } else {
      if (isPageLoading || !hasMoreData || nextPageUrl == null) return;

      if (!mounted) return;

      setState(() {
        isPageLoading = true;
      });
    }

    try {
      final Uri uri = _buildProductListUri(
        warehouseId: warehouse,
        refresh: refresh,
      );

      final http.Response response = await http.get(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic parsed = jsonDecode(response.body);

        final int count = parsed['count'] is int
            ? parsed['count']
            : int.tryParse(parsed['count']?.toString() ?? "0") ?? 0;

        final String? parsedNext = parsed['next']?.toString();
        final String? parsedPrevious = parsed['previous']?.toString();

        final dynamic results = parsed['results'];

        String responseMessage = "No products found";
        List<dynamic> productsData = <dynamic>[];
        Map<String, dynamic> parsedSummary = <String, dynamic>{};

        if (results is Map) {
          responseMessage =
              results['message']?.toString() ?? "No products found";

          final dynamic summaryData = results['summary'];
          if (summaryData is Map) {
            parsedSummary = Map<String, dynamic>.from(summaryData);
          }

          final dynamic data = results['data'];

          if (data is List) {
            productsData = data;
          }
        }

        final List<Map<String, dynamic>> productList = <Map<String, dynamic>>[];

        for (final dynamic item in productsData) {
          if (item is! Map) continue;

          final Map<String, dynamic> productData =
              Map<String, dynamic>.from(item);

          final double totalStock = _getProductLoadedStock(productData);

          productList.add(
            <String, dynamic>{
              'id': productData['id'],
              'name': productData['name'],
              'hsn_code': productData['hsn_code'],
              'type': productData['type'],
              'unit': productData['unit'],
              'purchase_type': productData['purchase_type'],
              'purchase_rate': productData['purchase_rate'],
              'tax': productData['tax'],
              'exclude_price': productData['exclude_price'],
              'selling_price': productData['selling_price'],
              'retail_price': productData['retail_price'],
              'stock': productData['stock'],
              'locked_stock': productData['locked_stock'],
              'total_variant_stock': totalStock,
              'created_user': productData['created_user'],
              'family': _getFamilyNames(productData['family']),
              'image': _buildImageUrl(productData['image']),
              'product_category_id': productData['product_category_id'] ??
                  productData['product_category'],
              'product_category_name': productData['product_category_name'],
              'product_category': productData['product_category'],
              'variantIDs': productData['variantIDs'],
              'images': productData['images'],
              'approval_status': productData['approval_status'],
              'groupID': productData['groupID'],
              'variantID': productData['variantID'],
              'rack_details': productData['rack_details'],
              'damaged_stock': productData['damaged_stock'],
              'partially_damaged_stock': productData['partially_damaged_stock'],
              'warehouse': productData['warehouse'],
            },
          );
        }

        if (!mounted) return;

        setState(() {
          backendTotalProducts = count;
          productSummary = parsedSummary;
          nextPageUrl =
              parsedNext != null && parsedNext.isNotEmpty ? parsedNext : null;
          previousPageUrl = parsedPrevious != null && parsedPrevious.isNotEmpty
              ? parsedPrevious
              : null;
          hasMoreData = nextPageUrl != null;

          if (refresh) {
            products = productList;
          } else {
            products.addAll(productList);
          }

          _updateCategoryListFromProducts(products);

          isLoading = false;
          isPageLoading = false;
          emptyMessage = responseMessage;
        });

        _applyLocalFilters();
      } else {
        String message = "Failed to fetch products";

        try {
          final dynamic parsed = jsonDecode(response.body);

          if (parsed is Map) {
            if (parsed['message'] != null) {
              message = parsed['message'].toString();
            } else if (parsed['results'] is Map &&
                parsed['results']['message'] != null) {
              message = parsed['results']['message'].toString();
            }
          }
        } catch (error) {}

        if (!mounted) return;

        setState(() {
          isLoading = false;
          isPageLoading = false;
          hasMoreData = false;
          emptyMessage = message;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        isPageLoading = false;
        hasMoreData = false;
        emptyMessage = "Something went wrong while fetching products";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Something went wrong: $error"),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('token');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ScaffoldMessenger.of(context).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });

    await Future.delayed(const Duration(seconds: 2));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (BuildContext context) => login()),
    );
  }

  Future<void> refreshEntirePageToInitialState() async {
    _searchDebounce?.cancel();

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    if (!mounted) return;

    setState(() {
      searchController.clear();

      selectpurchasetype = "All Type";

      selectedCategoryId = "";
      selectedCategoryName = "All Categories";

      categories = <Map<String, dynamic>>[
        <String, dynamic>{
          "id": "",
          "name": "All Categories",
        },
      ];

      products = <Map<String, dynamic>>[];
      filteredProducts = <Map<String, dynamic>>[];

      backendTotalProducts = 0;
      productSummary = <String, dynamic>{};
      nextPageUrl = null;
      previousPageUrl = null;
      hasMoreData = true;

      emptyMessage = "No products found";
      isLoading = true;
      isPageLoading = false;
    });

    await getFamily();
    await fetchProductList(refresh: true);
  }

  Future<void> _navigateBack() async {
    final String? dep = await getdepFromPrefs();

    if (dep == "BDO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (BuildContext context) => bdo_dashbord()),
      );
    } else if (dep == "BDM") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (BuildContext context) => bdm_dashbord()),
      );
    } else if (dep == "warehouse") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => WarehouseDashboard(),
        ),
      );
    } else if (dep == "CEO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (BuildContext context) => ceo_dashboard()),
      );
    } else if (dep == "COO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (BuildContext context) => ceo_dashboard()),
      );
    } else if (dep == "Warehouse Admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (BuildContext context) => WarehouseAdmin()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (BuildContext context) => dashboard()),
      );
    }
  }

  int get totalProducts => backendTotalProducts;

  int get loadedProducts => products.length;

  int get visibleProducts => filteredProducts.length;

  double get totalStockIncludingVariants {
    double total = 0.0;

    for (final Map<String, dynamic> product in products) {
      total += _toDouble(
        product['total_variant_stock'] ?? product['stock'],
      );
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white, 
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: primaryBlue,
              size: 20,
            ),
            onPressed: _navigateBack,
          ),
          title: const Text(
            "Product List",
            style: TextStyle(
              color: darkText,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: <Widget>[
            IconButton(
              tooltip: "Refresh",
              onPressed: () {
                refreshEntirePageToInitialState();
              },
              icon: const Icon(
                Icons.refresh_rounded,
                color: primaryBlue,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: <Widget>[
            // _buildSummaryCard(),
            _buildSearchAndFilters(),
            Expanded(
              child: RefreshIndicator(
                color: primaryBlue,
                onRefresh: refreshEntirePageToInitialState,
                child: isLoading
                    ? _buildLoadingList()
                    : filteredProducts.isEmpty
                        ? _buildEmptyList()
                        : ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                            itemCount: filteredProducts.length +
                                (isPageLoading ? 1 : 0),
                            itemBuilder: (
                              BuildContext context,
                              int index,
                            ) {
                              if (index >= filteredProducts.length) {
                                return _buildPaginationLoader();
                              }

                              final Map<String, dynamic> product =
                                  filteredProducts[index];

                              return _buildProductCard(product);
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildSummaryCard() {
  if (productSummary.isEmpty) {
    return const SizedBox.shrink();
  }

  final Map<String, dynamic> damagedSummary =
      productSummary['damaged_stock_summary'] is Map
          ? Map<String, dynamic>.from(productSummary['damaged_stock_summary'])
          : <String, dynamic>{};

  final Map<String, dynamic> partiallyDamagedSummary =
      productSummary['partially_damaged_stock_summary'] is Map
          ? Map<String, dynamic>.from(
              productSummary['partially_damaged_stock_summary'],
            )
          : <String, dynamic>{};

  return Container(
    margin: const EdgeInsets.fromLTRB(12, 8, 12, 3),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE5E7EB)),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: Colors.black.withOpacity(0.035),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.summarize_rounded,
                color: primaryBlue,
                size: 17,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "Warehouse Summary",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: darkText,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    "Full stock and amount summary",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 9),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _buildSummaryTile(
                title: "Total Stock",
                value: _formatNumber(productSummary['total_stock']),
                icon: Icons.warehouse_rounded,
                bgColor: const Color(0xFFECFDF5),
                iconColor: const Color(0xFF059669),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _buildSummaryTile(
                title: "Selling Amount",
                value: _formatAmount(productSummary['total_selling_amount']),
                icon: Icons.sell_rounded,
                bgColor: const Color(0xFFFDF2F8),
                iconColor: const Color(0xFFDB2777),
              ),
            ),
          ],
        ),

        const SizedBox(height: 7),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _buildSummaryTile(
                title: "Landing Cost",
                value: _formatAmount(
                  productSummary['total_landing_cost_amount'],
                ),
                icon: Icons.local_shipping_rounded,
                bgColor: const Color(0xFFF8FAFC),
                iconColor: const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _buildSummaryTile(
                title: "Retail Amount",
                value: _formatAmount(productSummary['total_retail_amount']),
                icon: Icons.currency_rupee_rounded,
                bgColor: const Color(0xFFF0FDFA),
                iconColor: const Color(0xFF0D9488),
              ),
            ),
          ],
        ),

        const SizedBox(height: 7),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _buildSummaryTile(
                title: "Damaged Stock",
                value: _formatNumber(
                  damagedSummary['total_damaged_stock'],
                ),
                icon: Icons.warning_rounded,
                bgColor: const Color(0xFFFEF2F2),
                iconColor: const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _buildSummaryTile(
                title: "Partial Damage",
                value: _formatNumber(
                  partiallyDamagedSummary[
                      'total_partially_damaged_stock'],
                ),
                icon: Icons.report_problem_rounded,
                bgColor: const Color(0xFFFFFBEB),
                iconColor: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

 Widget _buildSummaryTile({
  required String title,
  required String value,
  required IconData icon,
  required Color bgColor,
  required Color iconColor,
}) {
  return Container(
    constraints: const BoxConstraints(
      minHeight: 68,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(13),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              icon,
              size: 14,
              color: iconColor,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 9.2,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),

        SizedBox(
          width: double.infinity,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Text(
              value,
              softWrap: false,
              style: const TextStyle(
                color: darkText,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
  Widget _buildMiniSummaryRow({
    required String title,
    required String value,
    required String amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "$value Qty",
            style: const TextStyle(
              color: darkText,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          TextField(
            controller: searchController,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            onSubmitted: (String value) {
              _searchDebounce?.cancel();
              fetchProductList(refresh: true);
            },
            decoration: InputDecoration(
              hintText: "Search product name",
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: primaryBlue,
                size: 22,
              ),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () {
                        searchController.clear();
                        _searchDebounce?.cancel();
                        fetchProductList(refresh: true);
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: primaryBlue,
                  width: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildFilterDropdown(
                  label: "Purchase Type",
                  value: selectpurchasetype,
                  items: purchasetype,
                  icon: Icons.shopping_bag_outlined,
                  onChanged: (String? value) {
                    if (value != null) {
                      _filterProductsByPurchaseType(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCategoryDropdown(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Icon(
                Icons.inventory_2_outlined,
                color: Colors.grey.shade500,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Showing $visibleProducts loaded products from $totalProducts total products",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: primaryBlue, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: primaryBlue,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(14),
                style: const TextStyle(
                  color: darkText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                selectedItemBuilder: (BuildContext context) {
                  return items.map((String item) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: darkText,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    );
                  }).toList();
                },
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final bool selectedExists = categories.any(
      (Map<String, dynamic> category) {
        return category['id'].toString() == selectedCategoryId;
      },
    );

    final String dropdownValue = selectedExists ? selectedCategoryId : "";

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.category_outlined,
            color: primaryBlue,
            size: 18,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: dropdownValue,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: primaryBlue,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(14),
                style: const TextStyle(
                  color: darkText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                selectedItemBuilder: (BuildContext context) {
                  return categories.map((Map<String, dynamic> category) {
                    final String name =
                        category['name']?.toString() ?? "All Categories";

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "Category",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: darkText,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    );
                  }).toList();
                },
                items: categories.map((Map<String, dynamic> category) {
                  final String id = category['id']?.toString() ?? "";
                  final String name =
                      category['name']?.toString() ?? "All Categories";

                  return DropdownMenuItem<String>(
                    value: id,
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    filterByCategory(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final String productName = product['name']?.toString() ?? "Unnamed Product";

    final String retailPrice = _formatPrice(
      product['retail_price'] ?? product['selling_price'],
    );

    final String stock = _formatStock(
      product['total_variant_stock'] ?? product['stock'],
    );

    final bool isOutOfStock = _isOutOfStock(
      product['total_variant_stock'] ?? product['stock'],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => add_product_variant(
                  id: product['id'],
                  type: product['type'],
                ),
              ),
            );

            fetchProductList(refresh: true);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                _buildProductImage(product['image']),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: darkText,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          _buildPriceChip(
                            value: "₹$retailPrice",
                          ),
                          _buildStockChip(
                            stock: stock,
                            isOutOfStock: isOutOfStock,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: primaryBlue,
                    size: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(dynamic imageUrl) {
    final String image = imageUrl?.toString() ?? "";

    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: image.isNotEmpty
          ? Image.network(
              image,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (
                BuildContext context,
                Object error,
                StackTrace? stackTrace,
              ) {
                return _buildImagePlaceholder();
              },
            )
          : _buildImagePlaceholder(),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey.shade500,
        size: 28,
      ),
    );
  }

  Widget _buildPriceChip({
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFD1FAE5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.currency_rupee_rounded,
            color: Color(0xFF047857),
            size: 13,
          ),
          Flexible(
            child: Text(
              value.replaceFirst("₹", ""),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF047857),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockChip({
    required String stock,
    required bool isOutOfStock,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: isOutOfStock ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color:
              isOutOfStock ? const Color(0xFFFECACA) : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            isOutOfStock
                ? Icons.warning_amber_rounded
                : Icons.inventory_2_outlined,
            color: isOutOfStock
                ? const Color(0xFFDC2626)
                : const Color(0xFF2563EB),
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            isOutOfStock ? "Out of Stock" : "Total Stock: $stock",
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            style: TextStyle(
              color: isOutOfStock
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF2563EB),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
      itemCount: 8,
      itemBuilder: (BuildContext context, int index) {
        return _buildShimmerProductCard();
      },
    );
  }

  Widget _buildPaginationLoader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: _buildShimmerProductCard(),
    );
  }

  Widget _buildShimmerProductCard() {
    return Container(
      height: 112,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          _buildShimmerBox(
            width: 72,
            height: 72,
            radius: 15,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildShimmerBox(
                  width: double.infinity,
                  height: 15,
                  radius: 8,
                ),
                const SizedBox(height: 8),
                _buildShimmerBox(
                  width: 160,
                  height: 13,
                  radius: 8,
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    _buildShimmerBox(
                      width: 78,
                      height: 26,
                      radius: 30,
                    ),
                    const SizedBox(width: 8),
                    _buildShimmerBox(
                      width: 92,
                      height: 26,
                      radius: 30,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildShimmerBox(
            width: 34,
            height: 34,
            radius: 12,
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    required double radius,
  }) {
    final AnimationController? controller = _shimmerController;

    if (controller == null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + (controller.value * 2), -0.2),
              end: Alignment(1.0 + (controller.value * 2), 0.2),
              colors: const <Color>[
                Color(0xFFE5E7EB),
                Color(0xFFF8FAFC),
                Color(0xFFE5E7EB),
              ],
              stops: const <double>[0.25, 0.5, 0.75],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyList() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(22, 80, 22, 24),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: <Widget>[
              Container(
                height: 68,
                width: 68,
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  color: primaryBlue,
                  size: 34,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: darkText,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Try changing the search text, purchase type, or category filter.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
