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
import 'package:beposoft/pages/ACCOUNTS/view_cart.dart';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class order_products extends StatefulWidget {
  const order_products({super.key});

  @override
  State<order_products> createState() => _order_productsState();
}

class _order_productsState extends State<order_products> {
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
    final dep = await getdepFromPrefs();
    if (dep == "BDO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                bdo_dashbord()), // Replace AnotherPage with your target page
      );
    } else if (dep == "SD") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                SdDashboard()), // Replace AnotherPage with your target page
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
    } else if (dep == "Marketing") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                marketing_dashboard()), // Replace AnotherPage with your target page
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => dashboard()),
      );
    }
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

  Future<void> initdata() async {
    dep = await getdepFromPrefs();
    defaultWarehouse = await getwarehouseFromPrefs();
    warehouse = defaultWarehouse; // initially default
    await fetchProductListid(warehouse);
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

    setState(() {
      isProductLoading = true;
    });

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

          productList.add(Map<String, dynamic>.from(p));
        }

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
      setState(() {
        isProductLoading = false;
      });
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

  Future<String> addtocart(varid, quantity) async {
    final token = await getTokenFromPrefs();
    try {
      final response = await http.post(
        Uri.parse('$api/api/cart/product/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'product': varid, 'quantity': quantity}),
      );
      if (response.statusCode == 201) return "success";
      if (response.statusCode == 400) return "failed";
      return "error";
    } catch (e) {
      return "exception";
    }
  }

  void handleAddToCart(BuildContext context, varid, quantity) async {
    final result = await addtocart(varid, quantity);
    if (!mounted) return;
    if (result == "success") {
      showCustomPopup("Success", "Product added to cart successfully!");
    } else if (result == "failed") {
      showCustomPopup("Notice", "Product already in cart!");
    } else {
      showCustomPopup("Error", "Failed to add Product!");
    }
  }

  // ✅ FIXED: Scrollable + Keyboard-safe dialog
  void showSizeDialog3(BuildContext context, mainid, stock, lockedStock) async {
    final List<Map<String, dynamic>> lockedInvoices =
        await showlockedstockinvoice(mainid);
    TextEditingController quantityController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Stock: $stock", style: const TextStyle(fontSize: 14)),
                  Text("Locked: $lockedStock",
                      style: const TextStyle(fontSize: 14)),
                  if (lockedInvoices.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text("Locked Invoices:",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    ...lockedInvoices.map((inv) => Text(
                        "🧾 ${inv['invoice']} - 🔒 ${inv['quantity_locked']}")),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Enter Quantity",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: isDefaultWarehouse
                          ? () {
                              int quantity =
                                  int.tryParse(quantityController.text) ?? 1;

                              if (quantity > (stock - lockedStock)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Quantity exceeds stock!")),
                                );
                                return;
                              }
                              if (stock == 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("No stock available")),
                                );
                                return;
                              }

                              handleAddToCart(context, mainid, quantity);
                              Navigator.of(context).pop();
                            }
                          : null, // 🔒 Disable if different warehouse
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDefaultWarehouse
                            ? Colors.blue
                            : Colors.grey, // grey when disabled
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "ADD TO CART",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _applyFilters() {
    searchQuery = searchController.text.trim();

    if (_searchDebounce?.isActive ?? false) {
      _searchDebounce!.cancel();
    }

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      fetchProductListid(
        warehouse,
        page: 1,
        search: searchQuery,
      );
    });
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
            onPressed: () async {
              final dep = await getdepFromPrefs();
              if (dep == "BDO") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          bdo_dashbord()), // Replace AnotherPage with your target page
                );
              } else if (dep == "SD") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SdDashboard()), // Replace AnotherPage with your target page
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
              } else if (dep == "Marketing") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          marketing_dashboard()), // Replace AnotherPage with your target page
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
                                          fontSize: 12, color: Colors.grey),
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
                                      product['stock'],
                                      product['locked_stock'],
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
                                    height: 80,
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.all(8.0),
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
                                          Image.network(
                                            '$api${product['image']}',
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          )
                                        else
                                          const Icon(Icons.image_not_supported),
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
                                              Text(
                                                "Stock: ${product['stock']} | Locked: ${product['locked_stock']}",
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            showSizeDialog3(
                                              context,
                                              product[
                                                  'id'], // <-- Main product ID
                                              product['stock'] ?? 0,
                                              product['locked_stock'] ?? 0,
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
                                      height: 80,
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.all(8.0),
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
                                            Image.network(
                                              '$api${variant['image']}',
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                            )
                                          else
                                            const Icon(
                                                Icons.image_not_supported),
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
                                                Text(
                                                    "Stock: ${variant['stock']} | Locked: ${variant['locked_stock']}",
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey)),
                                              ],
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              showSizeDialog3(
                                                context,
                                                variant['id'],
                                                variant['stock'] ?? 0,
                                                variant['locked_stock'] ?? 0,
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
