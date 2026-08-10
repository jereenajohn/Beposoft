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
import 'package:beposoft/pages/ACCOUNTS/new_performa_products.dart';
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
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';

class proforma_to_order_request extends StatefulWidget {
  var invoice;
  proforma_to_order_request({super.key, required this.invoice});

  @override
  State<proforma_to_order_request> createState() =>
      _proforma_to_order_requestState();
}

class _proforma_to_order_requestState extends State<proforma_to_order_request> {
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
  String selectcodtype = "select type";
  List<String> codtype = [
    "select type",
    "FULL_COD",
    'PARTIAL_COD',
  ];
  final TextEditingController codamountcontroller = TextEditingController();
  final TextEditingController advancecodamount = TextEditingController();
  List<Map<String, dynamic>> warehousecusomer2 = [];

  List<Map<String, dynamic>> variant = [];
  int? selectedFamilyId;
  int? selectedCompanyId;
  int? selectedwarehouseId; // Variable to store the selected department's ID
  String? selectedwarehouseName;

  List<Map<String, dynamic>> cartdata = [];
  var Discount;
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> stat = [];

  int? selectedbankId;
  String selectedstaff = '';
  int? selectedstaffId;
  int? selectedstateId;
  int? selectedAddressId; // Variable to store the selected address ID
  String? selectedAddressName; // Variable to store the selected address name
  List<Map<String, dynamic>> bank = [];

  List<Map<String, dynamic>> courierdata = [];
  int? selectedCourierServiceId;
  final TextEditingController parcelServiceNoteController =
      TextEditingController();
final TextEditingController accountsNoteController =
    TextEditingController();
  double total = 0.0;
  Set<int> expandedRows = {};
  var famid;
  var staffid;

  final ImagePicker _imagePicker = ImagePicker();
  final List<XFile> paymentReceiptImages = [];
  bool isUploadingReceiptImages = false;
  bool paymentReceiptImagesUploaded = false;
  bool isCreatingOrder = false;


  Future<void> _selectPaymentReceiptImages() async {
    final List<XFile> selectedImages =
        await _imagePicker.pickMultiImage(
      imageQuality: 85,
    );

    if (selectedImages.isEmpty || !mounted) return;

    setState(() {
      paymentReceiptImagesUploaded = false;

      for (final image in selectedImages) {
        final alreadyAdded = paymentReceiptImages.any(
          (existingImage) => existingImage.path == image.path,
        );

        if (!alreadyAdded) {
          paymentReceiptImages.add(image);
        }
      }
    });
  }

  void _removePaymentReceiptImage(int index) {
    if (index < 0 || index >= paymentReceiptImages.length) return;

    setState(() {
      paymentReceiptImages.removeAt(index);
      paymentReceiptImagesUploaded = false;
    });
  }


  Future<Uint8List> _readImageBytes(XFile image) async {
    return await image.readAsBytes();
  }

  MediaType _resolveImageMediaType(XFile image) {
    final String extension =
        image.path.split('.').last.toLowerCase();

    switch (extension) {
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'heic':
      case 'heif':
        return MediaType('image', 'heic');
      case 'jpeg':
      case 'jpg':
      default:
        return MediaType('image', 'jpeg');
    }
  }

  Future<void> addimages(BuildContext scaffoldContext) async {
    if (isUploadingReceiptImages) return;

    if (paymentReceiptImages.isEmpty) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFD92D20),
          content: Text(
            'Please select at least one payment receipt image.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isUploadingReceiptImages = true;
      paymentReceiptImagesUploaded = false;
    });

    try {
      for (final XFile image in paymentReceiptImages) {
        await image.readAsBytes();
      }

      if (!mounted) return;

      setState(() {
        paymentReceiptImagesUploaded = true;
      });

      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF027A48),
          content: Text(
            'Receipt images are ready. You can now generate the invoice.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        paymentReceiptImagesUploaded = false;
      });

      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFD92D20),
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUploadingReceiptImages = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    initdata();
  }

  var dep;
  void initdata() async {
    dep = await getdepFromPrefs();

    selectedFamilyId = famid;

    selectedstaffId = staffid;

    searchController.addListener(() {});
    getstate();
    getcourierservices();

    getbank();
    fetchperformalistData();
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

        final List<Map<String, dynamic>> courierList = [];

        if (parsed is Map &&
            parsed['data'] != null &&
            parsed['data'] is List) {
          for (final dynamic item in parsed['data']) {
            courierList.add({
              'id': item['id'],
              'name': item['name'],
            });
          }
        }

        if (!mounted) return;

        setState(() {
          courierdata = courierList;
        });
      } else {
        debugPrint(
          'Courier service fetch failed: '
          '${response.statusCode} - ${response.body}',
        );
      }
    } catch (error) {
      debugPrint('Courier service fetch error: $error');
    }
  }

  Future<void> getstate() async {
    try {
      final token = await gettokenFromPrefs();
      var response = await http.get(
        Uri.parse('$api/api/states/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        List<Map<String, dynamic>> statelist = productsData
            .map<Map<String, dynamic>>((productData) => {
                  'id': productData['id'],
                  'name': productData['name'],
                })
            .toList();

        setState(() {
          stat = statelist;
        });
      }
    } catch (error) {}
  }

  String getStateNameById(int stateId) {
    final state = stat.firstWhere(
      (element) => element['id'] == stateId,
      orElse: () => {'name': 'Unknown'}, // Return a Map with a default 'name'
    );
    return state['name'];
  }

  List<Map<String, dynamic>> perfomaItemsWithImages = [];
  Future<void> fetchperformalistData() async {
    try {
      final token = await gettokenFromPrefs();
      final response = await http.get(
        Uri.parse('$api/api/perfoma/${widget.invoice}/invoice/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List<Map<String, dynamic>> performaInvoiceList = [];

        perfomaItemsWithImages =
            (parsed['perfoma_items'] as List<dynamic>?)?.map((item) {
                  return {
                    'id': item['id'],
                    'product': item['product'],
                    'name': item['name'],
                    'quantity': item['quantity'],
                    'actual_price': item['rate'],
                    'first_image': item['images'],
                    'discount': item['discount'],
                  };
                }).toList() ??
                [];

        // Get state name from ID
        final stateName = getStateNameById(parsed['state']);

        performaInvoiceList.add({
          'id': parsed['id'],
          'invoice': parsed['invoice'],
          'manage_staff': parsed['manage_staff'],
          'company': parsed['company'],
          'company_name': parsed['company_name'],
          'customer_name': parsed['customer']?['name'] ?? 'Unknown',
          'customerID': parsed['customer']?['id'] ?? 'Unknown',

          'family': parsed['family'],
          'state': parsed['state'], // Use state name instead of ID
          'address': parsed['billing_address']?['address'] ?? 'Unknown',
          'billing_id': parsed['billing_address']['id'],
          'payment_status': parsed['payment_status'],
          'bank': parsed['bank']?['name'] ?? 'Unknown',
          'payment_method': parsed['payment_method'],
          'status': parsed['status'],
          'total_amount': parsed['total_amount'],
          'order_date': parsed['order_date'],
          'created_at': parsed['customer']?['created_at'] ?? 'Unknown',
          'perfoma_items': perfomaItemsWithImages,
          'warehouse_id': parsed['warehouse_id']
        });

        if (!mounted) return;

        setState(() {
          orders = performaInvoiceList;
        });

        await _prepareProformaCart(perfomaItemsWithImages);
      } else {
        // Handle error response
      }
    } catch (error) {
      // Handle exception
    }
  }

  Future<void> _prepareProformaCart(
    List<Map<String, dynamic>> proformaItems,
  ) async {
    try {
      await _clearExistingCart();
      await addtocart(proformaItems);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFD92D20),
          content: Text(
            'Unable to prepare proforma products: $error',
          ),
        ),
      );
    }
  }

  Future<void> _clearExistingCart() async {
    final String? token = await gettokenFromPrefs();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Authentication token not found.');
    }

    final http.Response response = await http.delete(
      Uri.parse('$api/api/cart/delete/all/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200 &&
        response.statusCode != 202 &&
        response.statusCode != 204) {
      String message = 'Unable to clear the existing cart.';

      try {
        final dynamic decoded = jsonDecode(response.body);

        if (decoded is Map) {
          message = decoded['message']?.toString() ??
              decoded['detail']?.toString() ??
              decoded['error']?.toString() ??
              message;
        }
      } catch (_) {}

      throw Exception(message);
    }

    if (mounted) {
      setState(() {
        cartdata = [];
        total = 0.0;
      });
    }
  }

  Future<void> addtocart(
    List<Map<String, dynamic>> proformaItems,
  ) async {
    final String? token = await gettokenFromPrefs();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Authentication token not found.');
    }

    for (final Map<String, dynamic> item in proformaItems) {
      final dynamic productId = item['product'];
      final int quantity =
          int.tryParse((item['quantity'] ?? 0).toString()) ?? 0;

      if (productId == null || quantity <= 0) {
        throw Exception(
          'Invalid product or quantity in the selected proforma.',
        );
      }

      final http.Response response = await http.post(
        Uri.parse('$api/api/cart/product/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'product': productId,
          'quantity': quantity,
        }),
      );

      if (response.statusCode != 200 &&
          response.statusCode != 201) {
        String message = 'Unable to add a proforma product to the cart.';

        try {
          final dynamic decoded = jsonDecode(response.body);

          if (decoded is Map) {
            message = decoded['message']?.toString() ??
                decoded['detail']?.toString() ??
                decoded['error']?.toString() ??
                message;
          }
        } catch (_) {}

        throw Exception(message);
      }
    }

    await fetchCartData();
  }

  Future<void> createlog({
    required dynamic createdOrderData,
    required dynamic createdOrderId,
  }) async {
    final String? token = await gettokenFromPrefs();

    if (token == null || token.trim().isEmpty) {
      debugPrint(
        'Unable to create order log: authentication token not found.',
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
            'Action': 'Order created from proforma',
            'Proforma ID':
                orders.isNotEmpty ? orders.first['id'] : null,
            'Proforma Invoice':
                orders.isNotEmpty ? orders.first['invoice'] : null,
          },
          'after_data': {
            'Data': createdOrderData,
          },
          'order': createdOrderId?.toString() ?? '',
        }),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        debugPrint(
          'Order creation log added successfully. '
          'Order ID: $createdOrderId',
        );
      } else {
        debugPrint(
          'Order creation log failed: '
          '${response.statusCode} - ${response.body}',
        );
      }
    } catch (error) {
      debugPrint(
        'Error creating order log: $error',
      );
    }
  }

  Future<void> ordercreate(
    BuildContext scaffoldContext,
  ) async {
    if (isCreatingOrder) return;

    if (orders.isEmpty) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFD92D20),
          content: Text(
            'Proforma details are not loaded yet. Please try again.',
          ),
        ),
      );
      return;
    }

    if (paymentReceiptImages.isEmpty) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFD92D20),
          content: Text(
            'Please select at least one payment receipt image.',
          ),
        ),
      );
      return;
    }

    if (!paymentReceiptImagesUploaded) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFD92D20),
          content: Text(
            'Please click Upload Receipt Images before generating the invoice.',
          ),
        ),
      );
      return;
    }

    final String? token = await gettokenFromPrefs();

    if (token == null || token.trim().isEmpty) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFD92D20),
          content: Text('Authentication token not found.'),
        ),
      );
      return;
    }

    final String? warehouseId = _resolveWarehouseId();

    if (warehouseId == null || warehouseId.trim().isEmpty) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFD92D20),
          content: Text('Warehouse information is missing.'),
        ),
      );
      return;
    }

    if (selectpaymethod == 'Bank Transfer' && selectedbankId == null) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFD92D20),
          content: Text('Please select the bank used for payment.'),
        ),
      );
      return;
    }

    setState(() {
      isCreatingOrder = true;
    });

    try {
      String? codStatusToSend;

      if (selectcodtype != 'select type') {
        codStatusToSend = selectcodtype;
      }

      final double totalAmount = _parseAmount(
        orders.first['total_amount'],
      );

      final http.MultipartRequest request = http.MultipartRequest(
        'POST',
        Uri.parse('$api/api/order/create/new/'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields.addAll({
        'performa_id': orders.first['id'].toString(),
        'state': orders.first['state'].toString(),
        'company': orders.first['company'].toString(),
        'family': orders.first['family'].toString(),
        'customer': orders.first['customerID'].toString(),
        'manage_staff': orders.first['manage_staff'].toString(),
        'billing_address': orders.first['billing_id'].toString(),
        'accounts_note': accountsNoteController.text.trim(),
        'warehouses': warehouseId,
        'total_amount': totalAmount.toStringAsFixed(2),
        'order_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'status': 'Invoice Created',
        'payment_status': _paymentStatusForApi(),
        'payment_method': selectpaymethod,
      });

      if (selectedCourierServiceId != null) {
        request.fields['parcel_service'] =
            selectedCourierServiceId.toString();
      }

      request.fields['parcel_service_note'] =
          parcelServiceNoteController.text.trim();

      if (selectedbankId != null) {
        request.fields['bank'] = selectedbankId.toString();
      }

      if (selectpaystatus == 'COD') {
        if (codStatusToSend != null) {
          request.fields['cod_status'] = codStatusToSend;
        }

        request.fields['cod_amount'] =
            codamountcontroller.text.trim().isEmpty
                ? '0'
                : codamountcontroller.text.trim();

        if (selectcodtype == 'PARTIAL_COD') {
          request.fields['adv_cod_amount'] =
              advancecodamount.text.trim().isEmpty
                  ? '0'
                  : advancecodamount.text.trim();
        }
      }

      for (int index = 0;
          index < paymentReceiptImages.length;
          index++) {
        final XFile image = paymentReceiptImages[index];
        final Uint8List bytes = await _readImageBytes(image);
        final String extension =
            image.path.split('.').last.toLowerCase();

        request.files.add(
          http.MultipartFile.fromBytes(
            'images',
            bytes,
            filename:
                'receipt_${DateTime.now().millisecondsSinceEpoch}_$index.$extension',
            contentType: _resolveImageMediaType(image),
          ),
        );
      }

      final http.StreamedResponse streamedResponse =
          await request.send();

      final http.Response response =
          await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        dynamic createdOrderData;
        dynamic createdOrderId;

        try {
          createdOrderData = jsonDecode(response.body);

          if (createdOrderData is Map) {
            createdOrderId =
                createdOrderData['id'] ??
                createdOrderData['order_id'] ??
                createdOrderData['data']?['id'] ??
                createdOrderData['order']?['id'];
          }
        } catch (_) {
          createdOrderData = response.body;
        }

        await createlog(
          createdOrderData: createdOrderData,
          createdOrderId: createdOrderId,
        );

        if (!mounted) return;

        if (Navigator.of(scaffoldContext).canPop()) {
          Navigator.of(scaffoldContext).pop();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF027A48),
            content: Text('Order created successfully.'),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CreatePerformaProduct_List(),
          ),
        );
      } else {
        String message = 'Order creation failed.';

        try {
          final dynamic decoded = jsonDecode(response.body);

          if (decoded is Map) {
            message = decoded['message']?.toString() ??
                decoded['detail']?.toString() ??
                decoded['error']?.toString() ??
                decoded.toString();
          }
        } catch (_) {
          if (response.body.trim().isNotEmpty) {
            message = response.body;
          }
        }

        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFD92D20),
            content: Text(message),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFD92D20),
          content: Text('Unable to create order: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isCreatingOrder = false;
        });
      }
    }
  }

  String _paymentStatusForApi() {
    switch (selectpaystatus) {
      case 'Paid':
        return 'paid';
      case 'COD':
        return 'COD';
      case 'credit':
        return 'credit';
      default:
        return selectpaystatus.toLowerCase();
    }
  }

  String? _resolveWarehouseId() {
    if (orders.isEmpty) return selectedwarehouseId?.toString();

    final dynamic warehouseValue = orders.first['warehouse_id'];

    if (warehouseValue == null) {
      return selectedwarehouseId?.toString();
    }

    if (warehouseValue is List) {
      if (warehouseValue.isEmpty) {
        return selectedwarehouseId?.toString();
      }

      final dynamic firstWarehouse = warehouseValue.first;

      if (firstWarehouse is Map) {
        return firstWarehouse['id']?.toString();
      }

      return firstWarehouse.toString();
    }

    if (warehouseValue is Map) {
      return warehouseValue['id']?.toString();
    }

    return warehouseValue.toString();
  }

  double _calculateCartTotal() {
    double calculatedTotal = 0.0;

    for (final item in cartdata) {
      final double discountPerQuantity =
          double.tryParse((item['discount'] ?? 0).toString()) ?? 0.0;
      final int quantity =
          int.tryParse((item['quantity'] ?? 0).toString()) ?? 0;
      final double price =
          double.tryParse((item['price'] ?? 0).toString()) ?? 0.0;

      calculatedTotal +=
          (quantity * price) - (quantity * discountPerQuantity);
    }

    return calculatedTotal;
  }

  Future<String?> getwarehouseFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? warehouseId = prefs.getInt('warehouse');

    // Check if warehouseId is null before converting to String
    return warehouseId?.toString();
  }

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

  double _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  void showTotalDialog(BuildContext pageContext) {
    if (orders.isEmpty) {
      ScaffoldMessenger.of(pageContext).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFD92D20),
          content: Text(
            'Proforma details are not loaded yet. Please try again.',
          ),
        ),
      );
      return;
    }

    double totalItemPrice = 0.0;
    double totalDiscount = 0.0;

    for (final item in perfomaItemsWithImages) {
      final int quantity =
          int.tryParse((item['quantity'] ?? 0).toString()) ?? 0;
      final double rate = _parseAmount(item['actual_price']);
      final double discountPerQuantity = _parseAmount(item['discount']);

      totalItemPrice += quantity * rate;
      totalDiscount += quantity * discountPerQuantity;
    }

    final double proformaTotal = _parseAmount(
      orders.first['total_amount'],
    );

    final double calculatedNetAmount =
        totalItemPrice - totalDiscount;

    final double netAmount = proformaTotal > 0
        ? proformaTotal
        : calculatedNetAmount;

    setState(() {
      tot = netAmount;
    });

    showDialog<void>(
      context: pageContext,
      barrierDismissible: !isCreatingOrder,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Proforma Total'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text('Items Total:'),
                    const Spacer(),
                    Text(
                      '₹${totalItemPrice.toStringAsFixed(2)}',
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    const Text('Total Discount:'),
                    const Spacer(),
                    Text(
                      '₹${totalDiscount.toStringAsFixed(2)}',
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    const Text(
                      'Net Amount:',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '₹${netAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: isCreatingOrder
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            SizedBox(
              width: 100,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                ),
                onPressed: isCreatingOrder
                    ? null
                    : () => ordercreate(dialogContext),
                child: const Text('OK'),
              ),
            ),
          ],
        );
      },
    );
  }

  String? selectedValue;
  int? selectedCustomerId;
  final TextEditingController textEditingController = TextEditingController();

@override
void dispose() {
  textEditingController.dispose();
  searchController.dispose();
  codamountcontroller.dispose();
  advancecodamount.dispose();
  parcelServiceNoteController.dispose();
  accountsNoteController.dispose();
  super.dispose();
}

  List<String> paystatus = ["Paid", 'COD', 'credit'];
  List<String> mode = ["request", 'invoice', 'warehouse to warehouse'];

  String selectpaystatus = "Paid";
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


  InputDecoration _professionalInputDecoration({
    required String hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 13,
        color: Color(0xFF98A2B3),
      ),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(
              prefixIcon,
              size: 20,
              color: const Color(0xFF667085),
            ),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE4E7EC),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF2563EB),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFD92D20),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFD92D20),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _fieldLabel(String label, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF344054),
            ),
          ),
          if (required)
            const Text(
              " *",
              style: TextStyle(
                color: Color(0xFFD92D20),
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeading({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF2563EB),
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF101828),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: Color(0xFF667085),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleGenerateInvoice() async {
    if (paymentReceiptImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please select payment receipt images.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!paymentReceiptImagesUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please upload the selected payment receipt images.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectpaystatus == "COD") {
      if (codamountcontroller.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enter COD amount"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (selectpaystatus == "COD") {
      if (selectcodtype == "PARTIAL_COD") {
        if (advancecodamount.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please enter Advance COD amount"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    if (selectpaystatus == "COD") {
      if (selectcodtype == "select type") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select COD type"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    showTotalDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          tooltip: "Back",
          onPressed: () => Navigator.pop(context),
          icon: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: Color(0xFF344054),
            ),
          ),
        ),
        titleSpacing: 4,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Create Order Request",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF101828),
              ),
            ),
            SizedBox(height: 2),
            Text(
              "Convert proforma invoice to an order",
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: Color(0xFF667085),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                'lib/assets/profile.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.person_outline_rounded,
                    color: Color(0xFF475467),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2563EB),
                      Color(0xFF1D4ED8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F2563EB),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Order Request",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Review payment details and generate the invoice.",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.82),
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFEAECF0),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D101828),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionHeading(
                      icon: Icons.account_balance_wallet_outlined,
                      title: "Payment Details",
                      subtitle:
                          "Configure the payment status, bank and payment method.",
                    ),
                    const SizedBox(height: 22),

               
                    _fieldLabel("Payment Status", required: true),
                    DropdownButtonFormField<String>(
                      value: selectpaystatus,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      decoration: _professionalInputDecoration(
                        hint: "Select payment status",
                        prefixIcon: Icons.payments_outlined,
                      ),
                      items: paystatus
                          .map(
                            (value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF101828),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectpaystatus = value;
                        });
                      },
                    ),

                    if (selectpaystatus == "COD") ...[
                      const SizedBox(height: 16),
                      _fieldLabel("COD Type", required: true),
                      DropdownButtonFormField<String>(
                        value: selectcodtype,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        decoration: _professionalInputDecoration(
                          hint: "Select COD type",
                          prefixIcon: Icons.local_shipping_outlined,
                        ),
                        items: codtype
                            .map(
                              (value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF101828),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            selectcodtype = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _fieldLabel("COD Amount", required: true),
                      TextField(
                        controller: codamountcontroller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF101828),
                        ),
                        decoration: _professionalInputDecoration(
                          hint: "Enter COD amount",
                          prefixIcon: Icons.currency_rupee_rounded,
                        ),
                      ),
                    ],

                    if (selectcodtype == "PARTIAL_COD") ...[
                      const SizedBox(height: 16),
                      _fieldLabel("Advance COD Amount", required: true),
                      TextField(
                        controller: advancecodamount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF101828),
                        ),
                        decoration: _professionalInputDecoration(
                          hint: "Enter advance amount",
                          prefixIcon: Icons.savings_outlined,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    _fieldLabel("Bank"),
                    DropdownButtonFormField<int>(
                      value: selectedbankId,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      decoration: _professionalInputDecoration(
                        hint: "Select bank",
                        prefixIcon: Icons.account_balance_outlined,
                      ),
                      items: bank
                          .map(
                            (bankItem) => DropdownMenuItem<int>(
                              value: bankItem['id'],
                              child: Text(
                                bankItem['name']?.toString() ?? "",
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF101828),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedbankId = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),
                    _fieldLabel("Payment Method", required: true),
                    DropdownButtonFormField<String>(
                      value: selectpaymethod,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      decoration: _professionalInputDecoration(
                        hint: "Select payment method",
                        prefixIcon: Icons.credit_card_outlined,
                      ),
                      items: paymethod
                          .map(
                            (value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF101828),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectpaymethod = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                         _fieldLabel("Courier Service"),
                    DropdownButtonFormField<int>(
                      value: selectedCourierServiceId,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                      ),
                      decoration: _professionalInputDecoration(
                        hint: "Select courier service",
                        prefixIcon: Icons.local_shipping_outlined,
                      ),
                      items: courierdata
                          .map(
                            (service) => DropdownMenuItem<int>(
                              value: service['id'],
                              child: Text(
                                service['name']?.toString() ?? "",
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF101828),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCourierServiceId = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),
                    _fieldLabel("Courier Service Note"),
                    TextField(
                      controller: parcelServiceNoteController,
                      maxLines: 3,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF101828),
                      ),
                      decoration: _professionalInputDecoration(
                        hint: "Enter courier service note",
                        prefixIcon: Icons.note_alt_outlined,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _fieldLabel("Accounts Note"),
TextField(
  controller: accountsNoteController,

  // Starts with a comfortable height but can keep growing.
  minLines: 4,
  maxLines: null,

  keyboardType: TextInputType.multiline,
  textInputAction: TextInputAction.newline,

  style: const TextStyle(
    fontSize: 13,
    color: Color(0xFF101828),
    height: 1.4,
  ),

  decoration: _professionalInputDecoration(
    hint: "Enter accounts note",
    prefixIcon: Icons.sticky_note_2_outlined,
  ),
),

const SizedBox(height: 16),

                   
                    _fieldLabel(
                      "Payment Receipt Images",
                      required: true,
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _selectPaymentReceiptImages,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: paymentReceiptImages.isEmpty
                                ? const Color(0xFFE4E7EC)
                                : const Color(0xFF84ADFF),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.add_photo_alternate_outlined,
                                color: Color(0xFF2563EB),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Select receipt images",
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF101828),
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    "You can select multiple payment receipt images.",
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      height: 1.35,
                                      color: Color(0xFF667085),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF667085),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (paymentReceiptImages.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(
                            "${paymentReceiptImages.length} image${paymentReceiptImages.length == 1 ? "" : "s"} selected",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475467),
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                paymentReceiptImages.clear();
                                paymentReceiptImagesUploaded = false;
                              });
                            },
                            child: const Text("Remove all"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        itemCount: paymentReceiptImages.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
                          final image =
                              paymentReceiptImages[index];

                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  child: Image.file(
                                    File(image.path),
                                    fit: BoxFit.cover,
                                    errorBuilder: (
                                      context,
                                      error,
                                      stackTrace,
                                    ) {
                                      return Container(
                                        color:
                                            const Color(0xFFF2F4F7),
                                        child: const Icon(
                                          Icons
                                              .broken_image_outlined,
                                          color:
                                              Color(0xFF98A2B3),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 5,
                                right: 5,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    onTap: () =>
                                        _removePaymentReceiptImage(
                                      index,
                                    ),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.black
                                            .withOpacity(0.68),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 17,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: isUploadingReceiptImages
                              ? null
                              : () => addimages(context),
                          icon: isUploadingReceiptImages
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  paymentReceiptImagesUploaded
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.cloud_upload_outlined,
                                  size: 20,
                                ),
                          label: Text(
                            isUploadingReceiptImages
                                ? "Uploading Images..."
                                : paymentReceiptImagesUploaded
                                    ? "Images Uploaded"
                                    : "Upload Receipt Images",
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor:
                                paymentReceiptImagesUploaded
                                    ? const Color(0xFF027A48)
                                    : const Color(0xFF7F56D9),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                const Color(0xFFBDB4FE),
                            disabledForegroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      const Text(
                        "Payment receipt images are required.",
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFFD92D20),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: paymentReceiptImagesUploaded &&
                                !isUploadingReceiptImages &&
                                !isCreatingOrder
                            ? _handleGenerateInvoice
                            : null,
                        icon: isCreatingOrder
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                paymentReceiptImagesUploaded
                                    ? Icons.description_outlined
                                    : Icons.lock_outline_rounded,
                                size: 20,
                              ),
                        label: Text(
                          isCreatingOrder
                              ? "Creating Order..."
                              : paymentReceiptImagesUploaded
                                  ? "Generate Invoice"
                                  : "Upload Receipt Images First",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFD0D5DD),
                          disabledForegroundColor: const Color(0xFF667085),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFAEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFED777),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 19,
                      color: Color(0xFFB54708),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Verify all payment details before generating the invoice.",
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: Color(0xFF7A2E0E),
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
    );
  }
}
