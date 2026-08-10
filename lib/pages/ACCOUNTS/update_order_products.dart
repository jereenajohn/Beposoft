import 'dart:convert';
import 'package:beposoft/Sales%20Directors/SD_dashboard.dart';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/MARKETING/marketing_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/order.review.dart';
import 'package:beposoft/pages/ACCOUNTS/view_cart.dart';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'dart:async';

class update_order_products extends StatefulWidget {
  final dynamic id;
  final dynamic customer;

  const update_order_products({
    super.key,
    required this.id,
    required this.customer,
  });

  @override
  State<update_order_products> createState() =>
      _update_order_productsState();
}

class _update_order_productsState extends State<update_order_products> {
  drower d = drower();
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  List<Map<String, dynamic>> Warehouses = [];
  Map<int, bool> expandedProducts = {};
  String? dep;
  var warehouse;
  String? selectedCategoryId;
  List<String> categories = ["All Categories"];
  String selectedCategory = "All Categories";

  int currentPage = 1;
  int totalProductCount = 0;
  String? nextPageUrl;
  String? previousPageUrl;
  bool isProductLoading = false;
  String searchQuery = "";
  Timer? _searchDebounce;

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initdata();
    getwarehouse();
  }

  Future<void> _navigateBack() async {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OrderReview(
          id: widget.id,
          customer: widget.customer,
        ),
      ),
    );
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<String?> getwarehouseFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? warehouseId = prefs.getInt('warehouse');
    return warehouseId?.toString();
  }

  bool isDefaultWarehouse = true;
  String? defaultWarehouse;

  bool get canViewStock {
    final department = dep?.trim().toUpperCase();

    return department == "CEO" ||
        department == "COO" ||
        department == "ADMIN";
  }

  Future<void> initdata() async {
    dep = await getdepFromPrefs();
    defaultWarehouse = await getwarehouseFromPrefs();
    warehouse = defaultWarehouse; // initially default
    await fetchProductListid(warehouse);

    if (!mounted) return;

    setState(() {
      filteredProducts = products;
      isDefaultWarehouse = true;
    });
  }

  Future<void> getwarehouse() async {
    final token = await getTokenFromPrefs();
    try {
      final response =
          await http.get(Uri.parse('$api/api/warehouse/add/'), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        List<Map<String, dynamic>> warehouselist = [];
        for (var w in parsed) {
          warehouselist.add(
              {'id': w['id'], 'name': w['name'], 'location': w['location']});
        }
        if (!mounted) return;

        setState(() {
          Warehouses = warehouselist;
        });
      }
    } catch (e) {}
  }

  Future<void> fetchProductListid(
    var warehouse, {
    int page = 1,
    String search = "",
  }) async {
    final token = await getTokenFromPrefs();
    dep = await getdepFromPrefs();

    if (mounted) {
      setState(() {
        isProductLoading = true;
      });
    }

    try {
      final uri =
          Uri.parse("$api/api/warehouse/products/$warehouse/get/").replace(
        queryParameters: {
          'page': page.toString(),
          if (search.trim().isNotEmpty) 'search': search.trim(),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        totalProductCount = parsed['count'] ?? 0;
        nextPageUrl = parsed['next'];
        previousPageUrl = parsed['previous'];
        currentPage = page;

        final List<dynamic> productsData = parsed['results']['data'] ?? [];

        List<Map<String, dynamic>> productList = [];
        Set<String> categorySet = {};

        for (final p in productsData) {
          if ((p['approval_status'] ?? '') != 'Approved') continue;

          if (p['product_category_name'] != null &&
              p['product_category_name'].toString().trim().isNotEmpty) {
            categorySet.add(p['product_category_name']);
          }

          final product = Map<String, dynamic>.from(p);

          final approvedVariants =
              (product['variantIDs'] as List<dynamic>? ?? [])
                  .where(
                    (variant) =>
                        (variant['approval_status'] ?? '') == 'Approved',
                  )
                  .map(
                    (variant) => Map<String, dynamic>.from(variant),
                  )
                  .toList();

          product['variantIDs'] = approvedVariants;
          productList.add(product);
        }

        if (!mounted) return;

        setState(() {
          products = productList;
          categories = ["All Categories", ...categorySet];

          if (!categories.contains(selectedCategory)) {
            selectedCategory = "All Categories";
          }

          filteredProducts = products.where((product) {
            if (selectedCategory == "All Categories") return true;
            return product['product_category_name'] == selectedCategory;
          }).toList();
        });
      }
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() {
          isProductLoading = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> showlockedstockinvoice(
      int productId) async {
    try {
      final token = await getTokenFromPrefs();
      var response = await http.get(
        Uri.parse('$api/api/product/$productId/locked-invoices/'),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['locked_invoices']);
      }
    } catch (e) {}
    return [];
  }

  void showCustomPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<String> addtocart(
    dynamic id,
    dynamic varid,
    dynamic quantity,
    dynamic tax,
    dynamic rate,
  ) async {
    final token = await getTokenFromPrefs();

    try {
      final response = await http.post(
        Uri.parse('$api/api/order-item/create/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'order': widget.id,
          'product': varid,
          'quantity': quantity,
          'tax': rate,
          'rate': tax,
        }),
      );

      if (response.statusCode == 201) {
        await fetchOrderItems();
        return "success";
      } else if (response.statusCode == 400) {
        return "failed";
      } else {
        return "error";
      }
    } catch (e) {
      return "exception";
    }
  }

  Future<String> addtocart2(
    dynamic mainid,
    dynamic quantity,
    dynamic tax,
    dynamic rate,
  ) async {
    final token = await getTokenFromPrefs();

    try {
      final response = await http.post(
        Uri.parse('$api/api/order-item/create/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'order': widget.id,
          'product': mainid,
          'quantity': quantity,
          'tax': tax,
          'rate': rate,
        }),
      );

      if (response.statusCode == 201) {
        await fetchOrderItems();
        return "success";
      } else if (response.statusCode == 400) {
        return "failed";
      } else {
        return "error";
      }
    } catch (e) {
      return "exception";
    }
  }

  Future<void> _handleAddResult(String result) async {
    if (!mounted) return;

    if (result == "success") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Product added successfully!"),
          duration: Duration(milliseconds: 900),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 350));

      if (!mounted) return;
      await _navigateBack();
    } else if (result == "failed") {
      showCustomPopup(
        "Notice",
        "Product already in order!",
      );
    } else if (result == "exception") {
      showCustomPopup(
        "Error",
        "Unable to connect to the server.",
      );
    } else {
      showCustomPopup(
        "Error",
        "Failed to add Product!",
      );
    }
  }

  Future<void> handleAddToCart(
    BuildContext context,
    dynamic id,
    dynamic varid,
    dynamic quantity,
    dynamic tax,
    dynamic rate,
  ) async {
    final result = await addtocart(
      id,
      varid,
      quantity,
      tax,
      rate,
    );

    await _handleAddResult(result);
  }

  Future<void> handleAddToCart2(
    BuildContext context,
    dynamic varid,
    dynamic quantity,
    dynamic tax,
    dynamic rate,
  ) async {
    final result = await addtocart2(
      varid,
      quantity,
      tax,
      rate,
    );

    await _handleAddResult(result);
  }

  // Same stock and available-stock UI/conditions as CreatePerformaProduct_List.
  Future<void> showSizeDialog3(
    BuildContext context,
    dynamic mainid,
    dynamic availableStockValue,
    dynamic stockValue,
    dynamic tax,
    dynamic rate,
  ) async {
    final num availableStock = availableStockValue is num
        ? availableStockValue
        : num.tryParse(
              availableStockValue?.toString() ?? "0",
            ) ??
            0;

    final num stock = stockValue is num
        ? stockValue
        : num.tryParse(stockValue?.toString() ?? "0") ?? 0;

    final int? selectedQuantity = await showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _UpdateOrderProductQuantityDialog(
          availableStock: availableStock,
          stock: stock,
          canViewStock: canViewStock,
          canAddToOrder: isDefaultWarehouse,
        );
      },
    );

    if (selectedQuantity == null || !mounted) return;

    await handleAddToCart2(
      context,
      mainid,
      selectedQuantity,
      tax,
      rate,
    );
  }

 Future<void> updatestatus() async {
    try {
      final token = await getTokenFromPrefs();


    

      Map<String, dynamic> body = {
  'total_amount': tot,
};

var response = await http.put(
  Uri.parse('$api/api/shipping/${widget.id}/order/'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
  body: jsonEncode(body),
);
      if (response.statusCode == 200) {
     ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('status updated successfully'),
    duration: Duration(seconds: 2),
    backgroundColor: Colors.green, // Add green background color
  ),
);
      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red, // Add red background color
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
    var ord;
      List<Map<String, dynamic>> items = [];
    String? createdBy;
double netAmountBeforeTax = 0.0; // Define at the class level
  double totalTaxAmount = 0.0; // Define at the class level
  double payableAmount = 0.0; // Define at the class level
  double Balance = 0.0; // Define at the class level
  double paymentreceipt = 0.0; // Define at the class level
  double totalDiscount = 0.0; // Define at the class level
  double tot = 0.0; // Define at the class level
 Future<void> fetchOrderItems() async {
  try {
    
    final token = await getTokenFromPrefs();

    if (token == null) {
      
      return;
    }
    final jwt = JWT.decode(token);
    var name = jwt.payload['name'] ?? 'Unknown'; // Provide a default value
    setState(() {
      createdBy = name;
    });
    var response = await http.get(
      Uri.parse('$api/api/order/${widget.id}/items/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
   
    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);

      ord = parsed['order'] ?? {};
      List<dynamic> itemsData = parsed['items'] ?? [];
      List<dynamic> warehouseData = (parsed['order'] != null && parsed['order']['warehouse'] is List) ? parsed['order']['warehouse'] : [];



      List<Map<String, dynamic>> orderList = [];
      List<Map<String, dynamic>> warehouseList = [];
      double calculatedNetAmount = 0.0;
      double calculatedTotalTax = 0.0;
      double calculatedPayableAmount = 0.0;
      double calculatedTotalDiscount = 0.0;

      // Process each item and calculate totals
      for (var item in itemsData) {
        orderList.add({
          'id': item['id'],
          'name': item['name'] ?? '',
          'quantity': item['quantity'] ?? 0,
          'rate': item['rate'] ?? 0.0,
          'tax': item['tax'] ?? 0.0,
          'discount': item['discount'] ?? 0.0,
          'actual_price': item['actual_price'] ?? 0.0,
          'exclude_price': item['exclude_price'] ?? 0.0,
          'images': item['image'] ?? '',
        });
        double price=(item['rate'] ?? 0).toDouble();

        double price_discount=(item['price_discount'] ?? 0).toDouble();
        double excludePrice = (item['exclude_price'] ?? 0).toDouble();
        double actualPrice = (item['actual_price'] ?? 0).toDouble();
        double discount = (item['discount'] ?? 0).toDouble();
        final quantity = int.tryParse(item['quantity'].toString()) ?? 1;

      
        calculatedTotalTax += (price_discount - excludePrice)* quantity;
        calculatedNetAmount += excludePrice* quantity;
        calculatedTotalDiscount += discount * quantity;
        calculatedPayableAmount += price* quantity;

      }

      // Process each warehouse item
      for (var warehouse in warehouseData) {
        warehouseList.add({
          'id': warehouse['id'],
          'box': warehouse['box'] ?? '',
          'weight': warehouse['weight'] ?? '0',
          'length': warehouse['length'] ?? '0',
          'breadth': warehouse['breadth'] ?? '0',
          'height': warehouse['height'] ?? '0',
          'image': warehouse['image'] ?? '',
          'parcel_service': warehouse['parcel_service'] ?? '',
          'tracking_id': warehouse['tracking_id'] ?? '',
          'shipping_charge': warehouse['shipping_charge'] ?? '0.0',
          'status': warehouse['status'] ?? '',
          'shipped_date': warehouse['shipped_date'] ?? '',
          'actual_weight': warehouse['actual_weight'] ?? '0.0',
          'parcel_amount': warehouse['parcel_amount'] ?? '0.0',
          'postoffice_date': warehouse['postoffice_date'] ?? '',
          'message_status': warehouse['message_status'] ?? '',
        });
      }

      double paymentReceiptsSum = 0.0;

      for (var receipt in parsed['order']['recived_payment'] ?? []) {
        paymentReceiptsSum += double.tryParse(receipt['amount'].toString()) ?? 0.0;
        
      }

double remainingAmount;
if(calculatedNetAmount>paymentReceiptsSum){
       remainingAmount = (calculatedNetAmount+calculatedTotalTax) - paymentReceiptsSum;
     
}

else{
  remainingAmount=paymentReceiptsSum-calculatedNetAmount;
}
      setState(() {

        items = orderList;
        warehouse = warehouseList;
        netAmountBeforeTax = calculatedNetAmount;
        totalTaxAmount = calculatedTotalTax;
        payableAmount = calculatedPayableAmount;
        totalDiscount = calculatedTotalDiscount;
        Balance = remainingAmount;
        paymentreceipt=remainingAmount;
        tot = netAmountBeforeTax + totalTaxAmount;

      });
updatestatus();
// fetchCustomerLedgerDetails();
    } else {
      
    }
  } catch (error) {

  }
}



  Future<void> _showVariantQuantityDialog(
    BuildContext context,
    dynamic mainProductId,
    Map<String, dynamic> variant,
    Map<String, dynamic> parentProduct,
  ) async {
    final num availableStock =
        variant['available_stock'] is num
            ? variant['available_stock']
            : num.tryParse(
                  variant['available_stock']?.toString() ?? "0",
                ) ??
                0;

    final num stock = variant['stock'] is num
        ? variant['stock']
        : num.tryParse(variant['stock']?.toString() ?? "0") ?? 0;

    final int? selectedQuantity = await showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _UpdateOrderProductQuantityDialog(
          availableStock: availableStock,
          stock: stock,
          canViewStock: canViewStock,
          canAddToOrder: isDefaultWarehouse,
        );
      },
    );

    if (selectedQuantity == null || !mounted) return;

    await handleAddToCart(
      context,
      mainProductId,
      variant['id'],
      selectedQuantity,
      variant['selling_price'] ??
          parentProduct['selling_price'],
      variant['tax'] ?? parentProduct['tax'],
    );
  }

  void _applyFilters() {
    searchQuery = searchController.text.trim();

    if (_searchDebounce?.isActive ?? false) {
      _searchDebounce!.cancel();
    }

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      fetchProductListid(
        warehouse,
        page: 1,
        search: searchQuery,
      );
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _navigateBack();
        return false; // Prevent default back navigation
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Product List",
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _navigateBack,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.shopping_cart, color: Colors.grey),
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => View_Cart()));
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // 🔹 SELECT WAREHOUSE
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: "Select Warehouse",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                      ),
                      value: warehouse,
                      items: Warehouses.map((wh) {
                        return DropdownMenuItem<String>(
                          value: wh['id'].toString(),
                          child: Text(
                            "${wh['name']} (${wh['location']})",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                      onChanged: (selectedId) async {
                        if (selectedId != null) {
                          if (!mounted) return;

                          setState(() {
                            warehouse = selectedId;
                            selectedCategory = "All Categories";
                            categories = ["All Categories"];
                            products = [];
                            filteredProducts = [];
                            isDefaultWarehouse =
                                (selectedId == defaultWarehouse);
                          });

                          searchQuery = searchController.text.trim();

                          await fetchProductListid(
                            selectedId,
                            page: 1,
                            search: searchQuery,
                          );
                        }
                      },
                    ),
                  ),

                  const SizedBox(width: 10),

                  // 🔹 SELECT CATEGORY
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: "Select Category",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                      ),
                      value: selectedCategory,
                      items: categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Text(
                            cat,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          if (!mounted) return;

                          setState(() {
                            selectedCategory = value;
                          });

                          filteredProducts = products.where((product) {
                            if (selectedCategory == "All Categories")
                              return true;
                            return product['product_category_name'] ==
                                selectedCategory;
                          }).toList();

                          setState(() {});
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search products...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0)),
                ),
                onChanged: (_) => _applyFilters(),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: previousPageUrl == null || isProductLoading
                        ? null
                        : () {
                            fetchProductListid(
                              warehouse,
                              page: currentPage - 1,
                              search: searchQuery,
                            );
                          },
                    child: const Text("Previous"),
                  ),
                  Text(
                    "Page $currentPage",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: nextPageUrl == null || isProductLoading
                        ? null
                        : () {
                            fetchProductListid(
                              warehouse,
                              page: currentPage + 1,
                              search: searchQuery,
                            );
                          },
                    child: const Text("Next"),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => fetchProductListid(
                  warehouse,
                  page: currentPage,
                  search: searchQuery,
                ),
                child: ListView.builder(
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    final isExpanded = expandedProducts[product['id']] ?? false;

                    return Padding(
                      padding:
                          const EdgeInsets.only(top: 10, left: 10, right: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            height: 90,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10.0),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color.fromARGB(255, 210, 209, 209)
                                          .withOpacity(0.5),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: product['image'] != null &&
                                      product['image'].isNotEmpty
                                  ? Image.network(
                                      '$api${product['image']}',
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(Icons.error),
                                    )
                                  : const Icon(Icons.image_not_supported),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${product['name']}",
                                    style: const TextStyle(fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (product['color'] != null &&
                                      product['color'].isNotEmpty)
                                    Text(
                                      "Color: ${product['color']}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  Text(
                                    "Price: ₹${product['selling_price'] ?? 0}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF344054),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: ElevatedButton.icon(
                                onPressed: () {
                                  if (product['type'] == 'variant') {
                                    setState(() {
                                      expandedProducts[product['id']] =
                                          !isExpanded;
                                    });
                                  } else if (product['type'] == 'single') {
                                    showSizeDialog3(
                                      context,
                                      product['id'],
                                      product['available_stock'] ?? 0,
                                      product['stock'] ?? 0,
                                      product['tax'],
                                      product['selling_price'],
                                    );
                                  }
                                },
                                icon: Icon(
                                  product['type'] == 'single'
                                      ? Icons.add
                                      : (isExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down),
                                  size: 14,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  product['type'] == 'single' ? "Add" : "View",
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 10),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: product['type'] == 'single'
                                      ? Colors.green
                                      : Colors.blue,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  minimumSize: const Size(60, 24),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // ✅ Inline Variant Expansion
                          if (isExpanded &&
                              product['variantIDs'] != null &&
                              product['variantIDs'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 8.0, left: 10, right: 10),
                              child: Column(
                                children: [
                                  // ✅ 1. MAIN PRODUCT AS FIRST ROW
                                  Container(
                                    constraints: const BoxConstraints(
                                      minHeight: 80,
                                    ),
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.3),
                                          spreadRadius: 2,
                                          blurRadius: 5,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        if (product['image'] != null &&
                                            product['image'].isNotEmpty)
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.network(
                                              '$api${product['image']}',
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                return Container(
                                                  width: 60,
                                                  height: 60,
                                                  color: Colors.grey.shade200,
                                                  child: const Icon(
                                                    Icons.image_not_supported,
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                        else
                                          Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey.shade200,
                                            child: const Icon(
                                              Icons.image_not_supported,
                                            ),
                                          ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                product['name'] ?? '',
                                                style: const TextStyle(
                                                    fontSize: 13),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (canViewStock)
                                                Text(
                                                  "Stock: ${product['stock'] ?? 0}",
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              Text(
                                                "Available Stock: ${product['available_stock'] ?? 0}",
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.green,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                "Price: ₹${product['selling_price'] ?? 0}",
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF344054),
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            showSizeDialog3(
                                              context,
                                              product['id'],
                                              product['available_stock'] ?? 0,
                                              product['stock'] ?? 0,
                                              product['tax'],
                                              product['selling_price'],
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.deepPurple,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            minimumSize: const Size(60, 32),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                          ),
                                          child: const Text(
                                            "Add",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // ✅ 2. ALL VARIANTS BELOW
                                  ...product['variantIDs']
                                      .map<Widget>((variant) {
                                    return Container(
                                      constraints: const BoxConstraints(
                                        minHeight: 80,
                                      ),
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.3),
                                            spreadRadius: 2,
                                            blurRadius: 5,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          if (variant['image'] != null &&
                                              variant['image'].isNotEmpty)
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                '$api${variant['image']}',
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return Container(
                                                    width: 60,
                                                    height: 60,
                                                    color:
                                                        Colors.grey.shade200,
                                                    child: const Icon(
                                                      Icons
                                                          .image_not_supported,
                                                    ),
                                                  );
                                                },
                                              ),
                                            )
                                          else
                                            Container(
                                              width: 60,
                                              height: 60,
                                              color: Colors.grey.shade200,
                                              child: const Icon(
                                                Icons.image_not_supported,
                                              ),
                                            ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(variant['name'] ?? '',
                                                    style: const TextStyle(
                                                        fontSize: 13),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis),
                                                if (canViewStock)
                                                  Text(
                                                    "Stock: ${variant['stock'] ?? 0}",
                                                    style:
                                                        const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                Text(
                                                  "Available Stock: ${variant['available_stock'] ?? 0}",
                                                  style:
                                                      const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.green,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  "Price: ₹${variant['selling_price'] ?? product['selling_price'] ?? 0}",
                                                  style:
                                                      const TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        Color(0xFF344054),
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              _showVariantQuantityDialog(
                                                context,
                                                product['id'],
                                                variant,
                                                product,
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                              minimumSize: const Size(60, 32),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                            ),
                                            child: const Text(
                                              "Add",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _UpdateOrderProductQuantityDialog extends StatefulWidget {
  final num availableStock;
  final num stock;
  final bool canViewStock;
  final bool canAddToOrder;

  const _UpdateOrderProductQuantityDialog({
    required this.availableStock,
    required this.stock,
    required this.canViewStock,
    required this.canAddToOrder,
  });

  @override
  State<_UpdateOrderProductQuantityDialog> createState() =>
      _UpdateOrderProductQuantityDialogState();
}

class _UpdateOrderProductQuantityDialogState
    extends State<_UpdateOrderProductQuantityDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  String? _validateQuantity(String? value) {
    final int? quantity = int.tryParse(value?.trim() ?? "");

    if (quantity == null || quantity <= 0) {
      return "Please enter a valid quantity!";
    }

    if (widget.availableStock <= 0) {
      return "No stock available";
    }

    if (quantity > widget.availableStock) {
      return "Quantity exceeds available stock!";
    }

    return null;
  }

  void _submit() {
    if (!widget.canAddToOrder) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.of(context).pop(
      int.parse(_quantityController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 40,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Add Product",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.canViewStock) ...[
                  Text(
                    "Stock: ${widget.stock}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  "Available Stock: ${widget.availableStock}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  validator: _validateQuantity,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: "Enter Quantity",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed:
                        widget.canAddToOrder ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.canAddToOrder
                          ? Colors.blue
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "ADD TO ORDER",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

