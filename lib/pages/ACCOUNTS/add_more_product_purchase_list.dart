import 'dart:convert';
import 'package:beposoft/pages/ACCOUNTS/Purchase_product_cart.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddMoreProductPurchaseList extends StatefulWidget {
  const AddMoreProductPurchaseList({super.key});

  @override
  State<AddMoreProductPurchaseList> createState() =>
      _AddMoreProductPurchaseListState();
}

class _AddMoreProductPurchaseListState
    extends State<AddMoreProductPurchaseList> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  List<Map<String, dynamic>> Warehouses = [];

  Map<int, bool> expandedProducts = {};

  String? warehouse;
  String? defaultWarehouse;

  List<String> categories = ["All Categories"];
  String selectedCategory = "All Categories";

  TextEditingController searchController = TextEditingController();

  bool loading = false;

  // ✅ GET TOKEN
  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ✅ GET LOGGED-IN WAREHOUSE
  Future<String?> getwarehouseFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? warehouseId = prefs.getInt('warehouse');
    return warehouseId?.toString();
  }

  @override
  void initState() {
    super.initState();
    initdata();
  }

  // ✅ INIT DATA
  Future<void> initdata() async {
    await getwarehouse();

    defaultWarehouse = await getwarehouseFromPrefs();
    warehouse = defaultWarehouse;

    if (warehouse != null) {
      await fetchProductListid(warehouse);
    }

    setState(() {
      filteredProducts = products;
    });
  }

  // ✅ FETCH WAREHOUSE LIST
  Future<void> getwarehouse() async {
    final token = await getTokenFromPrefs();
    if (token == null) return;

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
          warehouselist.add({
            'id': w['id'].toString(),
            'name': w['name'],
            'location': w['location']
          });
        }

        setState(() {
          Warehouses = warehouselist;
        });
      }
    } catch (e) {
      // debugPrint("Warehouse Error: $e");
    }
  }

  // ✅ FETCH PRODUCTS BASED ON WAREHOUSE
  Future<void> fetchProductListid(var warehouse) async {
    final token = await getTokenFromPrefs();
    if (token == null) return;

    setState(() {
      loading = true;
      products = [];
      filteredProducts = [];
      categories = ["All Categories"];
      selectedCategory = "All Categories";
    });

    try {
      final response = await http.get(
        Uri.parse("$api/api/warehouse/products/$warehouse/"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final List<dynamic> productsData = parsed['data'];

        List<Map<String, dynamic>> productList = [];
        Set<String> categorySet = {};

        for (final p in productsData) {
          if ((p['approval_status'] ?? '') != 'Approved') continue;

          if (p['product_category_name'] != null &&
              p['product_category_name'].toString().trim().isNotEmpty) {
            categorySet.add(p['product_category_name'].toString());
          }

          productList.add(Map<String, dynamic>.from(p));
        }

        setState(() {
          products = productList;
          categories = ["All Categories", ...categorySet.toList()];
          filteredProducts = products;
        });
      }
    } catch (e) {
      // debugPrint("Product Fetch Error: $e");
    }

    setState(() {
      loading = false;
    });
  }

  // ✅ APPLY FILTERS
  void applyFilters() {
    final query = searchController.text.toLowerCase();

    setState(() {
      filteredProducts = products.where((product) {
        bool matchesCategory = true;
        bool matchesSearch = true;

        if (selectedCategory != "All Categories") {
          matchesCategory =
              product['product_category_name'] == selectedCategory;
        }

        if (query.isNotEmpty) {
          matchesSearch =
              (product['name'] ?? "").toString().toLowerCase().contains(query);
        }

        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  // ✅ SHOW POPUP
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

  Future<void> showQuantityDialog(Map<String, dynamic> product) async {
    TextEditingController quantityController = TextEditingController(text: "1");

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Enter Quantity"),
                const SizedBox(height: 10),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {
                    int qty = int.tryParse(quantityController.text) ?? 1;

                    if (qty <= 0) return;

                    Navigator.pop(context); // close dialog

                    // ✅ RETURN DATA TO PREVIOUS SCREEN
                    double price = double.tryParse(
                            product["price"]?.toString() ??
                                product["selling_price"]?.toString() ??
                                product["mrp"]?.toString() ??
                                product["variant_price"]?.toString() ??
                                "0") ??
                        0;

                    Navigator.pop(context, {
                      "id": product["id"],
                      "product_id": product["id"],
                      "product_name": product["name"],
                      "quantity": qty,
                      "price": price,
                      "discount": 0,
                      "tax": 0,
                      "total": price * qty,
                      "image": product["image"] ?? "",
                    });
                  },
                  child: const Text("ADD"),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Product List",
            style: TextStyle(color: Colors.grey, fontSize: 14)),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.grey),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SellerCartPage()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ DROPDOWNS
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
                          expandedProducts = {};
                        });

                        await fetchProductListid(selectedId);
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
                        applyFilters();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // ✅ SEARCH
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search products...",
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onChanged: (_) => applyFilters(),
            ),
          ),

          // ✅ PRODUCT LIST
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => fetchProductListid(warehouse),
                    child: ListView.builder(
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        final isExpanded =
                            expandedProducts[product['id']] ?? false;

                        return Padding(
                          padding: const EdgeInsets.only(
                              top: 10, left: 10, right: 10),
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
                                      color: const Color.fromARGB(
                                              255, 210, 209, 209)
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        showQuantityDialog(product);
                                      } else {
                                        showQuantityDialog(product);
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
                                      product['type'] == 'single'
                                          ? "Add"
                                          : "View",
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 10),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          product['type'] == 'single'
                                              ? Colors.orange
                                              : Colors.blue,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      minimumSize: const Size(60, 24),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // ✅ VARIANT EXPANSION LIST (NO STOCK/LOCKED STOCK)
                              if (isExpanded &&
                                  product['variantIDs'] != null &&
                                  product['variantIDs'].isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 8.0, left: 10, right: 10),
                                  child: Column(
                                    children: [
                                      // ✅ MAIN PRODUCT FIRST
                                      Container(
                                        height: 80,
                                        margin:
                                            const EdgeInsets.only(bottom: 6),
                                        padding: const EdgeInsets.all(8.0),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.3),
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
                                              const Icon(
                                                  Icons.image_not_supported),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                product['name'] ?? '',
                                                style: const TextStyle(
                                                    fontSize: 13),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                showQuantityDialog(product);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.deepPurple,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4),
                                                minimumSize: const Size(60, 32),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
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

                                      // ✅ VARIANTS BELOW
                                      ...product['variantIDs']
                                          .map<Widget>((variant) {
                                        return Container(
                                          height: 80,
                                          margin:
                                              const EdgeInsets.only(bottom: 6),
                                          padding: const EdgeInsets.all(8.0),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey
                                                    .withOpacity(0.3),
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
                                                child: Text(
                                                  variant['name'] ?? '',
                                                  style: const TextStyle(
                                                      fontSize: 13),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  variant["price"] = variant[
                                                          "price"] ??
                                                      variant[
                                                          "variant_price"] ??
                                                      variant[
                                                          "selling_price"] ??
                                                      variant["mrp"] ??
                                                      0;

                                                  showQuantityDialog(variant);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.orange,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                                  minimumSize:
                                                      const Size(60, 32),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
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
    );
  }
}
