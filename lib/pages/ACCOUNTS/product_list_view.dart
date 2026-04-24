import 'dart:convert';
import 'dart:io';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/add_attribute.dart';
import 'package:beposoft/pages/ACCOUNTS/add_bank.dart';
import 'package:beposoft/pages/ACCOUNTS/add_company.dart';
import 'package:beposoft/pages/ACCOUNTS/add_department.dart';
import 'package:beposoft/pages/ACCOUNTS/add_family.dart';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
import 'package:beposoft/pages/ACCOUNTS/add_state.dart';
import 'package:beposoft/pages/ACCOUNTS/add_supervisor.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/methods.dart';
import 'package:beposoft/pages/ACCOUNTS/product_list.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropdown_button2/dropdown_button2.dart';


class Productlist_view extends StatefulWidget {
  final int id;  const Productlist_view({super.key, required this.id});

  @override
  State<Productlist_view> createState() => _Productlist_viewState();
}

class _Productlist_viewState extends State<Productlist_view> {
  List<String> type = ["single", 'variant'];
  String selecttype = "single";
  List<String> unit = ["BOX", 'NOS', 'PRS', 'SET'];
  String selectunit = "BOX";
  List<int> _selectedFamily = [];
  List<Map<String, dynamic>> fam = [];
  List<bool> _checkboxValues = [];
  Map<String, dynamic>? productDetails;
  List<Map<String, dynamic>> filteredProducts = [];
  final List<dynamic> products = [];
  List<File> selectedImagesList = [];
  final ImagePicker _picker = ImagePicker();
  int imagePickerCount = 1; // To keep track of the number of image pickers
  List<Map<String, dynamic>> productImages = [];
  bool isLoading = true;
  List<Map<String, String>> variantList = [];
  final List<String> items = [];
  String? selectedValue;
  List<Map<String, dynamic>> attribute = [];
  String? selectedAttributeName; // Store the selected attribute name
  int? selectedAttributeId; // Store the selected attribute ID

  // Controllers for the TextFields
  TextEditingController name = TextEditingController();
  TextEditingController hsncode = TextEditingController();
  TextEditingController purchaserate = TextEditingController();
  TextEditingController sellingprice = TextEditingController();
  TextEditingController taxx = TextEditingController();
  TextEditingController excludedprice = TextEditingController();
  TextEditingController stock = TextEditingController();
  TextEditingController attributenameController = TextEditingController();
  final TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getfamily();
    fetchProductDetails();
    initdata();
    getattributes();
  }

  void initdata() async {
    
    await fetchImages();
  }

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImagesList
            .add(File(pickedFile.path)); // Store image in the single list
      });
    }
  }

  void removeImage(int index) {
    setState(() {
      selectedImagesList
          .removeAt(index); // Remove the image at the specified index
    });
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchProductDetails() async {
    final token = await getTokenFromPrefs();

    try {
      final response = await http.get(
        Uri.parse('$api/api/products/'), // Fetch all products
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> products = jsonDecode(response.body)['data'];

        setState(() {
          // Find the product with the matching id
          productDetails = products.firstWhere(
              (product) => product['id'] == widget.id,
              orElse: () => null);

          if (productDetails == null) {
            
          } else {
            // Set values for text fields
            name.text = productDetails!['name'] ?? '';
            hsncode.text = productDetails!['hsn_code'] ?? '';
            purchaserate.text = productDetails!['purchase_rate'].toString();
            sellingprice.text = productDetails!['selling_price'].toString();
            taxx.text = productDetails!['tax'].toString();
            stock.text = productDetails!['stock'] != null
                ? productDetails!['stock'].toString()
                : '0';
            excludedprice.text = productDetails!['exclude_price'].toString();

            // Set default dropdown value for product type
            selecttype = productDetails!['type'] ?? "single";
            selectunit = productDetails!['unit'] ?? "BOX";

            // Fetch family checkboxes
            List<int> productFamilies =
                List<int>.from(productDetails!['family'] ?? []);
            setState(() {
              _selectedFamily = productFamilies;
              // Update checkbox values based on the fetched families
              for (int i = 0; i < fam.length; i++) {
                _checkboxValues[i] = _selectedFamily.contains(fam[i]['id']);
              }
            });

            
          }
        });
      } else {
        
      }
    } catch (error) {
      
    }
  }

  Future<void> getfamily() async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/familys/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];
        List<Map<String, dynamic>> familylist = [];

        for (var productData in productsData) {
          familylist.add({
            'id': productData['id'],
            'name': productData['name'],
          });
        }

        setState(() {
          fam = familylist;
          _checkboxValues = List<bool>.filled(fam.length, false);
        });

        // Call fetchProductDetails after family data is fetched
        await fetchProductDetails();
      }
    } catch (error) {
      
    }
  }

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> deleteproduct() async {
    final token = await gettokenFromPrefs();

    try {
      final response = await http.delete(
        Uri.parse('$api/api/product/update/${widget.id}/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

   

      if (response.statusCode == 200) {
        // Product successfully deleted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.push(
            context, MaterialPageRoute(builder: (context) => Product_List()));
      } else {
        // Handle error cases
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete product.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> updateproduct() async {
    try {
      final token = await gettokenFromPrefs();

      // Create a map with the updated product details
      var updatedProductData = {
        "name": name.text,
        "hsn_code": hsncode.text,
        "family": _selectedFamily,
        "type": selecttype,
        "unit": selectunit,
        "purchase_rate": purchaserate.text,
        "tax": taxx.text,
        "stock": stock.text,
        "selling_price": sellingprice.text,
        "exclude_price": excludedprice.text,
      };
      

      // Make a PUT request to update the product
      var response = await http.put(
        Uri.parse('$api/api/product/update/${widget.id}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updatedProductData),
      );

      if (response.statusCode == 200) {
        // Product updated successfully
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product updated successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to the product list or another page after update
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Product_List()),
        );
      } else {
        // Handle errors during update
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update product.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void addimage(
    BuildContext scaffoldContext,
  ) async {
    try {
      final token = await gettokenFromPrefs();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$api/api/image/add/${widget.id}/"),
      );

      // Add headers
      request.headers.addAll({
        "Content-Type": "multipart/form-data",
        'Authorization': 'Bearer $token',
      });

      // Add image files to request
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
      
      

      if (responseData.statusCode == 201) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text('Product added successfully.'),
          ),
        );
        // Navigator.push(
        //     context, MaterialPageRoute(builder: (context) => add_product()));
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
      
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          content: Text('Enter valid information'),
        ),
      );
    }
  }

  var image2;
  Future<void> fetchImages() async {
    try {
      final token = await gettokenFromPrefs();

      // Send GET request to fetch product variants
      final response = await http.get(
        Uri.parse('$api/api/products/${widget.id}/variants/'),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> productsData =
            jsonDecode(response.body)['products'];

        // Find the product by its `product` ID matching `widget.id`
        final List<Map<String, dynamic>> productImagesList = productsData
            .where((product) => product['product'] == widget.id)
            .map<Map<String, dynamic>>((product) => {
                  'id': product['id'], // Store the image ID
                  'imageUrl': "$api${product['image']}" // Store the image URL
                })
            .toList();

        setState(() {
          productImages = productImagesList; // No error now
          
          isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch products');
      }
    } catch (error) {
      
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteimages(int imageId) async {
    final token = await gettokenFromPrefs();

    try {
      final response = await http.delete(
        Uri.parse('$api/api/image/delete/$imageId/'), // Use the image ID
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Image successfully deleted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Productlist_view(id: widget.id)));

        // Optionally, refetch the images after deleting
        fetchImages();
      } else {
        // Handle error cases
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete image.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> addattribute(String attributeName) async {
  try {
    var attributeUpperCase = attributeName.toUpperCase();
    final token = await gettokenFromPrefs();
    var response = await http.post(
      Uri.parse('$api/api/add/product/attributes/'),
      headers: {
        "Content-Type": "application/json",
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "name": attributeUpperCase, 
      }),
    );

    if (response.statusCode == 200) {
      

      var newAttribute = jsonDecode(response.body);

      setState(() {
        attribute.add(newAttribute); 
        selectedAttributeName = newAttribute['name']; 
        selectedAttributeId = newAttribute['id'];

      });

       await getattributes(); 


    } else {
      
    }
  } catch (error) {
    
  }
}

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
Future<void> deleteattribute(int attributeId) async {
  final token = await gettokenFromPrefs();

  try {
    final response = await http.delete(
      Uri.parse('$api/api/product/attribute/$attributeId/delete/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attribute deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      // Use the attribute ID to find and remove the item, not the index
      setState(() {
        attribute.removeWhere((attr) => attr['id'] == attributeId);
        
        // Optionally reset the selected attribute if it was deleted
        if (selectedAttributeId == attributeId) {
          selectedAttributeName = null;
          selectedAttributeId = null;
        }

        getattributes();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete attribute.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

void removeProduct(int index) {
  setState(() {
    if (index >= 0 && index < attribute.length) {
      // Check if the index is valid before trying to remove
      attribute.removeAt(index);
    } else {
      
    }
  });
}
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(242, 255, 255, 255),
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Image.asset('lib/assets/profile.png'),
            onPressed: () {},
          ),
        ],
      ),
           drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "lib/assets/logo.png",
                        width: 150, // Change width to desired size
                        height: 150, // Change height to desired size
                        fit: BoxFit
                            .contain, // Use BoxFit.contain to maintain aspect ratio
                      ),
                    ],
                  )),
              ListTile(
                leading: Icon(Icons.dashboard),
                title: Text('Dashboard'),
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => dashboard()));
                },
              ),
              
              ListTile(
                leading: Icon(Icons.person),
                title: Text('Company'),
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => add_company()));
                  // Navigate to the Settings page or perform any other action
                },
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text('Departments'),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => add_department()));
                  // Navigate to the Settings page or perform any other action
                },
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text('Supervisors'),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => add_supervisor()));
                  // Navigate to the Settings page or perform any other action
                },
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text('Family'),
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => add_family()));
                  // Navigate to the Settings page or perform any other action
                },
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text('Bank'),
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => add_bank()));
                  // Navigate to the Settings page or perform any other action
                },
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text('States'),
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => add_state()));
                  // Navigate to the Settings page or perform any other action
                },
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text('Attributes'),
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => add_attribute()));
                  // Navigate to the Settings page or perform any other action
                },
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text('Services'),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CourierServices()));
                  // Navigate to the Settings page or perform any other action
                },
              ),
               ListTile(
                leading: Icon(Icons.person),
                title: Text('Delivery Notes'),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => WarehouseOrderView(status: null,)));
                  // Navigate to the Settings page or perform any other action
                },
              ),
              Divider(),
              _buildDropdownTile(context, 'Reports', [
                'Sales Report',
                'Credit Sales Report',
                'COD Sales Report',
                'Statewise Sales Report',
                'Expence Report',
                'Delivery Report',
                'Product Sale Report',
                'Stock Report',
                'Damaged Stock'
              ]),
              _buildDropdownTile(context, 'Customers', [
                'Add Customer',
                'Customers',
              ]),
              _buildDropdownTile(context, 'Staff', [
                'Add Staff',
                'Staff',
              ]),
              _buildDropdownTile(context, 'Credit Note', [
                'Add Credit Note',
                'Credit Note List',
              ]),
              _buildDropdownTile(context, 'Proforma Invoice', [
                'New Proforma Invoice',
                'Proforma Invoice List',
              ]),
              _buildDropdownTile(context, 'Delivery Note',
                  ['Delivery Note List', 'Daily Goods Movement']),
              _buildDropdownTile(
                  context, 'Orders', ['New Orders', 'Orders List']),
              Divider(),
              Text("Others"),
              Divider(),
              _buildDropdownTile(context, 'Product', [
                'Product List',
                'Product Add',
                'Stock',
              ]),
              _buildDropdownTile(context, 'Expence', [
                'Add Expence',
                'Expence List',
              ]),
              _buildDropdownTile(
                  context, 'GRV', ['Create New GRV', 'GRVs List']),
              _buildDropdownTile(context, 'Banking Module',
                  ['Add Bank ', 'List', 'Other Transfer']),
              Divider(),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('Methods'),
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Methods()));
                },
              ),
              ListTile(
                leading: Icon(Icons.chat),
                title: Text('Chat'),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.exit_to_app),
                title: Text('Logout'),
                onTap: () {
                  logout();
                },
              ),
            ],
          ),
        ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 30, left: 12, right: 12),
          child: Container(
            color: Colors.white,
            width: 700,
            child: Column(
              children: [
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Update Product ",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 15),

                SizedBox(
                  height: 260,
                  width: 340,
                  child: Card(
                    elevation: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                            color: Color.fromARGB(255, 236, 236, 236)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(13.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Product Name * ",
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            TextField(
                              controller:
                                  name, // Using the controller for the product name
                              decoration: InputDecoration(
                                labelText: 'Label/Description of product',
                                prefixIcon: Icon(Icons.mode_edit),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 8.0),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "HSN Code",
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            TextField(
                              controller:
                                  hsncode, // Using the controller for the HSN code
                              decoration: InputDecoration(
                                labelText: 'Index',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 10.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 15),

                // Product Type Dropdown
                SizedBox(
                  height: 550,
                  width: 340,
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10.0), // Set border radius
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                            color: Color.fromARGB(255, 236, 236, 236)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Product Type * ",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                            SizedBox(height: 20),
                            Container(
                              width: 310,
                              height: 49,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(width: 20),
                                  Container(
                                    width: 276,
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: '',
                                        contentPadding:
                                            EdgeInsets.symmetric(horizontal: 1),
                                      ),
                                      child: DropdownButton<String>(
                                        value: selecttype,
                                        underline:
                                            Container(), // This removes the underline
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            selecttype = newValue!;
                                          });
                                        },
                                        items: type
                                            .map<DropdownMenuItem<String>>(
                                                (String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                        icon: Container(
                                          padding: EdgeInsets.only(
                                              left:
                                                  137), // Adjust padding as needed
                                          alignment: Alignment.centerRight,
                                          child: Icon(Icons.arrow_drop_down),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 10),

                            // Conditionally show stock TextField for "single" type products
                            if (selecttype == "single") ...[
                              Text("Stock",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 10),
                              TextField(
                                controller: stock,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Enter stock quantity',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 8.0),
                                ),
                              ),
                            ],

              if (selecttype == "variant")
  Container(
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
            style: TextStyle(fontSize: 14, color: Theme.of(context).hintColor),
          ),
          items: attribute.asMap().entries.map((entry) {
            var attr = entry.value; // Get the attribute value

            return DropdownMenuItem<String>(
              value: attr['name'],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(attr['name'], style: const TextStyle(fontSize: 14)),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () async {
                      await deleteattribute(attr['id']); // Delete by ID
                    },
                  ),
                ],
              ),
            );
          }).toList(),
          value: selectedAttributeName,
          onChanged: (value) {
            setState(() {
              var selectedAttr = attribute.firstWhere(
                (attr) => attr['name'].toLowerCase() == value!.toLowerCase(),
                orElse: () => {'id': null, 'name': 'Unknown'},
              );
              selectedAttributeName = selectedAttr['name'];
              selectedAttributeId = selectedAttr['id'];
              
              
            });
          },
          buttonStyleData: const ButtonStyleData(
            padding: EdgeInsets.symmetric(horizontal: 16),
            height: 40,
          ),
          dropdownStyleData: const DropdownStyleData(maxHeight: 200),
          menuItemStyleData: const MenuItemStyleData(height: 40),
          dropdownSearchData: DropdownSearchData(
            searchController: textEditingController,
            searchInnerWidgetHeight: 50,
            searchInnerWidget: Container(
              height: 50,
              padding: const EdgeInsets.only(top: 8, bottom: 4, right: 8, left: 8),
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

  //                           SizedBox(
  //                             height: 20,
                            // ),
                            // if (selecttype == "variant")
                            //   ElevatedButton(
                            //     onPressed: () {
                            //       showDialog(
                            //         context: context,
                            //         builder: (BuildContext context) {
                            //           return AlertDialog(
                            //             title: Text('Add Attributes'),
                            //             content: Column(
                            //               mainAxisSize: MainAxisSize.min,
                            //               children: [
                            //                 TextField(
                            //                   controller:
                            //                       attributenameController,
                            //                   decoration: InputDecoration(
                            //                     labelText:
                            //                         'Enter Attribute Name',
                            //                   ),
                            //                 ),
                            //               ],
                            //             ),
                            //             actions: [
                            //               TextButton(
                            //                 child: Text('Add'),
                            //                 onPressed: () {
                            //                   addattribute(attributenameController
                            //                       .text); // Pass the attribute name
                            //                   Navigator.of(context).pop();

                            //                 },
                            //               ),
                            //             ],
                            //           );
                            //         },
                            //       );
                            //     },
                            //     child: Text(
                            //       'Add Attributes',
                            //       style: TextStyle(
                            //         color: Colors.white, // White text color
                            //       ),
                            //     ),
                            //     style: ElevatedButton.styleFrom(
                            //       backgroundColor:
                            //           Colors.blue, // Black button color
                            //       shape: RoundedRectangleBorder(
                            //         borderRadius: BorderRadius.circular(
                            //             12), // Curved edges
                            //       ),
                            //       padding: EdgeInsets.symmetric(
                            //           horizontal: 20,
                            //           vertical: 12), // Adjust button padding
                            //     ),
                            //   ),
                            // SizedBox(height: 20),

                            // Text("Variants:"),
                            // ...variantList.map((variant) => Text(
                            //     "Color: ${variant['color']}, Size: ${variant['size']}")),

                            // Family Checkboxes

                            
                            Text("Checkbox Family",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                            SizedBox(height: 20),
                            fam.isEmpty
                                ? CircularProgressIndicator()
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: fam.length,
                                    itemBuilder: (context, index) {
                                      return CheckboxListTile(
                                        title: Text(fam[index]['name']),
                                        value: _checkboxValues[index],
                                        
                                        onChanged: (bool? value) {
                                          setState(() {
                                            _checkboxValues[index] =
                                                value ?? false;
                                            if (_checkboxValues[index]) {
                                              _selectedFamily
                                                  .add(fam[index]['id']);
                                            } else {
                                              _selectedFamily
                                                  .remove(fam[index]['id']);
                                            }
                                            
                                          });
                                        },
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                      );
                                    },
                                  ),
                            SizedBox(height: 10),

                            // Unit Dropdown
                            Text("Unit * ",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                            SizedBox(height: 20),
                            Container(
                              width: 310,
                              height: 49,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(width: 20),
                                  Container(
                                    width: 276,
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: '',
                                        contentPadding:
                                            EdgeInsets.symmetric(horizontal: 1),
                                      ),
                                      child: DropdownButton<String>(
                                        value: selectunit,
                                        underline: Container(),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            selectunit = newValue!;
                                          });
                                        },
                                        items: unit
                                            .map<DropdownMenuItem<String>>(
                                                (String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                        icon: Container(
                                          padding: EdgeInsets.only(left: 167),
                                          alignment: Alignment.centerRight,
                                          child: Icon(Icons.arrow_drop_down),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Other fields and buttons
                SizedBox(
                  height: 460,
                  width: 340,
                  child: Card(
                    elevation: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                            color: Color.fromARGB(255, 236, 236, 236)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(13.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10),
                            Text(
                              "Other Information",
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 15),
                            Text(
                              "Purchase Rate (Including Tax): ",
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            TextField(
                              controller: purchaserate,
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Purchase Rate',
                                prefixIcon: Icon(Icons.rate_review),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 8.0),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Selling Price (Excluding Tax) ",
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            TextField(
                              controller: sellingprice,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: '',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 8.0),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Tax Amount (in %) ",
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            TextField(
                              controller: taxx,
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.monetization_on),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 8.0),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Excluded Price",
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            TextField(
                              controller: excludedprice,
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              enabled:
                                  false, // Makes the TextField non-editable
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.monetization_on),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 8.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                Column(
                  children: List.generate(imagePickerCount, (index) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Select Image',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.image),
                              onPressed: () =>
                                  pickImage(), // Trigger image picker for this index
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    );
                  }),
                ),
                if (selectedImagesList.isEmpty && productImages.isNotEmpty)
                  // Display product images from the network in a vertical list
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: productImages.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, dynamic> imageDetails = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Image.network(
                              imageDetails[
                                  'imageUrl'], // Extract the 'imageUrl' from the map
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                            SizedBox(width: 10),
                            Text(
                                'Image ${imageDetails['id']}'), // Display image ID or other details
                            Spacer(),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                deleteimages(imageDetails[
                                    'id']); // Use the image ID to delete
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                else if (selectedImagesList.isNotEmpty)
                  // Display selected images from the local file system in a vertical list
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: selectedImagesList.asMap().entries.map((entry) {
                      int index = entry.key;
                      File image = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Image.file(
                              image,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                            SizedBox(width: 10),
                            Text(image.path.split('/').last),
                            Spacer(),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () =>
                                  removeImage(index), // Remove image on click
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                else
                  // If no images are available
                  Text('No additional images available'),

                // Buttons
                Padding(
                  padding: const EdgeInsets.only(left: 120),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          updateproduct();
                          addimage(context);
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                            Color.fromARGB(255, 164, 164, 164),
                          ),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          fixedSize: MaterialStateProperty.all<Size>(
                            Size(85, 15), // Adjust to your width and height
                          ),
                        ),
                        child:
                            Text("Edit", style: TextStyle(color: Colors.white)),
                      ),
                      SizedBox(width: 13),
                      ElevatedButton(
                        onPressed: () {
                          deleteproduct();
                          // Submit button logic here
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                            Color.fromARGB(255, 244, 66, 66),
                          ),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          fixedSize: MaterialStateProperty.all<Size>(
                            Size(95, 15), // Adjust to your width and height
                          ),
                        ),
                        child: Text("Delete",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 35),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
