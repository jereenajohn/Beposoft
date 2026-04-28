import 'dart:convert';
import 'dart:async';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/add_address.dart';
import 'package:beposoft/pages/ACCOUNTS/add_attribute.dart';
import 'package:beposoft/pages/ACCOUNTS/add_company.dart';
import 'package:beposoft/pages/ACCOUNTS/add_department.dart';
import 'package:beposoft/pages/ACCOUNTS/add_family.dart';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
import 'package:beposoft/pages/ACCOUNTS/add_state.dart';
import 'package:beposoft/pages/ACCOUNTS/add_supervisor.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/order_products.dart';
import 'package:beposoft/pages/ACCOUNTS/view_cart.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

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
import 'package:beposoft/pages/api.dart';

class order_request extends StatefulWidget {
  const order_request({super.key});

  @override
  State<order_request> createState() => _order_requestState();
}

class _order_requestState extends State<order_request> {
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

  bool isCreating = false;
  List<Map<String, dynamic>> products = [];
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredProducts = [];
  List<Map<String, dynamic>> manager = [];
  String selectmanager = "jeshiya";
  List<String> address = [
    "empty",
  ];
  String selectaddress = "empty";
  List<Map<String, dynamic>> fam = [];
  List<Map<String, dynamic>> customer = [];
  List<Map<String, dynamic>> warehousecusomer1 = [];
  String? selectedCustomerName;
  List<Map<String, dynamic>> warehousecusomer2 = [];

  List<Map<String, dynamic>> variant = [];
  int? selectedFamilyId;
  int? selectedCompanyId;
  int? selectedwarehouseId; // Variable to store the selected department's ID
  String? selectedwarehouseName;
  Timer? _debounce;
  List<Map<String, dynamic>> cartdata = [];
  var Discount;
  List<Map<String, dynamic>> Warehouses = [];

  int? selectedbankId;
  String selectedstaff = '';
  int? selectedstaffId;
  int? selectedstateId;
  int? selectedAddressId; // Variable to store the selected address ID
  String? selectedAddressName; // Variable to store the selected address name
  List<Map<String, dynamic>> bank = [];
  double total = 0.0;
  Set<int> expandedRows = {};
  var famid;
  var staffid;
  List<Map<String, dynamic>> courierdata = [];
  int? selectedCourierServiceId;
  final TextEditingController parcelServiceNoteController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    initdata();
  }

  var dep;
  void initdata() async {
    getstate();
    getcompany();
    getcourierservices();
    dep = await getdepFromPrefs();

    if (dep == "BDO" || dep == "BDM") {
      getcustomer2();
    } else {
      getcustomer();
    }
    await getprofiledata();
    getfamily();
    selectedFamilyId = famid;

    getstaff();
    selectedstaffId = staffid;

    await fetchProductList();

    searchController.addListener(() {
      filterProducts();
    });

    getbank();

    getwarehouse();
    await fetchCartData();
  }

  var allocatedstates;
  void handleOrderCreate(BuildContext context) async {
    setState(() {
      isCreating = true;
    });

    try {
      await ordercreate(context); // Make sure this is an async function
    } finally {
      // Optional: keep disabled or reset after done
      // setState(() => isCreating = false); // Uncomment if you want to re-enable
    }
  }

  Future<void> getcourierservices() async {
    try {
      final token = await gettokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/parcal/service/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List<Map<String, dynamic>> courierList = [];

        if (parsed['data'] != null && parsed['data'] is List) {
          for (var item in parsed['data']) {
            courierList.add({
              'id': item['id'],
              'name': item['name'],
            });
          }
        }

        setState(() {
          courierdata = courierList;
        });
      }
    } catch (e) {
      debugPrint("Courier service fetch error: $e");
    }
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

        ;
      }
    } catch (e) {}
  }

  var warehouse;

  int? _extractOrderId(String body) {
    try {
      final j = jsonDecode(body);
      if (j is Map) {
        // { status, message, data: { id: ... } }
        final data = j['data'];
        if (data is Map && data['id'] != null) {
          return int.tryParse(data['id'].toString());
        }
        // { id: ... }
        if (j['id'] != null) {
          return int.tryParse(j['id'].toString());
        }
      }
    } catch (_) {}
    return null;
  }

  var createdOrderId;
  Future<void> ordercreate(BuildContext scaffoldContext) async {
    String stringify(dynamic v) {
      if (v == null) return '';
      if (v is String) return v;
      if (v is List)
        return v.map(stringify).where((s) => s.trim().isNotEmpty).join('\n');
      if (v is Map)
        return v.entries
            .map((e) => '${e.key}: ${stringify(e.value)}')
            .join('\n');
      return v.toString();
    }

    String extractServerError(String body) {
      try {
        final data = jsonDecode(body);
        final msg = stringify(data['message']);
        final errs = stringify(data['errors']);
        final combined =
            [errs, msg].where((s) => s.trim().isNotEmpty).join('\n');
        return combined.isEmpty
            ? 'An unknown server error occurred.'
            : combined;
      } catch (_) {
        return body.isNotEmpty ? body : 'An unknown error occurred.';
      }
    }

    void showSnack(String text, {Color? color}) {
      ScaffoldMessenger.of(scaffoldContext).clearSnackBars();
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          backgroundColor: color,
          content: Text(text),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    try {
      final token = await gettokenFromPrefs();
      final warehouse =
          await getwarehouseFromPrefs(); // keep your existing getter
      String? codStatusToSend;

      if (selectcodtype == "select type") {
        codStatusToSend = null;
      } else {
        codStatusToSend = selectcodtype;
      }
      var cod;
      if (codamountcontroller.text.trim().isEmpty) {
        cod = 0;
      } else {
        cod = codamountcontroller.text;
      }
      // Build request body
      final requestBody = <String, dynamic>{
        'manage_staff': selectedstaffId,
        'company': selectedCompanyId,
        'customer': selectedCustomerId,
        'billing_address': selectedAddressId,
        'order_date':
            "${selectedDate.toLocal().year}-${selectedDate.toLocal().month.toString().padLeft(2, '0')}-${selectedDate.toLocal().day.toString().padLeft(2, '0')}",
        'family': selectedFamilyId,
        'state': selectedstateId,
        'payment_status': selectpaystatus,
        'cod_status': codStatusToSend,
        'cod_amount': cod,
        'adv_cod_amount': advancecodamount.text,
        'total_amount': tot,
        'bank': selectedbankId,
        'payment_method': selectpaymethod,
        'parcel_service': selectedCourierServiceId,
        'parcel_service_note': parcelServiceNoteController.text.trim(),
      };

      // ⚠️ If your API expects a list for warehouses, pass a list:
      if (selectedmode == 'request') {
        requestBody['warehouses'] = selectedwarehouseId is int
            ? [selectedwarehouseId]
            : selectedwarehouseId;
        requestBody['status'] = 'Order Request by Warehouse';
      } else if (selectedmode == 'invoice') {
        requestBody['warehouses'] = warehouse is int ? [warehouse] : warehouse;
        requestBody['status'] = 'Invoice Created';
      }

      // Logs

      final response = await http.post(
        Uri.parse('$api/api/order/create/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );
      final orderId = _extractOrderId(response.body);

      print("Order Create Response: ${response.statusCode} - ${response.body}");
      if (response.statusCode == 201) {
        setState(() {
          createdOrderId = orderId;
        });

        AddStatusTime(scaffoldContext, createdOrderId);

        showSnack('Order Created Successfully.', color: Colors.green);
        Navigator.push(
          scaffoldContext,
          MaterialPageRoute(builder: (_) => order_products()),
        );
        return;
      }
      // Non-201 → show server-provided error (e.g. "Not enough available stock to lock.")
      final errText = extractServerError(response.body);
      showSnack(errText, color: Colors.red);
    } catch (e) {
      showSnack('Failed to create order: $e', color: Colors.red);
    }
  }

  Future<String?> getwarehouseFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? warehouseId = prefs.getInt('warehouse');

    // Check if warehouseId is null before converting to String
    return warehouseId?.toString();
  }

  void toggleExpansion(int productId) {
    setState(() {
      if (expandedRows.contains(productId)) {
        expandedRows.remove(productId);
      } else {
        expandedRows.add(productId);
      }
    });
  }

  Future<void> AddStatusTime(BuildContext scaffoldContext, int orderId) async {
    final token = await gettokenFromPrefs();
    try {
      final response = await http.post(
        Uri.parse('$api/api/datalog/create/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'before_data': {"status": "N/A"},
          'after_data': {"status": "Invoice Created"},
          'order': orderId,
        }),
      );

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

  void filterProducts() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredProducts = products
          .where((product) => product['name'].toLowerCase().contains(query))
          .toList();
    });
  }

//dateselection
  DateTime selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> getbank() async {
    final token = await gettokenFromPrefs();
    try {
      final response = await http.get(Uri.parse('$api/api/banks/'), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      List<Map<String, dynamic>> banklist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          String imageUrl = "${productData['image']}";
          banklist.add({
            'id': productData['id'],
            'name': productData['name'],
            'branch': productData['branch']
          });
        }
        setState(() {
          bank = banklist;
        });
      }
    } catch (e) {}
  }

  var department = '';
  List<Map<String, dynamic>> company = [];
  Future<void> getcompany() async {
    try {
      final token = await gettokenFromPrefs();
      var response = await http.get(
        Uri.parse('$api/api/company/data/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> companylist = [];
      ;
      if (response.statusCode == 200) {
        final Data = jsonDecode(response.body);
        final productsData = Data['data'];

        for (var productData in productsData) {
          String imageUrl = "${productData['image']}";
          companylist.add({
            'id': productData['id'],
            'name': productData['name'],
          });
        }
        setState(() {
          company = companylist;
        });
      }
    } catch (error) {}
  }
//  void calculateTotalPrice() {
// double total = 0.0;
//
//     for (var item in cartdata) {
//       final discountPerQuantity = item['discount'] ?? 0.0;
//       final quantity = item['quantity'] ?? 0;
//       final price = item['price'] ?? 0.0;
//       final totalItemPrice = quantity * price;
//

//       final totalDiscount = quantity * discountPerQuantity;
//

//       total += totalItemPrice - totalDiscount;
//     }
//
//   }

  Future<void> fetchCartData() async {
    try {
      final token = await gettokenFromPrefs();

      final response = await http.get(
        Uri.parse("$api/api/cart/products/"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final List<dynamic> cartsData = parsed['data'];
        List<Map<String, dynamic>> cartList = [];

        double total = 0.0; // Initialize total here

        for (var cartData in cartsData) {
          // Safely handle the null value for image
          String imageUrl = cartData['image'] ??
              'default_image_url'; // Provide a default value or a placeholder URL

          cartList.add({
            'id': cartData['id'],
            'name': cartData['name'],
            'image': imageUrl,
            'slug': cartData['slug'],
            'size': cartData['size'],
            'quantity': cartData['quantity'],
            'price': cartData['price'],
            'discount': cartData['discount'],
          });
        }

        setState(() {
          cartdata = cartList;

          // Calculate total
          for (var item in cartdata) {
            final discountPerQuantity = item['discount'] ?? 0.0;
            final quantity = int.tryParse(item['quantity'].toString()) ??
                0; // Ensure it's an integer
            final price = double.tryParse(item['price'].toString()) ??
                0.0; // Ensure it's a double
            final totalItemPrice = quantity * price;
            final totalDiscount = quantity * discountPerQuantity;
            total += totalItemPrice - totalDiscount;
          }
        });

        // Call the function to show total in a dialog box
      } else {
        throw Exception('Failed to load cart data');
      }
    } catch (error) {
      // Consider adding error handling in the UI
    }
  }

  var tot;
  void showTotalDialog(BuildContext context) {
    double total = 0.0;
    double totalDiscount = 0.0;
    double totalItemPrice = 0.0;
    // Calculate total
    for (var item in cartdata) {
      final discountPerQuantity = item['discount'] ?? 0.0;
      final quantity = int.tryParse(item['quantity'].toString()) ??
          0; // Ensure it's an integer
      final price = double.tryParse(item['price'].toString()) ??
          0.0; // Ensure it's a double

      totalItemPrice += quantity * price;
      totalDiscount += quantity * discountPerQuantity;

      total = totalItemPrice - totalDiscount;
    }
    setState(() {
      tot = total;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Cart Total"),
          content: SizedBox(
            width: 300, // Set the desired width
            height: 180, // Set the desired height
            child: Column(
              children: [
                Row(
                  children: [
                    Text("Total:"),
                    Spacer(),
                    Text("$totalItemPrice"),
                  ],
                ),
                Divider(),
                Row(
                  children: [
                    Text("Advance paid:"),
                    Spacer(),
                    Text("0.0"),
                  ],
                ),
                Row(
                  children: [
                    Text("Total Discount:"),
                    Spacer(),
                    Text("$totalDiscount"),
                  ],
                ),
                Divider(),
                Row(
                  children: [
                    Text("Shipping Charge:"),
                    Spacer(),
                    Text("0.0"),
                  ],
                ),
                // Row(
                //   children: [
                //     Text("Total Cart Discount:"),
                //     Spacer(),
                //     Text("0.0"),
                //   ],
                // ),

                Divider(),
                Row(
                  children: [
                    Text("Net Amount:"),
                    Spacer(),
                    Text("${total.toStringAsFixed(2)}"),
                  ],
                ),
              ],
            ),
          ),
          actions: <Widget>[
            SizedBox(
              width: 100,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                ),
                onPressed: isCreating ? null : () => handleOrderCreate(context),
                child: Text(isCreating ? "Creating..." : "OK"),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> fetchProductList() async {
    final token = await gettokenFromPrefs();

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
          List<String> familyNames = (productData['family'] as List<dynamic>?)
                  ?.map((id) => id as int)
                  .map<String>((id) => fam.firstWhere(
                      (famItem) => famItem['id'] == id,
                      orElse: () => {'name': 'Unknown'})['name'] as String)
                  .toList() ??
              [];
          var imgurl = '$api/${productData['image']}';

          // Check if the product type is 'variant'
          if (productData['type'] == "variant") {
            for (var variant in productData['variant_products']) {
              // Process each variant product
              productList.add({
                'id': variant['id'],
                'name': variant['name'],
                'color': variant['color'],
                'stock': variant['stock'],
                'created_user': variant['created_user'],
                'family': familyNames,
                'image': variant['variant_images'].isNotEmpty
                    ? '$api/${variant['variant_images'][0]['image']}'
                    : imgurl, // Use variant image or fallback to main image
              });
            }
          } else {
            // Process non-variant products
            productList.add({
              'id': productData['id'],
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
              'family': familyNames,
              'image': imgurl,
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

  Future<void> getvariant(int id, var type) async {
    try {
      final token = await gettokenFromPrefs();
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
          // Check if there is at least one image in 'variant_images'
          String firstImageUrl = product['variant_images'].isNotEmpty
              ? product['variant_images'][0]['image']
              : '';
          var imgurl = "$api/$firstImageUrl";
          productList.add({
            'name': product['name'],
            'color': product['color'],
            'image': imgurl, // Add the first image URL
            'is_variant:': product['is_variant:'],
            'stock': product['stock'],
          });
        }
        setState(() {
          variant = productList;
        });
      }
    } catch (error) {}
  }

  Future<void> getcustomer2() async {
    ;
    try {
      // final dep = await getdepFromPrefs();
      final token = await gettokenFromPrefs();

      final jwt = JWT.decode(token!);
      var name = jwt.payload['name'];
      ;
      ;

      List<Map<String, dynamic>> managerlist = [];

      var response = await http.get(
        Uri.parse('$api/api/staff/customers/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      ;

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        List<Map<String, dynamic>> newCustomers = [];

        for (var productData in productsData) {
          newCustomers.add({
            'id': productData['id'],
            'name': productData['name'],
            'created_at': productData['created_at'],
          });
        }
        setState(() {
          customer = newCustomers;
        });

        ;
      } else {
        throw Exception("Failed to load customer data");
      }
    } catch (error) {
      ;
    }
  }

  Future<void> getcustomer({String search = '', int page = 1}) async {
    try {
      final token = await gettokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/customers/?search=$search&page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final List<dynamic> customersData = parsed['results'] ?? [];

        List<Map<String, dynamic>> newCustomers = customersData.map((item) {
          return {
            'id': item['id'],
            'name': item['name'],
            'phone': item['phone'],
            'state': item['state_name'],
            'gst': item['gst'],
          };
        }).toList();

        setState(() {
          if (page == 1) {
            customer = newCustomers;
          } else {
            customer.addAll(newCustomers);
          }
        });

        if (parsed['next'] != null) {
          await getcustomer(search: search, page: page + 1);
        }
      }
    } catch (e) {}
  }

  List<Map<String, dynamic>> stat = [];
  Future<void> getstate() async {
    try {
      final token = await gettokenFromPrefs();
      department = (await getdepFromPrefs())!;
      var response = await http.get(
        Uri.parse('$api/api/states/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> statelist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          statelist.add({
            'id': productData['id'],
            'name': productData['name'],
          });
        }
        if (department == "BDM" || department == "BDO") {
          if (allocatedstates.isNotEmpty) {
            // Filter to keep only allocated states
            List<Map<String, dynamic>> filteredStates = statelist
                .where((state) => allocatedstates.contains(state['id']))
                .toList();

            setState(() {
              stat = filteredStates;
            });
          }
        } else {
          stat = statelist;
        }
      }
    } catch (error) {
      ;
    }
  }

  List<Map<String, dynamic>> addres = [];

  Future<void> getaddress(var id) async {
    try {
      final token = await gettokenFromPrefs();

      setState(() {
        addres = [];
        selectedAddressId = null;
      });

      var response = await http.get(
        Uri.parse('$api/api/add/customer/address/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> addresslist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          addresslist.add({
            'id': productData['id'],
            'name': productData['name'],
            'email': productData['email'],
            'zipcode': productData['zipcode'],
            'address': productData['address'],
            'phone': productData['phone'],
            'country': productData['country'],
            'city': productData['city'],
            'state': productData['state'],
          });
        }

        setState(() {
          addres = addresslist;
          if (addres.isNotEmpty) {
            selectedAddressId = addres.first['id']; // optional auto select
          }
        });
      }
    } catch (error) {}
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
        });
      }
    } catch (error) {}
  }
  //searchable dropdown

  Future<void> getprofiledata() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse("$api/api/profile/"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      ;
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        setState(() {
          famid = productsData['family'];
          staffid = productsData['id'];
          allocatedstates = productsData['allocated_states'];
        });
        getstate();
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

  List<Map<String, dynamic>> sta = [];

  Future<void> getstaff() async {
    try {
      final token = await gettokenFromPrefs();
      var dep = await getdepFromPrefs();
      var response = await http.get(
        Uri.parse('$api/api/staffs/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> stafflist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          String imageUrl = "${productData['image']}";
          if (dep == "BDM") {
            if (productData['family'] == famid) {
              stafflist.add({
                'id': productData['id'],
                'name': productData['name'],
              });
            }
          } else if (dep == "BDO") {
            if (staffid == productData['id']) {
              stafflist.add({
                'id': productData['id'],
                'name': productData['name'],
              });
            }
          } else {
            stafflist.add({
              'id': productData['id'],
              'name': productData['name'],
            });
          }
        }
        setState(() {
          sta = stafflist;
        });
      }
    } catch (error) {}
  }

  final List<String> items = [
    'A_Item1',
    'A_Item2',
    'A_Item3',
    'A_Item4',
    'B_Item1',
    'B_Item2',
    'B_Item3',
    'B_Item4',
    "anii"
  ];
  String? selectedValue;
  int? selectedCustomerId;
  final TextEditingController textEditingController = TextEditingController();

  @override
  void dispose() {
    textEditingController.dispose();
    searchController.dispose();
    parcelServiceNoteController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  List<String> paystatus = ["paid", 'COD', 'credit'];
  List<String> codtype = [
    "select type",
    "FULL_COD",
    'PARTIAL_COD',
  ];

  List<String> mode = ["request", 'invoice', 'warehouse to warehouse'];

  String selectpaystatus = "paid";
  String selectcodtype = "select type";
  TextEditingController codamountcontroller = TextEditingController();
  TextEditingController advancecodamount = TextEditingController();
  String selectedmode = "invoice";

  List<String> paymethod = [
    '1 Razorpay',
    "Credit Card",
    'Debit Card',
    'Net Banking',
    'PayPal',
    'Cash on Delivery (COD)',
    'Bank Transfer'
  ];
  String selectpaymethod = "1 Razorpay";

  void showInvoiceDialog(BuildContext context, double total) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Invoice",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${total?.toStringAsFixed(2) ?? '0.00'}',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${total != null ? total.toStringAsFixed(2) : '0.00'}',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Discount',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${Discount.toStringAsFixed(2)}',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      Colors.blue,
                    ),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  child: Text("Close", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Color.fromARGB(242, 255, 255, 255),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Custom back arrow
          onPressed: () async {
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
      body: RefreshIndicator(
        onRefresh: () async {
          initdata();
          getaddress(selectedCustomerId);
        },
        child: SingleChildScrollView(
            child: Column(
          children: [
            Container(
              child: Column(
                children: [
                  SizedBox(
                    height: 15,
                  ),
                  Text(
                    "ORDER REQUEST",
                    style: TextStyle(
                        fontSize: 20,
                        letterSpacing: 9.0,
                        fontWeight: FontWeight.bold),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 15, left: 15, right: 15),
                    child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                              color: Color.fromARGB(255, 202, 202, 202)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 15,
                              ),

                              if (dep == "ADMIN" ||
                                  dep == "COO" ||
                                  dep == "Accounts")
                                Text(
                                  "Order Mode",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),

                              SizedBox(
                                height: 5,
                              ),

                              if (dep == "ADMIN" ||
                                  dep == "COO" ||
                                  dep == "Accounts")
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: '',
                                        contentPadding:
                                            EdgeInsets.symmetric(horizontal: 1),
                                      ),
                                      child: DropdownButton<String>(
                                        value: selectedmode,
                                        underline:
                                            Container(), // Removes the underline
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            selectedmode = newValue!;
                                          });
                                        },
                                        items: mode
                                            .map<DropdownMenuItem<String>>(
                                                (String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(
                                              value,
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          );
                                        }).toList(),
                                        icon: Container(
                                          padding: EdgeInsets.only(left: 140),
                                          alignment: Alignment.centerRight,
                                          child: Icon(Icons.arrow_drop_down),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              SizedBox(height: 5),

                              Text(
                                "Company ",
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 5,
                              ),

                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10.0),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey, width: 1.0),
                                        borderRadius: BorderRadius.circular(
                                            8.0), // Rounded corners
                                      ),
                                      child: DropdownButton<int>(
                                        isExpanded: true,
                                        underline:
                                            SizedBox(), // Removes default underline
                                        hint: Text('Select a company'),
                                        value: selectedCompanyId,
                                        items: company.map((item) {
                                          return DropdownMenuItem<int>(
                                            value: item['id'],
                                            child: Text(item['name']),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            selectedCompanyId = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (selectedmode == "warehouse to warehouse")
                                SizedBox(height: 5),
                              if (selectedmode == "warehouse to warehouse")
                                Text(
                                  "TO",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              SizedBox(
                                height: 5,
                              ),

                              if (dep == "ADMIN" ||
                                  dep == "COO" ||
                                  dep == "Accounts")
                                if (selectedmode == "warehouse to warehouse")
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        return Container(
                                          child: DropdownButtonHideUnderline(
                                            child: Container(
                                              height: 46,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.grey,
                                                    width: 1.0),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              child: DropdownButton2<String>(
                                                isExpanded: true,
                                                hint: Text(
                                                  'Select a warehouse',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Theme.of(context)
                                                          .hintColor),
                                                ),
                                                items: customer
                                                    .map((item) =>
                                                        DropdownMenuItem<
                                                            String>(
                                                          value: item[
                                                              'name'], // Use the customer's name as the value
                                                          child: Text(
                                                            item['name'],
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        12),
                                                          ),
                                                        ))
                                                    .toList(),
                                                value: selectedValue,
                                                onChanged: (value) {
                                                  setState(() {
                                                    // Update the selected value with the chosen customer's name
                                                    selectedValue = value;
                                                    // Find the corresponding customer ID
                                                    selectedCustomerId =
                                                        customer.firstWhere(
                                                            (item) =>
                                                                item['name'] ==
                                                                value)['id'];

                                                    // Reset the selected address ID when a new customer is selected
                                                    selectedAddressId = null;
                                                  });

                                                  // Fetch the addresses for the newly selected customer
                                                  getaddress(
                                                      selectedCustomerId);
                                                },
                                                buttonStyleData:
                                                    const ButtonStyleData(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 16),
                                                  height: 40,
                                                ),
                                                dropdownStyleData:
                                                    const DropdownStyleData(
                                                  maxHeight: 200,
                                                ),
                                                menuItemStyleData:
                                                    const MenuItemStyleData(
                                                  height: 40,
                                                ),
                                                dropdownSearchData:
                                                    DropdownSearchData(
                                                  searchController:
                                                      textEditingController,
                                                  searchInnerWidgetHeight: 50,
                                                  searchInnerWidget: Container(
                                                    height: 50,
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 8,
                                                            bottom: 4,
                                                            right: 8,
                                                            left: 8),
                                                    child: TextFormField(
                                                      expands: true,
                                                      maxLines: null,
                                                      controller:
                                                          textEditingController,
                                                      decoration:
                                                          InputDecoration(
                                                        isDense: true,
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 10,
                                                                vertical: 8),
                                                        hintText:
                                                            'Search for a warehouse...',
                                                        hintStyle:
                                                            const TextStyle(
                                                                fontSize: 12),
                                                        border:
                                                            OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8)),
                                                      ),
                                                    ),
                                                  ),
                                                  searchMatchFn:
                                                      (item, searchValue) {
                                                    // Perform case-insensitive search
                                                    return item.value
                                                        .toString()
                                                        .toLowerCase()
                                                        .contains(searchValue
                                                            .toLowerCase());
                                                  },
                                                ),
                                                // Clear the search value when the menu is closed
                                                onMenuStateChange: (isOpen) {
                                                  if (!isOpen) {
                                                    textEditingController
                                                        .clear();
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                              if (selectedmode == "warehouse to warehouse")
                                SizedBox(height: 5),
                              if (selectedmode == "warehouse to warehouse")
                                Text(
                                  "From",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              SizedBox(
                                height: 5,
                              ),

                              if (dep == "ADMIN" ||
                                  dep == "COO" ||
                                  dep == "Accounts")
                                if (selectedmode == "warehouse to warehouse")
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        return Container(
                                          child: DropdownButtonHideUnderline(
                                            child: Container(
                                              height: 46,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.grey,
                                                    width: 1.0),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              child: DropdownButton2<String>(
                                                isExpanded: true,
                                                hint: Text(
                                                  'Select a warehouse',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Theme.of(context)
                                                          .hintColor),
                                                ),
                                                items: customer
                                                    .map((item) =>
                                                        DropdownMenuItem<
                                                            String>(
                                                          value: item[
                                                              'name'], // Use the customer's name as the value
                                                          child: Text(
                                                            item['name'],
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        12),
                                                          ),
                                                        ))
                                                    .toList(),
                                                value: selectedValue,
                                                onChanged: (value) {
                                                  setState(() {
                                                    // Update the selected value with the chosen customer's name
                                                    selectedValue = value;
                                                    // Find the corresponding customer ID
                                                    selectedCustomerId =
                                                        customer.firstWhere(
                                                            (item) =>
                                                                item['name'] ==
                                                                value)['id'];

                                                    // Reset the selected address ID when a new customer is selected
                                                    selectedAddressId = null;
                                                  });

                                                  // Fetch the addresses for the newly selected customer
                                                  getaddress(
                                                      selectedCustomerId);
                                                },
                                                buttonStyleData:
                                                    const ButtonStyleData(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 16),
                                                  height: 40,
                                                ),
                                                dropdownStyleData:
                                                    const DropdownStyleData(
                                                  maxHeight: 200,
                                                ),
                                                menuItemStyleData:
                                                    const MenuItemStyleData(
                                                  height: 40,
                                                ),
                                                dropdownSearchData:
                                                    DropdownSearchData(
                                                  searchController:
                                                      textEditingController,
                                                  searchInnerWidgetHeight: 50,
                                                  searchInnerWidget: Container(
                                                    height: 50,
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 8,
                                                            bottom: 4,
                                                            right: 8,
                                                            left: 8),
                                                    child: TextFormField(
                                                      expands: true,
                                                      maxLines: null,
                                                      controller:
                                                          textEditingController,
                                                      decoration:
                                                          InputDecoration(
                                                        isDense: true,
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 10,
                                                                vertical: 8),
                                                        hintText:
                                                            'Search for a warehouse...',
                                                        hintStyle:
                                                            const TextStyle(
                                                                fontSize: 12),
                                                        border:
                                                            OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8)),
                                                      ),
                                                    ),
                                                  ),
                                                  searchMatchFn:
                                                      (item, searchValue) {
                                                    // Perform case-insensitive search
                                                    return item.value
                                                        .toString()
                                                        .toLowerCase()
                                                        .contains(searchValue
                                                            .toLowerCase());
                                                  },
                                                ),
                                                // Clear the search value when the menu is closed
                                                onMenuStateChange: (isOpen) {
                                                  if (!isOpen) {
                                                    textEditingController
                                                        .clear();
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                              if (dep == "ADMIN" ||
                                  dep == "COO" ||
                                  dep == "Accounts")
                                if (selectedmode == "request")
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        border: Border.all(color: Colors.grey),
                                      ),
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 12),
                                      child: DropdownButton<int>(
                                        isExpanded: true,
                                        value: selectedwarehouseId,
                                        hint: Text('Select a Warehouse'),
                                        underline:
                                            SizedBox(), // Remove the default underline
                                        onChanged: (int? newValue) {
                                          setState(() {
                                            selectedwarehouseId = newValue;
                                            selectedwarehouseName =
                                                Warehouses.firstWhere(
                                                    (element) =>
                                                        element['id'] ==
                                                        newValue)['name'];
                                          });
                                        },
                                        items: Warehouses.map<
                                                DropdownMenuItem<int>>(
                                            (Warehouses) {
                                          return DropdownMenuItem<int>(
                                            value: Warehouses['id'],
                                            child: Text(Warehouses['name']),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                              SizedBox(
                                height: 8,
                              ),
                              Text(
                                "Division",
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 5,
                              ),

                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Container(
                                  height: 49,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: const Color.fromARGB(
                                            255, 206, 206, 206)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 20),
                                      Container(
                                        width: 280,
                                        child: InputDecorator(
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              hintText: 'Select your class',
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 1),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<int>(
                                                hint: Text(
                                                  'Select a Family',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600]),
                                                ),
                                                value: selectedFamilyId,
                                                isExpanded: true,
                                                dropdownColor:
                                                    const Color.fromARGB(
                                                        255, 255, 255, 255),
                                                onChanged: (int? newValue) {
                                                  setState(() {
                                                    selectedFamilyId =
                                                        newValue; // Store the selected family ID
                                                  });
                                                },
                                                items: fam
                                                    .map<DropdownMenuItem<int>>(
                                                        (family) {
                                                  return DropdownMenuItem<int>(
                                                    value: family['id'],
                                                    child: Text(
                                                      family['name'],
                                                      style: TextStyle(
                                                          color: Colors.black87,
                                                          fontSize: 12),
                                                    ),
                                                  );
                                                }).toList(),
                                                icon: Container(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: Icon(
                                                      Icons.arrow_drop_down),
                                                ),
                                              ),
                                            )),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 8,
                              ),
                              Text(
                                "Manager",
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 5,
                              ),

                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Container(
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
                                                EdgeInsets.symmetric(
                                                    horizontal: 1),
                                          ),
                                          child: DropdownButton<int>(
                                            value: selectedstaffId,
                                            isExpanded: true,
                                            underline:
                                                Container(), // This removes the underline
                                            onChanged: (int? newValue) {
                                              setState(() {
                                                selectedstaffId = newValue!;
                                              });
                                            },
                                            items: sta
                                                .map<DropdownMenuItem<int>>(
                                                    (staff) {
                                              return DropdownMenuItem<int>(
                                                value: staff['id'],
                                                child: Text(
                                                  staff['name'],
                                                  style:
                                                      TextStyle(fontSize: 12),
                                                ),
                                              );
                                            }).toList(),
                                            icon: Container(
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
                              ),

                              SizedBox(
                                height: 8,
                              ),
                              Text(
                                "State",
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Container(
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
                                                EdgeInsets.symmetric(
                                                    horizontal: 1),
                                          ),
                                          child: DropdownButton<int>(
                                            hint: Text(
                                              'State',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context)
                                                      .hintColor),
                                            ),
                                            value: selectedstateId,
                                            isExpanded: true,
                                            underline:
                                                Container(), // This removes the underline
                                            onChanged: (int? newValue) {
                                              setState(() {
                                                selectedstateId = newValue!;
                                              });
                                            },
                                            items: stat
                                                .map<DropdownMenuItem<int>>(
                                                    (State) {
                                              return DropdownMenuItem<int>(
                                                value: State['id'],
                                                child: Text(State['name']),
                                              );
                                            }).toList(),
                                            icon: Container(
                                              padding: EdgeInsets.only(
                                                  left:
                                                      190), // Adjust padding as needed
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
                              ),
                              SizedBox(
                                height: 8,
                              ),
                              Text(
                                "Customer",
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 5,
                              ),

                              if (selectedmode == "request" ||
                                  selectedmode == 'invoice')
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return DropdownButtonHideUnderline(
                                        child: Container(
                                          height: 46,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.grey, width: 1.0),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          child: DropdownButton2<int>(
                                            isExpanded: true,
                                            hint: Text(
                                              'Select a Customer',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    Theme.of(context).hintColor,
                                              ),
                                            ),
                                            items: customer.map((item) {
                                              return DropdownMenuItem<int>(
                                                value: item['id'],
                                                child: Text(
                                                  item['name'] ?? '',
                                                  style: const TextStyle(
                                                      fontSize: 12),
                                                ),
                                              );
                                            }).toList(),
                                            value: selectedCustomerId,
                                            onChanged: (value) async {
                                              if (value == null) return;

                                              final selectedCustomer =
                                                  customer.firstWhere(
                                                (item) => item['id'] == value,
                                                orElse: () => {},
                                              );

                                              setState(() {
                                                selectedCustomerId = value;
                                                selectedCustomerName =
                                                    selectedCustomer['name'];
                                                selectedAddressId = null;
                                                addres = [];
                                              });

                                              await getaddress(value);
                                            },
                                            buttonStyleData:
                                                const ButtonStyleData(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 16),
                                              height: 40,
                                            ),
                                            dropdownStyleData:
                                                const DropdownStyleData(
                                              maxHeight: 300,
                                            ),
                                            menuItemStyleData:
                                                const MenuItemStyleData(
                                              height: 40,
                                            ),
                                            dropdownSearchData:
                                                DropdownSearchData(
                                              searchController:
                                                  textEditingController,
                                              searchInnerWidgetHeight: 50,
                                              searchInnerWidget: Container(
                                                height: 50,
                                                padding: const EdgeInsets.only(
                                                  top: 8,
                                                  bottom: 4,
                                                  right: 8,
                                                  left: 8,
                                                ),
                                                child: TextFormField(
                                                  controller:
                                                      textEditingController,
                                                  expands: true,
                                                  maxLines: null,
                                                  decoration: InputDecoration(
                                                    isDense: true,
                                                    contentPadding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                      horizontal: 10,
                                                      vertical: 8,
                                                    ),
                                                    hintText:
                                                        'Search customer...',
                                                    hintStyle: const TextStyle(
                                                        fontSize: 12),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                  ),
                                                  onChanged: (value) {
                                                    if (_debounce?.isActive ??
                                                        false)
                                                      _debounce!.cancel();

                                                    _debounce = Timer(
                                                        const Duration(
                                                            milliseconds: 500),
                                                        () async {
                                                      setState(() {
                                                        selectedCustomerId =
                                                            null;
                                                        selectedCustomerName =
                                                            null;
                                                        selectedAddressId =
                                                            null;
                                                        addres = [];
                                                        customer = [];
                                                      });

                                                      if (dep == "BDO" ||
                                                          dep == "BDM") {
                                                        await getcustomer2();
                                                      } else {
                                                        await getcustomer(
                                                            search: value);
                                                      }
                                                    });
                                                  },
                                                ),
                                              ),
                                              searchMatchFn:
                                                  (item, searchValue) {
                                                final childText =
                                                    (item.child is Text)
                                                        ? ((item.child as Text)
                                                                .data ??
                                                            '')
                                                        : '';
                                                return childText
                                                    .toLowerCase()
                                                    .contains(searchValue
                                                        .toLowerCase());
                                              },
                                            ),
                                            onMenuStateChange: (isOpen) {
                                              if (!isOpen) {
                                                textEditingController.clear();
                                              }
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                              SizedBox(height: 8),
                              if (selectedCustomerId != null)
                                if (addres.isNotEmpty) ...[
                                  Text("Shipping Address",
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(height: 5),
                                ] else ...[
                                  Row(
                                    children: [
                                      Text("No Address Found :",
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red)),
                                      SizedBox(width: 10),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => add_address(
                                                  customerid:
                                                      selectedCustomerId ?? 0,
                                                  name: selectedCustomerName),
                                            ),
                                          );
                                        },
                                        child: Text("Add",
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: const Color.fromARGB(
                                                    255, 1, 162, 237))),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 5),
                                ],
                              if (selectedCustomerId != null)
                                if (addres.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: Container(
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
                                                    EdgeInsets.symmetric(
                                                        horizontal: 1),
                                              ),
                                              child: DropdownButton<int>(
                                                hint: Text(
                                                  'Address',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(context)
                                                        .hintColor,
                                                  ),
                                                ),
                                                value: selectedAddressId,
                                                isExpanded: true,
                                                underline: Container(),
                                                onChanged: (int? newValue) {
                                                  setState(() {
                                                    selectedAddressId =
                                                        newValue!;
                                                  });
                                                },
                                                items: addres
                                                    .map<DropdownMenuItem<int>>(
                                                        (address) {
                                                  return DropdownMenuItem<int>(
                                                    value: address['id'],
                                                    child: Text(
                                                      "${address['address']}",
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        height: 1.3,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                                selectedItemBuilder:
                                                    (BuildContext context) {
                                                  return addres
                                                      .map<Widget>((address) {
                                                    final isSelected =
                                                        selectedAddressId ==
                                                            address['id'];

                                                    return Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Text(
                                                        isSelected
                                                            ? "${address['address']}"
                                                            : "Address",
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.black,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    );
                                                  }).toList();
                                                },
                                                icon: Container(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: Icon(
                                                    Icons.arrow_drop_down,
                                                    color: const Color.fromARGB(
                                                        255, 151, 150, 150),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                              // Display the selected address below the dropdown
                              if (selectedAddressId != null)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 10, right: 10),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F9FB),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE0E0E0),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(top: 2),
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.blue.withOpacity(0.08),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.location_on_outlined,
                                            size: 16,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                "Selected Shipping Address",
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF6B7280),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "${addres.firstWhere((address) => address['id'] == selectedAddressId)['address']}",
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  height: 1.45,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF111827),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              SizedBox(
                                height: 8,
                              ),
                              Text(
                                "Invoice Date",
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 5),

                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Container(
                                  height: 46,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.grey, width: 1.0),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 12),

                                      // Date text takes only required space
                                      Text(
                                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color.fromARGB(
                                              255, 116, 116, 116),
                                        ),
                                      ),

                                      // Push icon to the right safely
                                      const Spacer(),

                                      GestureDetector(
                                        onTap: () {
                                          _selectDate(context);
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12),
                                          child: Icon(Icons.date_range),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(height: 8),

                              Text(
                                "Courier Service",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),

                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Container(
                                  height: 49,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: selectedCourierServiceId,
                                      isExpanded: true,
                                      hint: const Text(
                                        "Select Courier Service",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      icon: const Icon(Icons.arrow_drop_down),
                                      onChanged: (int? newValue) {
                                        setState(() {
                                          selectedCourierServiceId = newValue;
                                        });
                                      },
                                      items: courierdata
                                          .map<DropdownMenuItem<int>>(
                                              (service) {
                                        return DropdownMenuItem<int>(
                                          value: service['id'],
                                          child: Text(
                                            service['name'] ?? '',
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: 8),

                              Text(
                                "Courier Service Note",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),

                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: TextField(
                                  controller: parcelServiceNoteController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText: 'Enter courier service note',
                                    hintStyle: const TextStyle(fontSize: 12),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide:
                                          const BorderSide(color: Colors.grey),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide:
                                          const BorderSide(color: Colors.blue),
                                    ),
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),

                              SizedBox(
                                height: 20,
                              ),
                            ],
                          ),
                        )),
                  ),
                ],
              ),
            ),
            Container(
              child: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 15, left: 15, right: 15),
                    child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                              color: Color.fromARGB(255, 202, 202, 202)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 15,
                              ),
                              Text(
                                "Bank Details ",
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                "Payment Status ",
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: '',
                                      contentPadding:
                                          EdgeInsets.symmetric(horizontal: 1),
                                    ),
                                    child: DropdownButton<String>(
                                      value: selectpaystatus,
                                      underline:
                                          Container(), // Removes the underline
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectpaystatus = newValue!;
                                        });
                                      },
                                      items: paystatus
                                          .map<DropdownMenuItem<String>>(
                                              (String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(
                                            value,
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        );
                                      }).toList(),
                                      icon: Container(
                                        padding: EdgeInsets.only(left: 240),
                                        alignment: Alignment.centerRight,
                                        child: Icon(Icons.arrow_drop_down),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (selectpaystatus == "COD") ...[
                                SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  "COD Type",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding:
                                            EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                      child: DropdownButton<String>(
                                        value: selectcodtype,
                                        isExpanded:
                                            true, // <-- IMPORTANT (prevents overflow)
                                        underline: Container(),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            selectcodtype = newValue!;
                                          });
                                        },
                                        items: codtype.map((value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value,
                                                style: TextStyle(fontSize: 12)),
                                          );
                                        }).toList(),

                                        icon: Icon(Icons
                                            .arrow_drop_down), // <-- No padding
                                      ),
                                    ),
                                  ),
                                )
                              ],
                              if (selectpaystatus == "COD") ...[
                                SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  "COD Amount ",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: TextField(
                                    controller: codamountcontroller,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: 'Enter COD Amount',
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 15),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        borderSide:
                                            BorderSide(color: Colors.grey),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        borderSide:
                                            BorderSide(color: Colors.blue),
                                      ),
                                    ),
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                              if (selectcodtype == "PARTIAL_COD") ...[
                                SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  "Advance COD Amount ",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: TextField(
                                    controller: advancecodamount,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: 'Enter Advance Amount',
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 15),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        borderSide:
                                            BorderSide(color: Colors.grey),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        borderSide:
                                            BorderSide(color: Colors.blue),
                                      ),
                                    ),
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                              SizedBox(
                                height: 8,
                              ),
                              Text(
                                "Bank",
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Container(
                                  height: 49,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: const Color.fromARGB(
                                            255, 206, 206, 206)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 20),
                                      Container(
                                        width: 280,
                                        child: InputDecorator(
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              hintText: 'Select',
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 1),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<int>(
                                                hint: Text(
                                                  'Select',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600]),
                                                ),
                                                value: selectedbankId,
                                                isExpanded: true,
                                                dropdownColor:
                                                    const Color.fromARGB(
                                                        255, 255, 255, 255),
                                                icon: Icon(
                                                    Icons.arrow_drop_down,
                                                    color: const Color.fromARGB(
                                                        255, 107, 107, 107)),
                                                onChanged: (int? newValue) {
                                                  setState(() {
                                                    selectedbankId =
                                                        newValue; // Store the selected family ID
                                                  });
                                                },
                                                items: bank
                                                    .map<DropdownMenuItem<int>>(
                                                        (bank) {
                                                  return DropdownMenuItem<int>(
                                                    value: bank['id'],
                                                    child: Text(
                                                      bank['name'],
                                                      style: TextStyle(
                                                          color: Colors.black87,
                                                          fontSize: 12),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            )),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Text(
                                "Payment Method ",
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8), // Adjusted padding
                                    ),
                                    child: DropdownButton<String>(
                                      value: selectpaymethod,
                                      underline:
                                          SizedBox(), // Removes the underline
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectpaymethod = newValue!;
                                        });
                                      },
                                      items: paymethod
                                          .map<DropdownMenuItem<String>>(
                                              (String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(
                                            value,
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        );
                                      }).toList(),
                                      icon: Icon(Icons
                                          .arrow_drop_down), // Default icon without excessive padding
                                      isExpanded:
                                          true, // Ensures dropdown expands within its container
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Text(
                                "ADD Recipt",
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              SizedBox(
                                height: 8,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (selectedCourierServiceId == null) {
                                        ScaffoldMessenger.of(context)
                                            .clearSnackBars();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                "Please select parcel service"),
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                        return;
                                      }
                                      if (selectpaystatus == "COD") {
                                        // Validate COD Amount
                                        if (codamountcontroller.text
                                            .trim()
                                            .isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  "Please enter COD amount"),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return; // stop execution, do not show dialog
                                        }
                                      }
                                      if (selectpaystatus == "COD") {
                                        if (selectcodtype == "Partial_COD") {
                                          if (advancecodamount.text
                                              .trim()
                                              .isEmpty) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    "Please enter Advance COD amount"),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return; // stop execution, do not show dialog
                                          }
                                        }
                                      }

                                      if (selectpaystatus == "COD") {
                                        if (selectcodtype == "select type") {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  "Please select COD type"),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return; // stop execution, do not show dialog
                                        }
                                      }

                                      // If COD is entered or payment is not COD -> proceed
                                      showTotalDialog(context);
                                    },
                                    style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all<Color>(
                                        Colors.blue,
                                      ),
                                      shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      fixedSize:
                                          MaterialStateProperty.all<Size>(
                                        Size(95, 15),
                                      ),
                                    ),
                                    child: Text("Generate Invoice",
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 20,
                              ),
                            ],
                          ),
                        )),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
          ],
        )),
      ),
    );
  }
}
