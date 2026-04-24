import 'dart:convert';
import 'dart:io';

import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/add_attribute.dart';
import 'package:beposoft/pages/ACCOUNTS/add_company.dart';
import 'package:beposoft/pages/ACCOUNTS/add_department.dart';
import 'package:beposoft/pages/ACCOUNTS/add_family.dart';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
import 'package:beposoft/pages/ACCOUNTS/add_state.dart';
import 'package:beposoft/pages/ACCOUNTS/add_supervisor.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/product_list.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'package:beposoft/pages/ACCOUNTS/add_bank.dart';
import 'package:beposoft/pages/ACCOUNTS/new_grv.dart';
import 'package:beposoft/pages/ACCOUNTS/transfer.dart';

import 'package:beposoft/main.dart';
import 'package:beposoft/pages/ACCOUNTS/add_credit_note.dart';
import 'package:beposoft/pages/ACCOUNTS/customer.dart';
import 'package:beposoft/pages/ACCOUNTS/recipts_list.dart';
import 'package:beposoft/pages/ACCOUNTS/add_new_stock.dart';
import 'package:beposoft/pages/ACCOUNTS/credit_note_list.dart';
import 'package:beposoft/pages/ACCOUNTS/methods.dart';
import 'package:beposoft/pages/ACCOUNTS/new_product.dart';
import 'package:beposoft/pages/ACCOUNTS/order_request.dart';
import 'package:beposoft/pages/ACCOUNTS/purchases_request.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:beposoft/pages/ACCOUNTS/add_new_customer.dart';

class update_product_variant extends StatefulWidget {
  final id;
  
  const update_product_variant({super.key, required this.id});

  @override
  State<update_product_variant> createState() => _update_product_variantState();
}

class _update_product_variantState extends State<update_product_variant> {
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

// Function to remove an image from the list
  void removeImage(int index) {
    setState(() {
      selectedImagesList.removeAt(index); // Remove the image at the specified index
    });
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
    TextEditingController stock = TextEditingController();

  final TextEditingController textEditingController = TextEditingController();
List<Map<String,dynamic>> size=[];
List<Map<String,dynamic>> img=[];
 List<TextEditingController> _controllers = [];
  List<Map<String, dynamic>> fam = [];
  List<bool> _checkboxValues = [];
  List<Map<String, dynamic>> attribute = [];
  List<Map<String, dynamic>> valuess = [];
  List<Map<String, dynamic>> variantProducts = [];
  List<Map<String, dynamic>> singleProducts = [];
 bool _isLoading = true; // Added loading state
  @override
  void initState() {
    super.initState();
    getfamily();
    getprofiledata();
    getvariant();
    getattributes();
    get_product_values();
    get_product_images();
if (size != null && size.isNotEmpty) {
      // Initialize TextEditingControllers for each item
      _controllers = List.generate(size.length, (index) {
        return TextEditingController(text: size[index]['stock'].toString());
      });
      
    } else {
      
    }
  }

  @override
  void dispose() {
    name.dispose(); // Dispose the controller when the widget is removed
     _controllers.forEach((controller) => controller.dispose());
    super.dispose();
  }

  bool flag = false;
  List<String> type = ["yes", 'no'];
  String selecttype = "yes";
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
 List<File> selectedImagesList = []; // Single list to store all selected images
  final ImagePicker _picker = ImagePicker();
  int imagePickerCount = 1; // To keep track of the number of image pickers
  // Function to pick an image from the gallery
  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImagesList.add(File(pickedFile.path)); // Store image in the single list
      });
    }
  }
Future<void> pickImagemain() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        image=File(pickedFile.path);
        
      });
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
Future<void> updatestock(int id,var stock,var size) async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.put(
        Uri.parse('$api/api/variant/product/${id}/size/edit/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(  
          {
           'stock':stock,
           'variant_product':widget.id,
           'attribute':size        
          },
        ),
      );

    
    

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) =>add_family()),
        // );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile'),
            duration: Duration(seconds: 2),
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
  Future<void> getvariant() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/product/${widget.id}/variant/data/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        setState(() {
          // Handle response based on widget.type
          // if (widget.type == 'single') {
          //   // Handle single product response
          //   singleProducts = List<Map<String, dynamic>>.from(productsData);
          //   if (productsData.isNotEmpty) {
             product.text = productsData['name'] ?? '';
          //   }
          // } else if (widget.type == 'variant') {
          //   // Handle variant product response
          //   variantProducts = List<Map<String, dynamic>>.from(productsData);
          //   if (productsData.isNotEmpty) {
          //     product.text = productsData[0]['name'] ?? '';
          //   }
          // }
        });

        
      }
    } catch (error) {
      
    }
  }
     Future<void> get_product_values() async {
    try {
      final token = await gettokenFromPrefs();
      
      var response = await http.get(
        Uri.parse('$api/api/variant/product/${widget.id}/size/view/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];
        
        List<Map<String, dynamic>> sizes = [];
        for (var productData in productsData) {
          sizes.add(
            {
              'id': productData['id'],
              'size': productData['attribute'],
              'stock': productData['stock'],
            },
          );
        }

        // Update state with the fetched sizes and set loading to false
        setState(() {
          size = sizes;
          _controllers = List.generate(size.length, (index) {
            return TextEditingController(text: size[index]['stock'].toString());
          });
          _isLoading = false; // Data has been fetched
        });

        
      } else {
        setState(() {
          _isLoading = false; // Stop loading if there's an error
        });
        
      }
    } catch (error) {
      setState(() {
        _isLoading = false; // Stop loading on error
      });
      
    }
  }


Future<void> get_product_images() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/variant/${widget.id}/images/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['images'];

List<Map<String, dynamic>> images=[];
for(var productData in productsData){
var imgurl="$api/${productData['image']}";
images.add(
  {
    'id': productData['id'],
    'image': imgurl,
    
  }
);

}
        setState(() {
         img=images;
        });

        
      }
    } catch (error) {
      
    }
  }
 Future<void> deleteimage(int Id) async {
    final token = await gettokenFromPrefs();

    try {
      final response = await http.delete(
        Uri.parse('$api/api/variant/$Id/delete/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
    
    if(response.statusCode == 204){
         ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Color.fromARGB(255, 49, 212, 4),
          content: Text('Deleted sucessfully'),
        ),
      );
         Navigator.push(context, MaterialPageRoute(builder: (context)=>update_product_variant(id:widget.id)));
    }

      if (response.statusCode == 204) {
      } else {
        throw Exception('Failed to delete wishlist ID: $Id');
      }
    } catch (error) {
    }
  }

  void removeProduct(int index) {
    setState(() {
      img.removeAt(index);
    });
  }


 void addimage(
  BuildContext scaffoldContext,
) async {
  var slug = name.text.toUpperCase().replaceAll(' ', '-');

  final token = await gettokenFromPrefs();

  try {
    var request = http.MultipartRequest(
      'PUT',
      Uri.parse("$api/api/product/${widget.id}/variant/data/"),
    );

    // Add headers
    request.headers.addAll({
      "Content-Type": "multipart/form-data",
      'Authorization': 'Bearer $token',
    });

    request.fields['product'] = widget.id.toString(); // Convert to string

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
    } else if (responseData.statusCode == 500) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          content: Text('Session expired.'),
        ),
      );
    } else if (responseData.statusCode == 400) {
      Map<String, dynamic> responseDataBody = jsonDecode(responseData.body);
      Map<String, dynamic> data = responseDataBody['data'];
      String errorMessage =
          data.entries.map((entry) => entry.value[0]).join('\n');
      showDialog(
        context: scaffoldContext, // Fixed the context here
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



void addsizes(BuildContext scaffoldContext) async {
  try {
    final token = await gettokenFromPrefs();
    

    // Prepare the data for sending
    Map<String, dynamic> productData = {
      "size": selectedValues, // Ensure selectedValues is a list
    };

    

    // Adjust the data structure if needed, e.g., if the backend needs 'size' as a list
    var response = await http.put(
      Uri.parse("$api/api/product/${widget.id}/variant/data/"),
      headers: {
        "Content-Type": "application/json",
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'size': selectedValues, // Directly ensure it's being sent as a list
      }),
    );

    

    if (response.statusCode == 200) { // Successful update
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          content: Text('Product updated successfully.'),
        ),
      );

      Navigator.push(context, MaterialPageRoute(builder: (context) => Product_List()));
    } else {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Adding product failed. Response: ${response.body}'),
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

  Future<void> getfamily() async {
    try {
      final token = await gettokenFromPrefs();

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
      }
    } catch (error) {
      
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
                              height: 5,
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
                              height: 5,
                            ),
                            Text(
                              "product",
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            TextField(
                              controller: product,
                              decoration: InputDecoration(
                                hintText: product.text,
                                
                  
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 10.0),
                  
                                // Set vertical padding
                              ),
                            ),
                            SizedBox(height: 5),
                  
                  
                          
                  
                             Text("Is variant ",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                            SizedBox(height: 5),
                  
                             Container(
                              width: 360,
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
                                          child: Icon(Icons
                                              .arrow_drop_down), // Dropdown arrow icon
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                  
                            SizedBox(height: 5),
                  
                  
                          
                  
                             Text("Images",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                            SizedBox(height: 5),
                  
                  
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
                            onPressed: () => pickImage(), // Trigger image picker for this index
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  );
                                  }),
                                ),
                  
                                
                  
                                // Display all selected images with a cross icon to remove
                                if (selectedImagesList.isNotEmpty)
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
                            onPressed: (){
                              removeImage(index);
                  
                            }, // Remove image on click
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                                  ),
                              if (img.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: img.asMap().entries.map((entry) {
                        int index = entry.key;
                        var imageData = entry.value;
                        String imageUrl = imageData['image'];
                  
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Image.network(
                                imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  imageUrl.split('/').last,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, color: Colors.red),
                                onPressed: () {
                                  deleteimage(imageData['id']);
                                  removeProduct(index);
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  
                                 
                  
                  
                          if(selecttype=="no")
                  
                                
                  
                             Text(
                              "Stock",
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                              height: 5,
                            ),
                            if(selecttype=="no")
                             TextField(
                              controller: stock,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 10.0),
                  
                                // Set vertical padding
                              ),
                            ),
                                SizedBox(
                  height: 5,
                                  ),
                  
                  
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 5,
                ),

                

                if(selecttype=="yes")
                 Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            flag = !flag;
                            
                          });
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              Colors.white), // Set background color to white
                          foregroundColor: MaterialStateProperty.all<Color>(
                              Colors.blue), // Set text color to blue
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  10), // Set your desired border radius
                              side: BorderSide(
                                  color: Colors
                                      .blue), // Set the border color to blue
                            ),
                          ),
                          fixedSize: MaterialStateProperty.all<Size>(
                            Size(120, 15), // Set your desired width and height
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add, // Use the add icon
                              color: Colors.blue, // Set icon color to blue
                              size: 15, // Set the desired size of the icon
                            ),
                            Text(
                              "Attribute",
                              style: TextStyle(
                                  color: Colors.blue), // Set text color to blue
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (flag == true)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
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
                if (flag == true)
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
                SizedBox(
                  height: 13,
                ),

                Padding(
                  padding: const EdgeInsets.only(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 13),
                      SizedBox(
                        width: 190,
                        child: ElevatedButton(
                          onPressed: () {
                            
                            addimage(context);
                            addsizes(context);
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
                      ),
                    ],
                  ),
                ),
               SizedBox(height: 5,),
                Padding(
                  padding: const EdgeInsets.all(13.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "Values",
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

               Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: DataTable(
              columns: [
                DataColumn(label: Text('Size')),
                DataColumn(label: Text('Stock')),
                DataColumn(label: Text('Edit')),
                DataColumn(label: Text('Delete')),
              ],
              rows: size.isNotEmpty // Check if size list is not empty
                  ? size.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, dynamic> item = entry.value;

                      return DataRow(cells: [
                        DataCell(Text(item['size'])),
                        DataCell(
                          SizedBox(
                            width: 100,
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: TextField(
                                controller: _controllers[index],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Enter stock',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: BorderSide(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          ElevatedButton(
                            onPressed: () {
                              updatestock(item['id'], _controllers[index].text,item['size']);
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: const Size(50, 20),
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
                        DataCell(
                          ElevatedButton(
                            onPressed: () {
                              //deleteProduct(item['id'], context);
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: const Size(50, 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: const Text(
                              'Delete',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                      ]);
                    }).toList()
                  : [], // Return an empty list if size is empty
            ),
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
