import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
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

class new_product extends StatefulWidget {
  const new_product({super.key});

  @override
  State<new_product> createState() => _new_productState();
}

class _new_productState extends State<new_product> {
  String globalProductId = '';
  String globalProductName = '';
  var respo;
  File? image;

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

  String? selectedUsability;
  List<String> usabilityOptions = ["usable", "damaged", "partially_damaged"];

  List<String> type = ["single", 'variant'];
  List<String> purchasetype = ["International", 'Local'];
  List<Map<String, dynamic>> allRacks = []; // Holds full rack list from API
  List<Map<String, dynamic>> filteredRacks =
      []; // Only racks matching selected warehouse

  String selecttype = "single";
  String selectpurchasetype = "International";
  List<String> unit = [
    "BOX",
    'NOS',
    'PRS',
    'PCS',
    'SET',
    'SET OF 12',
    'SET OF 16',
    'SET OF 8',
    'SET OF 6'
  ];
  String selectunit = "BOX";
  bool checkbox3 = false;
  bool checkbox1 = false;
  bool checkbox2 = false;
  bool checkbox4 = false;
  List<int> _selectedFamily = [];
  List<String> rackColumns = []; // State variable
  List<String> columnNames = []; // For storing selected rack's columns
  String? selectedColumn; // For selected column
  int? selectedwarehouseId; // Variable to store the selected department's ID
  String? selectedwarehouseName;

  int? selectedcategoryId; // Variable to store the selected department's ID
  String? selectedcategoryName;
  int? selectedrackId; // Variable to store the selected department's ID
  String? selectedrackName;

  TextEditingController landingprice = TextEditingController();
  TextEditingController rackStockController =
      TextEditingController(); // Controller for rack stock input

  double prate = 0.00;
  double tax = 0.00;
  double spricetax = 0.00;

  TextEditingController name = TextEditingController();
  TextEditingController hsncode = TextEditingController();
  TextEditingController groupID = TextEditingController();
  TextEditingController price = TextEditingController();
  TextEditingController family = TextEditingController();
  TextEditingController types = TextEditingController();
  TextEditingController units = TextEditingController();
  TextEditingController purchaserate = TextEditingController();
  TextEditingController taxx = TextEditingController();
  TextEditingController sellingprice = TextEditingController();
  TextEditingController excludedprice = TextEditingController();
  TextEditingController stock = TextEditingController();
  TextEditingController retailprice = TextEditingController();
  double landingPriceValue = 0.0;
  List<Map<String, dynamic>> fam = [];
  List<bool> _checkboxValues = [];
  List<Map<String, dynamic>> Warehouses = [];
  List<Map<String, dynamic>> rackDetails = [];

  @override
  void initState() {
    super.initState();
    getfamily();
    getwarehouse();
    getproductcategory();
    getrack();
  }

  void addRackDetail() {
    if (selectedrackId != null &&
        selectedColumn != null &&
        selectedUsability != null &&
        rackStockController.text.isNotEmpty) {
      // Find rack name from filteredRacks
      String? rackName = filteredRacks
          .firstWhere((rack) => rack['id'] == selectedrackId)['rack_name'];

      setState(() {
        rackDetails.add({
          "rack_id": selectedrackId,
          "rack_name": rackName, // <-- Add rack_name
          "column_name": selectedColumn,
          "usability": selectedUsability!.toLowerCase(),
          "rack_stock": int.parse(rackStockController.text),
          "rack_lock": 0
        });
        // Clear after adding
        selectedrackId = null;
        selectedColumn = null;
        selectedUsability = null;
        rackStockController.clear();
      });
    }
  }

  List<Map<String, dynamic>> rack = [];

  Future<void> AddStatusTime(BuildContext scaffoldContext) async {
    final token = await gettokenFromPrefs();
    try {
      final response = await http.post(
        Uri.parse('$api/api/datalog/create/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'before_data': {"Action": "$globalProductName New Product Created"},
          'after_data': {"Data": "$respo"},
          'order': "",
        }),
      );

      // print("====================${response.body}");

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('time added Successfully.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Adding time failed.'),
          ),
        );
      }
    } catch (e) {}
  }

  Future<void> getrack() async {
    final token = await gettokenFromPrefs();
    try {
      final response = await http.get(
        Uri.parse('$api/api/rack/add/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      List<Map<String, dynamic>> racklist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        for (var productData in parsed) {
          // String columnNames = (productData['column_names'] as List)
          //     .join(', '); // Convert list to a comma-separated string

          racklist.add({
            'id': productData['id'],
            'warehouse': productData['warehouse'], // required for filtering
            'rack_name': productData['rack_name'],
            'column_names':
                productData['column_names'], // already a List<String>
          });
        }
        setState(() {
          setState(() {
            allRacks = racklist;
          });
        });
      }
    } catch (e) {}
  }

  List<Map<String, dynamic>> category = [];

  Future<void> getproductcategory() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/product/category/add/'),
        headers: {
          'Authorization': ' Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> categorylist = [];
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        for (var productData in parsed) {
          categorylist.add({
            'id': productData['id'],
            'name': productData['category_name'],
          });
          setState(() {
            category = categorylist;
          });
        }
      }
    } catch (error) {}
  }

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Uint8List? imageBytes;
  final ImagePicker _picker = ImagePicker();
  Future<void> pickImagemain() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes(); // convert file to bytes
      setState(() {
        imageBytes = bytes;
      });
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

  int imagePickerCount = 1; // To keep track of the number of image pickers
  // Function to pick an image from the gallery
  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        image = File(pickedFile
            .path); // Store the selected image in the 'image' variable
      });
    }
  }

  void calculateLandingPrice() {
    double purchaseRate = double.tryParse(purchaserate.text) ?? 0.0;
    double taxPercentage = tax; // From taxx TextField

    // Calculate the tax amount
    double taxAmount = (purchaseRate * taxPercentage) / 100;

    // Calculate the landing price
    double landingPrice = purchaseRate + taxAmount;

    // Update the landing price TextField
    landingprice.text =
        landingPrice.toStringAsFixed(2); // Set to 2 decimal places
  }

  // Function to add a new image selection option
  void addImagePicker() {
    setState(() {
      imagePickerCount += 1; // Increment the number of image pickers
    });
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> getwarehouse() async {
    final token = await gettokenFromPrefs();
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

  Future<void> addProduct(BuildContext scaffoldContext) async {
    final token = await gettokenFromPrefs();

    try {
      // Create the request
      var request = http.Request(
        'POST',
        Uri.parse("$api/api/add/product/"),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json', // Specify content type as JSON
      });

      // Prepare the data to send in JSON format
      Map<String, dynamic> data = {
        'name': name.text,
        'hsn_code': hsncode.text,
        'groupID': groupID.text,
        'type': selecttype,
        'purchase_type': selectpurchasetype,
        'unit': selectunit,
        'product_category': selectedcategoryId,
        'purchase_rate': purchaserate.text,
        'tax': taxx.text,
        'landing_cost': landingPriceValue,
        'selling_price': sellingprice.text,
        'retail_price': retailprice.text,
        'warehouse': selectedwarehouseId,
        'rack_details': rackDetails
      };

      // Ensure _selectedFamily is populated correctly and send as a list of numbers
      if (_selectedFamily != null && _selectedFamily.isNotEmpty) {
        // Send family as a list of integers: [1, 2, 3]
        data['family'] = _selectedFamily; // Directly send the list as is
      } else {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text('Please select a valid family.'),
          ),
        );
        return;
      }

      // Convert data to JSON and set the request body
      request.body = jsonEncode(data);

      // Send the request
      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      // Print the response status and body for debugging

      if (responseData.statusCode == 201) {
        // Parse the response body
        final Map<String, dynamic> responseBody = jsonDecode(responseData.body);

        // Store the product ID in the global variable
        globalProductId = responseBody['data']['id'].toString();
        globalProductName = responseBody['data']['name'].toString();
        respo = responseBody['data'];

        AddStatusTime(context);

        // Show success message
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text('Product added successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    Product_List())); // Navigate to the new product page
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
          content: Text('Error: ${e.toString()}'),
        ),
      );
    }
  }

  Future<void> updateProductImage(BuildContext context) async {
    final token = await gettokenFromPrefs();

    try {
      if (imageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please select an image")),
        );
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File(
          "${tempDir.path}/main_${DateTime.now().millisecondsSinceEpoch}.jpg");
      await file.writeAsBytes(imageBytes!);

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse("$api/api/product/update/$globalProductId/"),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        file.path,
      ));

      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      if (responseData.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image updated successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Image update failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  List<File> selectedImagesList =
      []; // Single list to store all selected images

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
    } catch (error) {}
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
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
        backgroundColor: Color.fromARGB(242, 255, 255, 255),
        appBar: AppBar(
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
              } else if (dep == "Warehouse Admin") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          WarehouseAdmin()), // Replace AnotherPage with your target page
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
                        "New Product",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  SizedBox(
                    height: 390,
                    width: 340,
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
                              // Text(
                              //   "ID ",
                              //   style: TextStyle(
                              //       fontSize: 15, fontWeight: FontWeight.bold),
                              // ),
                              // SizedBox(
                              //   height: 10,
                              // ),
                              // TextField(
                              //   decoration: InputDecoration(
                              //     labelText: 'AAA00',
                              //     prefixIcon: Icon(Icons.numbers),
                              //     border: OutlineInputBorder(
                              //       borderRadius: BorderRadius.circular(10.0),
                              //       borderSide: BorderSide(color: Colors.grey),
                              //     ),
                              //     contentPadding: EdgeInsets.symmetric(
                              //         vertical: 8.0), // Set vertical padding
                              //   ),
                              // ),
                              // SizedBox(
                              //   height: 10,
                              // ),

                              Text("Purchase Type",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 10),
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
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 1),
                                        ),
                                        child: DropdownButton<String>(
                                          value: selectpurchasetype,
                                          underline:
                                              Container(), // This removes the underline
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              selectpurchasetype = newValue!;
                                            });
                                          },
                                          items: purchasetype
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
                              Text(
                                "Product Name * ",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              TextField(
                                controller: name,
                                decoration: InputDecoration(
                                  labelText: 'Label/Description of prodct',
                                  prefixIcon: Icon(Icons.mode_edit),
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
                                "HSN Code",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              TextField(
                                controller: hsncode,
                                decoration: InputDecoration(
                                  labelText: 'Index',

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
                                height: 10,
                              ),
                              Text(
                                "Group ID",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              TextField(
                                controller: groupID,
                                decoration: InputDecoration(
                                  labelText: 'Index',

                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 10.0),

                                  // Set vertical padding
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  SizedBox(
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
                          borderRadius: BorderRadius.circular(
                              10.0), // Set border radius for Container
                          border: Border.all(
                              color: Color.fromARGB(255, 236, 236,
                                  236)), // Add border to Container if needed
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Product Type * ",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
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
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 1),
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
                              const SizedBox(height: 10),

                              DropdownButtonFormField<int>(
                                isExpanded: true,
                                value: selectedcategoryId,
                                decoration: const InputDecoration(
                                  labelText: 'Select a Category',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                                onChanged: (int? newValue) {
                                  setState(() {
                                    selectedcategoryId = newValue;
                                    selectedcategoryName = category.firstWhere(
                                      (element) => element['id'] == newValue,
                                    )['name'];
                                  });
                                },
                                items: category
                                    .map<DropdownMenuItem<int>>((categoryItem) {
                                  return DropdownMenuItem<int>(
                                    value: categoryItem['id'],
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            categoryItem['name']?.toString() ??
                                                '',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 10),

// Warehouse
                              DropdownButtonFormField<int>(
                                isExpanded: true,
                                value: selectedwarehouseId,
                                decoration: const InputDecoration(
                                  labelText: 'Select a Warehouse',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                                onChanged: (int? newValue) {
                                  setState(() {
                                    selectedwarehouseId = newValue;
                                    selectedwarehouseName =
                                        Warehouses.firstWhere(
                                      (w) => w['id'] == newValue,
                                    )['name'];

                                    // Filter racks for this warehouse
                                    filteredRacks = allRacks
                                        .where((rack) =>
                                            rack['warehouse'] == newValue)
                                        .toList();

                                    // Reset rack and column selections
                                    selectedrackId = null;
                                    selectedrackName = null;
                                    columnNames = [];
                                    selectedColumn = null;
                                  });
                                },
                                items:
                                    Warehouses.map<DropdownMenuItem<int>>((w) {
                                  return DropdownMenuItem<int>(
                                    value: w['id'],
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            w['name']?.toString() ?? '',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 10),

// Rack (Filtered)
                              if (filteredRacks.isNotEmpty)
                                DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  value: selectedrackId,
                                  decoration: const InputDecoration(
                                    labelText: 'Select a Rack',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                  ),
                                  onChanged: (int? newValue) {
                                    setState(() {
                                      selectedrackId = newValue;
                                      final selectedRack =
                                          filteredRacks.firstWhere(
                                              (rack) => rack['id'] == newValue);
                                      selectedrackName =
                                          selectedRack['rack_name'];

                                      columnNames = List<String>.from(
                                          selectedRack['column_names'] ?? []);
                                      selectedColumn = null;
                                    });
                                  },
                                  items: filteredRacks
                                      .map<DropdownMenuItem<int>>((rack) {
                                    return DropdownMenuItem<int>(
                                      value: rack['id'],
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              rack['rack_name']?.toString() ??
                                                  '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              softWrap: false,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),

                              if (filteredRacks.isNotEmpty)
                                const SizedBox(height: 10),

// Column (from selected rack)
                              if (columnNames.isNotEmpty)
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value: selectedColumn,
                                  decoration: const InputDecoration(
                                    labelText: 'Select a Column',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                  ),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedColumn = newValue;
                                    });
                                  },
                                  items: columnNames
                                      .map<DropdownMenuItem<String>>((col) {
                                    return DropdownMenuItem<String>(
                                      value: col,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              col,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              softWrap: false,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),

                              if (columnNames.isNotEmpty)
                                const SizedBox(height: 10),

// Usability
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: selectedUsability,
                                decoration: const InputDecoration(
                                  labelText: 'Select Usability',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedUsability = newValue;
                                  });
                                },
                                items: usabilityOptions
                                    .map<DropdownMenuItem<String>>((option) {
                                  return DropdownMenuItem<String>(
                                    value: option,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            option,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),

                              SizedBox(
                                height: 10,
                              ),
                              TextField(
                                controller: rackStockController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Rack Stock',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 8.0),
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              if (rackDetails.isNotEmpty)
                                ...rackDetails.map((rack) => ListTile(
                                      title: Text(
                                          'Rack: ${rack["rack_name"]}  ${rack["column_name"]} (${rack["usability"]})'),
                                      subtitle:
                                          Text('Stock: ${rack["rack_stock"]}'),
                                    )),
                              ElevatedButton(
                                onPressed: addRackDetail,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(
                                      0xFF1976D2), // Professional blue shade
                                  foregroundColor: Colors.white, // Text color
                                  minimumSize: Size(double.infinity,
                                      48), // Full width, taller button
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 3,
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  textStyle: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_box_outlined,
                                        size: 22, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text("Add Rack Details"),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Family",
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 20),
                                    fam.isEmpty
                                        ? CircularProgressIndicator() // Show a loading indicator while the data is being fetched
                                        : ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                NeverScrollableScrollPhysics(), // Prevent nested scrolling
                                            itemCount: fam.length,
                                            itemBuilder: (context, index) {
                                              return CheckboxListTile(
                                                title: Text(fam[index]['name']),
                                                value: _checkboxValues[index],
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    _checkboxValues[index] =
                                                        value ?? false;
                                                    if (_checkboxValues[
                                                        index]) {
                                                      _selectedFamily.add(
                                                          fam[index]['id']);
                                                    } else {
                                                      _selectedFamily.remove(
                                                          fam[index]['id']);
                                                    }
                                                  });
                                                },
                                                controlAffinity:
                                                    ListTileControlAffinity
                                                        .leading,
                                              );
                                            },
                                          ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 10),
                              Text("Unit * ",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
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
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 1),
                                        ),
                                        child: DropdownButton<String>(
                                          value: selectunit,
                                          underline:
                                              Container(), // This removes the underline
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
                                            padding: EdgeInsets.only(
                                                left:
                                                    167), // Adjust padding as needed
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

                              SizedBox(
                                height: 10,
                              ),

                              // Conditionally show the TextField if `selecttype` is "single"
                              // if (selecttype == 'single') ...[
                              //   SizedBox(height: 10),
                              //   Text("Stock for Single Product *",
                              //       style: TextStyle(
                              //           fontSize: 15,
                              //           fontWeight: FontWeight.bold)),
                              //   SizedBox(height: 10),
                              //   TextField(
                              //     controller: stock,
                              //     decoration: InputDecoration(
                              //       labelText: 'Enter stock quantity',
                              //       border: OutlineInputBorder(
                              //         borderRadius: BorderRadius.circular(10.0),
                              //         borderSide:
                              //             BorderSide(color: Colors.grey),
                              //       ),
                              //       contentPadding:
                              //           EdgeInsets.symmetric(vertical: 8.0),
                              //     ),
                              //   ),
                              // ]
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  SizedBox(
                    width: 340,
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
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                "Other Information",
                                style: TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Text(
                                "Purchase Rate (Including Tax): ",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Container(
                                width: 310,
                                height: 49,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Color.fromARGB(255, 158, 157, 157),
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: TextField(
                                  controller: purchaserate,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.rate_review),
                                    border: InputBorder.none,
                                    hintText: 'Enter purchase rate',
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      // Recalculate landing price whenever purchase rate changes
                                      calculateLandingPrice();
                                    });
                                  },
                                ),
                              ),

                              SizedBox(
                                height: 10,
                              ),

                              Text(
                                "Tax Amount (in %) ",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Container(
                                width: 310,
                                height: 49,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: taxx,
                                                keyboardType: TextInputType
                                                    .numberWithOptions(
                                                        decimal: true),
                                                decoration: InputDecoration(
                                                  prefixIcon: Icon(
                                                      Icons.monetization_on),
                                                  border: InputBorder.none,
                                                  hintText: '',
                                                ),
                                                onChanged: (value) {
                                                  setState(() {
                                                    tax = double.tryParse(
                                                            value) ??
                                                        0.00;
                                                    // Recalculate landing price when tax value changes
                                                    calculateLandingPrice();
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(
                                height: 10,
                              ),

                              Text(
                                "Landing Price ",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              TextField(
                                controller: landingprice,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: ' ',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 8.0),
                                ),
                                enabled: false, // Make the field non-editable
                              ),

                              SizedBox(
                                height: 10,
                              ),

                              Text(
                                "Wholesale Rate",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              TextField(
                                controller: sellingprice,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: ' ',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 8.0),
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),

                              Text(
                                "Retail Rate",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              TextField(
                                controller: retailprice,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: ' ',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 8.0),
                                ),
                              ),
                              SizedBox(
                                height: 20,
                              ),

                              TextFormField(
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Select Main Image',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(Icons.image),
                                    onPressed: pickImagemain,
                                  ),
                                ),
                              ),

                              SizedBox(height: 10),

                              if (imageBytes != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Image.memory(
                                      imageBytes!,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                    SizedBox(height: 10),
                                  ],
                                ),

                              // SizedBox(
                              //   height: 10,
                              // ),
                              // Text(
                              //   "Actual Selling Price (Including Tax)",
                              //   style: TextStyle(
                              //       fontSize: 15, fontWeight: FontWeight.bold),
                              // ),
                              // SizedBox(
                              //   height: 10,
                              // ),
                              // Container(
                              //   width: 310,
                              //   height: 49,
                              //   decoration: BoxDecoration(
                              //     border: Border.all(color: Colors.grey),
                              //     borderRadius: BorderRadius.circular(10),
                              //   ),
                              //   child: Row(
                              //     children: [
                              //       Expanded(
                              //         child: Container(
                              //           child: Row(
                              //             children: [
                              //               Expanded(
                              //                 child: TextField(
                              //                   controller: controller14,
                              //                   keyboardType: TextInputType
                              //                       .numberWithOptions(
                              //                           decimal: true),
                              //                   decoration: InputDecoration(
                              //                     prefixIcon:
                              //                         Icon(Icons.local_offer),
                              //                     border: InputBorder.none,
                              //                     hintText: '',
                              //                   ),
                              //                   onChanged: (value) {
                              //                     setState(() {
                              //                       spricetax =
                              //                           double.tryParse(value) ??
                              //                               0.00;
                              //                     });
                              //                   },
                              //                 ),
                              //               ),
                              //               Container(
                              //                 width: 30,
                              //                 color: Color.fromARGB(
                              //                     255, 88, 184, 248),
                              //                 child: IconButton(
                              //                   icon: Icon(
                              //                       Icons
                              //                           .keyboard_arrow_down_rounded,
                              //                       size: 20,
                              //                       color: Colors
                              //                           .white), // Down arrow icon with size 20
                              //                   onPressed: decrementspricetax,
                              //                 ),
                              //               ),
                              //               Container(
                              //                 width: 30,
                              //                 decoration: BoxDecoration(
                              //                     color: Color.fromARGB(
                              //                         255, 64, 176, 251),
                              //                     border: Border.all(
                              //                         color: Color.fromARGB(
                              //                             255, 64, 176, 251)),
                              //                     borderRadius: BorderRadius.only(
                              //                         bottomRight:
                              //                             Radius.circular(10),
                              //                         topRight:
                              //                             Radius.circular(10))),
                              //                 child: IconButton(
                              //                   icon: Icon(
                              //                       Icons
                              //                           .keyboard_arrow_up_rounded,
                              //                       size: 20,
                              //                       color: Colors
                              //                           .white), // Up arrow icon with size 20
                              //                   onPressed: incrementspricetax,
                              //                 ),
                              //               ),
                              //             ],
                              //           ),
                              //         ),
                              //       ),
                              //     ],
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 1,
                        width: 300,
                        color: Color.fromARGB(255, 215, 201, 201),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 13,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 120),
                    child: Row(
                      children: [
                        // ElevatedButton(
                        //   onPressed: () {
                        //     Navigator.push(
                        //         context,
                        //         MaterialPageRoute(
                        //             builder: (context) => View_newproduct()));
                        //   },
                        //   style: ButtonStyle(
                        //     backgroundColor: MaterialStateProperty.all<Color>(
                        //       Color.fromARGB(255, 164, 164, 164),
                        //     ),
                        //     shape:
                        //         MaterialStateProperty.all<RoundedRectangleBorder>(
                        //       RoundedRectangleBorder(
                        //         borderRadius: BorderRadius.circular(
                        //             10), // Set your desired border radius
                        //       ),
                        //     ),
                        //     fixedSize: MaterialStateProperty.all<Size>(
                        //       Size(85, 15), // Set your desired width and heigh
                        //     ),
                        //   ),
                        //   child:
                        //       Text("View", style: TextStyle(color: Colors.white)),
                        // ),
                        SizedBox(width: 13),
                        ElevatedButton(
                          onPressed: () async {
                            // Parse the values
                            landingPriceValue =
                                double.tryParse(landingprice.text) ?? 0.0;
                            double wholesaleRate =
                                double.tryParse(sellingprice.text) ?? 0.0;
                            double retailRate =
                                double.tryParse(retailprice.text) ?? 0.0;

                            // Check if values are valid
                            if (wholesaleRate < landingPriceValue) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      "Wholesale Rate cannot be less than Landing Price"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return; // Stop further execution if invalid
                            }

                            if (retailRate < landingPriceValue) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      "Retail Rate cannot be less than Landing Price"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return; // Stop further execution if invalid
                            }

                            // If validation passes, proceed with submission
                            await addProduct(context);
                            updateProductImage(context);
                          },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                              Color.fromARGB(255, 244, 66, 66),
                            ),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            fixedSize: MaterialStateProperty.all<Size>(
                              Size(95, 15),
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
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
