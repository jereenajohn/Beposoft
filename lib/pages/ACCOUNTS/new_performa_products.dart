import 'dart:convert';
import 'package:beposoft/Sales%20Directors/SD_dashboard.dart';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/performa_cart.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // Import for Timer

class CreatePerformaProduct_List extends StatefulWidget {
  const CreatePerformaProduct_List({super.key});

  @override
  State<CreatePerformaProduct_List> createState() =>
      _CreatePerformaProduct_ListState();
}

class _CreatePerformaProduct_ListState
    extends State<CreatePerformaProduct_List> {
  drower d = drower();
  Timer? timer; // Declare the timer variable
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

  var mainid;
  var varid;
  Map<int, bool> expandedProducts = {}; // Track expanded state for products
  List<Map<String, dynamic>> fam = [];
  List<Map<String, dynamic>> products = [];
  List<bool> _checkboxValues = [];
  List<Map<String, dynamic>> filteredProducts = [];
  List<Map<String, dynamic>> variant = [];
  int? selectedwarehouseId; // Variable to store the selected department's ID
  String? selectedwarehouseName;

  List<Map<String, dynamic>> Warehouses = [];

  TextEditingController searchController =
      TextEditingController(); // Search controller

  @override
  void initState() {
    super.initState();
    initdata();
    getwarehouse();
  }

  var warehouse;
  Future<void> initdata() async {
    final dep = await getdepFromPrefs();
    warehouse = await getwarehouseFromPrefs();

    // Fetch product list based on warehouse
    await fetchProductListid(warehouse);

    // Check if the widget is still mounted before calling setState
    if (mounted) {
      setState(() {
        filteredProducts = products;
      });
    }
  }

  Future<void> _getAndShowVariants(int productId) async {
    await getvariant(
        productId, "type"); // Call your existing getvariant function
    setState(() {
      expandedProducts[productId] = !(expandedProducts[productId] ?? false);
    });
  }

  void _filterProducts(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredProducts = products; // Show all products if search is cleared
      });
    } else {
      setState(() {
        filteredProducts = products
            .where((product) =>
                product['name'].toLowerCase().contains(query.toLowerCase()))
            .toList(); // Filter products by name (case-insensitive)
      });
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

    // Check if warehouseId is null before converting to String
    return warehouseId?.toString();
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

//    Future<void> fetchProductList() async {
//   final token = await getTokenFromPrefs();

//   try {
//     final response = await http.get(
//       Uri.parse("$api/api/products/"),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token',
//       },
//     );

//     if (response.statusCode == 200) {
//       final parsed = jsonDecode(response.body);
//       var productsData = parsed['data'];
//       List<Map<String, dynamic>> productList = [];

//

//       for (var productData in productsData) {
//         List<String> familyNames = (productData['family'] as List<dynamic>?)?.map((id) => id as int).map<String>((id) => fam.firstWhere(
//             (famItem) => famItem['id'] == id,
//             orElse: () => {'name': 'Unknown'})['name'] as String).toList() ?? [];
//         var imgurl = '$api/${productData['image']}';
//
//         // Check if the product type is 'variant'
//         if (productData['type'] == "variant") {
//

//           for (var variant in productData['variant_products']) {
//

//             if (variant['is_variant'] == true && variant['sizes'] != null) {

//                productList.add({
//               'mainid':productData['id'],
//               'id': variant['id'],
//               'is_vaiant':variant['is_variant'],
//               'name': variant['name'],
//               'color': variant['color'],
//               'stock': variant['stock'],
//               'created_user': variant['created_user'],
//               'family': familyNames,
//               'image': variant['variant_images'].isNotEmpty
//                   ? '${variant['variant_images'][0]['image']}'
//                   : imgurl, // Use variant image or fallback to main image
//                'sizes': variant['sizes'],
//             });

//             }
//             // Process each variant product
//             else{
//             productList.add({
//               'mainid':productData['id'],
//               'type':productData['type'],
//               'id': variant['id'],
//               'name': variant['name'],
//               'color': variant['color'],
//               'is_vaiant':variant['is_variant'],
//               'stock': variant['stock'],
//               'created_user': variant['created_user'],
//               'family': familyNames,
//               'image': variant['variant_images'].isNotEmpty
//                   ? '${variant['variant_images'][0]['image']}'
//                   : imgurl, // Use variant image or fallback to main image
//             });}
//           }
//         } else {
//           // Process non-variant products
//           productList.add({
//             'id': productData['id'],
//             'name': productData['name'],
//             'hsn_code': productData['hsn_code'],
//             'type': productData['type'],
//             'unit': productData['unit'],
//             'purchase_rate': productData['purchase_rate'],
//             'tax': productData['tax'],
//             'exclude_price': productData['exclude_price'],
//             'selling_price': productData['selling_price'],
//             'stock': productData['stock'],
//             'created_user': productData['created_user'],
//             'family': familyNames,
//             'image': imgurl,
//           });
//         }
//       }

//       setState(() {
//         products = productList;
//
//         filteredProducts = products;
//       });
//     }
//   } catch (error) {
//
//   }
// }
  var dep;
  void handleAddToCart2(BuildContext context, varid, quantity) async {
    final result = await addtocart2(varid, quantity);

    if (!mounted) return; // Prevent invalid context error

    if (result == "success") {
      showCustomPopup("Success", "Product added to cart successfully!");
    } else if (result == "failed") {
      showCustomPopup("Success", "Product already in cart!");
    } else {
      showCustomPopup("Success", "Failed to add Product!");
    }
  }

  Future<void> fetchProductList() async {
    final token = await getTokenFromPrefs();

    dep = await getdepFromPrefs();

    try {
      final response = await http.get(
        Uri.parse("$api/api/products/"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];
        List<Map<String, dynamic>> productList = [];

        for (var productData in productsData) {
          // Ensure that 'family', 'single_products', and 'variant_products' are non-null and lists
          List<String> familyNames = (productData['family'] as List<dynamic>?)
                  ?.map((id) => id as int)
                  .map<String>((id) => fam.firstWhere(
                      (famItem) => famItem['id'] == id,
                      orElse: () => {'name': 'Unknown'})['name'] as String)
                  .toList() ??
              [];

          // Add the product data to the list
          productList.add({
            'id': productData['id'],
            'variantIDs': productData['variantIDs'],
            'name': productData['name'],
            'hsn_code': productData['hsn_code'],
            'type': productData['type'],
            'unit': productData['unit'],
            'purchase_rate': productData['purchase_rate'],
            'tax': productData['tax'],
            'exclude_price': productData['exclude_price'],
            'selling_price': productData['selling_price'],
            'stock': productData['stock'],
            'created_user': productData['created_user'],
            'family': familyNames, // Add family names here
            'image': productData['image'], // Main product image
            // Don't process single_products or variant_products
          });
        }

        setState(() {
          products = productList;
          filteredProducts = products;
        });
      }
    } catch (error) {}
  }

  Future<void> fetchProductListid(var warehouse) async {
    final token = await getTokenFromPrefs();

    dep = await getdepFromPrefs();

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
        var productsData = parsed['data'];
        List<Map<String, dynamic>> productList = [];

        for (var productData in productsData) {
          if (productData['approval_status'] == "Approved") {
            // Ensure that 'family', 'single_products', and 'variant_products' are non-null and lists
            List<String> familyNames = (productData['family'] as List<dynamic>?)
                    ?.map((id) => id as int)
                    .map<String>((id) => fam.firstWhere(
                        (famItem) => famItem['id'] == id,
                        orElse: () => {'name': 'Unknown'})['name'] as String)
                    .toList() ??
                [];

            // Add the product data to the list
            productList.add({
              'id': productData['id'],
              'variantIDs': productData['variantIDs'],
              'name': productData['name'],
              'hsn_code': productData['hsn_code'],
              'type': productData['type'],
              'unit': productData['unit'],
              'purchase_rate': productData['purchase_rate'],
              'tax': productData['tax'],
              'exclude_price': productData['exclude_price'],
              'selling_price': productData['selling_price'],
              'stock': productData['stock'],
              'locked_stock': productData['locked_stock'],
              'created_user': productData['created_user'],
              'family': familyNames, // Add family names here
              'image': productData['image'], // Main product image
              // Don't process single_products or variant_products
            });
          }
        }

        setState(() {
          products = productList;
          filteredProducts = products;
        });
      }
    } catch (error) {}
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

  Future<void> getvariant(int id, var type) async {
    try {
      final token = await getTokenFromPrefs();
      List<Map<String, dynamic>> productList = [];

      var response = await http.get(
        Uri.parse('$api/api/products/$id/variants/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['products'];

        for (var product in productsData) {
          if (product['is_variant'] == false) {
            // Add product details for non-variant product
            productList.add({
              'name': product['name'],
              'color': product['color'],
              'stock': product['stock'],
            });
          } else {
            // Add product details including the first image and sizes for variant product
            String firstImageUrl = product['variant_images'].isNotEmpty
                ? product['variant_images'][0]['image']
                : '';
            var imgurl = "$firstImageUrl";

            // Extract sizes as a list of maps with attribute and stock
            List<Map<String, dynamic>> sizesList =
                product['sizes'].map<Map<String, dynamic>>((size) {
              return {
                'attribute': size['attribute'],
                'stock': size['stock'],
              };
            }).toList();

            productList.add({
              'name': product['name'],
              'color': product['color'],
              'image': imgurl,
              'is_variant': product['is_variant'],
              'sizes': sizesList, // Add sizes list
            });
          }
        }

        setState(() {
          variant = productList;
        });
      }
    } catch (error) {}
  }

  void showCustomPopup(String title, String message) {
    if (!mounted) return;

    showDialog(
      context: context, // 👈 Use context directly
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void handleAddToCart(BuildContext context, varid, quantity) async {
    final result = await addtocart(varid, quantity);

    if (!mounted) return; // Prevent invalid context error

    if (result == "success") {
      showCustomPopup("Success", "Product added to cart successfully!");
    } else if (result == "failed") {
      showCustomPopup("Success", "Product already in cart!");
    } else {
      showCustomPopup("Success", "Failed to add Product!");
    }
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
        body: jsonEncode({
          'product': varid,
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 201) {
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

  Future<String> addtocart2(mainid, quantity) async {
    final token = await getTokenFromPrefs();
    try {
      final response = await http.post(
        Uri.parse('$api/api/cart/product/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'product': mainid,
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 201) {
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

  void showSizeDialog2(BuildContext context, List variants) {
    // Filter only approved variants
    List approvedVariants =
        variants.where((v) => v['approval_status'] == 'Approved').toList();

    ValueNotifier<Map<String, dynamic>?> selectedProductNotifier =
        ValueNotifier(null);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        TextEditingController quantityController = TextEditingController();

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Select Variant",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),

                  // Display the selected product as the "Selected Option"
                  ValueListenableBuilder<Map<String, dynamic>?>(
                    valueListenable: selectedProductNotifier,
                    builder: (context, selectedProduct, child) {
                      if (selectedProduct != null) {
                        return Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.blue, width: 2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.all(10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  selectedProduct['image'] != null &&
                                          selectedProduct['image'].isNotEmpty
                                      ? Image.network(
                                          '$api${selectedProduct['image']}',
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.grey[300],
                                          child: Icon(Icons.image_not_supported,
                                              color: Colors.grey),
                                        ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          selectedProduct['name'],
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                            "Stock: ${selectedProduct['stock']}"),
                                        Text(
                                            "Price: ${selectedProduct['selling_price']}"),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 20),
                          ],
                        );
                      } else {
                        return SizedBox.shrink();
                      }
                    },
                  ),

                  // Display the approved variants
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: approvedVariants.length,
                    itemBuilder: (context, index) {
                      var variant = approvedVariants[index];
                      return ListTile(
                        leading: variant['image'] != null &&
                                variant['image'].isNotEmpty
                            ? Image.network(
                                '$api${variant['image']}',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[300],
                                child: Icon(Icons.image_not_supported,
                                    color: Colors.grey),
                              ),
                        title: Text(variant['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Stock: ${variant['stock']}"),
                            Text("Locked Stock: ${variant['locked_stock']}",
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        trailing: selectedProductNotifier.value == variant
                            ? Icon(Icons.check_circle, color: Colors.green)
                            : null,
                        onTap: () {
                          selectedProductNotifier.value = variant;
                        },
                      );
                    },
                  ),

                  SizedBox(height: 20),

                  // Quantity input
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

                  SizedBox(height: 20),

                  // Add to Cart button
                  SizedBox(
                    height: 50,
                    width: 300,
                    child: ElevatedButton(
                      onPressed: () {
                        if (selectedProductNotifier.value == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text("Please select a product first!")),
                          );
                          return;
                        }

                        var selectedProduct = selectedProductNotifier.value;
                        int quantity =
                            int.tryParse(quantityController.text) ?? 1;

                        if (quantity >
                            (selectedProduct!['stock'] -
                                selectedProduct['locked_stock'])) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text("Quantity exceeds available stock!")),
                          );
                          return;
                        }
                        if (selectedProduct!['stock'] == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("No stock Available")),
                          );
                          return;
                        }

                        handleAddToCart(
                            context, selectedProduct['id'], quantity);

                        Navigator.of(context).pop();
                      },
                      child: Text("ADD TO CART",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
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

  void showSizeDialog3(BuildContext context, mainid, stock, lockedstock) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        String selectedColor = '';
        String selectedSize = '';
        int? selectedSizeId;
        int? selectedStock; // Variable to store the selected stock
        TextEditingController quantityController =
            TextEditingController(); // Controller for quantity input

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: SingleChildScrollView(
                  // Make the content scrollable if needed
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (stock !=
                          null) // Show stock info only if a size is selected
                        Container(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              'Available Stock: $stock',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                          ),
                        ),
                      if (lockedstock !=
                          null) // Show locked stock info only if a size is selected
                        Container(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              'Locked Stock: $lockedstock',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      const Color.fromARGB(255, 128, 128, 128)),
                            ),
                          ),
                        ),
                      SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SizedBox(
                          width: 300, // Set the desired width here
                          height: 40,
                          child: TextField(
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Enter Quantity',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 50,
                        width: 300,
                        child: ElevatedButton(
                          onPressed: () {
                            // Get the entered quantity value
                            int quantity =
                                int.tryParse(quantityController.text) ?? 1;

                            // Add logic for adding to cart, using selectedSizeId and quantity

                            if (quantity > (stock - lockedstock)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        "Quantity exceeds available stock!")),
                              );
                              return;
                            }
                            if (stock == 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("No stock Available")),
                              );
                              return;
                            }
                            // Call add to cart function
                            handleAddToCart2(context, mainid, quantity);

                            // Close the dialog after adding to cart
                            Navigator.of(context).pop();
                          },
                          child: Text("ADD TO CART",
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
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
      },
    );
  }

  List<Map<String, dynamic>> extractSizeList(List<dynamic> sizes) {
    return sizes.map((size) {
      return {
        'id': size['id'],
        'attribute': size['attribute'],
        'stock': size['stock'],
      };
    }).toList();
  }

  List<String> extractStringList(List<dynamic> list, String key) {
    if (list is List) {
      return list.map((item) {
        if (item is Map && item.containsKey(key)) {
          return item[key]?.toString() ?? '';
        }
        return '';
      }).toList();
    }
    return [];
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
    }
        else if (dep == "SD") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                SdDashboard()), // Replace AnotherPage with your target page
      );
    }
     else if (dep == "BDM") {
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
        backgroundColor: const Color.fromARGB(246, 255, 255, 255),
        appBar: AppBar(
          title: Text(
            "Product List",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
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
              }
                  else if (dep == "SD") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                SdDashboard()), // Replace AnotherPage with your target page
      );
    }
               else if (dep == "BDM") {
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
                  MaterialPageRoute(
                      builder: (context) =>
                          dashboard()), // Replace AnotherPage with your target page
                );
              }
            },
          ),
          actions: [
            // Cart icon with badge
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Stack(
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.shopping_cart, color: Colors.grey),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Performa_Cart()),
                      );
                    },
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      constraints: BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Container(
          child: Column(
            children: [
              if (dep == 'COO' || dep == 'ADMIN' || dep == 'Accounts')
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30.0),
                      border: Border.all(color: Colors.grey),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: selectedwarehouseId,
                      hint: Text('Select a Warehouse'),
                      underline: SizedBox(), // Remove the default underline
                      onChanged: (int? newValue) {
                        setState(() {
                          selectedwarehouseId = newValue;
                          selectedwarehouseName = Warehouses.firstWhere(
                              (element) => element['id'] == newValue)['name'];
                          fetchProductListid(newValue!);
                        });
                      },
                      items:
                          Warehouses.map<DropdownMenuItem<int>>((Warehouses) {
                        return DropdownMenuItem<int>(
                          value: Warehouses['id'],
                          child: Text(Warehouses['name']),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Search products...",
                    prefixIcon: Icon(Icons.search),
                    fillColor:
                        Colors.white, // Set your desired background color
                    filled: true, // Enable background color
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(
                        color: Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(
                        color: Colors.blue,
                        width: 2.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(
                        color: Colors.grey,
                        width: 1.0,
                      ),
                    ),
                  ),
                  onChanged: (query) {
                    _filterProducts(
                        query); // Filter the products as the user types
                  },
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () {
                    return fetchProductListid(warehouse);
                  },
                  child: ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];

                      final isExpanded =
                          expandedProducts[product['id']] ?? false;

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
                                    offset: Offset(0, 3),
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
                                                Icon(Icons.error),
                                      )
                                    : Icon(Icons.image_not_supported),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${product['name']}",
                                      style: TextStyle(fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (product['color'] != null &&
                                        product['color']
                                            .isNotEmpty) // Display color if it exists
                                      Text(
                                        "Color: ${product['color']}",
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                  ],
                                ),
                                trailing: ElevatedButton.icon(
                                  onPressed: () {
                                    if (product['is_vaiant'] == true) {
                                      // Ensure colors are non-null before passing to extractStringList
                                      List<String> colors = extractStringList(
                                          product['colors'] ?? [],
                                          'color_name');
                                      List<Map<String, dynamic>> sizes =
                                          extractSizeList(
                                              product['sizes'] ?? []);

                                      // showSizeDialog(
                                      //   context,
                                      //   colors,
                                      //   sizes,
                                      //   product['mainid'],
                                      //   product['id'],
                                      // );
                                    } else if (product['type'] == 'variant') {
                                      showSizeDialog2(
                                          context, product['variantIDs']);
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
                                        : Icons.view_agenda,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    product['type'] == 'single'
                                        ? "Add"
                                        : "View",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 10),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        product['type'] == 'single' ||
                                                product['is_vaiant'] == false
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
                            // Display variant list if expanded
                            if (isExpanded &&
                                product['variant_products'] != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 8.0, left: 10, right: 10),
                                child: Column(
                                  children: product['variant_products']
                                      .map<Widget>((variantProduct) {
                                    return Container(
                                      height: 70,
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
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          if (variantProduct['image'] != null &&
                                              variantProduct['image']
                                                  .isNotEmpty)
                                            Image.network(
                                              variantProduct['image'],
                                              width: 65,
                                              height: 65,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  Icon(Icons.error),
                                            )
                                          else
                                            Icon(Icons.image_not_supported),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              "${variantProduct['name']} - ${variantProduct['color']} - Stock: ${variantProduct['stock']}",
                                              style: TextStyle(fontSize: 12),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
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
      ),
    );
  }

  @override
  void dispose() {
    // Cancel any ongoing operations
    timer?.cancel();
    super.dispose();
  }
}
