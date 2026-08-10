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

class Performa_order_request extends StatefulWidget {
  const Performa_order_request({super.key});

  @override
  State<Performa_order_request> createState() => _Performa_order_requestState();
}

class _Performa_order_requestState extends State<Performa_order_request> {
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

  int? selectedCompanyId;

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
  String? selectedCustomerName;
  Timer? _debounce;
  List<Map<String, dynamic>> variant = [];
  int? selectedFamilyId;
  List<Map<String, dynamic>> cartdata = [];
  var Discount;

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
  String loggedInStaffName = '';
  String loggedInFamilyName = '';

  @override
  void initState() {
    super.initState();
    initdata();
  }

  var dep;

  bool get canChooseStaffAndFamily {
    final String departmentName = dep?.toString().trim() ?? '';

    return departmentName == 'ADMIN' ||
        departmentName == 'Accounts / Accounting' ||
        departmentName == 'CEO' ||
        departmentName == 'COO' ||
        departmentName == 'CSO';
  }

  void initdata() async {
    await getprofiledata();

    dep = await getdepFromPrefs();

    if (dep == "BDO" || dep == "BDM") {
      await getcustomer2();
    } else {
      await getcustomer();
    }

    await getfamily();

    selectedFamilyId = famid;
    selectedstaffId = staffid;

    final Map<String, dynamic> loggedInFamily = fam.firstWhere(
      (family) => family['id'] == famid,
      orElse: () => <String, dynamic>{'name': ''},
    );

    loggedInFamilyName =
        loggedInFamily['name']?.toString() ?? '';

    if (canChooseStaffAndFamily) {
      await getstaff();
    }

    await getstate();
    await fetchProductList();
    await getbank();
    await getcompany();
    await fetchCartData();

    searchController.addListener(() {
      filterProducts();
    });
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

  var warehouse;

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

  Future<void> createlog({
    required BuildContext scaffoldContext,
    required dynamic createdProformaData,
    required dynamic createdProformaId,
  }) async {
    final String? token = await gettokenFromPrefs();

    if (token == null || token.trim().isEmpty) {
      debugPrint(
        'Unable to create proforma log: authentication token not found.',
      );
      return;
    }

    try {
      final http.Response response = await http.post(
        Uri.parse(
          '$api/api/datalog/create/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'before_data': {
            'Action': 'Proforma created',
          },
          'after_data': {
            'Data': createdProformaData,
          },
          'order': '',
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        debugPrint(
          'Proforma creation log added successfully. '
          'Proforma ID: $createdProformaId',
        );
      } else {
        debugPrint(
          'Proforma creation log failed: '
          '${response.statusCode} - ${response.body}',
        );
      }
    } catch (error) {
      debugPrint(
        'Error creating proforma log: $error',
      );
    }
  }

  void performaordercreate(
    BuildContext scaffoldContext,
  ) async {
    try {
      warehouse = await getwarehouseFromPrefs();
      final token = await gettokenFromPrefs();
      var response = await http.post(
        Uri.parse('$api/api/perfoma/invoice/create/'),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'manage_staff': selectedstaffId,
          "company": selectedCompanyId,
          "customer": selectedCustomerId,
          "warehouse_id": warehouse,
          'billing_address': selectedAddressId,
          'order_date':
              "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}",
          "family": selectedFamilyId,
          "state": selectedstateId,
          'total_amount': tot,
        }),
      );
      if (response.statusCode == 201) {
        dynamic createdProformaData;
        dynamic createdProformaId;

        try {
          createdProformaData = jsonDecode(response.body);

          if (createdProformaData is Map) {
            createdProformaId =
                createdProformaData['id'] ??
                createdProformaData['data']?['id'];
          }
        } catch (_) {
          createdProformaData = response.body;
        }

        await createlog(
          scaffoldContext: scaffoldContext,
          createdProformaData: createdProformaData,
          createdProformaId: createdProformaId,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Performa Created Successfully.'),
          ),
        );
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => order_products()));
      } else {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Performa Creation failed.'),
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

  void toggleExpansion(int productId) {
    setState(() {
      if (expandedRows.contains(productId)) {
        expandedRows.remove(productId);
      } else {
        expandedRows.add(productId);
      }
    });
  }

  void filterProducts() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredProducts = products
          .where((product) => product['name'].toLowerCase().contains(query))
          .toList();
    });
  }

// Current date only. Date selection is intentionally disabled.
  DateTime get currentDate => DateTime.now();

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
                  backgroundColor: Colors.blue, // Set the text color to white
                ),
                onPressed: () {
                  performaordercreate(context);
                },
                child: Text("OK"),
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

  Future<void> getcustomer2({String search = ''}) async {
    try {
      final token = await gettokenFromPrefs();

      final queryParameters = <String, String>{};

      if (search.trim().isNotEmpty) {
        queryParameters['search'] = search.trim();
      }

      final uri = Uri.parse('$api/api/staff/customers/').replace(
        queryParameters: queryParameters,
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("Staff Customer API URL: $uri");
      debugPrint("Staff Customer API Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List<dynamic> customersData = [];

        if (parsed is Map && parsed['data'] is List) {
          customersData = parsed['data'];
        } else if (parsed is Map && parsed['results'] is List) {
          customersData = parsed['results'];
        } else if (parsed is List) {
          customersData = parsed;
        }

        final List<Map<String, dynamic>> newCustomers =
            customersData.map((item) {
          return {
            'id': item['id'],
            'name': item['name'] ?? '',
            'created_at': item['created_at'],
            'phone': item['phone'] ?? '',
            'state': item['state_name'] ?? item['state'] ?? '',
            'gst': item['gst'] ?? '',
          };
        }).toList();

        debugPrint("Staff customer count: ${newCustomers.length}");
        if (newCustomers.isNotEmpty) {
          debugPrint("First staff customer: ${newCustomers.first}");
        }

        if (!mounted) return;

        setState(() {
          customer = newCustomers;
        });
      } else {
        debugPrint("Staff Customer API Error: ${response.body}");
      }
    } catch (e) {
      debugPrint("Staff customer fetch error: $e");
    }
  }

  Future<void> _openCustomerSelector() async {
    final TextEditingController modalSearchController = TextEditingController();
    final FocusNode modalSearchFocusNode = FocusNode();

    Timer? modalDebounce;
    bool isSearching = false;
    bool isInitialLoading = true;
    List<Map<String, dynamic>> modalCustomers = [];

    final bool isStaffCustomer = dep == "BDO" || dep == "BDM";

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (modalContext, modalSetState) {
            Future<void> loadInitialCustomers() async {
              final result = await fetchCustomersForDropdown(
                staffCustomer: isStaffCustomer,
              );

              if (!mounted) return;

              modalSetState(() {
                modalCustomers = result;
                isInitialLoading = false;
              });
            }

            Future<void> searchCustomers(String value) async {
              final searchText = value.trim();

              if (searchText.length < 2) {
                final result = await fetchCustomersForDropdown(
                  staffCustomer: isStaffCustomer,
                );

                if (!mounted) return;

                modalSetState(() {
                  modalCustomers = result;
                  isSearching = false;
                });
                return;
              }

              modalSetState(() {
                isSearching = true;
              });

              final result = await fetchCustomersForDropdown(
                search: searchText,
                staffCustomer: isStaffCustomer,
              );

              if (!mounted) return;

              modalSetState(() {
                modalCustomers = result;
                isSearching = false;
              });
            }

            if (isInitialLoading) {
              Future.microtask(loadInitialCustomers);
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "Select Customer",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              FocusScope.of(modalContext).unfocus();
                              Navigator.pop(bottomSheetContext);
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: TextField(
                        controller: modalSearchController,
                        focusNode: modalSearchFocusNode,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: "Search customer by name or phone...",
                          hintStyle: const TextStyle(fontSize: 13),
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: modalSearchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () async {
                                    modalSearchController.clear();
                                    modalDebounce?.cancel();

                                    modalSetState(() {
                                      isSearching = true;
                                    });

                                    final result =
                                        await fetchCustomersForDropdown(
                                      staffCustomer: isStaffCustomer,
                                    );

                                    if (!mounted) return;

                                    modalSetState(() {
                                      modalCustomers = result;
                                      isSearching = false;
                                    });
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          modalSetState(() {});

                          if (modalDebounce?.isActive ?? false) {
                            modalDebounce!.cancel();
                          }

                          modalDebounce = Timer(
                            const Duration(milliseconds: 500),
                            () async {
                              await searchCustomers(value);
                            },
                          );
                        },
                      ),
                    ),
                    if (isInitialLoading || isSearching)
                      const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (modalCustomers.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text(
                            "No customers found",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: modalCustomers.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = modalCustomers[index];

                            final int? customerId = item['id'];
                            final String customerName =
                                item['name']?.toString() ?? '';
                            final String phone =
                                item['phone']?.toString() ?? '';
                            final String state =
                                item['state']?.toString() ?? '';

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.withOpacity(0.08),
                                child: Text(
                                  customerName.isNotEmpty
                                      ? customerName[0].toUpperCase()
                                      : "?",
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                customerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                [
                                  if (phone.isNotEmpty) phone,
                                  if (state.isNotEmpty) state,
                                ].join(" • "),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                size: 20,
                              ),
                              onTap: () async {
                                if (customerId == null) return;

                                FocusScope.of(modalContext).unfocus();

                                setState(() {
                                  selectedCustomerId = customerId;
                                  selectedCustomerName = customerName;
                                  selectedAddressId = null;
                                  addres = [];
                                });

                                Navigator.pop(bottomSheetContext);

                                await getaddress(customerId);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    modalDebounce?.cancel();

    FocusManager.instance.primaryFocus?.unfocus();

    await Future.delayed(const Duration(milliseconds: 300));

    modalSearchController.dispose();
    modalSearchFocusNode.dispose();
  }

  Future<List<Map<String, dynamic>>> fetchCustomersForDropdown({
    String search = '',
    bool staffCustomer = false,
  }) async {
    try {
      final token = await gettokenFromPrefs();

      final endpoint =
          staffCustomer ? '$api/api/staff/customers/' : '$api/api/customers/';

      final queryParameters = <String, String>{};

      if (search.trim().isNotEmpty) {
        queryParameters['search'] = search.trim();
      }

      final uri = Uri.parse(endpoint).replace(
        queryParameters: queryParameters,
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("Customer Dropdown API URL: $uri");
      debugPrint("Customer Dropdown API Status: ${response.statusCode}");

      if (response.statusCode != 200) {
        debugPrint("Customer Dropdown API Error: ${response.body}");
        return [];
      }

      final parsed = jsonDecode(response.body);

      List<dynamic> customersData = [];

      if (parsed is Map && parsed['results'] is List) {
        customersData = parsed['results'];
      } else if (parsed is Map && parsed['data'] is List) {
        customersData = parsed['data'];
      } else if (parsed is List) {
        customersData = parsed;
      }

      final customers = customersData.map<Map<String, dynamic>>((item) {
        return {
          'id': item['id'],
          'name': item['name'] ?? '',
          'created_at': item['created_at'],
          'phone': item['phone'] ?? '',
          'state': item['state_name'] ?? item['state'] ?? '',
          'gst': item['gst'] ?? '',
        };
      }).toList();

      debugPrint("Customer Dropdown Count: ${customers.length}");

      return customers;
    } catch (e) {
      debugPrint("Customer dropdown fetch error: $e");
      return [];
    }
  }

  Future<void> getcustomer({String search = ''}) async {
    try {
      final token = await gettokenFromPrefs();

      final queryParameters = <String, String>{};

      if (search.trim().isNotEmpty) {
        queryParameters['search'] = search.trim();
      }

      final uri = Uri.parse('$api/api/customers/').replace(
        queryParameters: queryParameters,
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("Customer API URL: $uri");
      debugPrint("Customer API Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List<dynamic> customersData = [];

        if (parsed is Map && parsed['results'] is List) {
          customersData = parsed['results'];
        } else if (parsed is Map && parsed['data'] is List) {
          customersData = parsed['data'];
        } else if (parsed is List) {
          customersData = parsed;
        }

        final List<Map<String, dynamic>> newCustomers =
            customersData.map((item) {
          return {
            'id': item['id'],
            'name': item['name'] ?? '',
            'phone': item['phone'] ?? '',
            'state': item['state_name'] ?? item['state'] ?? '',
            'gst': item['gst'] ?? '',
          };
        }).toList();

        debugPrint("Customer count: ${newCustomers.length}");
        if (newCustomers.isNotEmpty) {
          debugPrint("First customer: ${newCustomers.first}");
        }

        if (!mounted) return;

        setState(() {
          customer = newCustomers;
        });
      } else {
        debugPrint("Customer API Error: ${response.body}");
      }
    } catch (e) {
      debugPrint("Customer fetch error: $e");
    }
  }

  List<Map<String, dynamic>> stat = [];

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
  var allocatedstates;

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
          selectedstaffId = productsData['id'];
          loggedInStaffName = productsData['name']?.toString() ?? '';
          allocatedstates = productsData['allocated_states'];
        });
        getstate();
      }
    } catch (error) {}
  }

  var department = '';

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
    _debounce?.cancel();
    super.dispose();
  }

  String selectcomp = "MICHEAL IMPORT EXPORT PVT LTD";
  List<String> paystatus = ["Payed", 'COD', 'credit'];
  String selectpaystatus = "COD";
  List<String> paymethod = [
    'Razorpay',
    "Credit Card",
    'Debit Card',
    'Net Banking',
    'PayPal',
    'Cash on Delivery',
    'Bank Transfer'
  ];
  String selectpaymethod = "Razorpay";

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


  static const Color _primaryColor = Color(0xFF2563EB);
  static const Color _primaryDark = Color(0xFF1D4ED8);
  static const Color _pageBackground = Color(0xFFF4F7FB);
  static const Color _textPrimary = Color(0xFF101828);
  static const Color _textSecondary = Color(0xFF667085);
  static const Color _borderColor = Color(0xFFE4E7EC);
  static const Color _fieldBackground = Color(0xFFF9FAFB);

  InputDecoration _fieldDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 14,
        color: Color(0xFF98A2B3),
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(
        icon,
        size: 21,
        color: const Color(0xFF667085),
      ),
      filled: true,
      fillColor: _fieldBackground,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _borderColor,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _primaryColor,
          width: 1.5,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _borderColor,
          width: 1,
        ),
      ),
    );
  }

  Widget _sectionLabel(
    String label, {
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          if (required)
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFFD92D20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEAECF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDropdownField({
    required int? value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<int>> items,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0xFF667085),
      ),
      decoration: _fieldDecoration(
        hintText: hint,
        icon: icon,
      ),
      items: items,
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      ),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(14),
    );
  }

  Widget _buildReadOnlyField({
    required String value,
    required String placeholder,
    required IconData icon,
    IconData? trailingIcon,
  }) {
    final bool hasValue = value.trim().isNotEmpty;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _fieldBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 21,
            color: const Color(0xFF667085),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasValue ? value : placeholder,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    hasValue ? FontWeight.w600 : FontWeight.w400,
                color: hasValue
                    ? _textPrimary
                    : const Color(0xFF98A2B3),
              ),
            ),
          ),
          if (trailingIcon != null)
            Icon(
              trailingIcon,
              size: 21,
              color: const Color(0xFF98A2B3),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerField() {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        await _openCustomerSelector();
      },
      child: _buildReadOnlyField(
        value: selectedCustomerName ?? '',
        placeholder: 'Select a customer',
        icon: Icons.person_search_outlined,
        trailingIcon: Icons.keyboard_arrow_down_rounded,
      ),
    );
  }

  Widget _buildAddressSelector() {
    if (selectedCustomerId == null) {
      return const SizedBox.shrink();
    }

    if (addres.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFAEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFEC84B)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFB54708),
              size: 20,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'No shipping address found for this customer.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7A2E0E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => add_address(
                      customerid: selectedCustomerId ?? 0,
                      name: selectedCustomerName,
                    ),
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Shipping Address', required: true),
        _buildDropdownField(
          value: selectedAddressId,
          hint: 'Select shipping address',
          icon: Icons.location_on_outlined,
          items: addres.map<DropdownMenuItem<int>>((address) {
            return DropdownMenuItem<int>(
              value: address['id'],
              child: Text(
                address['address']?.toString() ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              selectedAddressId = value;
            });
          },
        ),
        if (selectedAddressId != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFB9E6FE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  size: 20,
                  color: Color(0xFF026AA2),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    addres
                        .firstWhere(
                          (address) =>
                              address['id'] == selectedAddressId,
                          orElse: () => {'address': ''},
                        )['address']
                        .toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: Color(0xFF0B4A6F),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = currentDate;

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF2F4F7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: _textPrimary,
            ),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Proforma',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Prepare a new proforma order request',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: _textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF8FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  'lib/assets/profile.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(
            top: 18,
            bottom: 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2563EB),
                      Color(0xFF4F46E5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x332563EB),
                      blurRadius: 22,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0x33FFFFFF),
                        borderRadius: BorderRadius.all(
                          Radius.circular(16),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(
                          Icons.description_outlined,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Proforma Order Request',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Confirm company, customer and delivery details before generating.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.45,
                              color: Color(0xFFE0E7FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.business_center_outlined,
                          color: _primaryColor,
                          size: 22,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Order Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel('Company', required: true),
                    _buildDropdownField(
                      value: selectedCompanyId,
                      hint: 'Select a company',
                      icon: Icons.apartment_outlined,
                      items: company.map<DropdownMenuItem<int>>((item) {
                        return DropdownMenuItem<int>(
                          value: item['id'],
                          child: Text(
                            item['name']?.toString() ?? '',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCompanyId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _sectionLabel('Family', required: true),
                    if (canChooseStaffAndFamily)
                      _buildDropdownField(
                        value: selectedFamilyId,
                        hint: 'Select a family',
                        icon: Icons.account_tree_outlined,
                        items: fam.map<DropdownMenuItem<int>>((family) {
                          return DropdownMenuItem<int>(
                            value: family['id'],
                            child: Text(
                              family['name']?.toString() ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          final Map<String, dynamic> selectedFamily =
                              fam.firstWhere(
                            (family) => family['id'] == value,
                            orElse: () =>
                                <String, dynamic>{'name': ''},
                          );

                          setState(() {
                            selectedFamilyId = value;
                            loggedInFamilyName =
                                selectedFamily['name']?.toString() ?? '';
                          });
                        },
                      )
                    else
                      _buildReadOnlyField(
                        value: loggedInFamilyName,
                        placeholder: 'Loading family details...',
                        icon: Icons.account_tree_outlined,
                        trailingIcon: Icons.lock_outline_rounded,
                      ),
                    const SizedBox(height: 16),
                    _sectionLabel('Staff Name', required: true),
                    if (canChooseStaffAndFamily)
                      _buildDropdownField(
                        value: selectedstaffId,
                        hint: 'Select staff',
                        icon: Icons.badge_outlined,
                        items: sta.map<DropdownMenuItem<int>>((staff) {
                          return DropdownMenuItem<int>(
                            value: staff['id'],
                            child: Text(
                              staff['name']?.toString() ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            selectedstaffId = value;
                          });
                        },
                      )
                    else
                      _buildReadOnlyField(
                        value: loggedInStaffName,
                        placeholder: 'Loading staff details...',
                        icon: Icons.badge_outlined,
                        trailingIcon: Icons.lock_outline_rounded,
                      ),
                    const SizedBox(height: 16),
                    _sectionLabel('State', required: true),
                    _buildDropdownField(
                      value: selectedstateId,
                      hint: 'Select a state',
                      icon: Icons.map_outlined,
                      items: stat.map<DropdownMenuItem<int>>((state) {
                        return DropdownMenuItem<int>(
                          value: state['id'],
                          child: Text(
                            state['name']?.toString() ?? '',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedstateId = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.person_pin_circle_outlined,
                          color: _primaryColor,
                          size: 22,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Customer & Delivery',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel('Customer', required: true),
                    _buildCustomerField(),
                    if (selectedCustomerId != null) ...[
                      const SizedBox(height: 16),
                      _buildAddressSelector(),
                    ],
                    const SizedBox(height: 16),
                    _sectionLabel('Invoice Date'),
                    _buildReadOnlyField(
                      value:
                          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
                      placeholder: '',
                      icon: Icons.calendar_today_outlined,
                      trailingIcon: Icons.lock_outline_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFB9E6FE),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: Color(0xFF026AA2),
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Staff and family follow department permissions. The current date is submitted automatically.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Color(0xFF0B4A6F),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showTotalDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(
                      Icons.receipt_long_outlined,
                      size: 22,
                    ),
                    label: const Text(
                      'Generate Proforma',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
