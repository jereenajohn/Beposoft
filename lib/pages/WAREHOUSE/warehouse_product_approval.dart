import 'dart:convert';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/add_attribute.dart';
import 'package:beposoft/pages/ACCOUNTS/add_bank.dart';
import 'package:beposoft/pages/ACCOUNTS/add_company.dart';
import 'package:beposoft/pages/ACCOUNTS/add_department.dart';
import 'package:beposoft/pages/ACCOUNTS/add_family.dart';
import 'package:beposoft/pages/ACCOUNTS/add_product_variant.dart';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
import 'package:beposoft/pages/ACCOUNTS/add_state.dart';
import 'package:beposoft/pages/ACCOUNTS/add_supervisor.dart';
import 'package:beposoft/pages/ACCOUNTS/customer.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/methods.dart';
import 'package:beposoft/pages/ACCOUNTS/view_cart.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Approve_products extends StatefulWidget {
  const Approve_products({super.key});

  @override
  State<Approve_products> createState() => _Approve_productsState();
}

class _Approve_productsState extends State<Approve_products> {
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
  var mainid;
  var varid;
  Map<int, bool> expandedProducts = {}; // Track expanded state for products
  List<Map<String, dynamic>> fam = [];
  List<Map<String, dynamic>> products = [];
  List<bool> _checkboxValues = [];
  List<Map<String, dynamic>> filteredProducts = [];
  List<Map<String, dynamic>> variant= [];
  int? selectedwarehouseId; // Variable to store the selected department's ID
    String? selectedwarehouseName;

  List<Map<String, dynamic>> Warehouses = [];

  TextEditingController searchController =TextEditingController(); // Search controller

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

  // if(warehouse=="0"){
    
  //  await  fetchProductList();
  //   setState(() {
  //   filteredProducts = products;
  // });
  // }
  
    
  await  fetchProductListid(warehouse);
   setState(() {
    filteredProducts = products;
  });
  

 
}


Future<void> _getAndShowVariants(int productId) async {
    await getvariant(productId, "type"); // Call your existing getvariant function
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
          await http.get(Uri.parse('$api/api/warehouse/add/'), 
          headers: {
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
    } catch (e) {
      
    }
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

Future<void> fetchProductList() async {
  final token = await getTokenFromPrefs();
 
 
dep= await getdepFromPrefs();
 

  try {
    final response = await http.get(
      Uri.parse("$api/api/approved/products/"),
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
        List<String> familyNames = (productData['family'] as List<dynamic>?)?.map((id) => id as int).map<String>((id) => fam.firstWhere(
            (famItem) => famItem['id'] == id,
            orElse: () => {'name': 'Unknown'})['name'] as String).toList() ?? [];

        // Add the product data to the list
        productList.add({
          'id': productData['id'],
          'variantIDs':productData['variantIDs'],
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
        filteredProducts=products;
      });
    }
  } catch (error) {
    
  }
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
        // Filter products with "approval_status": "Disapproved"
        
          List<String> familyNames = (productData['family'] as List<dynamic>?)?.map((id) => id as int).map<String>((id) => fam.firstWhere(
              (famItem) => famItem['id'] == id,
              orElse: () => {'name': 'Unknown'})['name'] as String).toList() ?? [];
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
            'approval_status': productData['approval_status'],
            'selling_price': productData['selling_price'],
            'stock': productData['stock'],
            'created_user': productData['created_user'],
            'family': familyNames, // Add family names here
            'image': productData['image'], // Main product image
          });

      }

      setState(() {
        products = productList;
        filteredProducts = products;
      });
    }
  } catch (error) {
    // Handle error
  }
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
          List<Map<String, dynamic>> sizesList = product['sizes'].map<Map<String, dynamic>>((size) {
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
  } catch (error) {
    
  }
}


Future<void> updateproduct( var productId) async {
  
  try {
    final token = await getTokenFromPrefs();

    var response = await http.put(
      Uri.parse('$api/api/product/update/${productId}/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(
        {
          'approval_status': 'Approved',
        },
      ),
    );
  
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('updated successfully'),
          duration: Duration(seconds: 2),
        ),
      );
      var warehouse = await getwarehouseFromPrefs();
      fetchProductListid(warehouse);

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  } 
  catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error updating shipping charge'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

Future<void> addtocart(BuildContext scaffoldContext,varid,quantity) async{
    final token = await getTokenFromPrefs();
 try{
   final response= await http.post(Uri.parse('$api/api/cart/product/'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
  body:jsonEncode(
    {
     'product':varid,
     'quantity':quantity
    }
  )
  );
   

      if (response.statusCode == 201) {
       ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
             backgroundColor: Colors.green,
            content: Text(' added Successfully.'),
          ),
        );
        // Navigator.push(context, MaterialPageRoute(builder: (context)=>add_bank()));
      } else {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Adding Bank failed.'),
          ),
        );
      }
 }
 catch(e){
  
 }
}

Future<void> addtocart2(BuildContext scaffoldContext,mainid,quantity) async{
    final token = await getTokenFromPrefs();
 try{
   final response= await http.post(Uri.parse('$api/api/cart/product/'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
  body:jsonEncode(
    {
     'product':mainid,
     'quantity':quantity
    }
  )
  );
   
   
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
             backgroundColor: Colors.green,
            content: Text('Bank added Successfully.'),
          ),
        );
        // Navigator.push(context, MaterialPageRoute(builder: (context)=>add_bank()));
      } else {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Adding Bank failed.'),
          ),
        );
      }
 }
 catch(e){
  
 }
}
// 

void showSizeDialog2(BuildContext context, var products) {
  
  List variants = products['variantIDs'].where((variant) => variant['approval_status'] == "Disapproved").toList();

  // Create a ValueNotifier to track the selected product
  ValueNotifier<Map<String, dynamic>?> selectedProductNotifier = ValueNotifier(null);

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

                // Display the main product details
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      products['image'] != null && products['image'].isNotEmpty
                          ? Image.network(
                              '$api${products['image']}',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[300],
                              child: Icon(Icons.image_not_supported, color: Colors.grey),
                            ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              products['name'],
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text("HSN Code: ${products['hsn_code']}"),
                            Text("Unit: ${products['unit']}"),
                            Text("Purchase Rate: \$${products['purchase_rate']}"),
                            Text("Tax: ${products['tax']}%"),
                            Text("Selling Price: \$${products['selling_price']}"),
                            Text("Stock: ${products['stock']}"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Approve button for the main product
                SizedBox(
                  height: 50,
                  width: 300,
                  child: ElevatedButton(
                    onPressed: products['approval_status'] == "Approved" ? null : () {
                      // Approve the main product
                      updateproduct(products['id']);
                      // Close the dialog
                      Navigator.of(context).pop();
                    },
                    child: Text("Approve Main Product", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: products['approval_status'] == "Approved" ? Colors.grey : Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                ValueListenableBuilder<Map<String, dynamic>?>(
                  valueListenable: selectedProductNotifier,
                  builder: (context, selectedProduct, child) {
                    if (selectedProduct != null) {

                      return Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue, width: 2),
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
                                        child: Icon(Icons.image_not_supported, color: Colors.grey),
                                      ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedProduct['name'],
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      Text("Stock: ${selectedProduct['stock']}"),
                                      Text("Price: \$${selectedProduct['selling_price']}"),
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

                // Display the variants
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: variants.length,
                  itemBuilder: (context, index) {
                    var variant = variants[index];
                    return ListTile(
                      leading: variant['image'] != null && variant['image'].isNotEmpty
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
                              child: Icon(Icons.image_not_supported, color: Colors.grey),
                            ),
                      title: Text(variant['name']),
                      subtitle: Text("Stock: ${variant['stock']}"),
                      trailing: selectedProductNotifier.value == variant
                          ? Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () {
                        // Update the selected product using ValueNotifier
                        selectedProductNotifier.value = variant;
                      },
                    );
                  },
                ),

                SizedBox(height: 20),

                // Approve button for the selected variant
                SizedBox(
                  height: 50,
                  width: 300,
                  child: ElevatedButton(
                    onPressed: () {
                      if (selectedProductNotifier.value == null) {
                        // Show an error if no product is selected
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Please select a product first!")),
                        );
                        return;
                      }

                      // Get the selected product and entered quantity
                      var selectedProduct = selectedProductNotifier.value;
                      int quantity = int.tryParse(quantityController.text) ?? 1;

                      // Call update product function
                      if (selectedProduct != null) {
                        updateproduct(selectedProduct['id']);
                      }

                      // Close the dialog
                      Navigator.of(context).pop();
                    },
                    child: Text("Approve Selected Variant", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

void showSizeDialog3(BuildContext context, mainid, stock) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      String selectedColor = '';
      String selectedSize = '';
      int? selectedSizeId;
      int? selectedStock; // Variable to store the selected stock
      TextEditingController quantityController = TextEditingController(); // Controller for quantity input

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: SingleChildScrollView( // Make the content scrollable if needed
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (stock != null) // Show stock info only if a size is selected
                      Container(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'Available Stock: $stock',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
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
                          int quantity = int.tryParse(quantityController.text) ?? 1;
                      
                          // Add logic for adding to cart, using selectedSizeId and quantity
                          
                          
                      
                          // Call add to cart function
                          addtocart2(context, mainid,quantity);
                      
                          // Close the dialog after adding to cart
                          Navigator.of(context).pop();
                        },
                        child: Text("ADD TO CART", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
   if(dep=="BDO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => bdo_dashbord()), // Replace AnotherPage with your target page
            );

}
else if(dep=="BDM" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => bdm_dashbord()), // Replace AnotherPage with your target page
            );
}
else if(dep=="warehouse" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => WarehouseDashboard()), // Replace AnotherPage with your target page
            );
}
else if(dep=="CEO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ceo_dashboard()), // Replace AnotherPage with your target page
            );
}
else if(dep=="COO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ceo_dashboard()), // Replace AnotherPage with your target page
            );
}


else if(dep=="Warehouse Admin" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => WarehouseAdmin()), // Replace AnotherPage with your target page
            );
}else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => dashboard()),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(246, 255, 255, 255),
      appBar: AppBar(
        title: Text(
          "Product List",
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
     leading:IconButton(
            icon: const Icon(Icons.arrow_back), // Custom back arrow
            onPressed: () async{
                      final dep= await getdepFromPrefs();
     if(dep=="BDO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => bdo_dashbord()), // Replace AnotherPage with your target page
            );

}
else if(dep=="BDM" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => bdm_dashbord()), // Replace AnotherPage with your target page
            );
}
else if(dep=="warehouse" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => WarehouseDashboard()), // Replace AnotherPage with your target page
            );
}
else if(dep=="Warehouse Admin" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => WarehouseAdmin()), // Replace AnotherPage with your target page
            );
}
else if(dep=="CEO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ceo_dashboard()), // Replace AnotherPage with your target page
            );
}
else if(dep=="COO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ceo_dashboard()), // Replace AnotherPage with your target page
            );
}
 
      else {
      Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => dashboard()), // Replace AnotherPage with your target page
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
                      MaterialPageRoute(builder: (context) => View_Cart()),
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
    
          
    Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
    controller: searchController,
    decoration: InputDecoration(
      hintText: "Search products...",
      prefixIcon: Icon(Icons.search),
      fillColor: Colors.white, // Set your desired background color
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
      _filterProducts(query); // Filter the products as the user types
    },
      ),
    ),
    
    
    
     Expanded(
      child: RefreshIndicator(
    onRefresh: () {
      return fetchProductList();
    },
    child: ListView.builder(
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        ;
        final isExpanded = expandedProducts[product['id']] ?? false;
    
        return Padding(
          padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
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
                      color: const Color.fromARGB(255, 210, 209, 209).withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: product['image'] != null && product['image'].isNotEmpty
                      ? Image.network(
                          '$api${product['image']}',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
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
                     Text(
  "${product['approval_status']}",
  style: TextStyle(
    fontSize: 14,
    color: product['approval_status'] == "Approved" ? Colors.green : Colors.red,
  ),
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
),
                      if (product['color'] != null && product['color'].isNotEmpty) // Display color if it exists
                        Text(
                          "Color: ${product['color']}",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        
                    ],
                  ),
                  trailing: ElevatedButton.icon(
                  onPressed: () {
    if (product['is_vaiant'] == true) {
      
      // Ensure colors are non-null before passing to extractStringList
      List<String> colors = extractStringList(product['colors'] ?? [], 'color_name');
      List<Map<String, dynamic>> sizes = extractSizeList(product['sizes'] ?? []);
      
      // showSizeDialog(
      //   context,
      //   colors,
      //   sizes,
      //   product['mainid'],
      //   product['id'],
      // );
    }
    else if(product['type'] == 'variant'){
          
    
      showSizeDialog2(
        context,
       product );
    
    }
    else if(product['type']=='single'){
      updateproduct(product['id']);
      
     
    }
    
    },
    
                    icon: Icon(
                      product['type'] == 'single' ? Icons.add : Icons.view_agenda,
                      size: 14,
                      color: Colors.white,
                    ),
                    label: Text(
                      product['type'] == 'single' ? "Approve" : "View",
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: product['type'] == 'single' || product['is_vaiant'] == false ? Colors.green : Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(60, 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
              ),
              // Display variant list if expanded
              if (isExpanded && product['variant_products'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 10, right: 10),
                  child: Column(
                    children: product['variant_products'].map<Widget>((variantProduct) {
                      return Container(
                        height: 70,
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
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            if (variantProduct['image'] != null && variantProduct['image'].isNotEmpty)
                              Image.network(
                                variantProduct['image'],
                                width: 65,
                                height: 65,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
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
    
    );
  }
}
