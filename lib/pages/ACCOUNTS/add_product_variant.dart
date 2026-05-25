import 'dart:convert';
import 'dart:io';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/product_list.dart';
import 'package:beposoft/pages/ACCOUNTS/update_peoduct.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'add_state.dart';

class add_product_variant extends StatefulWidget {
  final id;
  final type;
  const add_product_variant({super.key, required this.id, required this.type});

  @override
  State<add_product_variant> createState() => _add_product_variantState();
}

class _add_product_variantState extends State<add_product_variant> {
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

 Widget buildProductTable() {
  String formatStock(dynamic value) {
    if (value == null) return "0";

    final double? stockValue = double.tryParse(value.toString());

    if (stockValue == null) return "0";

    if (stockValue == stockValue.toInt()) {
      return stockValue.toInt().toString();
    }

    return stockValue.toStringAsFixed(2);
  }

  Widget stockBadge(dynamic stockValue) {
    final double stock = double.tryParse(stockValue?.toString() ?? "0") ?? 0;
    final bool isOutOfStock = stock <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isOutOfStock
            ? const Color(0xFFFFEBEE)
            : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOutOfStock
              ? const Color(0xFFFFCDD2)
              : const Color(0xFFBFDBFE),
        ),
      ),
      child: Text(
        isOutOfStock ? "Out" : formatStock(stockValue),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isOutOfStock
              ? const Color(0xFFD32F2F)
              : const Color(0xFF1D4ED8),
        ),
      ),
    );
  }

  if (widget.type == 'single') {
    if (singleProducts.isNotEmpty) {
      final product = singleProducts.first;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 35,
          headingRowHeight: 40,
          dataRowMinHeight: 58,
          dataRowMaxHeight: 68,
          columns: const <DataColumn>[
            DataColumn(
              label: Text(
                'Name',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Image',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Stock',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Actions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
          rows: [
            DataRow(
              cells: <DataCell>[
                DataCell(
                  SizedBox(
                    width: 150,
                    child: Text(
                      product['name']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                DataCell(
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      '$api${product['image']}',
                      width: 45,
                      height: 45,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 45,
                          height: 45,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 20,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                DataCell(
                  stockBadge(product['stock']),
                ),
                DataCell(
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => update_product(
                            id: product['id'],
                            type: widget.type,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: const Size(55, 28),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No products available'),
      );
    }
  } else if (widget.type == 'variant') {
    if (variantProducts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No variant products available'),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 35,
        headingRowHeight: 40,
        dataRowMinHeight: 58,
        dataRowMaxHeight: 68,
        columns: const <DataColumn>[
          DataColumn(
            label: Text(
              'Name',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Image',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Stock',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Actions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
        rows: variantProducts.map((variant) {
          return DataRow(
            cells: <DataCell>[
              DataCell(
                SizedBox(
                  width: 150,
                  child: Text(
                    variant['name']?.toString() ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              DataCell(
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    '${api}${variant['image']}',
                    width: 45,
                    height: 45,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 45,
                        height: 45,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 20,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ),
              DataCell(
                stockBadge(variant['stock']),
              ),
              DataCell(
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => update_product(
                          id: variant['id'],
                          type: widget.type,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: const Size(55, 28),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  } else {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Text('No products available'),
    );
  }
}

// Method to handle editing a product
  void _editProduct(Map<String, dynamic> product) {
    // Add your edit functionality here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editing: ${product['name']}'),
      ),
    );
  }

  TextEditingController name = TextEditingController();
  TextEditingController product = TextEditingController();
  final TextEditingController textEditingController = TextEditingController();

  List<Map<String, dynamic>> fam = [];
  List<bool> _checkboxValues = [];
  List<Map<String, dynamic>> attribute = [];
  List<Map<String, dynamic>> valuess = [];
  List<Map<String, dynamic>> variantProducts = [];
  List<Map<String, dynamic>> singleProducts = [];
 List<Map<String, dynamic>> attributesToSend = []; 
  @override
  void initState() {
    super.initState();
    getprofiledata();
    getvariant();
    getattributes();
    

    
  }

  @override
  void dispose() {
    name.dispose(); // Dispose the controller when the widget is removed
    super.dispose();
  }

  List<File> selectedImagesList =
      []; // Single list to store all selected images

  bool flag = false;
  List<String> selectedValues = [];
  String? selectedAttributeName; // Store the selected attribute name
  int? selectedAttributeId; // Store the selected attribute ID
  Future<void> getattributes() async {
    try {
      final token = await gettokenFromPrefs();
      final response = await http.get(
        Uri.parse('$api/api/product/attributes/'),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token',
        },
      );

      

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        List<Map<String, dynamic>> attributelist = [];

        for (var productData in parsed) {
          attributelist.add({
            'id': productData['id'],
            'name': productData['name'],
          });
        }

        setState(() {
          attribute = attributelist;
          
        });
      }
    } catch (error) {
      
    }
  }

  var image;
  final ImagePicker _picker = ImagePicker();
  int imagePickerCount = 1; // To keep track of the number of image pickers
  // Function to pick an image from the gallery
  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImagesList
            .add(File(pickedFile.path)); // Store image in the single list
      });
    }
  }

  
  Future<void> pickImagemain() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        image = File(pickedFile.path);
      });
    }
  }
Future<void> updateProductImage(
      BuildContext scaffoldContext, File newImage) async {
    final token = await gettokenFromPrefs();

    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse(
            "$api/api/product/update/${widget.id}/"), // Use the global product ID
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Check if new image is provided
      if (newImage != null) {
        // Add the image file to the request
        request.files
            .add(await http.MultipartFile.fromPath('image', newImage.path));
      } else {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text('Please select a valid image.'),
          ),
        );
        return;
      }

      // Send the request
      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      
      

      if (responseData.statusCode == 200) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text('Image updated successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text('Image is not Updated'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
        ),
      );
    }
  }
  void addimage(
    BuildContext scaffoldContext,
  ) async {
    var slug = name.text.toUpperCase().replaceAll(' ', '-');

    final token = await gettokenFromPrefs();

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$api/api/image/add/${widget.id}/"),
      );

      // Add headers
      request.headers.addAll({
        "Content-Type": "multipart/form-data",
        'Authorization': 'Bearer $token',
      });

      request.fields['product'] = widget.id.toString();
      for (File imageFile in selectedImagesList) {
        var stream = http.ByteStream(imageFile.openRead());
        var length = await imageFile.length();
        var multipartFile = http.MultipartFile(
          'images', // The name 'images' must match your backend field name
          stream,
          length,
          filename: imageFile.path.split('/').last,
        );

        
        request.files.add(multipartFile);
      }

      // Send the request
      var response = await request.send();
      var responseData = await http.Response.fromStream(response);
;
      

      if (responseData.statusCode == 201) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text('Image added successfully.'),
          ),
        );
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => Product_List()));
      } else if (responseData.statusCode == 500) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text('Session expired.'),
          ),
        );
        // Navigator.push(
        //     context, MaterialPageRoute(builder: (context) => Login_Page()));
      } else if (responseData.statusCode == 400) {
        Map<String, dynamic> responseDataBody = jsonDecode(responseData.body);
        Map<String, dynamic> data = responseDataBody['data'];
        String errorMessage =
            data.entries.map((entry) => entry.value[0]).join('\n');
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Error"),
              content: Text(errorMessage),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
      } else {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text('Something went wrong. Please try again later.'),
          ),
        );
      }
    } catch (e) {
      ;
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          content: Text('Enter valid information'),
        ),
      );
    }
  }

  Future<void> getvalues(int attributeId) async {
    final token = await gettokenFromPrefs();

    try {
      // Fetch values for the selected attribute ID
      var response = await http.get(
        Uri.parse('$api/api/product/attribute/$attributeId/values/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> valuesList = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        

        // Iterate through the fetched data and only include values with the correct attribute ID
        for (var valueData in parsed) {
          if (valueData['attribute'] == attributeId) {
            valuesList.add({
              'id': valueData['id'],
              'value': valueData['value'],
              'attribute': valueData['attribute'],
            });
          }
        }

        // Update the state with the fetched values
        setState(() {
          valuess = valuesList;
          
        });
      } else {
        throw Exception("Failed to load values for attribute $attributeId");
      }
    } catch (error) {
      
    }
  }

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
var groupid;
  var viewprofileurl = "$api/api/profile/";
  String? selectedValue;
  Future<void> getprofiledata() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$viewprofileurl'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        

        setState(() {
          name.text = productsData['name'] ?? '';
        });
      }
    } catch (error) {
      
    }
  }

 Future<void> getvariant() async {
  try {
    final token = await gettokenFromPrefs();
    
    var response = await http.get(
      Uri.parse('$api/api/products/${widget.id}/variants/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
;
    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);
      var productData = parsed['products']; // Map of the product
      var variantIDs = productData['variantIDs']; // List of variants

      if (variantIDs is List) {
        setState(() {
          // Handle response based on widget.type
          if (widget.type == 'single') {
            singleProducts = [productData]; // Single product as a list
            if (singleProducts.isNotEmpty) {
              product.text = singleProducts[0]['name'] ?? '';
              
            }
          } else if (widget.type == 'variant') 
          {
            variantProducts = List<Map<String, dynamic>>.from(variantIDs); // List of variants
            ;
            if (variantProducts.isNotEmpty) {
              product.text = variantProducts[0]['name'] ?? '';
              groupid=variantProducts[0]['groupID'];
              ;

              
            }
          }
        });

        
      } else {
        
      }
    } else {
      
    }
  } catch (error) {
    
  }
}

  void addvariant(BuildContext scaffoldContext) async {
  
  try {
    final token = await gettokenFromPrefs();

    String attributesJson = jsonEncode(attributesToSend);

    // Prepare the final JSON body
    String jsonString = jsonEncode({
      'product': widget.id.toString(), // Ensure product ID is a string
      'attributes': attributesJson,   // Send attributes as a JSON string
    });

    var response = await http.post(
      Uri.parse('$api/api/add/product/variant/'),
      headers: {
        "Content-Type": "application/json",
        'Authorization': 'Bearer $token',
      },
      body: jsonString,
    );
;
    // Debugging output
    
    

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          content: Text('Product added successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => add_product_variant(
                    id: widget.id,
                    type: widget.type,
                  )));
    } else {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Adding product failed: ${response.body}'),
        ),
      );
    }
  } catch (e) {
    ;
    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
      SnackBar(
        content: Text('Enter valid information: ${e.toString()}'),
      ),
    );
  }
}

 
  Future<void> deleteProduct(int productId, BuildContext context) async {
    final token = await gettokenFromPrefs();

    try {
      final url = '$api/api/product/update/$productId/';

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      
            


      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Deleted successfully'),
          ),
        );

        // Refresh the products after deletion
        setState(() {
          if (widget.type == 'single') {
            singleProducts.removeWhere((product) => product['id'] == productId);
          } else {
            variantProducts
                .removeWhere((variant) => variant['id'] == productId);
          }
        });
      } else {
        throw Exception('Failed to delete variant product with ID: $productId');
      }
    } catch (error) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed to delete variant product. Please try again.'),
        ),
      );
    }
  }
Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(242, 255, 255, 255),
      appBar: AppBar(
           title: Text(
          "Add Product Variant",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Custom back arrow
          onPressed: () async{
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Image.asset('lib/assets/profile.png'),
            onPressed: () {},
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 30, left: 12, right: 12),
          child: Container(
            color: Colors.white,
            width: 700,
            child: Column(
              children: [
                SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Create Variant Product",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(
                  height: 15,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    elevation: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                            10.0), // Set border radius for Container
                        border: Border.all(
                            color: Color.fromARGB(255, 236, 236,
                                236)), // Add border to Container if needed
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(13.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Managed User",
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            TextField(
                              controller: name,
                              decoration: InputDecoration(
                                hintText: name.text,
                                enabled: false,
                  
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 8.0), // Set vertical padding
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              "product",
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            TextField(
                              controller: product,
                              decoration: InputDecoration(
                                hintText: product.text,
                                enabled: false,
                  
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 10.0),
                  
                                // Set vertical padding
                              ),
                            ),
                            // SizedBox(
                            //   height: 10,
                            // ),

                            // TextFormField(
                            //   readOnly: true,
                            //   decoration: InputDecoration(
                            //     labelText: 'Select Main Image',
                            //     border: OutlineInputBorder(
                            //       borderRadius: BorderRadius.circular(10.0),
                            //       borderSide: BorderSide(color: Colors.grey),
                            //     ),
                            //     suffixIcon: IconButton(
                            //       icon: Icon(Icons.image),
                            //       onPressed: () =>
                            //           pickImagemain(), // Trigger image picker for this index
                            //     ),
                            //   ),
                            // ),
                            // SizedBox(height: 10),
                            // if (image != null)
                            //   Column(
                            //     crossAxisAlignment: CrossAxisAlignment.start,
                            //     children: [
                            //       Image.file(
                            //         File(image
                            //             .path), // Use the file path obtained from the picked image
                            //         width: 100, // Set the desired width
                            //         height: 100, // Set the desired height
                            //         fit: BoxFit.cover, // Set the fit style
                            //       ),
                            //       SizedBox(height: 10),
                            //     ],
                            //   ),
                  
                            // if (widget.type != "single")
                            //   Column(
                            //     children:
                            //         List.generate(imagePickerCount, (index) {
                            //       return Column(
                            //         crossAxisAlignment:
                            //             CrossAxisAlignment.start,
                            //         children: [
                            //           TextFormField(
                            //             readOnly: true,
                            //             decoration: InputDecoration(
                            //               labelText: 'Select Image',
                            //               border: OutlineInputBorder(
                            //                 borderRadius:
                            //                     BorderRadius.circular(10.0),
                            //                 borderSide:
                            //                     BorderSide(color: Colors.grey),
                            //               ),
                            //               suffixIcon: IconButton(
                            //                 icon: Icon(Icons.image),
                            //                 onPressed: () =>
                            //                     pickImage(), // Trigger image picker for this index
                            //               ),
                            //             ),
                            //           ),
                            //           SizedBox(height: 20),
                            //         ],
                            //       );
                            //     }),
                            //   ),
                  
                            // Display all selected images with a cross icon to remove
                            // if (selectedImagesList.isNotEmpty &&
                            //     widget.type != "single")
                            //   Column(
                            //     crossAxisAlignment: CrossAxisAlignment.start,
                            //     children: selectedImagesList
                            //         .asMap()
                            //         .entries
                            //         .map((entry) {
                            //       int index = entry.key;
                            //       File image = entry.value;
                  
                            //       return Padding(
                            //         padding: const EdgeInsets.only(bottom: 8.0),
                            //         child: Row(
                            //           children: [
                            //             Image.file(
                            //               image,
                            //               width: 50,
                            //               height: 50,
                            //               fit: BoxFit.cover,
                            //             ),
                            //             SizedBox(width: 10),
                            //             Text(image.path.split('/').last),
                            //             Spacer(),
                            //             IconButton(
                            //               icon: Icon(Icons.close,
                            //                   color: Colors.red),
                            //               onPressed:
                            //                   () {}, // Remove image on click
                            //             ),
                            //           ],
                            //         ),
                            //       );
                            //     }).toList(),
                            //   ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
              
                if(widget.type!='single')
                 Container(
                  child: 
                  Column(
                    children: [
                        Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      child: DropdownButtonHideUnderline(
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey, width: 1.0),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: DropdownButton2<String>(
                            isExpanded: true,
                            hint: Text(
                              'Select Item',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).hintColor),
                            ),
                            items: attribute.asMap().entries.map((entry) {
                              var attr = entry.value; // Get the attribute value

                              return DropdownMenuItem<String>(
                                value: attr['name'],
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(attr['name'],
                                        style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                              );
                            }).toList(),
                            value: selectedAttributeName,
                            onChanged: (value) {
                              setState(() {
                                var selectedAttr = attribute.firstWhere(
                                  (attr) =>
                                      attr['name'].toLowerCase() ==
                                      value!.toLowerCase(),
                                  orElse: () => {'id': null, 'name': 'Unknown'},
                                );
                                selectedAttributeName = selectedAttr['name'];
                                selectedAttributeId = selectedAttr['id'];
                             
                                getvalues(selectedAttributeId!);
                              });
                            },
                            buttonStyleData: const ButtonStyleData(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              height: 40,
                            ),
                            dropdownStyleData:
                                const DropdownStyleData(maxHeight: 200),
                            menuItemStyleData:
                                const MenuItemStyleData(height: 40),
                            dropdownSearchData: DropdownSearchData(
                              searchController: textEditingController,
                              searchInnerWidgetHeight: 50,
                              searchInnerWidget: Container(
                                height: 50,
                                padding: const EdgeInsets.only(
                                    top: 8, bottom: 4, right: 8, left: 8),
                                child: TextFormField(
                                  expands: true,
                                  maxLines: null,
                                  controller: textEditingController,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    hintText: 'Search for an item...',
                                    hintStyle: const TextStyle(fontSize: 12),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                              searchMatchFn: (item, searchValue) {
                                return item.value
                                    .toString()
                                    .toLowerCase()
                                    .contains(searchValue.toLowerCase());
                              },
                            ),
                            onMenuStateChange: (isOpen) {
                              if (!isOpen) {
                                textEditingController.clear();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 46,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey, width: 1.0),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton2<String>(
                              isExpanded: true,
                              hint: Text(
                                'Select Items',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).hintColor),
                              ),
                              items: valuess.map((item) {
                                return DropdownMenuItem<String>(
                                  value: item['value'],
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(item['value'],
                                          style: const TextStyle(fontSize: 14)),
                                      if (selectedValues
                                          .contains(item['value']))
                                        Icon(Icons.check,
                                            color: Colors
                                                .blue), // Indicate selected items
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  if (selectedValues.contains(value)) {
                                    selectedValues.remove(
                                        value); // Remove value if already selected
                                  } else {
                                    selectedValues.add(
                                        value!); // Add value if not selected
                                  }
                                  
                                });
                              },
                              buttonStyleData: const ButtonStyleData(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                height: 40,
                              ),
                              dropdownStyleData:
                                  const DropdownStyleData(maxHeight: 200),
                              menuItemStyleData:
                                  const MenuItemStyleData(height: 40),
                            ),
                          ),
                        ),
                        SizedBox(height: 10), // Spacing
                        // Display selected values
                        Wrap(
                          spacing: 8.0,
                          children: selectedValues.map((value) {
                            return Chip(
                              label: Text(value),
                              deleteIcon: Icon(Icons.close),
                              onDeleted: () {
                                setState(() {
                                  selectedValues.remove(value);
                             
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                ),

                    ],
                  ),
                ),

                if(widget.type!='single')
               Padding(
  padding: const EdgeInsets.only(right: 8.0),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      ElevatedButton(
        onPressed: () {
          if (selectedAttributeName != null &&
              selectedAttributeName!.isNotEmpty &&
              selectedValues.isNotEmpty) {
            setState(() {
              // Add the new attribute to the list
              attributesToSend.add({
                'attribute': selectedAttributeName!,
                'values': selectedValues,
              });
;
              // Reset input fields
              selectedAttributeName = null;
              selectedValues = [];
            });
            
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Please provide valid inputs')),
            );
          }
        },
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(const Color.fromARGB(255, 255, 255, 255)), // Background color
          foregroundColor: MaterialStateProperty.all<Color>(Colors.white), // Text color
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0), // Border radius
              side: BorderSide(color: Colors.blue, width: 2.0), // Border color and width
            ),
          ),
        ),
        child: Text("Add Attribute",style: TextStyle(color: Colors.blue),),
      ),
    ],
  ),
),

                
                SizedBox(
                  height: 13,
                ),
              if(widget.type!='single')
                Padding(
                  padding: const EdgeInsets.only(),
                  child: Row(
                    children: [
                      SizedBox(width: 13),
                      ElevatedButton(
                        onPressed: () {
                          addvariant(context);
                         // addimage(context);
                         // updateProductImage(context, image);
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                            Color.fromARGB(255, 238, 57, 16),
                          ),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  10), // Set your desired border radius
                            ),
                          ),
                          fixedSize: MaterialStateProperty.all<Size>(
                            Size(95, 15), // Set your desired width and heigh
                          ),
                        ),
                        child: Text("Submit",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
              ),
                SizedBox(
                  height: 35,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        widget.type == 'single'
                            ? "Single Product Images"
                            : "Variant Products",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  // scrollDirection: Axis.vertical,
                  child: buildProductTable(),
                ),
                SizedBox(
                  height: 30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


}
