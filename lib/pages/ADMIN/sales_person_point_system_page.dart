import 'dart:async';
import 'dart:convert';

import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProductPointSystemPage extends StatefulWidget {
  const ProductPointSystemPage({super.key});

  @override
  State<ProductPointSystemPage> createState() =>
      _ProductPointSystemPageState();
}

class _ProductPointSystemPageState extends State<ProductPointSystemPage> {
  // ============================================================
  // API
  // ============================================================

  static const String _listCreateEndpoint =
      '/api/product/point/system/';

  static String _editEndpoint(int id) =>
      '/api/product/point/system/edit/$id/';

  // ============================================================
  // POINT TYPE OPTIONS
  // ============================================================

  final List<Map<String, String>> pointTypeOptions = const [
    {
      'value': 'product',
      'label': 'Product',
    },
    {
      'value': 'md',
      'label': 'MD',
    },
    {
      'value': 'sd',
      'label': 'SD',
    },
    {
      'value': 'new_conversions',
      'label': 'New Conversions',
    },
    {
      'value': 'new_customers',
      'label': 'New Customers',
    },
    {
      'value': 'new_lead',
      'label': 'New Lead',
    },
  ];

  // ============================================================
  // STATE
  // ============================================================

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _quantityController =
      TextEditingController();

  // ============================================================
  // PRODUCT PICKER STATE
  // ============================================================

  final TextEditingController _productSearchController =
      TextEditingController();

  final ScrollController _productScrollController =
      ScrollController();

  Timer? _productSearchDebounce;

  List<Map<String, dynamic>> productOptions =
      <Map<String, dynamic>>[];

  bool isLoadingProducts = false;
  bool isLoadingMoreProducts = false;
  bool productHasMore = true;

  String? productNextPageUrl;

  int? selectedProductId;
  String selectedProductName = '';
  String selectedProductImage = '';
  String productEmptyMessage = 'No products found';

  final TextEditingController _pointController =
      TextEditingController();

  final TextEditingController _searchController =
      TextEditingController();

  String selectedPointType = 'product';

  List<Map<String, dynamic>> pointSystems = [];
  List<Map<String, dynamic>> filteredPointSystems = [];

  bool isLoading = true;
  bool isSaving = false;
  bool isRefreshing = false;

  int? editingId;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(
      _filterRecords,
    );

    _productScrollController.addListener(
      _handleProductPagination,
    );

    fetchPointSystems();
  }

  @override
  void dispose() {
    _productSearchDebounce?.cancel();
    _productSearchController.dispose();
    _productScrollController.dispose();
    _quantityController.dispose();
    _pointController.dispose();
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // TOKEN
  // ============================================================

  Future<String?> _getToken() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getString('token');
  }

  Future<String?> _getWarehouseFromPrefs() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    final int? warehouseId = prefs.getInt('warehouse');

    return warehouseId?.toString();
  }

  // ============================================================
  // URL HELPER
  // ============================================================

  Uri _buildUri(String endpoint) {
    return Uri.parse(
      '$api$endpoint',
    );
  }

  // ============================================================
  // GENERIC RESPONSE PARSER
  // Handles:
  // [
  //   {...}
  // ]
  //
  // {
  //   "data": [...]
  // }
  //
  // {
  //   "results": [...]
  // }
  //
  // {
  //   "results": {
  //      "data": [...]
  //   }
  // }
  // ============================================================

  List<Map<String, dynamic>> _extractList(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();
    }

    if (decoded is Map) {
      final Map<String, dynamic> map =
          Map<String, dynamic>.from(decoded);

      final dynamic data = map['data'];

      if (data is List) {
        return data
            .whereType<Map>()
            .map(
              (item) => Map<String, dynamic>.from(item),
            )
            .toList();
      }

      final dynamic results = map['results'];

      if (results is List) {
        return results
            .whereType<Map>()
            .map(
              (item) => Map<String, dynamic>.from(item),
            )
            .toList();
      }

      if (results is Map) {
        final dynamic nestedData = results['data'];

        if (nestedData is List) {
          return nestedData
              .whereType<Map>()
              .map(
                (item) => Map<String, dynamic>.from(item),
              )
              .toList();
        }
      }
    }

    return [];
  }

  // ============================================================
  // GET ALL
  // GET /api/product/point/system/
  // ============================================================

  Future<void> fetchPointSystems({
    bool showLoader = true,
  }) async {
    if (showLoader && mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final String? token = await _getToken();

      if (token == null || token.trim().isEmpty) {
        _showMessage(
          'Authentication token not found.',
          isError: true,
        );

        return;
      }

      final http.Response response = await http.get(
        _buildUri(
          _listCreateEndpoint,
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      debugPrint(
        'POINT SYSTEM GET STATUS: ${response.statusCode}',
      );

      debugPrint(
        'POINT SYSTEM GET BODY: ${response.body}',
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(
          response.body,
        );

        final List<Map<String, dynamic>> records =
            _extractList(decoded);

        if (!mounted) return;

        setState(() {
          pointSystems = records;
          filteredPointSystems = List.from(records);
        });

        _filterRecords();
      } else {
        _showApiError(
          response,
          fallback: 'Failed to load point system.',
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        'POINT SYSTEM GET ERROR: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      _showMessage(
        'Unable to load point system.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isRefreshing = false;
        });
      }
    }
  }

  // ============================================================
  // GET SINGLE
  // GET /api/product/point/system/edit/<id>/
  // ============================================================

  Future<Map<String, dynamic>?> fetchSinglePointSystem(
    int id,
  ) async {
    try {
      final String? token = await _getToken();

      if (token == null || token.trim().isEmpty) {
        return null;
      }

      final http.Response response = await http.get(
        _buildUri(
          _editEndpoint(id),
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      debugPrint(
        'POINT SYSTEM SINGLE GET STATUS: '
        '${response.statusCode}',
      );

      debugPrint(
        'POINT SYSTEM SINGLE GET BODY: '
        '${response.body}',
      );

      if (response.statusCode != 200) {
        return null;
      }

      final dynamic decoded = jsonDecode(
        response.body,
      );

      if (decoded is Map) {
        final Map<String, dynamic> map =
            Map<String, dynamic>.from(decoded);

        if (map['data'] is Map) {
          return Map<String, dynamic>.from(
            map['data'],
          );
        }

        if (map['results'] is Map) {
          final Map<String, dynamic> results =
              Map<String, dynamic>.from(
            map['results'],
          );

          if (results['data'] is Map) {
            return Map<String, dynamic>.from(
              results['data'],
            );
          }

          return results;
        }

        return map;
      }
    } catch (error) {
      debugPrint(
        'POINT SYSTEM SINGLE GET ERROR: $error',
      );
    }

    return null;
  }

  // ============================================================
  // POST
  // POST /api/product/point/system/
  // ============================================================

  Future<void> createPointSystem() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final String? token = await _getToken();

      if (token == null || token.trim().isEmpty) {
        _showMessage(
          'Authentication token not found.',
          isError: true,
        );

        return;
      }

      final Map<String, dynamic> payload =
          _buildPayload();

      debugPrint(
        'POINT SYSTEM POST PAYLOAD: '
        '${jsonEncode(payload)}',
      );

      final http.Response response = await http.post(
        _buildUri(
          _listCreateEndpoint,
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(
          payload,
        ),
      );

      debugPrint(
        'POINT SYSTEM POST STATUS: '
        '${response.statusCode}',
      );

      debugPrint(
        'POINT SYSTEM POST BODY: '
        '${response.body}',
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        _showMessage(
          'Point configuration created successfully.',
        );

        _resetForm();

        await fetchPointSystems(
          showLoader: false,
        );
      } else {
        _showApiError(
          response,
          fallback:
              'Failed to create point configuration.',
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        'POINT SYSTEM POST ERROR: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      _showMessage(
        'Unable to create point configuration.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // PUT
  // PUT /api/product/point/system/edit/<id>/
  // ============================================================

  Future<void> updatePointSystem() async {
    if (editingId == null) {
      return;
    }

    if (!_validateForm()) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final String? token = await _getToken();

      if (token == null || token.trim().isEmpty) {
        _showMessage(
          'Authentication token not found.',
          isError: true,
        );

        return;
      }

      final Map<String, dynamic> payload =
          _buildPayload();

      debugPrint(
        'POINT SYSTEM PUT PAYLOAD: '
        '${jsonEncode(payload)}',
      );

      final http.Response response = await http.put(
        _buildUri(
          _editEndpoint(editingId!),
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(
          payload,
        ),
      );

      debugPrint(
        'POINT SYSTEM PUT STATUS: '
        '${response.statusCode}',
      );

      debugPrint(
        'POINT SYSTEM PUT BODY: '
        '${response.body}',
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        _showMessage(
          'Point configuration updated successfully.',
        );

        _resetForm();

        await fetchPointSystems(
          showLoader: false,
        );
      } else {
        _showApiError(
          response,
          fallback:
              'Failed to update point configuration.',
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        'POINT SYSTEM PUT ERROR: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      _showMessage(
        'Unable to update point configuration.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // FORM PAYLOAD
  // ============================================================

  Map<String, dynamic> _buildPayload() {
    final Map<String, dynamic> payload = {
      'point_type': selectedPointType,
      'point': double.parse(
        _pointController.text.trim(),
      ),
    };

    if (selectedPointType == 'product') {
      payload['product'] = selectedProductId;

      if (_quantityController.text.trim().isNotEmpty) {
        payload['quantity'] = int.parse(
          _quantityController.text.trim(),
        );
      } else {
        payload['quantity'] = null;
      }
    } else {
      payload['product'] = null;
      payload['quantity'] = null;
    }

    return payload;
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  bool _validateForm() {
    final bool isValid =
        _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return false;
    }

    if (selectedPointType == 'product') {
      if (selectedProductId == null) {
        _showMessage(
          'Please select a product.',
          isError: true,
        );

        return false;
      }

      if (_quantityController.text.trim().isNotEmpty) {
        final int? quantity = int.tryParse(
          _quantityController.text.trim(),
        );

        if (quantity == null || quantity <= 0) {
          _showMessage(
            'Quantity must be greater than 0.',
            isError: true,
          );

          return false;
        }
      }
    }

    final double? point = double.tryParse(
      _pointController.text.trim(),
    );

    if (point == null || point < 0) {
      _showMessage(
        'Enter a valid point value.',
        isError: true,
      );

      return false;
    }

    return true;
  }

  // ============================================================
  // EDIT
  // ============================================================

  Future<void> startEditing(
    Map<String, dynamic> existingRecord,
  ) async {
    final int? id = int.tryParse(
      existingRecord['id']?.toString() ?? '',
    );

    if (id == null) {
      _showMessage(
        'Invalid record ID.',
        isError: true,
      );

      return;
    }

    _showLoadingDialog();

    final Map<String, dynamic>? apiRecord =
        await fetchSinglePointSystem(id);

    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    final Map<String, dynamic> record =
        apiRecord ?? existingRecord;

    final String pointType =
        record['point_type']?.toString() ?? 'product';

    final dynamic product = record['product'];

    int? productId;
    String productName = '';
    String productImage = '';

    if (product is Map) {
      productId = int.tryParse(
        product['id']?.toString() ?? '',
      );

      productName =
          product['name']?.toString() ??
              product['product_name']?.toString() ??
              '';

      productImage = _buildImageUrl(
        product['image'],
      );
    } else if (product != null) {
      productId = int.tryParse(
        product.toString(),
      );
    }

    productId ??= int.tryParse(
      record['product_id']?.toString() ?? '',
    );

    if (productName.isEmpty) {
      productName =
          record['product_name']?.toString() ?? '';
    }

    if (productImage.isEmpty) {
      productImage = _buildImageUrl(
        record['product_image'],
      );
    }

    if (!mounted) return;

    setState(() {
      editingId = id;

      selectedPointType =
          pointTypeOptions.any(
        (option) =>
            option['value'] == pointType,
      )
              ? pointType
              : 'product';

      selectedProductId = productId;
      selectedProductName = productName;
      selectedProductImage = productImage;

      _quantityController.text =
          record['quantity']?.toString() ?? '';

      _pointController.text =
          record['point']?.toString() ?? '';
    });

    _scrollToForm();

    _showMessage(
      'Editing record #$id',
    );
  }

  // ============================================================
  // RESET
  // ============================================================

  void _resetForm() {
    FocusScope.of(context).unfocus();

    setState(() {
      editingId = null;
      selectedPointType = 'product';

      selectedProductId = null;
      selectedProductName = '';
      selectedProductImage = '';

      _quantityController.clear();
      _pointController.clear();
    });

    _formKey.currentState?.reset();
  }

  void _scrollToForm() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!mounted) return;

        Scrollable.ensureVisible(
          _formKey.currentContext!,
          duration: const Duration(
            milliseconds: 350,
          ),
          curve: Curves.easeOutCubic,
        );
      },
    );
  }


  // ============================================================
  // PRODUCT API
  // GET /api/warehouse/products/gets/<warehouseId>/
  // ============================================================

  Future<void> fetchProductList({
    bool refresh = true,
  }) async {
    final String? token = await _getToken();
    final String? warehouse = await _getWarehouseFromPrefs();

    if (warehouse == null || warehouse.isEmpty) {
      if (!mounted) return;

      setState(() {
        isLoadingProducts = false;
        isLoadingMoreProducts = false;
        productHasMore = false;
        productEmptyMessage = 'Warehouse not found';
      });

      return;
    }

    if (refresh) {
      if (!mounted) return;

      setState(() {
        isLoadingProducts = true;
        isLoadingMoreProducts = false;
        productHasMore = true;
        productNextPageUrl = null;
        productOptions = <Map<String, dynamic>>[];
        productEmptyMessage = 'No products found';
      });
    } else {
      if (isLoadingMoreProducts ||
          !productHasMore ||
          productNextPageUrl == null) {
        return;
      }

      if (!mounted) return;

      setState(() {
        isLoadingMoreProducts = true;
      });
    }

    try {
      final Uri uri = _buildProductListUri(
        warehouseId: warehouse,
        refresh: refresh,
      );

      debugPrint('POINT PRODUCT LIST URL: $uri');

      final http.Response response = await http.get(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic parsed = jsonDecode(response.body);

        final String? parsedNext =
            parsed['next']?.toString();

        final dynamic results = parsed['results'];

        String responseMessage = 'No products found';
        List<dynamic> productsData = <dynamic>[];

        if (results is Map) {
          responseMessage =
              results['message']?.toString() ??
                  'No products found';

          final dynamic data = results['data'];

          if (data is List) {
            productsData = data;
          }
        }

        final List<Map<String, dynamic>> productList =
            <Map<String, dynamic>>[];

        for (final dynamic item in productsData) {
          if (item is! Map) continue;

          final Map<String, dynamic> productData =
              Map<String, dynamic>.from(item);

          final double totalStock =
              _getProductLoadedStock(productData);

          productList.add(
            <String, dynamic>{
              'id': productData['id'],
              'name': productData['name'],
              'image': _buildImageUrl(
                productData['image'],
              ),
              'stock': productData['stock'],
              'total_variant_stock': totalStock,
              'type': productData['type'],
              'retail_price': productData['retail_price'],
              'selling_price': productData['selling_price'],
              'warehouse': productData['warehouse'],
            },
          );
        }

        if (!mounted) return;

        setState(() {
          productNextPageUrl =
              parsedNext != null && parsedNext.isNotEmpty
                  ? parsedNext
                  : null;

          productHasMore = productNextPageUrl != null;

          if (refresh) {
            productOptions = productList;
          } else {
            productOptions.addAll(productList);
          }

          productEmptyMessage = responseMessage;
          isLoadingProducts = false;
          isLoadingMoreProducts = false;
        });
      } else {
        String message = 'Failed to fetch products';

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
        } catch (_) {}

        if (!mounted) return;

        setState(() {
          isLoadingProducts = false;
          isLoadingMoreProducts = false;
          productHasMore = false;
          productEmptyMessage = message;
        });
      }
    } catch (error, stackTrace) {
      debugPrint(
        'POINT PRODUCT LIST ERROR: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      setState(() {
        isLoadingProducts = false;
        isLoadingMoreProducts = false;
        productHasMore = false;
        productEmptyMessage =
            'Something went wrong while fetching products';
      });
    }
  }

  Uri _buildProductListUri({
    required String warehouseId,
    required bool refresh,
  }) {
    if (!refresh &&
        productNextPageUrl != null &&
        productNextPageUrl!.isNotEmpty) {
      return Uri.parse(productNextPageUrl!);
    }

    final Map<String, String> queryParameters =
        <String, String>{};

    final String searchText =
        _productSearchController.text.trim();

    if (searchText.isNotEmpty) {
      queryParameters['search'] = searchText;
    }

    return Uri.parse(
      '$api/api/warehouse/products/gets/$warehouseId/',
    ).replace(
      queryParameters:
          queryParameters.isEmpty ? null : queryParameters,
    );
  }

  void _handleProductPagination() {
    if (!_productScrollController.hasClients) return;

    final double maxScroll =
        _productScrollController.position.maxScrollExtent;

    final double currentScroll =
        _productScrollController.position.pixels;

    if (currentScroll >= maxScroll - 180) {
      if (!isLoadingProducts &&
          !isLoadingMoreProducts &&
          productHasMore &&
          productNextPageUrl != null) {
        fetchProductList(
          refresh: false,
        );
      }
    }
  }

  void _onProductSearchChanged(String value) {
    _productSearchDebounce?.cancel();

    _productSearchDebounce =
        Timer(
      const Duration(milliseconds: 450),
      () {
        fetchProductList(
          refresh: true,
        );
      },
    );
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString().trim(),
        ) ??
        0;
  }

  double _calculateVariantTotalStock(
    dynamic variantIDs,
  ) {
    if (variantIDs is! List) return 0;

    double total = 0;

    for (final dynamic variant in variantIDs) {
      if (variant is Map) {
        total += _toDouble(
          variant['stock'],
        );
      }
    }

    return total;
  }

  double _getProductLoadedStock(
    Map<String, dynamic> productData,
  ) {
    final dynamic variantIDs =
        productData['variantIDs'];

    if (variantIDs is List &&
        variantIDs.isNotEmpty) {
      return _calculateVariantTotalStock(
        variantIDs,
      );
    }

    return _toDouble(
      productData['stock'],
    );
  }

  String _formatStock(dynamic value) {
    final double stock = _toDouble(value);

    if (stock == stock.toInt()) {
      return stock.toInt().toString();
    }

    return stock.toStringAsFixed(2);
  }

  String _buildImageUrl(dynamic imageValue) {
    if (imageValue == null) return '';

    final String image =
        imageValue.toString().trim();

    if (image.isEmpty) return '';

    if (image.startsWith('http://') ||
        image.startsWith('https://')) {
      return image;
    }

    if (image.startsWith('/')) {
      return '$api$image';
    }

    return '$api/$image';
  }

  Future<void> _openProductPicker() async {
    FocusScope.of(context).unfocus();

    _productSearchController.clear();

    await fetchProductList(
      refresh: true,
    );

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (
        BuildContext modalContext,
      ) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter modalSetState,
          ) {
            return Container(
              height:
                  MediaQuery.of(context).size.height * 0.82,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(26),
                  topRight: Radius.circular(26),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    margin: const EdgeInsets.only(
                      top: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0D5DD),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      14,
                      16,
                      10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFEAF4FF),
                            borderRadius:
                                BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color:
                                Color(0xFF287BE4),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Product',
                                style: TextStyle(
                                  color:
                                      Color(0xFF101828),
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Search products from your warehouse',
                                style: TextStyle(
                                  color:
                                      Color(0xFF667085),
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(
                              modalContext,
                            );
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      12,
                    ),
                    child: TextField(
                      controller:
                          _productSearchController,
                      onChanged: (
                        String value,
                      ) {
                        _onProductSearchChanged(
                          value,
                        );

                        modalSetState(() {});
                      },
                      decoration: InputDecoration(
                        hintText:
                            'Search product name',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color:
                              Color(0xFF0F3D75),
                        ),
                        suffixIcon:
                            _productSearchController
                                    .text
                                    .isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      _productSearchController
                                          .clear();

                                      fetchProductList(
                                        refresh: true,
                                      );

                                      modalSetState(
                                        () {},
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.close_rounded,
                                    ),
                                  )
                                : null,
                        filled: true,
                        fillColor:
                            const Color(0xFFF8FAFC),
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            15,
                          ),
                          borderSide:
                              const BorderSide(
                            color:
                                Color(0xFFE4E7EC),
                          ),
                        ),
                        enabledBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            15,
                          ),
                          borderSide:
                              const BorderSide(
                            color:
                                Color(0xFFE4E7EC),
                          ),
                        ),
                        focusedBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            15,
                          ),
                          borderSide:
                              const BorderSide(
                            color:
                                Color(0xFF287BE4),
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _buildProductPickerList(
                      modalContext:
                          modalContext,
                      modalSetState:
                          modalSetState,
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

  Widget _buildProductPickerList({
    required BuildContext modalContext,
    required StateSetter modalSetState,
  }) {
    if (isLoadingProducts &&
        productOptions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (productOptions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Text(
            productEmptyMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _productScrollController,
      padding: const EdgeInsets.fromLTRB(
        14,
        10,
        14,
        30,
      ),
      itemCount:
          productOptions.length +
              (isLoadingMoreProducts ? 1 : 0),
      itemBuilder: (
        BuildContext context,
        int index,
      ) {
        if (index >= productOptions.length) {
          return const Padding(
            padding: EdgeInsets.all(18),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final Map<String, dynamic> product =
            productOptions[index];

        final int? productId = int.tryParse(
          product['id']?.toString() ?? '',
        );

        final String productName =
            product['name']?.toString() ??
                'Unnamed Product';

        final String productImage =
            product['image']?.toString() ?? '';

        final String stock = _formatStock(
          product['total_variant_stock'] ??
              product['stock'],
        );

        final bool selected =
            productId != null &&
                productId == selectedProductId;

        return Container(
          margin: const EdgeInsets.only(
            bottom: 9,
          ),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFEAF4FF)
                : Colors.white,
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFF287BE4)
                  : const Color(0xFFE4E7EC),
            ),
          ),
          child: ListTile(
            onTap: productId == null
                ? null
                : () {
                    setState(() {
                      selectedProductId =
                          productId;

                      selectedProductName =
                          productName;

                      selectedProductImage =
                          productImage;
                    });

                    modalSetState(() {});

                    Navigator.pop(
                      modalContext,
                    );
                  },
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            leading: _buildProductImage(
              productImage,
            ),
            title: Text(
              productName,
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF101828),
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(
                top: 5,
              ),
              child: Text(
                'Stock: $stock',
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 10.5,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
            trailing: selected
                ? const Icon(
                    Icons.check_circle_rounded,
                    color:
                        Color(0xFF287BE4),
                  )
                : const Icon(
                    Icons.chevron_right_rounded,
                    color:
                        Color(0xFF98A2B3),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildProductImage(
    String image,
  ) {
    if (image.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F7),
          borderRadius:
              BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.inventory_2_outlined,
          color: Color(0xFF98A2B3),
          size: 22,
        ),
      );
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(12),
      child: Image.network(
        image,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
          return Container(
            width: 48,
            height: 48,
            color: const Color(0xFFF2F4F7),
            child: const Icon(
              Icons.image_not_supported_outlined,
              color:
                  Color(0xFF98A2B3),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _filterRecords() {
    final String query =
        _searchController.text.trim().toLowerCase();

    if (!mounted) return;

    setState(() {
      if (query.isEmpty) {
        filteredPointSystems =
            List.from(pointSystems);

        return;
      }

      filteredPointSystems =
          pointSystems.where(
        (record) {
          final String type =
              record['point_type']
                      ?.toString()
                      .toLowerCase() ??
                  '';

          final String typeLabel =
              _pointTypeLabel(type)
                  .toLowerCase();

          final String product =
              _productDisplay(record)
                  .toLowerCase();

          final String quantity =
              record['quantity']
                      ?.toString()
                      .toLowerCase() ??
                  '';

          final String point =
              record['point']
                      ?.toString()
                      .toLowerCase() ??
                  '';

          return type.contains(query) ||
              typeLabel.contains(query) ||
              product.contains(query) ||
              quantity.contains(query) ||
              point.contains(query);
        },
      ).toList();
    });
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _pointTypeLabel(String type) {
    for (final Map<String, String> option
        in pointTypeOptions) {
      if (option['value'] == type) {
        return option['label'] ?? type;
      }
    }

    return type;
  }

  String _productDisplay(
    Map<String, dynamic> record,
  ) {
    final dynamic product = record['product'];

    if (product == null) {
      final String directName =
          record['product_name']?.toString() ?? '';

      if (directName.isNotEmpty) {
        return directName;
      }

      final String directId =
          record['product_id']?.toString() ?? '';

      if (directId.isNotEmpty) {
        return 'Product #$directId';
      }

      return '-';
    }

    if (product is Map) {
      final String name =
          product['name']?.toString() ??
              product['product_name']
                  ?.toString() ??
              '';

      final String id =
          product['id']?.toString() ?? '';

      if (name.isNotEmpty && id.isNotEmpty) {
        return '$name (#$id)';
      }

      if (name.isNotEmpty) {
        return name;
      }

      if (id.isNotEmpty) {
        return '#$id';
      }
    }

    return product.toString();
  }

  String _formatDate(dynamic value) {
    if (value == null ||
        value.toString().trim().isEmpty) {
      return '-';
    }

    try {
      final DateTime date =
          DateTime.parse(
        value.toString(),
      ).toLocal();

      final String day =
          date.day.toString().padLeft(2, '0');

      final String month =
          date.month.toString().padLeft(2, '0');

      final String year =
          date.year.toString();

      final int hour12 =
          date.hour == 0
              ? 12
              : date.hour > 12
                  ? date.hour - 12
                  : date.hour;

      final String minute =
          date.minute
              .toString()
              .padLeft(2, '0');

      final String period =
          date.hour >= 12 ? 'PM' : 'AM';

      return '$day-$month-$year '
          '$hour12:$minute $period';
    } catch (_) {
      return value.toString();
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: isError
              ? const Color(0xFFD92D20)
              : const Color(0xFF039855),
          behavior: SnackBarBehavior.floating,
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
  }

  void _showApiError(
    http.Response response, {
    required String fallback,
  }) {
    String message = fallback;

    try {
      final dynamic decoded =
          jsonDecode(response.body);

      if (decoded is Map) {
        message =
            decoded['message']
                    ?.toString() ??
                decoded['detail']
                    ?.toString() ??
                decoded['error']
                    ?.toString() ??
                decoded.toString();
      }
    } catch (_) {
      if (response.body.trim().isNotEmpty) {
        message = response.body;
      }
    }

    _showMessage(
      message,
      isError: true,
    );
  }

  void _showLoadingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF4F6F8,
      ),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor:
            const Color(0xFF101828),
        titleSpacing: 8,
        title: const Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Point System',
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Manage product and sales points',
              style: TextStyle(
                fontSize: 10.5,
                color:
                    Color(0xFF667085),
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: isRefreshing
                ? null
                : () async {
                    setState(() {
                      isRefreshing = true;
                    });

                    await fetchPointSystems(
                      showLoader: false,
                    );
                  },
            icon: isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                  ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              fetchPointSystems(
            showLoader: false,
          ),
          child: ListView(
            padding:
                const EdgeInsets.fromLTRB(
              14,
              14,
              14,
              28,
            ),
            children: [
              _buildEditorCard(),

              const SizedBox(height: 18),

              _buildListHeader(),

              const SizedBox(height: 10),

              _buildSearchBox(),

              const SizedBox(height: 12),

              if (isLoading)
                _buildLoadingState()
              else if (filteredPointSystems
                  .isEmpty)
                _buildEmptyState()
              else
                ...List.generate(
                  filteredPointSystems
                      .length,
                  (index) {
                    return _buildRecordCard(
                      filteredPointSystems[
                          index],
                      index,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EDITOR
  // ============================================================

  Widget _buildEditorCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.045),
            blurRadius: 16,
            offset:
                const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(16),
            decoration:
                const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF37A7F7),
                  Color(0xFF287BE4),
                ],
              ),
              borderRadius:
                  BorderRadius.only(
                topLeft:
                    Radius.circular(22),
                topRight:
                    Radius.circular(22),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration:
                      BoxDecoration(
                    color: Colors.white
                        .withOpacity(0.15),
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
                  ),
                  child: Icon(
                    editingId == null
                        ? Icons
                            .add_chart_rounded
                        : Icons
                            .edit_note_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        editingId == null
                            ? 'Add Point Configuration'
                            : 'Edit Point Configuration',
                        style:
                            const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight:
                              FontWeight
                                  .w800,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        editingId == null
                            ? 'Create a new point rule'
                            : 'Updating record #$editingId',
                        style:
                            const TextStyle(
                          color:
                              Colors.white70,
                          fontSize: 10.5,
                          fontWeight:
                              FontWeight
                                  .w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (editingId != null)
                  IconButton(
                    tooltip:
                        'Cancel editing',
                    onPressed: isSaving
                        ? null
                        : _resetForm,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildPointTypeDropdown(),

                  if (selectedPointType ==
                      'product') ...[
                    const SizedBox(
                      height: 14,
                    ),

                    _buildProductSelector(),

                    const SizedBox(
                      height: 14,
                    ),

                    _buildTextField(
                      controller:
                          _quantityController,
                      label: 'Quantity',
                      hint:
                          'Optional quantity',
                      icon: Icons
                          .numbers_rounded,
                      keyboardType:
                          TextInputType.number,
                      validator: (value) {
                        if (value == null ||
                            value
                                .trim()
                                .isEmpty) {
                          return null;
                        }

                        final int? quantity =
                            int.tryParse(
                          value.trim(),
                        );

                        if (quantity ==
                                null ||
                            quantity <=
                                0) {
                          return 'Quantity must be greater than 0';
                        }

                        return null;
                      },
                    ),
                  ],

                  const SizedBox(
                    height: 14,
                  ),

                  _buildTextField(
                    controller:
                        _pointController,
                    label: 'Point',
                    hint:
                        'Example: 10.00',
                    icon: Icons
                        .stars_rounded,
                    keyboardType:
                        const TextInputType
                            .numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null ||
                          value
                              .trim()
                              .isEmpty) {
                        return 'Point is required';
                      }

                      final double? point =
                          double.tryParse(
                        value.trim(),
                      );

                      if (point == null) {
                        return 'Enter a valid point';
                      }

                      if (point < 0) {
                        return 'Point cannot be negative';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  SizedBox(
                    width:
                        double.infinity,
                    height: 50,
                    child:
                        ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : editingId ==
                                  null
                              ? createPointSystem
                              : updatePointSystem,
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            const Color(
                          0xFF287BE4,
                        ),
                        foregroundColor:
                            Colors.white,
                        disabledBackgroundColor:
                            const Color(
                          0xFFB8D5F4,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                color:
                                    Colors.white,
                                strokeWidth:
                                    2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                              children: [
                                Icon(
                                  editingId ==
                                          null
                                      ? Icons
                                          .add_rounded
                                      : Icons
                                          .save_outlined,
                                  size: 20,
                                ),
                                const SizedBox(
                                  width: 7,
                                ),
                                Text(
                                  editingId ==
                                          null
                                      ? 'Create Point Rule'
                                      : 'Update Point Rule',
                                  style:
                                      const TextStyle(
                                    fontSize:
                                        13,
                                    fontWeight:
                                        FontWeight
                                            .w800,
                                  ),
                                ),
                              ],
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

  Widget _buildPointTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedPointType,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Point Type',
        prefixIcon: const Icon(
          Icons.category_outlined,
        ),
        filled: true,
        fillColor:
            const Color(0xFFF8FAFC),
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              const BorderSide(
            color: Color(0xFFE4E7EC),
          ),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              const BorderSide(
            color: Color(0xFFE4E7EC),
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              const BorderSide(
            color: Color(0xFF287BE4),
            width: 1.4,
          ),
        ),
      ),
      items: pointTypeOptions.map(
        (option) {
          return DropdownMenuItem<String>(
            value: option['value'],
            child: Text(
              option['label'] ?? '',
            ),
          );
        },
      ).toList(),
      onChanged: isSaving
          ? null
          : (String? value) {
              if (value == null) {
                return;
              }

              setState(() {
                selectedPointType = value;

                if (value != 'product') {
                  selectedProductId = null;
                  selectedProductName = '';
                  selectedProductImage = '';

                  _quantityController.clear();
                }
              });
            },
    );
  }


  Widget _buildProductSelector() {
    final bool hasProduct =
        selectedProductId != null;

    return InkWell(
      borderRadius:
          BorderRadius.circular(14),
      onTap: isSaving
          ? null
          : _openProductPicker,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color: hasProduct
                ? const Color(0xFF287BE4)
                    .withOpacity(0.55)
                : const Color(0xFFE4E7EC),
          ),
        ),
        child: Row(
          children: [
            if (hasProduct)
              _buildProductImage(
                selectedProductImage,
              )
            else
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFEAF4FF),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color:
                      Color(0xFF287BE4),
                  size: 21,
                ),
              ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Product',
                    style: TextStyle(
                      color:
                          Color(0xFF667085),
                      fontSize: 10.5,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasProduct
                        ? selectedProductName.isNotEmpty
                            ? selectedProductName
                            : 'Product #$selectedProductId'
                        : 'Tap to select product',
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasProduct
                          ? const Color(
                              0xFF101828,
                            )
                          : const Color(
                              0xFF98A2B3,
                            ),
                      fontSize: 12.5,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  if (hasProduct)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        top: 3,
                      ),
                      child: Text(
                        'ID: $selectedProductId',
                        style: const TextStyle(
                          color:
                              Color(0xFF667085),
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color:
                  Color(0xFF0F3D75),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController
        controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)?
        validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor:
            const Color(0xFFF8FAFC),
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              const BorderSide(
            color: Color(0xFFE4E7EC),
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              const BorderSide(
            color: Color(0xFF287BE4),
            width: 1.4,
          ),
        ),
        errorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              const BorderSide(
            color: Color(0xFFD92D20),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LIST
  // ============================================================

  Widget _buildListHeader() {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color:
                const Color(0xFFEAF4FF),
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.list_alt_rounded,
            color:
                Color(0xFF287BE4),
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Point Configurations',
                style: TextStyle(
                  color:
                      Color(0xFF101828),
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Tap Edit to update a rule',
                style: TextStyle(
                  color:
                      Color(0xFF667085),
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color:
                const Color(0xFFEAF4FF),
            borderRadius:
                BorderRadius.circular(20),
          ),
          child: Text(
            '${filteredPointSystems.length}',
            style: const TextStyle(
              color:
                  Color(0xFF287BE4),
              fontWeight:
                  FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBox() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color:
              const Color(0xFFE4E7EC),
        ),
      ),
      child: TextField(
        controller:
            _searchController,
        decoration:
            InputDecoration(
          hintText:
              'Search point rules...',
          prefixIcon: const Icon(
            Icons.search_rounded,
            color:
                Color(0xFF667085),
          ),
          suffixIcon:
              _searchController
                      .text
                      .isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController
                            .clear();
                      },
                      icon:
                          const Icon(
                        Icons
                            .close_rounded,
                      ),
                    )
                  : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets
                  .symmetric(
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildRecordCard(
    Map<String, dynamic> record,
    int index,
  ) {
    final String type =
        record['point_type']
                ?.toString() ??
            '';

    final bool isProduct =
        type == 'product';

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              const Color(0xFFE4E7EC),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.03),
            blurRadius: 8,
            offset:
                const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets
                    .fromLTRB(
              13,
              12,
              10,
              12,
            ),
            decoration:
                const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF48AAF2),
                  Color(0xFF2B7CDF),
                ],
              ),
              borderRadius:
                  BorderRadius.only(
                topLeft:
                    Radius.circular(17),
                topRight:
                    Radius.circular(17),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 37,
                  height: 37,
                  decoration:
                      BoxDecoration(
                    color: Colors.white
                        .withOpacity(0.15),
                    borderRadius:
                        BorderRadius.circular(
                      11,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        _pointTypeLabel(
                          type,
                        ),
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 13,
                          fontWeight:
                              FontWeight
                                  .w800,
                        ),
                      ),
                      const SizedBox(
                        height: 2,
                      ),
                      Text(
                        'ID: ${record['id'] ?? '-'}',
                        style:
                            const TextStyle(
                          color:
                              Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () {
                    startEditing(
                      record,
                    );
                  },
                  icon: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.all(14),
            child: Column(
              children: [
                if (isProduct)
                  _buildDetailRow(
                    icon: Icons
                        .inventory_2_outlined,
                    label: 'Product',
                    value:
                        _productDisplay(
                      record,
                    ),
                  ),

                if (isProduct)
                  const Divider(
                    height: 20,
                  ),

                if (isProduct)
                  _buildDetailRow(
                    icon: Icons
                        .numbers_rounded,
                    label: 'Quantity',
                    value:
                        record['quantity']
                                ?.toString() ??
                            '-',
                  ),

                if (isProduct)
                  const Divider(
                    height: 20,
                  ),

                _buildDetailRow(
                  icon:
                      Icons.stars_rounded,
                  label: 'Point',
                  value:
                      record['point']
                              ?.toString() ??
                          '0',
                  emphasized: true,
                ),

                if (record[
                        'created_by'] !=
                    null) ...[
                  const Divider(
                    height: 20,
                  ),
                  _buildDetailRow(
                    icon: Icons
                        .person_outline,
                    label:
                        'Created By',
                    value: record[
                                'created_by']
                            is Map
                        ? record['created_by']
                                    ['username']
                                ?.toString() ??
                            record['created_by']
                                    ['name']
                                ?.toString() ??
                            record['created_by']
                                    ['id']
                                ?.toString() ??
                            '-'
                        : record[
                                'created_by']
                            .toString(),
                  ),
                ],

                if (record[
                        'updated_at'] !=
                    null) ...[
                  const Divider(
                    height: 20,
                  ),
                  _buildDetailRow(
                    icon: Icons
                        .update_rounded,
                    label:
                        'Updated At',
                    value:
                        _formatDate(
                      record[
                          'updated_at'],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool emphasized = false,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color:
                const Color(0xFFF2F4F7),
            borderRadius:
                BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color:
                const Color(0xFF475467),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(
              color:
                  Color(0xFF667085),
              fontSize: 11,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: emphasized
                  ? const Color(
                      0xFF287BE4,
                    )
                  : const Color(
                      0xFF101828,
                    ),
              fontSize:
                  emphasized ? 15 : 12,
              fontWeight: emphasized
                  ? FontWeight.w900
                  : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOADING / EMPTY
  // ============================================================

  Widget _buildLoadingState() {
    return const Padding(
      padding:
          EdgeInsets.symmetric(
        vertical: 60,
      ),
      child: Center(
        child:
            CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 50,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFF2F4F7),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons
                  .inbox_outlined,
              color:
                  Color(0xFF98A2B3),
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No point configurations',
            style: TextStyle(
              color:
                  Color(0xFF101828),
              fontSize: 14,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Create your first point rule using the form above.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color:
                  Color(0xFF667085),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}